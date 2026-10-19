import Foundation
import Network

// MARK: - Real IMAP Connection & Sync Service
public class RealIMAPService {
    public static let shared = RealIMAPService()
    
    private init() {}
    
    public enum IMAPError: LocalizedError {
        case connectionFailed(String)
        case authenticationFailed(String)
        case timeout
        case invalidResponse
        
        public var errorDescription: String? {
            switch self {
            case .connectionFailed(let host):
                return "Impossible de joindre le serveur IMAP '\(host)'. Vérifiez l'adresse du serveur ou votre connexion internet."
            case .authenticationFailed(let reason):
                return "Échec de connexion : \(reason)"
            case .timeout:
                return "Le serveur IMAP n'a pas répondu à temps (délai dépassé)."
            case .invalidResponse:
                return "Réponse inattendue du serveur de messagerie."
            }
        }
    }
    
    // MARK: - Test and Authenticate Real IMAP Credentials
    public func authenticateAndFetch(
        email: String,
        password: String,
        serverConfig: ServerConfig
    ) async throws -> [EmailMessage] {
        let host = NWEndpoint.Host(serverConfig.imapHost)
        let port = NWEndpoint.Port(rawValue: UInt16(serverConfig.imapPort)) ?? .imaps
        
        // TLS parameters for Port 993 (IMAPS)
        let tlsOptions = NWProtocolTLS.Options()
        let tcpOptions = NWProtocolTCP.Options()
        let parameters = NWParameters(tls: tlsOptions, tcp: tcpOptions)
        
        let connection = NWConnection(host: host, port: port, using: parameters)
        
        return try await withCheckedThrowingContinuation { continuation in
            var isContinuationResumed = false
            
            func resumeOnce(with result: Result<[EmailMessage], Error>) {
                guard !isContinuationResumed else { return }
                isContinuationResumed = true
                connection.cancel()
                continuation.resume(with: result)
            }
            
            // 15 seconds connection timeout
            DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
                resumeOnce(with: .failure(IMAPError.timeout))
            }
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    // Connection established, start IMAP dialog
                    self.performIMAPHandshake(
                        connection: connection,
                        email: email,
                        password: password,
                        serverConfig: serverConfig,
                        completion: { result in
                            resumeOnce(with: result)
                        }
                    )
                case .failed(let error):
                    resumeOnce(with: .failure(IMAPError.connectionFailed("\(serverConfig.imapHost): \(error.localizedDescription)")))
                case .cancelled:
                    break
                default:
                    break
                }
            }
            
            connection.start(queue: .global())
        }
    }
    
    // MARK: - IMAP Protocol Handshake (RFC 3501)
    private func performIMAPHandshake(
        connection: NWConnection,
        email: String,
        password: String,
        serverConfig: ServerConfig,
        completion: @escaping (Result<[EmailMessage], Error>) -> Void
    ) {
        // Step 1: Read Greeting from server (* OK ...)
        self.readResponse(from: connection) { greetingResult in
            switch greetingResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let greeting):
                guard greeting.contains("* OK") || greeting.contains("*") else {
                    completion(.failure(IMAPError.invalidResponse))
                    return
                }
                
                // Step 2: Send LOGIN command
                // Note: Escaping quotes in password
                let escapedPassword = password.replacingOccurrences(of: "\"", with: "\\\"")
                let loginCmd = "A01 LOGIN \"\(email)\" \"\(escapedPassword)\"\r\n"
                
                self.sendCommand(connection: connection, command: loginCmd) { sendResult in
                    if case .failure(let error) = sendResult {
                        completion(.failure(error))
                        return
                    }
                    
                    // Read LOGIN response
                    self.readResponse(from: connection) { loginResult in
                        switch loginResult {
                        case .failure(let error):
                            completion(.failure(error))
                        case .success(let loginResponse):
                            if loginResponse.contains("A01 NO") || loginResponse.contains("A01 BAD") {
                                var msg = "Identifiant ou mot de passe incorrect."
                                if email.contains("gmail.com") || email.contains("yahoo.") || email.contains("icloud.com") {
                                    msg = "Veuillez utiliser un Mot de passe d'application généré dans les paramètres de sécurité de votre compte (exigé par \(email.split(separator: "@").last ?? "ce fournisseur"))."
                                }
                                completion(.failure(IMAPError.authenticationFailed(msg)))
                                return
                            }
                            
                            guard loginResponse.contains("A01 OK") else {
                                completion(.failure(IMAPError.invalidResponse))
                                return
                            }
                            
                            // Step 3: SELECT INBOX
                            let selectCmd = "A02 SELECT INBOX\r\n"
                            self.sendCommand(connection: connection, command: selectCmd) { selectSendResult in
                                self.readResponse(from: connection) { selectResult in
                                    // Step 4: FETCH recent messages
                                    let fetchCmd = "A03 FETCH 1:15 (UID FLAGS BODY.PEEK[HEADER.FIELDS (SUBJECT FROM DATE)])\r\n"
                                    self.sendCommand(connection: connection, command: fetchCmd) { _ in
                                        self.readResponse(from: connection) { fetchResult in
                                            let fetchedText = (try? fetchResult.get()) ?? ""
                                            let parsedMessages = self.parseIMAPFetchResponse(
                                                rawText: fetchedText,
                                                accountEmail: email
                                            )
                                            
                                            // Send LOGOUT cleanly
                                            let logoutCmd = "A04 LOGOUT\r\n"
                                            self.sendCommand(connection: connection, command: logoutCmd) { _ in
                                                completion(.success(parsedMessages))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Parse Raw IMAP FETCH Data into EmailMessage entities
    private func parseIMAPFetchResponse(rawText: String, accountEmail: String) -> [EmailMessage] {
        var messages: [EmailMessage] = []
        let chunks = rawText.components(separatedBy: "* ")
        
        for chunk in chunks where chunk.contains("FETCH") {
            var subject = "Sans objet"
            var sender = "Expéditeur inconnu"
            var date = Date()
            
            let lines = chunk.components(separatedBy: "\n")
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.lowercased().hasPrefix("subject:") {
                    subject = String(trimmed.dropFirst(8)).trimmingCharacters(in: .whitespaces)
                    subject = decodeMIMERFC2047(subject)
                } else if trimmed.lowercased().hasPrefix("from:") {
                    sender = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                    sender = decodeMIMERFC2047(sender)
                }
            }
            
            if !subject.isEmpty && subject != "Sans objet" {
                let senderClean = sender.components(separatedBy: "<").first?.trimmingCharacters(in: .whitespaces) ?? sender
                let senderEmail = sender.components(separatedBy: "<").last?.replacingOccurrences(of: ">", with: "").trimmingCharacters(in: .whitespaces) ?? sender
                
                let triage = AISmartEngine.shared.triage(
                    emailSubject: subject,
                    body: "Message reçu sur votre boîte \(accountEmail).",
                    sender: senderClean
                )
                
                let message = EmailMessage(
                    accountId: UUID(),
                    provider: .customImap,
                    senderName: senderClean.isEmpty ? senderEmail : senderClean,
                    senderEmail: senderEmail,
                    recipientEmail: accountEmail,
                    subject: subject,
                    preview: triage.summary.tldr,
                    bodyContent: "Courriel synchronisé depuis votre boîte de réception.\n\nObjet : \(subject)\nDe : \(sender)\n\n\(triage.summary.tldr)",
                    timestamp: date,
                    isRead: false,
                    category: triage.category,
                    aiSummary: triage.summary,
                    smartReplies: triage.replies
                )
                messages.append(message)
            }
        }
        
        return messages.reversed() // Most recent first
    }
    
    // MARK: - RFC 2047 MIME Header Decoder (ex: =?UTF-8?B?...?=)
    private func decodeMIMERFC2047(_ input: String) -> String {
        guard input.contains("=?") && input.contains("?=") else { return input }
        // Simple decoder fallback for common headers
        var decoded = input
        if let regex = try? NSRegularExpression(pattern: #"=\?([^?]+)\?([bBqQ])\?([^?]+)\?="#) {
            let matches = regex.matches(in: input, range: NSRange(input.startIndex..., in: input))
            for match in matches.reversed() {
                if let encodingRange = Range(match.range(at: 2), in: input),
                   let dataRange = Range(match.range(at: 3), in: input),
                   let fullRange = Range(match.range, in: input) {
                    let enc = String(input[encodingRange]).uppercased()
                    let dataStr = String(input[dataRange])
                    if enc == "B", let data = Data(base64Encoded: dataStr), let text = String(data: data, encoding: .utf8) {
                        decoded.replaceSubrange(fullRange, with: text)
                    }
                }
            }
        }
        return decoded
    }
    
    // MARK: - Low-Level Socket I/O
    private func sendCommand(connection: NWConnection, command: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let data = command.data(using: .utf8) else {
            completion(.failure(IMAPError.invalidResponse))
            return
        }
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        })
    }
    
    private func readResponse(from connection: NWConnection, completion: @escaping (Result<String, Error>) -> Void) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let data = data, let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) {
                completion(.success(text))
            } else {
                completion(.failure(IMAPError.invalidResponse))
            }
        }
    }
}
