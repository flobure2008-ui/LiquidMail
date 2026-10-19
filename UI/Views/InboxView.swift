import SwiftUI

public struct InboxView: View {
    @EnvironmentObject var mailStore: MailStore
    @State private var showingCompose: Bool = false
    @State private var showingAccountSheet: Bool = false
    @State private var selectedEmailForDetail: EmailMessage? = nil
    @State private var filterUnreadOnly: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Background
                LiquidAmbientBackground(theme: mailStore.glassTheme)
                
                if mailStore.accounts.isEmpty {
                    // MARK: - Zero Accounts Welcome Onboarding Screen
                    VStack(spacing: 24) {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.cyan.opacity(0.3), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 110, height: 110)
                                .blur(radius: 12)
                            
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundStyle(LinearGradient(colors: [.white, .cyan], startPoint: .top, endPoint: .bottom))
                        }
                        
                        VStack(spacing: 8) {
                            Text("Bienvenue sur LiquidMail")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Connectez votre boîte e-mail personnelle ou professionnelle pour activer le triage intelligent par IA.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .lineSpacing(3)
                        }
                        
                        // Feature bullets
                        VStack(alignment: .leading, spacing: 14) {
                            FeatureRow(icon: "network", title: "Tous fournisseurs supportés", subtitle: "iCloud, Gmail, Yahoo, Infomaniak, Orange, Free, IMAP...")
                            FeatureRow(icon: "sparkles", title: "Triage & Résumés IA", subtitle: "Classement en Urgent, Factures, VIP et réponses rapides")
                            FeatureRow(icon: "lock.shield.fill", title: "Chiffrement Keychain", subtitle: "Identifiants stockés dans le Trousseau sécurisé Apple")
                        }
                        .padding(20)
                        .liquidGlass(cornerRadius: 20, borderOpacity: 0.25)
                        .padding(.horizontal, 24)
                        
                        Spacer()
                        
                        Button(action: {
                            Haptics.medium()
                            showingAccountSheet = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Connecter une boîte e-mail")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(18)
                            .foregroundColor(.white)
                            .shadow(color: Color.cyan.opacity(0.35), radius: 10, y: 5)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                } else {
                    // MARK: - Standard Apple Mail Interface with Liquid Glass
                    VStack(spacing: 0) {
                        
                        // Category pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(AICategory.allCases) { cat in
                                    LiquidPillBadge(
                                        title: cat.rawValue,
                                        icon: cat.iconName,
                                        color: cat.badgeColor,
                                        isSelected: mailStore.selectedCategory == cat
                                    ) {
                                        mailStore.selectedCategory = cat
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        
                        // Email List
                        if displayedEmails.isEmpty {
                            VStack(spacing: 14) {
                                Spacer()
                                Image(systemName: "tray")
                                    .font(.system(size: 44, weight: .light))
                                    .foregroundColor(.secondary.opacity(0.6))
                                Text("Aucun message")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text("Votre boîte de réception est à jour.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary.opacity(0.8))
                                Spacer()
                            }
                        } else {
                            List {
                                ForEach(displayedEmails) { email in
                                    StandardMailRow(email: email)
                                        .listRowBackground(Color.clear)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                        .listRowSeparator(.hidden)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedEmailForDetail = email
                                        }
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                mailStore.toggleRead(for: email)
                                            } label: {
                                                Label(email.isRead ? "Non lu" : "Lu", systemImage: email.isRead ? "envelope.badge" : "envelope.open")
                                            }
                                            .tint(.blue)
                                            
                                            Button {
                                                mailStore.toggleStar(for: email)
                                            } label: {
                                                Label("Favori", systemImage: "star.fill")
                                            }
                                            .tint(.yellow)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                mailStore.delete(email: email)
                                            } label: {
                                                Label("Supprimer", systemImage: "trash.fill")
                                            }
                                            
                                            Button {
                                                mailStore.archive(email: email)
                                            } label: {
                                                Label("Archiver", systemImage: "archivebox.fill")
                                            }
                                            .tint(.orange)
                                        }
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .refreshable {
                                await mailStore.refreshInbox()
                            }
                        }
                        
                        // MARK: - Native Apple Mail Bottom Toolbar
                        HStack {
                            Button(action: {
                                Haptics.light()
                                filterUnreadOnly.toggle()
                            }) {
                                Image(systemName: filterUnreadOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(filterUnreadOnly ? .cyan : .secondary)
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 1) {
                                Text(mailStore.isSyncing ? "Synchronisation..." : "Mis à jour à l'instant")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("\(displayedEmails.count) message\(displayedEmails.count > 1 ? "s" : "")")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                Haptics.medium()
                                showingCompose = true
                            }) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.cyan)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .overlay(
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundColor(Color.white.opacity(0.15)),
                            alignment: .top
                        )
                    }
                }
                
                // Floating Undo Send Toast
                if let pending = mailStore.pendingSend {
                    HStack(spacing: 12) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.cyan)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Envoi en cours...")
                                .font(.system(size: 13, weight: .semibold))
                            Text("À : \(pending.recipient)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: { mailStore.cancelSend() }) {
                            Text("Annuler (\(pending.remainingSeconds)s)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.red.opacity(0.85)))
                        }
                    }
                    .padding(12)
                    .liquidGlass(cornerRadius: 18, borderOpacity: 0.5, glowColor: .cyan)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle(mailStore.selectedAccount?.name ?? "Boîte de réception")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $mailStore.searchText, prompt: "Rechercher...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Haptics.light()
                        showingAccountSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 18))
                                .foregroundColor(.cyan)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCompose) {
                ComposeMailView()
                    .environmentObject(mailStore)
            }
            .sheet(isPresented: $showingAccountSheet) {
                AccountsSheetView()
                    .environmentObject(mailStore)
            }
            .navigationDestination(item: $selectedEmailForDetail) { email in
                EmailDetailView(email: email)
                    .environmentObject(mailStore)
            }
        }
    }
    
    private var displayedEmails: [EmailMessage] {
        var list = mailStore.filteredEmails
        if filterUnreadOnly {
            list = list.filter { !$0.isRead }
        }
        return list
    }
}

// MARK: - Standard Apple Mail Row Component with Liquid Glass Touch
public struct StandardMailRow: View {
    public let email: EmailMessage
    
    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Unread Blue Dot Indicator
            Circle()
                .fill(email.isRead ? Color.clear : Color.cyan)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(email.senderName)
                        .font(.system(size: 15, weight: email.isRead ? .medium : .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(email.formattedRelativeTime)
                        .font(.system(size: 12))
                        .foregroundColor(email.isRead ? .secondary : .cyan)
                }
                
                Text(email.subject)
                    .font(.system(size: 14, weight: email.isRead ? .regular : .semibold))
                    .foregroundColor(.primary.opacity(0.95))
                    .lineLimit(1)
                
                Text(email.preview)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .lineSpacing(2)
                
                // Subtle badges row
                HStack(spacing: 6) {
                    if email.category != .all && email.category != .vip {
                        Text(email.category.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(email.category.badgeColor.opacity(0.18)))
                            .foregroundColor(email.category.badgeColor)
                    }
                    
                    if !email.attachments.isEmpty {
                        Image(systemName: "paperclip")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    if email.isStarred {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                    Spacer()
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .liquidGlass(cornerRadius: 16, borderOpacity: email.isRead ? 0.15 : 0.35, glowColor: email.isRead ? .white : .cyan)
    }
}

// MARK: - Feature Bullet Row for Onboarding
struct FeatureRow: View {
    var icon: String
    var title: String
    var subtitle: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.cyan.opacity(0.18)).frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cyan)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}
