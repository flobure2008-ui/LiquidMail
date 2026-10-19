import SwiftUI

// MARK: - Email Provider Definition
public enum EmailProvider: String, CaseIterable, Codable, Identifiable {
    case icloud = "iCloud"
    case gmail = "Gmail"
    case yahoo = "Yahoo"
    case ikmail = "Infomaniak (ikmail)"
    case outlook = "Outlook"
    case customImap = "IMAP Personnalisé"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .icloud: return "iCloud Mail"
        case .gmail: return "Google Gmail"
        case .yahoo: return "Yahoo & myYahoo"
        case .ikmail: return "Infomaniak ikmail"
        case .outlook: return "Microsoft Outlook"
        case .customImap: return "IMAP / SMTP"
        }
    }
    
    public var iconName: String {
        switch self {
        case .icloud: return "cloud.fill"
        case .gmail: return "envelope.badge.shield.half.filled"
        case .yahoo: return "y.square.fill"
        case .ikmail: return "shield.lefthalf.filled.trianglebadge.exclamationmark"
        case .outlook: return "building.2.fill"
        case .customImap: return "server.rack"
        }
    }
    
    public var brandColorHex: String {
        switch self {
        case .icloud: return "#2997FF"
        case .gmail: return "#EA4335"
        case .yahoo: return "#7B1FA2"
        case .ikmail: return "#00A86B" // Infomaniak iconic emerald green
        case .outlook: return "#0078D4"
        case .customImap: return "#FF9500"
        }
    }
    
    public var imapHost: String {
        switch self {
        case .icloud: return "imap.mail.me.com"
        case .gmail: return "imap.gmail.com"
        case .yahoo: return "imap.mail.yahoo.com"
        case .ikmail: return "mail.infomaniak.com"
        case .outlook: return "outlook.office365.com"
        case .customImap: return "imap.example.com"
        }
    }
    
    public var imapPort: Int { 993 }
    
    public var smtpHost: String {
        switch self {
        case .icloud: return "smtp.mail.me.com"
        case .gmail: return "smtp.gmail.com"
        case .yahoo: return "smtp.mail.yahoo.com"
        case .ikmail: return "mail.infomaniak.com"
        case .outlook: return "smtp.office365.com"
        case .customImap: return "smtp.example.com"
        }
    }
    
    public var smtpPort: Int { 587 }
}

// MARK: - Email Account Entity
public struct EmailAccount: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var emailAddress: String
    public var provider: EmailProvider
    public var isActive: Bool
    public var unreadCount: Int
    public var lastSyncDate: Date
    public var avatarInitials: String
    public var isOAuthSupported: Bool
    public var serverConfig: ServerConfig?
    
    public init(
        id: UUID = UUID(),
        name: String,
        emailAddress: String,
        provider: EmailProvider,
        isActive: Bool = true,
        unreadCount: Int = 0,
        lastSyncDate: Date = Date(),
        avatarInitials: String? = nil,
        isOAuthSupported: Bool = true,
        serverConfig: ServerConfig? = nil
    ) {
        self.id = id
        self.name = name
        self.emailAddress = emailAddress
        self.provider = provider
        self.isActive = isActive
        self.unreadCount = unreadCount
        self.lastSyncDate = lastSyncDate
        self.isOAuthSupported = isOAuthSupported
        self.serverConfig = serverConfig
        
        if let initials = avatarInitials {
            self.avatarInitials = initials
        } else {
            let components = name.split(separator: " ")
            if components.count >= 2 {
                self.avatarInitials = "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
            } else {
                self.avatarInitials = String(name.prefix(2)).uppercased()
            }
        }
    }
}
