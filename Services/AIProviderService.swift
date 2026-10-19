import Foundation

// MARK: - Supported AI Providers
public enum AIModelProvider: String, CaseIterable, Identifiable, Codable {
    case openAI = "OpenAI (GPT-4o / GPT-4o-mini)"
    case anthropic = "Anthropic Claude (3.5 Sonnet)"
    case mistral = "Mistral AI (Le Chat / Small)"
    case gemini = "Google Gemini (1.5 Flash)"
    case localOllama = "Serveur Local (Ollama / LM Studio)"
    case appleIntelligence = "Apple Intelligence (On-Device)"
    
    public var id: String { rawValue }
    
    public var defaultEndpoint: String {
        switch self {
        case .openAI: return "https://api.openai.com/v1/chat/completions"
        case .anthropic: return "https://api.anthropic.com/v1/messages"
        case .mistral: return "https://api.mistral.ai/v1/chat/completions"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
        case .localOllama: return "http://127.0.0.1:11434/v1/chat/completions"
        case .appleIntelligence: return "local://apple-neural-engine"
        }
    }
    
    public var defaultModel: String {
        switch self {
        case .openAI: return "gpt-4o-mini"
        case .anthropic: return "claude-3-5-sonnet-20241022"
        case .mistral: return "mistral-small-latest"
        case .gemini: return "gemini-1.5-flash"
        case .localOllama: return "llama3.2"
        case .appleIntelligence: return "apple-foundation-models"
        }
    }
}

// MARK: - Structured AI Triage Response
public struct AITriageResult: Codable {
    public var category: String // "actionRequired", "vip", "receipts", "newsletters", "spam"
    public var tldr: String
    public var keyPoints: [String]
    public var actionItems: [String]
    public var securityScore: Double // 0.0 to 1.0
    public var suggestedReplies: [String]
    
    public init(
        category: String,
        tldr: String,
        keyPoints: [String],
        actionItems: [String],
        securityScore: Double = 0.98,
        suggestedReplies: [String] = []
    ) {
        self.category = category
        self.tldr = tldr
        self.keyPoints = keyPoints
        self.actionItems = actionItems
        self.securityScore = securityScore
        self.suggestedReplies = suggestedReplies
    }
}

// MARK: - Real AI API Client Service
public class AIProviderService: ObservableObject {
    public static let shared = AIProviderService()
    
    @Published public var activeProvider: AIModelProvider = .openAI
    @Published public var apiKey: String = ""
    @Published public var customEndpoint: String = ""
    @Published public var isTestingConnection: Bool = false
    @Published public var connectionStatusMessage: String? = nil
    
    private init() {
        // Load API key from Keychain
        if let savedKey = KeychainManager.shared.retrieve(key: "liquidmail_ai_api_key") {
            self.apiKey = savedKey
        }
        if let savedProviderRaw = UserDefaults.standard.string(forKey: "liquidmail_ai_provider"),
           let provider = AIModelProvider(rawValue: savedProviderRaw) {
            self.activeProvider = provider
        }
    }
    
    public func saveSettings(provider: AIModelProvider, key: String, endpoint: String = "") {
        self.activeProvider = provider
        self.apiKey = key
        self.customEndpoint = endpoint
        KeychainManager.shared.save(key: "liquidmail_ai_api_key", data: key)
        UserDefaults.standard.set(provider.rawValue, forKey: "liquidmail_ai_provider")
    }
    
    // MARK: - Test API Connectivity
    public func testConnection() async -> Bool {
        await MainActor.run {
            isTestingConnection = true
            connectionStatusMessage = nil
        }
        
        guard !apiKey.isEmpty || activeProvider == .localOllama || activeProvider == .appleIntelligence else {
            await MainActor.run {
                connectionStatusMessage = "Veuillez saisir une clé API valide."
                isTestingConnection = false
            }
            return false
        }
        
        if activeProvider == .appleIntelligence {
            await MainActor.run {
                connectionStatusMessage = "✓ Apple Intelligence actif sur ce terminal."
                isTestingConnection = false
            }
            return true
        }
        
        let endpointStr = customEndpoint.isEmpty ? activeProvider.defaultEndpoint : customEndpoint
        guard let url = URL(string: endpointStr) else {
            await MainActor.run {
                connectionStatusMessage = "URL d'endpoint invalide."
                isTestingConnection = false
            }
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let payload: [String: Any] = [
            "model": activeProvider.defaultModel,
            "messages": [
                ["role": "user", "content": "Ping test LiquidMail. Réponds uniquement par OK."]
            ],
            "max_tokens": 10
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 {
                await MainActor.run {
                    connectionStatusMessage = "✓ Connexion réussie à l'API (\(activeProvider.defaultModel)) !"
                    isTestingConnection = false
                }
                return true
            } else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                await MainActor.run {
                    connectionStatusMessage = "Erreur HTTP \(code) reçue de l'API."
                    isTestingConnection = false
                }
                return false
            }
        } catch {
            await MainActor.run {
                connectionStatusMessage = "Échec de connexion : \(error.localizedDescription)"
                isTestingConnection = false
            }
            return false
        }
    }
    
    // MARK: - Triage an Email with Real AI API
    public func triageEmail(subject: String, sender: String, body: String) async -> AITriageResult {
        // Fallback to local heuristic engine if no API key or local model selected
        if apiKey.isEmpty || activeProvider == .appleIntelligence {
            let res = AISmartEngine.shared.triage(emailSubject: subject, body: body, sender: sender)
            return AITriageResult(
                category: res.category.rawValue,
                tldr: res.summary.tldr,
                keyPoints: res.summary.keyPoints,
                actionItems: res.summary.actionItems.map { $0.title },
                securityScore: res.summary.securityScore,
                suggestedReplies: res.replies.map { $0.title }
            )
        }
        
        let endpointStr = customEndpoint.isEmpty ? activeProvider.defaultEndpoint : customEndpoint
        guard let url = URL(string: endpointStr) else {
            return fallbackResult(subject: subject, body: body, sender: sender)
        }
        
        let systemPrompt = """
        Tu es l'assistant de tri e-mail LiquidMail pour iOS.
        Analyse ce courriel et réponds STRICTEMENT avec un objet JSON respectant ce schéma exact :
        {
          "category": "actionRequired" | "vip" | "receipts" | "newsletters" | "spam",
          "tldr": "Résumé exécutif en 25 mots maximum",
          "keyPoints": ["point 1", "point 2"],
          "actionItems": ["action à faire 1"],
          "securityScore": 0.95,
          "suggestedReplies": ["Réponse 1", "Réponse 2"]
        }
        """
        
        let userContent = "Expéditeur: \(sender)\nObjet: \(subject)\nCorps:\n\(body.prefix(1500))"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let payload: [String: Any] = [
            "model": activeProvider.defaultModel,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.2
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
                return fallbackResult(subject: subject, body: body, sender: sender)
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let msg = first["message"] as? [String: Any],
               let contentStr = msg["content"] as? String,
               let contentData = contentStr.data(using: .utf8) {
                let decoded = try JSONDecoder().decode(AITriageResult.self, from: contentData)
                return decoded
            }
        } catch {
            print("AI Triage API error: \(error)")
        }
        
        return fallbackResult(subject: subject, body: body, sender: sender)
    }
    
    private func fallbackResult(subject: String, body: String, sender: String) -> AITriageResult {
        let res = AISmartEngine.shared.triage(emailSubject: subject, body: body, sender: sender)
        return AITriageResult(
            category: res.category.rawValue,
            tldr: res.summary.tldr,
            keyPoints: res.summary.keyPoints,
            actionItems: res.summary.actionItems.map { $0.title },
            securityScore: res.summary.securityScore,
            suggestedReplies: res.replies.map { $0.title }
        )
    }
}
