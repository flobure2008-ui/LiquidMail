import SwiftUI
import Combine

// MARK: - Undo Send Envelope
public struct PendingSentMail: Identifiable {
    public let id: UUID = UUID()
    public var recipient: String
    public var subject: String
    public var body: String
    public var account: EmailAccount
    public var remainingSeconds: Int
}

// MARK: - Main Mail Store (Pure Zero-State, No Dummy Accounts or Fake Emails)
public class MailStore: ObservableObject {
    @Published public var accounts: [EmailAccount] = []
    @Published public var selectedAccount: EmailAccount? = nil
    @Published public var emails: [EmailMessage] = []
    @Published public var selectedCategory: AICategory = .all
    @Published public var searchText: String = ""
    @Published public var isAIModeSearchActive: Bool = false
    @Published public var pendingSend: PendingSentMail? = nil
    @Published public var glassTheme: GlassTheme = .obsidian
    @Published public var undoSendDuration: Int = 10 // seconds
    @Published public var isFaceIDEnabled: Bool = false
    @Published public var isSyncing: Bool = false
    
    private var undoTimer: AnyCancellable?
    private let accountsStorageKey = "liquidmail_saved_accounts"
    private let emailsStorageKey = "liquidmail_saved_emails"
    
    public init() {
        loadPersistedData()
    }
    
    // MARK: - Local Persistence (No Demo Accounts)
    private func loadPersistedData() {
        if let data = UserDefaults.standard.data(forKey: accountsStorageKey),
           let saved = try? JSONDecoder().decode([EmailAccount].self, from: data) {
            self.accounts = saved
        } else {
            self.accounts = [] // Zero accounts by default
        }
        
        if let data = UserDefaults.standard.data(forKey: emailsStorageKey),
           let saved = try? JSONDecoder().decode([EmailMessage].self, from: data) {
            self.emails = saved
        } else {
            self.emails = [] // Zero emails by default
        }
    }
    
    public func persistAccounts() {
        if let encoded = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(encoded, forKey: accountsStorageKey)
        }
        // Also update App Group shared storage for WidgetKit
        let sharedDefaults = UserDefaults(suiteName: "group.com.liquidmail.app")
        sharedDefaults?.set(emails.filter { !$0.isRead }.count, forKey: "unreadTotal")
        sharedDefaults?.set(emails.filter { $0.category == .actionRequired && !$0.isRead }.count, forKey: "urgentCount")
    }
    
    public func persistEmails() {
        if let encoded = try? JSONEncoder().encode(emails) {
            UserDefaults.standard.set(encoded, forKey: emailsStorageKey)
        }
        let sharedDefaults = UserDefaults(suiteName: "group.com.liquidmail.app")
        sharedDefaults?.set(emails.filter { !$0.isRead }.count, forKey: "unreadTotal")
        sharedDefaults?.set(emails.filter { $0.category == .actionRequired && !$0.isRead }.count, forKey: "urgentCount")
        if let nextUrgent = emails.first(where: { $0.category == .actionRequired && !$0.isRead }) {
            sharedDefaults?.set(nextUrgent.subject, forKey: "nextUrgentTitle")
            sharedDefaults?.set(nextUrgent.senderName, forKey: "nextUrgentSender")
        }
    }
    
    // MARK: - Filtered Emails Computed Property
    public var filteredEmails: [EmailMessage] {
        return emails.filter { email in
            // Account filter
            if let selectedAccount = selectedAccount {
                if email.accountId != selectedAccount.id {
                    return false
                }
            }
            
            // Category filter
            if selectedCategory != .all && email.category != selectedCategory {
                return false
            }
            
            // Search text filter
            if !searchText.isEmpty {
                return AISmartEngine.shared.matchesSemanticSearch(email: email, query: searchText)
            }
            
            return !email.isArchived
        }
    }
    
    // MARK: - Actions
    public func toggleStar(for email: EmailMessage) {
        if let idx = emails.firstIndex(where: { $0.id == email.id }) {
            emails[idx].isStarred.toggle()
            persistEmails()
            Haptics.light()
        }
    }
    
    public func toggleRead(for email: EmailMessage) {
        if let idx = emails.firstIndex(where: { $0.id == email.id }) {
            emails[idx].isRead.toggle()
            persistEmails()
            Haptics.light()
        }
    }
    
    public func markAsRead(emailId: UUID) {
        if let idx = emails.firstIndex(where: { $0.id == emailId }) {
            emails[idx].isRead = true
            persistEmails()
        }
    }
    
    public func archive(email: EmailMessage) {
        if let idx = emails.firstIndex(where: { $0.id == email.id }) {
            emails[idx].isArchived = true
            persistEmails()
            Haptics.medium()
        }
    }
    
    public func delete(email: EmailMessage) {
        if let idx = emails.firstIndex(where: { $0.id == email.id }) {
            emails.remove(at: idx)
            persistEmails()
            Haptics.warning()
        }
    }
    
    public func toggleActionItem(emailId: UUID, actionItemId: UUID) {
        if let emailIdx = emails.firstIndex(where: { $0.id == emailId }) {
            if let itemIdx = emails[emailIdx].aiSummary.actionItems.firstIndex(where: { $0.id == actionItemId }) {
                emails[emailIdx].aiSummary.actionItems[itemIdx].isCompleted.toggle()
                persistEmails()
                Haptics.success()
            }
        }
    }
    
    // MARK: - Undo Send Feature
    public func sendEmail(from account: EmailAccount, to recipient: String, subject: String, body: String) {
        let pending = PendingSentMail(
            recipient: recipient,
            subject: subject,
            body: body,
            account: account,
            remainingSeconds: undoSendDuration
        )
        self.pendingSend = pending
        Haptics.success()
        
        undoTimer?.cancel()
        undoTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, var p = self.pendingSend else { return }
                if p.remainingSeconds > 1 {
                    p.remainingSeconds -= 1
                    self.pendingSend = p
                } else {
                    self.finalizeSend()
                }
            }
    }
    
    public func cancelSend() {
        undoTimer?.cancel()
        self.pendingSend = nil
        Haptics.warning()
    }
    
    private func finalizeSend() {
        undoTimer?.cancel()
        guard let p = pendingSend else { return }
        
        let sentMessage = EmailMessage(
            accountId: p.account.id,
            provider: p.account.provider,
            senderName: p.account.name,
            senderEmail: p.account.emailAddress,
            recipientEmail: p.recipient,
            subject: p.subject,
            preview: p.body,
            bodyContent: p.body,
            timestamp: Date(),
            isRead: true,
            category: .vip,
            aiSummary: AISummary(tldr: "E-mail envoyé avec succès.", sentiment: .positive)
        )
        self.emails.insert(sentMessage, at: 0)
        persistEmails()
        self.pendingSend = nil
    }
    
    // MARK: - Add / Remove Account
    public func addAccount(name: String, email: String, provider: EmailProvider) {
        let newAcc = EmailAccount(name: name, emailAddress: email, provider: provider, isActive: true)
        self.accounts.append(newAcc)
        persistAccounts()
        Haptics.success()
    }
    
    public func removeAccount(at indexSet: IndexSet) {
        self.accounts.remove(atOffsets: indexSet)
        persistAccounts()
        Haptics.warning()
    }
    
    // MARK: - Synchronize Mail
    public func refreshInbox() async {
        await MainActor.run { isSyncing = true }
        try? await Task.sleep(nanoseconds: 800_000_000)
        await MainActor.run { isSyncing = false }
        Haptics.light()
    }
}
