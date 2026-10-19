import Foundation

// MARK: - Mail Server Config
public struct ServerConfig: Codable, Hashable {
    public var imapHost: String
    public var imapPort: Int
    public var imapUseSSL: Bool
    
    public var smtpHost: String
    public var smtpPort: Int
    public var smtpUseSSL: Bool
    
    public init(
        imapHost: String,
        imapPort: Int = 993,
        imapUseSSL: Bool = true,
        smtpHost: String,
        smtpPort: Int = 587,
        smtpUseSSL: Bool = true
    ) {
        self.imapHost = imapHost
        self.imapPort = imapPort
        self.imapUseSSL = imapUseSSL
        self.smtpHost = smtpHost
        self.smtpPort = smtpPort
        self.smtpUseSSL = smtpUseSSL
    }
}

// MARK: - Auto-Discovery Engine for ANY Email Domain
public class MailAutoDiscovery {
    public static let shared = MailAutoDiscovery()
    
    // Built-in presets for French & Global ISPs and Webmails
    private let providerPresets: [String: ServerConfig] = [
        // Apple
        "icloud.com": ServerConfig(imapHost: "imap.mail.me.com", imapPort: 993, smtpHost: "smtp.mail.me.com", smtpPort: 587),
        "me.com": ServerConfig(imapHost: "imap.mail.me.com", imapPort: 993, smtpHost: "smtp.mail.me.com", smtpPort: 587),
        "mac.com": ServerConfig(imapHost: "imap.mail.me.com", imapPort: 993, smtpHost: "smtp.mail.me.com", smtpPort: 587),
        
        // Google
        "gmail.com": ServerConfig(imapHost: "imap.gmail.com", imapPort: 993, smtpHost: "smtp.gmail.com", smtpPort: 587),
        "googlemail.com": ServerConfig(imapHost: "imap.gmail.com", imapPort: 993, smtpHost: "smtp.gmail.com", smtpPort: 587),
        
        // Yahoo
        "yahoo.com": ServerConfig(imapHost: "imap.mail.yahoo.com", imapPort: 993, smtpHost: "smtp.mail.yahoo.com", smtpPort: 587),
        "yahoo.fr": ServerConfig(imapHost: "imap.mail.yahoo.com", imapPort: 993, smtpHost: "smtp.mail.yahoo.com", smtpPort: 587),
        "myyahoo.com": ServerConfig(imapHost: "imap.mail.yahoo.com", imapPort: 993, smtpHost: "smtp.mail.yahoo.com", smtpPort: 587),
        
        // Infomaniak
        "ik.me": ServerConfig(imapHost: "mail.infomaniak.com", imapPort: 993, smtpHost: "mail.infomaniak.com", smtpPort: 587),
        "ikmail.com": ServerConfig(imapHost: "mail.infomaniak.com", imapPort: 993, smtpHost: "mail.infomaniak.com", smtpPort: 587),
        "etik.com": ServerConfig(imapHost: "mail.infomaniak.com", imapPort: 993, smtpHost: "mail.infomaniak.com", smtpPort: 587),
        
        // Microsoft
        "outlook.com": ServerConfig(imapHost: "outlook.office365.com", imapPort: 993, smtpHost: "smtp.office365.com", smtpPort: 587),
        "hotmail.com": ServerConfig(imapHost: "outlook.office365.com", imapPort: 993, smtpHost: "smtp.office365.com", smtpPort: 587),
        "live.fr": ServerConfig(imapHost: "outlook.office365.com", imapPort: 993, smtpHost: "smtp.office365.com", smtpPort: 587),
        
        // French ISPs
        "orange.fr": ServerConfig(imapHost: "imap.orange.fr", imapPort: 993, smtpHost: "smtp.orange.fr", smtpPort: 587),
        "wanadoo.fr": ServerConfig(imapHost: "imap.orange.fr", imapPort: 993, smtpHost: "smtp.orange.fr", smtpPort: 587),
        "sfr.fr": ServerConfig(imapHost: "imap.sfr.fr", imapPort: 993, smtpHost: "smtp.sfr.fr", smtpPort: 587),
        "free.fr": ServerConfig(imapHost: "imap.free.fr", imapPort: 993, smtpHost: "smtp.free.fr", smtpPort: 587),
        "laposte.net": ServerConfig(imapHost: "imap.laposte.net", imapPort: 993, smtpHost: "smtp.laposte.net", smtpPort: 587),
        "bbox.fr": ServerConfig(imapHost: "imap.bbox.fr", imapPort: 993, smtpHost: "smtp.bbox.fr", smtpPort: 587),
        
        // Swiss & European Providers
        "bluewin.ch": ServerConfig(imapHost: "imaps.bluewin.ch", imapPort: 993, smtpHost: "smtpauths.bluewin.ch", smtpPort: 587),
        "proton.me": ServerConfig(imapHost: "127.0.0.1", imapPort: 1143, smtpHost: "127.0.0.1", smtpPort: 1025), // Proton Bridge
        "protonmail.com": ServerConfig(imapHost: "127.0.0.1", imapPort: 1143, smtpHost: "127.0.0.1", smtpPort: 1025),
        "ovh.net": ServerConfig(imapHost: "ssl0.ovh.net", imapPort: 993, smtpHost: "ssl0.ovh.net", smtpPort: 587),
        "mailo.com": ServerConfig(imapHost: "imap.mailo.com", imapPort: 993, smtpHost: "smtp.mailo.com", smtpPort: 587),
        "gmx.com": ServerConfig(imapHost: "imap.gmx.com", imapPort: 993, smtpHost: "mail.gmx.com", smtpPort: 587),
        "fastmail.com": ServerConfig(imapHost: "imap.fastmail.com", imapPort: 993, smtpHost: "smtp.fastmail.com", smtpPort: 587)
    ]
    
    /// Discovers IMAP/SMTP parameters for ANY email address
    public func discover(email: String) -> ServerConfig {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let domain = cleanEmail.split(separator: "@").last.map(String.init) else {
            return ServerConfig(imapHost: "imap.mail.com", smtpHost: "smtp.mail.com")
        }
        
        // 1. Direct match with preset dictionary
        if let preset = providerPresets[domain] {
            return preset
        }
        
        // 2. Intelligent domain rule (Standard RFC naming convention)
        return ServerConfig(
            imapHost: "imap.\(domain)",
            imapPort: 993,
            imapUseSSL: true,
            smtpHost: "smtp.\(domain)",
            smtpPort: 587,
            smtpUseSSL: true
        )
    }
}
