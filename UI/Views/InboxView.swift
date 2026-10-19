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
                LiquidAmbientBackground(theme: mailStore.glassTheme)
                
                if mailStore.accounts.isEmpty {
                    // MARK: - Zero Accounts Welcome Onboarding Screen
                    VStack(spacing: 24) {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.cyan.opacity(0.25), .purple.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 42, weight: .semibold))
                                .foregroundColor(.cyan)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Bienvenue sur LiquidMail")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Connectez votre boîte de messagerie pour activer le triage intelligent par IA et les résumés automatiques.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .lineSpacing(3)
                        }
                        
                        VStack(alignment: .leading, spacing: 14) {
                            FeatureRow(icon: "network", title: "Tous fournisseurs supportés", subtitle: "iCloud, Gmail, Yahoo, Infomaniak, Orange, Free, IMAP...")
                            FeatureRow(icon: "sparkles", title: "Triage & Résumés IA", subtitle: "Catégorisation automatique et extraction d'actions")
                            FeatureRow(icon: "lock.shield.fill", title: "Chiffrement Keychain", subtitle: "Identifiants protégés par le Trousseau Apple")
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 18, borderOpacity: 0.20)
                        .padding(.horizontal, 20)
                        
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
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                } else {
                    // MARK: - Native Apple Mail Inbox View
                    VStack(spacing: 0) {
                        
                        // Category Pills
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
                        
                        if displayedEmails.isEmpty {
                            VStack(spacing: 12) {
                                Spacer()
                                Image(systemName: "tray")
                                    .font(.system(size: 40, weight: .light))
                                    .foregroundColor(.secondary.opacity(0.6))
                                Text("Aucun message")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text("Tirez vers le bas pour actualiser.")
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
                    .liquidGlass(cornerRadius: 16, borderOpacity: 0.4, glowColor: .cyan)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle(mailStore.selectedAccount?.name ?? "Boîte de réception")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $mailStore.searchText, prompt: "Rechercher...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Haptics.light()
                        showingAccountSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "tray.2")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.cyan)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        Button(action: {
                            filterUnreadOnly.toggle()
                        }) {
                            Image(systemName: filterUnreadOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.system(size: 16))
                                .foregroundColor(filterUnreadOnly ? .cyan : .secondary)
                        }
                        
                        Button(action: {
                            Haptics.medium()
                            showingCompose = true
                        }) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 17, weight: .semibold))
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

// MARK: - Clean Apple Mail Row Component
public struct StandardMailRow: View {
    public let email: EmailMessage
    
    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(email.isRead ? Color.clear : Color.cyan)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(email.senderName)
                        .font(.system(size: 15, weight: email.isRead ? .regular : .bold))
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
                
                if email.category != .all && email.category != .vip {
                    Text(email.category.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(email.category.badgeColor.opacity(0.18)))
                        .foregroundColor(email.category.badgeColor)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .liquidGlass(cornerRadius: 14, borderOpacity: email.isRead ? 0.10 : 0.25, glowColor: email.isRead ? .white : .cyan)
    }
}
