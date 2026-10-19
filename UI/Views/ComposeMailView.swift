import SwiftUI

public struct ComposeMailView: View {
    @EnvironmentObject var mailStore: MailStore
    @Environment(\.dismiss) private var dismiss
    
    var replyToEmail: EmailMessage? = nil
    var prefilledBody: String = ""
    
    @State private var selectedAccount: EmailAccount?
    @State private var recipientText: String = ""
    @State private var subjectText: String = ""
    @State private var bodyText: String = ""
    @State private var showAIToneSheet: Bool = false
    @State private var isAIProcessing: Bool = false
    @State private var rawNotesInput: String = ""
    @State private var showDraftFromNotesAlert: Bool = false
    
    public init(replyToEmail: EmailMessage? = nil, prefilledBody: String = "") {
        self.replyToEmail = replyToEmail
        self.prefilledBody = prefilledBody
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidAmbientBackground(theme: mailStore.glassTheme)
                
                ScrollView {
                    VStack(spacing: 16) {
                        
                        // MARK: - From Account Selector
                        HStack {
                            Text("De :")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(width: 45, alignment: .leading)
                            
                            Menu {
                                ForEach(mailStore.accounts) { acc in
                                    Button(action: {
                                        selectedAccount = acc
                                    }) {
                                        HStack {
                                            Text("\(acc.name) (\(acc.emailAddress))")
                                            if selectedAccount?.id == acc.id {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    if let acc = selectedAccount {
                                        ProviderBrandBadge(provider: acc.provider, size: 16)
                                        Text(acc.emailAddress)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                    } else {
                                        Text("Sélectionner un compte")
                                            .foregroundColor(.secondary)
                                    }
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.white.opacity(0.12)))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .liquidGlass(cornerRadius: 16, borderOpacity: 0.25)
                        
                        // MARK: - Recipient & Subject Fields
                        VStack(spacing: 0) {
                            HStack {
                                Text("À :")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .frame(width: 45, alignment: .leading)
                                
                                TextField("destinataire@exemple.com", text: $recipientText)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            
                            Divider().background(Color.white.opacity(0.15))
                            
                            HStack {
                                Text("Objet :")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .frame(width: 45, alignment: .leading)
                                
                                TextField("Objet du message", text: $subjectText)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .liquidGlass(cornerRadius: 18, borderOpacity: 0.25)
                        
                        // MARK: - AI Magic Toolbar
                        HStack(spacing: 12) {
                            Menu {
                                ForEach(AIToneStyle.allCases) { tone in
                                    Button(action: {
                                        applyToneRewrite(tone)
                                    }) {
                                        Label(tone.rawValue, systemImage: tone.iconName)
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "wand.and.stars")
                                        .symbolEffect(.pulse)
                                        .foregroundColor(.cyan)
                                    Text("Ton IA")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.cyan)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(.cyan)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(Color.cyan.opacity(0.18)))
                                .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.4), lineWidth: 1))
                            }
                            
                            Button(action: {
                                polishDraft()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                    Text("Fluidifier & Corriger")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(Color.white.opacity(0.12)))
                                .foregroundColor(.primary)
                            }
                            
                            Spacer()
                        }
                        
                        // MARK: - Editor Body
                        ZStack(alignment: .topLeading) {
                            if bodyText.isEmpty {
                                Text("Rédigez votre message ici ou utilisez l'IA pour générer un brouillon...")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary.opacity(0.6))
                                    .padding(.top, 10)
                                    .padding(.leading, 6)
                            }
                            
                            TextEditor(text: $bodyText)
                                .font(.system(size: 15))
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 280)
                                .foregroundColor(.primary)
                        }
                        .padding(14)
                        .liquidGlass(cornerRadius: 20, borderOpacity: 0.25)
                        
                    }
                    .padding(16)
                }
            }
            .navigationTitle(replyToEmail != nil ? "Répondre" : "Nouveau Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        send()
                    }) {
                        HStack(spacing: 6) {
                            Text("Envoyer")
                                .fontWeight(.semibold)
                            Image(systemName: "paperplane.fill")
                        }
                        .foregroundColor(.cyan)
                    }
                    .disabled(recipientText.isEmpty || subjectText.isEmpty)
                }
            }
            .onAppear {
                if let firstAcc = mailStore.accounts.first {
                    self.selectedAccount = firstAcc
                }
                if let reply = replyToEmail {
                    self.recipientText = reply.senderEmail
                    self.subjectText = reply.subject.hasPrefix("Re:") ? reply.subject : "Re: \(reply.subject)"
                    if !prefilledBody.isEmpty {
                        self.bodyText = prefilledBody
                    }
                }
            }
        }
    }
    
    // MARK: - Tone Rewrite Helper
    private func applyToneRewrite(_ tone: AIToneStyle) {
        Haptics.medium()
        withAnimation {
            isAIProcessing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let rewritten = AISmartEngine.shared.rewriteText(bodyText.isEmpty ? "Merci pour ton message." : bodyText, in: tone)
            withAnimation {
                self.bodyText = rewritten
                self.isAIProcessing = false
            }
            Haptics.success()
        }
    }
    
    private func polishDraft() {
        Haptics.medium()
        guard !bodyText.isEmpty else { return }
        withAnimation {
            bodyText = bodyText.trimmingCharacters(in: .whitespacesAndNewlines) + "\n\nBien cordialement,\nFlorian"
        }
        Haptics.success()
    }
    
    // MARK: - Send Action with Undo Queue
    private func send() {
        guard let account = selectedAccount ?? mailStore.accounts.first else { return }
        mailStore.sendEmail(
            from: account,
            to: recipientText,
            subject: subjectText,
            body: bodyText
        )
        dismiss()
    }
}
