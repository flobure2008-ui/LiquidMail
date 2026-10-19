import SwiftUI

public struct EmailDetailView: View {
    public let email: EmailMessage
    @EnvironmentObject var mailStore: MailStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var isReplying: Bool = false
    @State private var replyInitialText: String = ""
    @State private var showingDeleteAlert: Bool = false
    
    public init(email: EmailMessage) {
        self.email = email
    }
    
    public var body: some View {
        ZStack {
            // Background Liquid Glass ambient
            LiquidAmbientBackground(theme: mailStore.glassTheme)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: - Sender Header Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 14) {
                            // Avatar with provider badge
                            ZStack(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.cyan.opacity(0.8), Color.blue.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Text(String(email.senderName.prefix(2)).uppercased())
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                    )
                                
                                ProviderBrandBadge(provider: email.provider, size: 20)
                                    .offset(x: 4, y: 4)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(email.senderName)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(email.formattedRelativeTime)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(email.senderEmail)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 6) {
                                    Text("À : \(email.recipientEmail)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary.opacity(0.8))
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        mailStore.toggleStar(for: email)
                                    }) {
                                        Image(systemName: email.isStarred ? "star.fill" : "star")
                                            .foregroundColor(email.isStarred ? .yellow : .secondary)
                                            .font(.system(size: 18))
                                    }
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        // Subject
                        Text(email.subject)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(18)
                    .liquidGlass(cornerRadius: 24, borderOpacity: 0.3)
                    
                    // MARK: - AI Executive Summary Card (Apple Intelligence Style)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .symbolEffect(.variableColor)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(colors: [.cyan, .purple, .pink], startPoint: .leading, endPoint: .trailing)
                                )
                            
                            Text("Résumé Exécutif IA")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Sentiment Pill
                            HStack(spacing: 4) {
                                Text(email.aiSummary.sentiment.emoji)
                                Text(email.aiSummary.sentiment.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                        }
                        
                        Text(email.aiSummary.tldr)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary.opacity(0.95))
                            .lineSpacing(4)
                        
                        if !email.aiSummary.keyPoints.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(email.aiSummary.keyPoints, id: \.self) { point in
                                    HStack(alignment: .top, spacing: 8) {
                                        Circle()
                                            .fill(Color.cyan)
                                            .frame(width: 5, height: 5)
                                            .offset(y: 7)
                                        Text(point)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        // Action items list if present
                        if !email.aiSummary.actionItems.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Actions à accomplir :")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                ForEach(email.aiSummary.actionItems) { item in
                                    HStack(spacing: 10) {
                                        Button(action: {
                                            mailStore.toggleActionItem(emailId: email.id, actionItemId: item.id)
                                        }) {
                                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(item.isCompleted ? .green : .secondary)
                                                .font(.system(size: 18))
                                        }
                                        
                                        Text(item.title)
                                            .font(.system(size: 14, weight: item.isCompleted ? .regular : .medium))
                                            .strikethrough(item.isCompleted)
                                            .foregroundColor(item.isCompleted ? .secondary : .primary)
                                        
                                        Spacer()
                                        
                                        if let due = item.dueDate {
                                            Text(due, style: .time)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(18)
                    .liquidGlass(cornerRadius: 24, borderOpacity: 0.5, glowColor: .cyan)
                    
                    // MARK: - Phishing Alert (If Suspicious)
                    if email.isPhishingAlert {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Alerte de Sécurité IA")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.red)
                                
                                Text(email.aiSummary.phishingExplanation ?? "Ce message présente de fortes caractéristiques de phishing ou d'usurpation d'identité.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary.opacity(0.85))
                            }
                        }
                        .padding(16)
                        .liquidGlass(cornerRadius: 20, borderOpacity: 0.8, glowColor: .red)
                    }
                    
                    // MARK: - Email Body
                    VStack(alignment: .leading, spacing: 14) {
                        Text(email.bodyContent)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .lineSpacing(6)
                    }
                    .padding(20)
                    .liquidGlass(cornerRadius: 24, borderOpacity: 0.25)
                    
                    // MARK: - Attachments Section
                    if !email.attachments.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Pièces jointes (\(email.attachments.count))")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            ForEach(email.attachments) { att in
                                HStack(spacing: 12) {
                                    Image(systemName: att.iconName)
                                        .font(.system(size: 22))
                                        .foregroundColor(.cyan)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(att.filename)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                        Text(att.formattedSize)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.down.circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(.secondary)
                                }
                                .padding(12)
                                .liquidGlass(cornerRadius: 16, borderOpacity: 0.25)
                            }
                        }
                    }
                    
                    // MARK: - Smart Quick Replies
                    if !email.smartReplies.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "wand.and.stars")
                                    .foregroundColor(.cyan)
                                    .font(.system(size: 13, weight: .bold))
                                Text("Réponses Suggérées par l'IA")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(email.smartReplies) { reply in
                                        Button(action: {
                                            Haptics.medium()
                                            replyInitialText = reply.fullResponseText
                                            isReplying = true
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: reply.toneIcon)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.cyan)
                                                
                                                Text(reply.title)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.primary)
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .liquidGlass(cornerRadius: 18, borderOpacity: 0.4, glowColor: .cyan)
                                        }
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            mailStore.archive(email: email)
                            dismiss()
                        }) {
                            Image(systemName: "archivebox")
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: {
                            mailStore.delete(email: email)
                            dismiss()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            replyInitialText = ""
                            isReplying = true
                        }) {
                            Image(systemName: "arrowshape.turn.up.left.fill")
                                .foregroundColor(.cyan)
                        }
                    }
                }
            }
            .sheet(isPresented: $isReplying) {
                ComposeMailView(
                    replyToEmail: email,
                    prefilledBody: replyInitialText
                )
                .environmentObject(mailStore)
            }
            .onAppear {
                mailStore.markAsRead(emailId: email.id)
            }
        }
    }
}
