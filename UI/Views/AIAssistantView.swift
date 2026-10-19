import SwiftUI

public struct AIChatMessage: Identifiable {
    public let id: UUID = UUID()
    public var isUser: Bool
    public var text: String
    public var referencedEmailIds: [UUID] = []
    public var timestamp: Date = Date()
}

public struct AIAssistantView: View {
    @EnvironmentObject var mailStore: MailStore
    @State private var inputText: String = ""
    @State private var messages: [AIChatMessage] = [
        AIChatMessage(
            isUser: false,
            text: "Bonjour Florian ! Je suis votre Copilote Liquid Intelligence. Je veille sur vos boîtes iCloud, Gmail, Yahoo et ikmail. Que souhaitez-vous savoir ?"
        )
    ]
    @State private var isThinking: Bool = false
    @State private var selectedEmailForDetail: EmailMessage? = nil
    
    let suggestedPrompts = [
        "Qu'ai-je d'urgent à traiter aujourd'hui ?",
        "Fais la synthèse de mes dernières factures",
        "Y a-t-il des alertes de sécurité ou du spam ?",
        "Quels sont mes prochains voyages réservés ?"
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                LiquidAmbientBackground(theme: mailStore.glassTheme)
                
                VStack(spacing: 0) {
                    
                    // Header Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .symbolEffect(.variableColor)
                                    .foregroundStyle(
                                        LinearGradient(colors: [.cyan, .purple, .pink], startPoint: .leading, endPoint: .trailing)
                                    )
                                Text("Liquid Intelligence")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            Text("Apple Neural Engine • Analyse locale et privée")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    
                    // Chat messages list
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(messages) { msg in
                                    ChatMessageRow(message: msg, onSelectEmail: { email in
                                        selectedEmailForDetail = email
                                    })
                                }
                                
                                if isThinking {
                                    HStack(spacing: 8) {
                                        ProgressView().tint(.cyan)
                                        Text("Analyse de vos boîtes de messagerie...")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.cyan)
                                        Spacer()
                                    }
                                    .padding(14)
                                    .liquidGlass(cornerRadius: 16, borderOpacity: 0.3, glowColor: .cyan)
                                    .padding(.horizontal, 16)
                                }
                                
                                Color.clear.frame(height: 140).id("bottomAnchor")
                            }
                            .padding(.top, 10)
                        }
                        .onChange(of: messages.count) { _, _ in
                            withAnimation {
                                proxy.scrollTo("bottomAnchor", anchor: .bottom)
                            }
                        }
                    }
                    
                    // Bottom Input Area
                    VStack(spacing: 8) {
                        // Horizontal Suggested Prompts Carousel
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestedPrompts, id: \.self) { prompt in
                                    Button(action: {
                                        sendUserPrompt(prompt)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "wand.and.stars")
                                                .font(.system(size: 11))
                                            Text(prompt)
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .liquidGlass(cornerRadius: 14, borderOpacity: 0.3, glowColor: .cyan)
                                        .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        // Input Field
                        HStack(spacing: 10) {
                            TextField("Posez une question sur vos e-mails...", text: $inputText)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                            
                            Button(action: {
                                if !inputText.isEmpty {
                                    sendUserPrompt(inputText)
                                    inputText = ""
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .liquidGlass(cornerRadius: 22, borderOpacity: 0.4, glowColor: .cyan)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                    .background(.ultraThinMaterial)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedEmailForDetail) { email in
                EmailDetailView(email: email)
                    .environmentObject(mailStore)
            }
        }
    }
    
    private func sendUserPrompt(_ text: String) {
        Haptics.medium()
        let userMsg = AIChatMessage(isUser: true, text: text)
        messages.append(userMsg)
        
        withAnimation {
            isThinking = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let reply = generateAIResponse(for: text)
            withAnimation {
                self.messages.append(reply)
                self.isThinking = false
            }
            Haptics.success()
        }
    }
    
    private func generateAIResponse(for prompt: String) -> AIChatMessage {
        let p = prompt.lowercased()
        
        if p.contains("urgent") || p.contains("faire") || p.contains("action") {
            let urgentEmails = mailStore.emails.filter { $0.category == .actionRequired }
            return AIChatMessage(
                isUser: false,
                text: "Vous avez 1 e-mail hautement prioritaire nécessitant une décision aujourd'hui :\n\n• Sophie Martin attend votre validation de l'architecture iOS 18 avant 15h00 pour lancer les développements.",
                referencedEmailIds: urgentEmails.map { $0.id }
            )
        }
        
        if p.contains("facture") || p.contains("dépense") || p.contains("achat") {
            let receiptEmails = mailStore.emails.filter { $0.category == .receipts }
            return AIChatMessage(
                isUser: false,
                text: "Voici les dernières dépenses enregistrées dans vos boîtes :\n\n1. Apple Store : 1 609,00 € (iPhone 16 Pro Max - Facture PDF jointe)\n2. Air France : Billet Paris-Tokyo confirmé pour le 14 Novembre.",
                referencedEmailIds: receiptEmails.map { $0.id }
            )
        }
        
        if p.contains("securite") || p.contains("sécurité") || p.contains("spam") || p.contains("phishing") {
            let spamEmails = mailStore.emails.filter { $0.category == .spam || $0.isPhishingAlert }
            return AIChatMessage(
                isUser: false,
                text: "⚠️ Attention : L'IA a intercepté et bloqué une tentative de phishing sur votre compte Yahoo :\n\n• Expéditeur 'Securite-Banque-Alerte' exigeant un mot de passe sous 24h. Les liens malveillants ont été neutralisés.",
                referencedEmailIds: spamEmails.map { $0.id }
            )
        }
        
        if p.contains("voyage") || p.contains("vol") || p.contains("tokyo") {
            let travelEmails = mailStore.emails.filter { $0.subject.contains("Tokyo") || $0.subject.contains("Air France") }
            return AIChatMessage(
                isUser: false,
                text: "✈️ Vous avez un voyage confirmé :\n\n• Vol Air France AF276 : Paris CDG -> Tokyo Haneda le 14 Novembre à 13h10 (Siège 12A). La carte d'embarquement sera disponible 30h avant le vol.",
                referencedEmailIds: travelEmails.map { $0.id }
            )
        }
        
        // Default smart response
        return AIChatMessage(
            isUser: false,
            text: "J'ai bien analysé l'ensemble de vos 4 boîtes (iCloud, Gmail, Yahoo, ikmail). Vous avez \(mailStore.emails.count) e-mails synchronisés, dont \(mailStore.emails.filter { !$0.isRead }.count) non-lus. Souhaitez-vous que je rédige une réponse ou que je trie automatiquement vos newsletters ?"
        )
    }
}

// MARK: - Chat Message Row
public struct ChatMessageRow: View {
    public let message: AIChatMessage
    public var onSelectEmail: (EmailMessage) -> Void
    @EnvironmentObject var mailStore: MailStore
    
    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.isUser {
                Spacer()
                
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(18)
                    .padding(.leading, 40)
                    .padding(.trailing, 16)
            } else {
                Circle()
                    .fill(LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 32, height: 32)
                    .overlay(Image(systemName: "sparkles").font(.system(size: 14)).foregroundColor(.white))
                    .padding(.leading, 16)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(message.text)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                        .padding(14)
                        .liquidGlass(cornerRadius: 18, borderOpacity: 0.35, glowColor: .cyan)
                    
                    // Interactive Email Attachment Cards
                    if !message.referencedEmailIds.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(message.referencedEmailIds, id: \.self) { id in
                                if let email = mailStore.emails.first(where: { $0.id == id }) {
                                    Button(action: {
                                        Haptics.light()
                                        onSelectEmail(email)
                                    }) {
                                        HStack(spacing: 10) {
                                            ProviderBrandBadge(provider: email.provider, size: 24)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(email.subject)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                                Text("\(email.senderName) • \(email.formattedRelativeTime)")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(10)
                                        .liquidGlass(cornerRadius: 14, borderOpacity: 0.3, glowColor: .cyan)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.trailing, 40)
                
                Spacer()
            }
        }
    }
}
