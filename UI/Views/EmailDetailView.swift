import SwiftUI

public struct EmailDetailView: View {
    public let email: EmailMessage
    @EnvironmentObject var mailStore: MailStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var isReplying: Bool = false
    @State private var replyInitialText: String = ""
    @State private var isAISummaryExpanded: Bool = true
    
    public init(email: EmailMessage) {
        self.email = email
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            LiquidAmbientBackground(theme: mailStore.glassTheme)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // MARK: - Native Apple Mail Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 12) {
                            // Sender Avatar
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.cyan.opacity(0.8), .blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 44, height: 44)
                                
                                Text(String(email.senderName.prefix(2)).uppercased())
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(email.senderName)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(email.formattedRelativeTime)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("À : \(email.recipientEmail)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(email.subject)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, 4)
                    }
                    .padding(16)
                    .liquidGlass(cornerRadius: 18, borderOpacity: 0.25)
                    
                    // MARK: - Native Liquid Glass AI Summary Card
                    VStack(alignment: .leading, spacing: 10) {
                        Button(action: {
                            Haptics.light()
                            withAnimation(.spring()) {
                                isAISummaryExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.cyan)
                                    .font(.system(size: 14))
                                Text("Résumé IA")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.cyan)
                                
                                Spacer()
                                
                                Image(systemName: isAISummaryExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if isAISummaryExpanded {
                            Text(email.aiSummary.tldr)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary.opacity(0.95))
                                .lineSpacing(3)
                            
                            if !email.aiSummary.keyPoints.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(email.aiSummary.keyPoints, id: \.self) { point in
                                        HStack(alignment: .top, spacing: 6) {
                                            Circle().fill(Color.cyan).frame(width: 4, height: 4).offset(y: 6)
                                            Text(point)
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.top, 2)
                            }
                            
                            // Smart quick replies
                            if !email.smartReplies.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(email.smartReplies) { reply in
                                            Button(action: {
                                                Haptics.medium()
                                                replyInitialText = reply.fullResponseText
                                                isReplying = true
                                            }) {
                                                Text(reply.title)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(Capsule().fill(Color.cyan.opacity(0.18)))
                                                    .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.4), lineWidth: 0.8))
                                                    .foregroundColor(.cyan)
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(14)
                    .liquidGlass(cornerRadius: 18, borderOpacity: 0.35, glowColor: .cyan)
                    
                    // MARK: - Email Body
                    Text(email.bodyContent)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineSpacing(6)
                        .padding(18)
                        .liquidGlass(cornerRadius: 18, borderOpacity: 0.15)
                    
                    Spacer(minLength: 70)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            
            // MARK: - Apple Mail Bottom Action Bar
            HStack(spacing: 28) {
                Button(action: {
                    mailStore.delete(email: email)
                    dismiss()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    mailStore.archive(email: email)
                    dismiss()
                }) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    mailStore.toggleStar(for: email)
                }) {
                    Image(systemName: email.isStarred ? "flag.fill" : "flag")
                        .font(.system(size: 18))
                        .foregroundColor(email.isStarred ? .orange : .secondary)
                }
                
                Spacer()
                
                Button(action: {
                    replyInitialText = ""
                    isReplying = true
                }) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.cyan)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .overlay(Rectangle().frame(height: 0.5).foregroundColor(Color.white.opacity(0.15)), alignment: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
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
