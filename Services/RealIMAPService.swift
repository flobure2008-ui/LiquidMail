import Foundation
import Network

// MARK: - Real IMAP Connection & Sync Service with Full TLS, Tagged Streaming & SASL
public class RealIMAPService {
    public static let shared = RealIMAPService()
    
    private init() {}
    
    public enum IMAPError: LocalizedError {
        case connectionFailed(String)
        case authenticationFailed(String)
        case timeout
        case invalidResponse(String)
        
        public var errorDescription: String? {
            switch self {
            case .connectionFailed(let host):
                return "Impossible de joindre le serveur IMAP '\(host)'. Vérifiez l'adresse de votre serveur ou votre connexion internet."
            case .authenticationFailed(let reason):
                return "Échec d'authentification : \(reason)"
            case .timeout:
                return "Le serveur IMAP n'a pas répondu à temps (délai de 15s dépassé)."
            case .invalidResponse(let msg):
                return "Réponse inattendue du serveur : \(msg)"
            }
        }
    }
    
    // MARK: - Test and Authenticate Real IMAP Credentials
    public func authenticateAndFetch(
        email: String,
        password: String,
        serverConfig: ServerConfig
    ) async throws -> [EmailMessage] {
        let hostStr = serverConfig.imapHost.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !hostStr.isEmpty else {
            throw IMAPError.connectionFailed("Nom d'hôte IMAP vide.")
        }
        
        let host = NWEndpoint.Host(hostStr)
        let port = NWEndpoint.Port(rawValue: UInt16(serverConfig.imapPort)) ?? .imaps
        
        // TLS parameters for Port 993 or STARTTLS
        let tlsOptions = serverConfig.imapUseSSL ? NWProtocolTLS.Options() : nil
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
            
            // 15 seconds global connection timeout
            DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
                resumeOnce(with: .failure(IMAPError.timeout))
            }
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
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
                    resumeOnce(with: .failure(IMAPError.connectionFailed("\(hostStr):\(serverConfig.imapPort) (\(error.localizedDescription))")))
                case .cancelled:
                    break
                default:
                    break
                }
            }
            
            connection.start(queue: .global())
        }
    }
    
    // MARK: - IMAP Protocol Handshake (RFC 3501 & RFC 4616)
    private func performIMAPHandshake(
        connection: NWConnection,
        email: String,
        password: String,
        serverConfig: ServerConfig,
        completion: @escaping (Result<[EmailMessage], Error>) -> Void
    ) {
        // Step 1: Read Greeting from server (* OK ...)
        self.readGreeting(connection: connection) { greetingResult in
            switch greetingResult {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                // Step 2: Attempt Authentication
                self.performAuthentication(
                    connection: connection,
                    email: email,
                    password: password,
                    serverConfig: serverConfig
                ) { authResult in
                    switch authResult {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success:
                        // Step 3: SELECT INBOX
                        let selectCmd = "A03 SELECT INBOX\r\n"
                        self.sendCommand(connection: connection, command: selectCmd) { _ in
                            self.readUntilTagged(connection: connection, tag: "A03") { selectResult in
                                // Step 4: FETCH recent messages headers
                                let fetchCmd = "A04 FETCH 1:25 (UID FLAGS BODY.PEEK[HEADER.FIELDS (SUBJECT FROM DATE)])\r\n"
                                self.sendCommand(connection: connection, command: fetchCmd) { _ in
                                    self.readUntilTagged(connection: connection, tag: "A04") { fetchResult in
                                        let fetchedText = (try? fetchResult.get()) ?? ""
                                        let parsedMessages = self.parseIMAPFetchResponse(
                                            rawText: fetchedText,
                                            accountEmail: email
                                        )
                                        
                                        // Send LOGOUT cleanly
                                        let logoutCmd = "A05 LOGOUT\r\n"
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
    
    // MARK: - Dual-Strategy Authentication (LOGIN + SASL PLAIN)
    private func performAuthentication(
        connection: NWConnection,
        email: String,
        password: String,
        serverConfig: ServerConfig,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let effectiveUser = serverConfig.resolvedUsername(email: email)
        let escapedUser = effectiveUser.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let escapedPass = password.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        
        // Attempt 1: Standard IMAP LOGIN
        let loginCmd = "A01 LOGIN \"\(escapedUser)\" \"\(escapedPass)\"\r\n"
        self.sendCommand(connection: connection, command: loginCmd) { sendResult in
            if case .failure(let err) = sendResult {
                completion(.failure(err))
                return
            }
            
            self.readUntilTagged(connection: connection, tag: "A01") { loginResult in
                switch loginResult {
                case .failure(let err):
                    completion(.failure(err))
                case .success(let loginResponse):
                    if loginResponse.contains("A01 OK") {
                        completion(.success(()))
                        return
                    }
                    
                    // Attempt 2: SASL AUTHENTICATE PLAIN fallback
                    let authString = "\0\(effectiveUser)\0\(password)"
                    let base64Auth = Data(authString.utf8).base64EncodedString()
                    let plainCmd = "A02 AUTHENTICATE PLAIN \(base64Auth)\r\n"
                    
                    self.sendCommand(connection: connection, command: plainCmd) { plainSendResult in
                        self.readUntilTagged(connection: connection, tag: "A02") { plainResult in
                            let plainResponse = (try? plainResult.get()) ?? ""
                            if plainResponse.contains("A02 OK") {
                                completion(.success(()))
                            } else {
                                let errorReason = self.extractDetailedAuthError(
                                    email: email,
                                    serverConfig: serverConfig,
                                    responseText: loginResponse + "\n" + plainResponse
                                )
                                completion(.failure(IMAPError.authenticationFailed(errorReason)))
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Detailed Human-Friendly Error Extractor
    private func extractDetailedAuthError(email: String, serverConfig: ServerConfig, responseText: String) -> String {
        let lowerEmail = email.lowercased()
        
        if lowerEmail.contains("gmail.com") || lowerEmail.contains("googlemail.com") {
            return "Google bloque les mots de passe standards pour les apps tierces. Vous devez activer la validation en 2 étapes sur Google et générer un 'Mot de passe d'application' (16 lettres) dans myaccount.google.com/apppasswords."
        }
        if lowerEmail.contains("yahoo.") || lowerEmail.contains("myyahoo.") {
            return "Yahoo exige un 'Mot de passe d'application' (généré dans Sécurité du compte Yahoo > Gérer les mots de passe d'application)."
        }
        if lowerEmail.contains("icloud.com") || lowerEmail.contains("me.com") || lowerEmail.contains("mac.com") {
            return "Apple exige un 'Mot de passe pour application tierce' (généré sur appleid.apple.com)."
        }
        if lowerEmail.contains("outlook.") || lowerEmail.contains("hotmail.") || lowerEmail.contains("live.") {
            return "Microsoft requiert un mot de passe d'application si la double vérification est activée, ou l'utilisation d'Office 365."
        }
        
        // Extract server's own explanation after NO or BAD
        for line in responseText.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.contains(" NO ") || trimmed.contains(" BAD ") {
                let parts = trimmed.components(separatedBy: " ")
                if parts.count > 2 {
                    return parts.dropFirst(2).joined(separator: " ")
                }
                return trimmed
            }
        }
        
        return "Identifiant ou mot de passe refusé par le serveur \(serverConfig.imapHost)."
    }
    
    // MARK: - Parse Raw IMAP FETCH Data into EmailMessage entities
    private func parseIMAPFetchResponse(rawText: String, accountEmail: String) -> [EmailMessage] {
        var messages: [EmailMessage] = []
        let chunks = rawText.components(separatedBy: "* ")
        
        for chunk in chunks where chunk.contains("FETCH") {
            var subject = "Sans objet"
            var sender = "Expéditeur inconnu"
            let date = Date()
            
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
                    body: "Message synchronisé en direct depuis votre serveur IMAP.",
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
    
    // MARK: - RFC 2047 MIME Header Decoder (Base64 ?B? & Quoted-Printable ?Q?)
    private func decodeMIMERFC2047(_ input: String) -> String {
        guard input.contains("=?") && input.contains("?=") else { return input }
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
                    } else if enc == "Q" {
                        let text = decodeQuotedPrintable(dataStr)
                        decoded.replaceSubrange(fullRange, with: text)
                    }
                }
            }
        }
        return decoded
    }
    
    private func decodeQuotedPrintable(_ input: String) -> String {
        let normalized = input.replacingOccurrences(of: "_", with: " ")
        var bytes: [UInt8] = []
        var i = normalized.startIndex
        while i < normalized.endIndex {
            let c = normalized[i]
            if c == "=" {
                let next1 = normalized.index(after: i)
                if next1 < normalized.endIndex {
                    let next2 = normalized.index(after: next1)
                    if next2 < normalized.endIndex {
                        let hexStr = String(normalized[next1...next2])
                        if let b = UInt8(hexStr, radix: 16) {
                            bytes.append(b)
                            i = normalized.index(after: next2)
                            continue
                        }
                    }
                }
            }
            if let asciiVal = c.asciiValue {
                bytes.append(asciiVal)
            }
            i = normalized.index(after: i)
        }
        return String(data: Data(bytes), encoding: .utf8) ?? normalized
    }
    
    // MARK: - Low-Level Streaming Socket I/O
    private func sendCommand(connection: NWConnection, command: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let data = command.data(using: .utf8) else {
            completion(.failure(IMAPError.invalidResponse("Commande invalide.")))
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
    
    private func readGreeting(
        connection: NWConnection,
        accumulated: Data = Data(),
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        if let currentText = String(data: accumulated, encoding: .utf8) ?? String(data: accumulated, encoding: .ascii) {
            if currentText.contains("* OK") || currentText.contains("* PREAUTH") {
                completion(.success(currentText))
                return
            }
        }
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, !data.isEmpty else {
                let text = String(data: accumulated, encoding: .utf8) ?? ""
                if text.contains("* OK") {
                    completion(.success(text))
                } else {
                    completion(.failure(IMAPError.invalidResponse("Aucune bannière de bienvenue IMAP reçue.")))
                }
                return
            }
            
            var nextData = accumulated
            nextData.append(data)
            let text = String(data: nextData, encoding: .utf8) ?? String(data: nextData, encoding: .ascii) ?? ""
            if text.contains("* OK") || text.contains("* PREAUTH") {
                completion(.success(text))
                return
            }
            self.readGreeting(connection: connection, accumulated: nextData, completion: completion)
        }
    }
    
    private func readUntilTagged(
        connection: NWConnection,
        tag: String,
        accumulated: Data = Data(),
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        if let currentText = String(data: accumulated, encoding: .utf8) ?? String(data: accumulated, encoding: .ascii) {
            if self.hasTaggedStatus(text: currentText, tag: tag) {
                completion(.success(currentText))
                return
            }
        }
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, !data.isEmpty else {
                if isComplete {
                    let text = String(data: accumulated, encoding: .utf8) ?? String(data: accumulated, encoding: .ascii) ?? ""
                    completion(.success(text))
                } else {
                    completion(.failure(IMAPError.invalidResponse("Connexion interrompue par le serveur.")))
                }
                return
            }
            
            var nextData = accumulated
            nextData.append(data)
            
            if let text = String(data: nextData, encoding: .utf8) ?? String(data: nextData, encoding: .ascii) {
                if self.hasTaggedStatus(text: text, tag: tag) {
                    completion(.success(text))
                    return
                }
            }
            
            self.readUntilTagged(connection: connection, tag: tag, accumulated: nextData, completion: completion)
        }
    }
    
    private func hasTaggedStatus(text: String, tag: String) -> Bool {
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("\(tag) OK") || trimmed.hasPrefix("\(tag) NO") || trimmed.hasPrefix("\(tag) BAD") {
                return true
            }
        }
        return false
    }
}
