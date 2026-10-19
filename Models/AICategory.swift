import SwiftUI

// MARK: - AI Categorization
public enum AICategory: String, CaseIterable, Codable, Identifiable {
    case all = "Tous"
    case actionRequired = "Action Requise"
    case vip = "VIP & Prioritaire"
    case receipts = "Factures & Achats"
    case newsletters = "Newsletters"
    case social = "Réseaux & Alertes"
    case spam = "Spam Détecté"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .all: return "tray.2.fill"
        case .actionRequired: return "exclamationmark.bubble.fill"
        case .vip: return "star.fill"
        case .receipts: return "creditcard.fill"
        case .newsletters: return "newspaper.fill"
        case .social: return "bubble.left.and.bubble.right.fill"
        case .spam: return "shield.slash.fill"
        }
    }
    
    public var badgeColor: Color {
        switch self {
        case .all: return .primary
        case .actionRequired: return Color(red: 1.0, green: 0.23, blue: 0.19) // iOS Red
        case .vip: return Color(red: 1.0, green: 0.8, blue: 0.0) // Gold
        case .receipts: return Color(red: 0.2, green: 0.78, blue: 0.35) // Emerald Green
        case .newsletters: return Color(red: 0.35, green: 0.34, blue: 0.84) // Indigo
        case .social: return Color(red: 0.0, green: 0.48, blue: 1.0) // Azure
        case .spam: return Color.gray
        }
    }
    
    public var promptDescription: String {
        switch self {
        case .all: return "Afficher tous les e-mails reçus"
        case .actionRequired: return "E-mails exigeant une réponse, une signature ou un paiement urgent"
        case .vip: return "E-mails de vos correspondants clés et collègues"
        case .receipts: return "Justificatifs de paiement, confirmations de commande et billets de train/avion"
        case .newsletters: return "Lettres d'information, articles et synthèses hebdomadaires"
        case .social: return "Notifications de réseaux sociaux, forums et alertes d'applications"
        case .spam: return "Tentatives de phishing ou messages publicitaires non sollicités"
        }
    }
}

// MARK: - Sentiment Analysis
public enum AISentiment: String, Codable {
    case positive = "Positif"
    case neutral = "Neutre"
    case urgent = "Urgent"
    case delicate = "Délicat"
    case suspicious = "Suspect"
    
    public var emoji: String {
        switch self {
        case .positive: return "✨"
        case .neutral: return "💬"
        case .urgent: return "⚡"
        case .delicate: return "⚖️"
        case .suspicious: return "⚠️"
        }
    }
}

// MARK: - Action Item extracted by AI
public struct EmailActionItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool
    public var dueDate: Date?
    
    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false, dueDate: Date? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
    }
}

// MARK: - AI Executive Summary
public struct AISummary: Codable, Hashable {
    public var tldr: String
    public var keyPoints: [String]
    public var actionItems: [EmailActionItem]
    public var sentiment: AISentiment
    public var estimatedReadingTimeSeconds: Int
    public var securityScore: Double // 0.0 (Spam/Phishing) to 1.0 (Totally Safe)
    public var phishingExplanation: String?
    
    public init(
        tldr: String,
        keyPoints: [String] = [],
        actionItems: [EmailActionItem] = [],
        sentiment: AISentiment = .neutral,
        estimatedReadingTimeSeconds: Int = 30,
        securityScore: Double = 0.98,
        phishingExplanation: String? = nil
    ) {
        self.tldr = tldr
        self.keyPoints = keyPoints
        self.actionItems = actionItems
        self.sentiment = sentiment
        self.estimatedReadingTimeSeconds = estimatedReadingTimeSeconds
        self.securityScore = securityScore
        self.phishingExplanation = phishingExplanation
    }
}

// MARK: - AI Smart Quick Reply
public struct SmartReply: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var fullResponseText: String
    public var toneIcon: String
    
    public init(id: UUID = UUID(), title: String, fullResponseText: String, toneIcon: String = "wand.and.sparkles") {
        self.id = id
        self.title = title
        self.fullResponseText = fullResponseText
        self.toneIcon = toneIcon
    }
}
