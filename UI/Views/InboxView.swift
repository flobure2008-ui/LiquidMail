import SwiftUI

public struct InboxView: View {
    @EnvironmentObject var mailStore: MailStore
    @State private var showingCompose: Bool = false
    @State private var showingAccountSheet: Bool = false
    @State private var selectedEmailForDetail: EmailMessage? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Background
                LiquidAmbientBackground(theme: mailStore.glassTheme)
                
                VStack(spacing: 0) {
                    
                    // MARK: - Top Header & Account Switcher
                    HStack {
                        // Account Selector Pill
                        Button(action: {
                            Haptics.light()
                            showingAccountSheet = true
                        }) {
                            HStack(spacing: 8) {
                                if let acc = mailStore.selectedAccount {
                                    ProviderBrandBadge(provider: acc.provider, size: 20)
                                    Text(acc.name)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                } else {
                                    Image(systemName: "tray.2.fill")
                                        .foregroundColor(.cyan)
                                    Text("Toutes les boîtes")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .liquidGlass(cornerRadius: 18, borderOpacity: 0.3)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // Compose Floating Button
                        Button(action: {
                            Haptics.medium()
                            showingCompose = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.cyan, Color.blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 42, height: 42)
                                
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: Color.cyan.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    
                    // MARK: - Search Bar (With AI Natural Language Support)
                    LiquidGlassSearchBar(
                        text: $mailStore.searchText,
                        isAIModeActive: mailStore.isAIModeSearchActive,
                        onToggleAIMode: {
                            mailStore.isAIModeSearchActive.toggle()
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    
                    // MARK: - Category Filter Pills
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
                    }
                    .padding(.bottom, 12)
                    
                    // MARK: - AI Inbox Zero & Productivity Banner
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .symbolEffect(.pulse)
                            .foregroundColor(.cyan)
                            .font(.system(size: 15))
                        
                        let actionCount = mailStore.emails.filter { $0.category == .actionRequired && !$0.isRead }.count
                        Text("\(actionCount) action\(actionCount > 1 ? "s" : "") urgente\(actionCount > 1 ? "s" : "") • 184 min gagnées par l'IA")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary.opacity(0.9))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.cyan.opacity(0.12))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    
                    // MARK: - Email Messages List
                    if mailStore.filteredEmails.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "tray.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("Boîte de réception vide")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("Tous les e-mails sont triés ou archivés.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary.opacity(0.8))
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(mailStore.filteredEmails) { email in
                                EmailRowView(email: email)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
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
                    }
                }
                
                // MARK: - Floating Undo Send Toast
                if let pending = mailStore.pendingSend {
                    HStack(spacing: 12) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.cyan)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Envoi en cours...")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Destinataire : \(pending.recipient)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            mailStore.cancelSend()
                        }) {
                            Text("Annuler (\(pending.remainingSeconds)s)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.red.opacity(0.85)))
                        }
                    }
                    .padding(14)
                    .liquidGlass(cornerRadius: 20, borderOpacity: 0.6, glowColor: .cyan)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: mailStore.pendingSend?.remainingSeconds)
                }
            }
            .navigationBarHidden(true)
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
}

// MARK: - Email Row Component
public struct EmailRowView: View {
    public let email: EmailMessage
    
    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Unread dot indicator
            Circle()
                .fill(email.isRead ? Color.clear : Color.cyan)
                .frame(width: 8, height: 8)
                .padding(.top, 14)
            
            // Avatar with Provider Badge
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(email.senderName.prefix(2)).uppercased())
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    )
                
                ProviderBrandBadge(provider: email.provider, size: 16)
                    .offset(x: 3, y: 3)
            }
            
            // Email Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(email.senderName)
                        .font(.system(size: 15, weight: email.isRead ? .medium : .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(email.formattedRelativeTime)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Text(email.subject)
                    .font(.system(size: 14, weight: email.isRead ? .regular : .semibold))
                    .foregroundColor(.primary.opacity(0.9))
                    .lineLimit(1)
                
                Text(email.preview)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .lineSpacing(2)
                
                // Bottom Badges (Category & AI TL;DR snippet)
                HStack(spacing: 8) {
                    // Category pill
                    HStack(spacing: 4) {
                        Image(systemName: email.category.iconName)
                            .font(.system(size: 10))
                        Text(email.category.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(email.category.badgeColor.opacity(0.2)))
                    .foregroundColor(email.category.badgeColor)
                    
                    if email.isPhishingAlert {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                            Text("Phishing")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.red.opacity(0.2)))
                        .foregroundColor(.red)
                    }
                    
                    if !email.attachments.isEmpty {
                        Image(systemName: "paperclip")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    if email.isStarred {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                    }
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .liquidGlass(
            cornerRadius: 18,
            borderOpacity: email.isRead ? 0.2 : 0.45,
            glowColor: email.isRead ? .white : .cyan
        )
    }
}
