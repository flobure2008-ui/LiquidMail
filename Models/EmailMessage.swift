import SwiftUI

// MARK: - Email Attachment
public struct EmailAttachment: Identifiable, Codable, Hashable {
    public let id: UUID
    public var filename: String
    public var fileSizeBytes: Int
    public var fileType: String // e.g., "pdf", "image", "invoice"
    
    public init(id: UUID = UUID(), filename: String, fileSizeBytes: Int, fileType: String) {
        self.id = id
        self.filename = filename
        self.fileSizeBytes = fileSizeBytes
        self.fileType = fileType
    }
    
    public var formattedSize: String {
        let kb = Double(fileSizeBytes) / 1024.0
        if kb > 1024.0 {
            return String(format: "%.1f Mo", kb / 1024.0)
        }
        return String(format: "%.0f Ko", kb)
    }
    
    public var iconName: String {
        switch fileType.lowercased() {
        case "pdf": return "doc.richtext.fill"
        case "png", "jpg", "jpeg", "heic": return "photo.fill"
        case "zip", "rar": return "archivebox.fill"
        default: return "doc.fill"
        }
    }
}

// MARK: - Email Message
public struct EmailMessage: Identifiable, Codable, Hashable {
    public let id: UUID
    public var threadId: UUID
    public var accountId: UUID
    public var provider: EmailProvider
    
    public var senderName: String
    public var senderEmail: String
    public var recipientEmail: String
    
    public var subject: String
    public var preview: String
    public var bodyContent: String
    
    public var timestamp: Date
    public var isRead: Bool
    public var isStarred: Bool
    public var isArchived: Bool
    public var isSnoozed: Bool
    public var snoozeDate: Date?
    
    public var attachments: [EmailAttachment]
    public var category: AICategory
    public var aiSummary: AISummary
    public var smartReplies: [SmartReply]
    
    public init(
        id: UUID = UUID(),
        threadId: UUID = UUID(),
        accountId: UUID,
        provider: EmailProvider,
        senderName: String,
        senderEmail: String,
        recipientEmail: String,
        subject: String,
        preview: String,
        bodyContent: String,
        timestamp: Date = Date(),
        isRead: Bool = false,
        isStarred: Bool = false,
        isArchived: Bool = false,
        isSnoozed: Bool = false,
        snoozeDate: Date? = nil,
        attachments: [EmailAttachment] = [],
        category: AICategory = .all,
        aiSummary: AISummary,
        smartReplies: [SmartReply] = []
    ) {
        self.id = id
        self.threadId = threadId
        self.accountId = accountId
        self.provider = provider
        self.senderName = senderName
        self.senderEmail = senderEmail
        self.recipientEmail = recipientEmail
        self.subject = subject
        self.preview = preview
        self.bodyContent = bodyContent
        self.timestamp = timestamp
        self.isRead = isRead
        self.isStarred = isStarred
        self.isArchived = isArchived
        self.isSnoozed = isSnoozed
        self.snoozeDate = snoozeDate
        self.attachments = attachments
        self.category = category
        self.aiSummary = aiSummary
        self.smartReplies = smartReplies
    }
    
    public var formattedRelativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    public var isPhishingAlert: Bool {
        return aiSummary.securityScore < 0.5 || category == .spam
    }
}
