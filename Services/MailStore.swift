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

// MARK: - Main Mail Store
public class MailStore: ObservableObject {
    @Published public var accounts: [EmailAccount] = []
    @Published public var selectedAccount: EmailAccount? = nil // nil means "Toutes les boîtes" (Unified Inbox)
    @Published public var emails: [EmailMessage] = []
    @Published public var selectedCategory: AICategory = .all
    @Published public var searchText: String = ""
    @Published public var isAIModeSearchActive: Bool = false
    @Published public var pendingSend: PendingSentMail? = nil
    @Published public var glassTheme: GlassTheme = .aurora
    @Published public var undoSendDuration: Int = 10 // seconds
    @Published public var isFaceIDEnabled: Bool = false
    
    private var undoTimer: AnyCancellable?
    
    public init() {
        setupDefaultAccounts()
        loadSampleData()
    }
    
    // MARK: - Initial Accounts (iCloud, Gmail, Yahoo, Infomaniak ikmail)
    private func setupDefaultAccounts() {
        let icloudAcc = EmailAccount(
            name: "iCloud Personnel",
            emailAddress: "florian.perso@icloud.com",
            provider: .icloud,
            isActive: true,
            unreadCount: 2
        )
        let gmailAcc = EmailAccount(
            name: "Google Workspace",
            emailAddress: "florian.pro@gmail.com",
            provider: .gmail,
            isActive: true,
            unreadCount: 4
        )
        let yahooAcc = EmailAccount(
            name: "Yahoo Mail",
            emailAddress: "florian.vintage@yahoo.fr",
            provider: .yahoo,
            isActive: true,
            unreadCount: 1
        )
        let ikmailAcc = EmailAccount(
            name: "Infomaniak ikmail",
            emailAddress: "contact@entreprise.ik.me",
            provider: .ikmail,
            isActive: true,
            unreadCount: 1
        )
        
        self.accounts = [icloudAcc, gmailAcc, yahooAcc, ikmailAcc]
    }
    
    // MARK: - Load Realistic Demo Emails
    private func loadSampleData() {
        guard accounts.count >= 4 else { return }
        let icloud = accounts[0]
        let gmail = accounts[1]
        let yahoo = accounts[2]
        let ikmail = accounts[3]
        
        let sampleList: [EmailMessage] = [
            // 1. Action Required (Gmail)
            EmailMessage(
                accountId: gmail.id,
                provider: .gmail,
                senderName: "Sophie Martin (Lead Dev)",
                senderEmail: "sophie.martin@techstudio.io",
                recipientEmail: gmail.emailAddress,
                subject: "🚨 Urgent : Validation de l'architecture iOS 18 & Liquid Glass",
                preview: "Peux-tu valider le wireframe et la spec CoreML avant notre réunion de 15h ?",
                bodyContent: """
                Bonjour Florian,
                
                J'ai terminé la proposition de refonte avec les composants Liquid Glass pour l'application iPhone.
                
                Pourrais-tu jeter un œil aux deux points bloquants avant notre comité de pilotage aujourd'hui à 15h00 ?
                1. Le temps de réponse de l'IA locale (Apple Intelligence) sur l'iPhone 16 Pro.
                2. La gestion du cache hors-ligne pour les boîtes IMAP volumineuses (notamment ikmail et Yahoo).
                
                Les maquettes interactives sont validées par le design. J'attends ton feu vert pour lancer les devs !
                
                Bien à toi,
                Sophie
                """,
                timestamp: Calendar.current.date(byAdding: .minute, value: -25, to: Date()) ?? Date(),
                isRead: false,
                isStarred: true,
                category: .actionRequired,
                aiSummary: AISummary(
                    tldr: "Sophie attend ta validation urgente sur l'architecture Liquid Glass et les perfs Apple Intelligence avant 15h.",
                    keyPoints: [
                        "Point 1 : Temps d'inférence de l'IA sur iPhone 16 Pro",
                        "Point 2 : Gestion du cache IMAP (Yahoo & Infomaniak)",
                        "Deadline : Réunion de pilotage à 15h00"
                    ],
                    actionItems: [
                        EmailActionItem(title: "Valider les perfs IA locale et cache IMAP", isCompleted: false, dueDate: Calendar.current.date(byAdding: .hour, value: 3, to: Date()))
                    ],
                    sentiment: .urgent,
                    estimatedReadingTimeSeconds: 45,
                    securityScore: 0.99
                ),
                smartReplies: [
                    SmartReply(title: "C'est validé, go !", fullResponseText: "Bonjour Sophie,\n\nJ'ai examiné la spec, tout est parfait ! Feu vert pour lancer le sprint. On fait un point rapide à 15h comme prévu.\n\nFlorian"),
                    SmartReply(title: "Je regarde avant 14h30", fullResponseText: "Hello Sophie,\n\nBien noté ! Je me pose dessus tout de suite et je te fais mes retours précis avant 14h30.\n\nÀ tout à l'heure."),
                    SmartReply(title: "Décaler le point de 15h", fullResponseText: "Bonjour Sophie,\n\nPourrais-t-on décaler notre réunion à 16h afin que j'aie le temps de tester les benchs CoreML en conditions réelles ?\n\nMerci !")
                ]
            ),
            
            // 2. Receipts & Invoices (iCloud)
            EmailMessage(
                accountId: icloud.id,
                provider: .icloud,
                senderName: "Apple Store",
                senderEmail: "no_reply@email.apple.com",
                recipientEmail: icloud.emailAddress,
                subject: "🧾 Votre reçu de commande Apple N° W894218902",
                preview: "Merci pour votre achat : iPhone 16 Pro Max 512 Go Titane Naturel",
                bodyContent: """
                Chère cliente, Cher client,
                
                Nous vous remercions pour votre commande effectuée sur l'Apple Store en ligne.
                
                Récapitulatif de votre commande :
                - Article : iPhone 16 Pro Max 512 Go Titane Naturel
                - Montant total TTC : 1 609,00 €
                - Moyen de paiement : Apple Pay (Visa terminée par 9042)
                - Date estimée de livraison : Mercredi 22 Octobre
                
                La facture au format électronique conforme est jointe au présent courriel.
                """,
                timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                isRead: false,
                isStarred: false,
                attachments: [
                    EmailAttachment(filename: "Facture_Apple_W894218902.pdf", fileSizeBytes: 420_000, fileType: "pdf")
                ],
                category: .receipts,
                aiSummary: AISummary(
                    tldr: "Facture Apple Store acquittée de 1 609,00 € pour un iPhone 16 Pro Max. Livraison prévue le 22 Octobre.",
                    keyPoints: ["Commande confirmée et payée via Apple Pay", "Livraison estimée le 22 Octobre", "Facture PDF de 420 Ko en pièce jointe"],
                    actionItems: [EmailActionItem(title: "Sauvegarder la facture pour garantie / compta", isCompleted: false)],
                    sentiment: .positive,
                    estimatedReadingTimeSeconds: 20,
                    securityScore: 1.0
                ),
                smartReplies: [
                    SmartReply(title: "Suivre la livraison", fullResponseText: "Ouvrir le suivi de livraison transporteur."),
                    SmartReply(title: "Transférer au dossier Achats", fullResponseText: "Archiver automatiquement la facture.")
                ]
            ),
            
            // 3. Infomaniak ikmail (Hosting & Privacy)
            EmailMessage(
                accountId: ikmail.id,
                provider: .ikmail,
                senderName: "Infomaniak Support & Cloud",
                senderEmail: "support@infomaniak.com",
                recipientEmail: ikmail.emailAddress,
                subject: "🛡️ Renouvellement de votre Suite Éthique & Boîte ikmail",
                preview: "Votre stockage kDrive 2 To et vos adresses @ik.me sont renouvelés avec succès.",
                bodyContent: """
                Bonjour Florian,
                
                Nous vous confirmons le bon renouvellement de vos services hébergés en Suisse au cœur de nos datacenters écologiques :
                
                - Adresse mail souveraine et chiffrée : contact@entreprise.ik.me
                - Espace de stockage kDrive : 2 To (utilisé à 34%)
                - Filtres anti-spam IA et sécurité zéro-connaissance activés.
                
                Aucune action n'est requise de votre part, le prélèvement a été opéré via votre moyen de paiement habituel.
                
                Merci de faire confiance à un cloud indépendant et respectueux de la vie privée !
                
                L'équipe Infomaniak
                """,
                timestamp: Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date(),
                isRead: true,
                isStarred: true,
                category: .vip,
                aiSummary: AISummary(
                    tldr: "Renouvellement automatique réussi de votre boîte mail Infomaniak et kDrive 2 To en Suisse.",
                    keyPoints: ["Services sécurisés et chiffrés", "Aucune action nécessaire, prélèvement automatique effectué"],
                    actionItems: [],
                    sentiment: .positive,
                    estimatedReadingTimeSeconds: 25,
                    securityScore: 0.99
                ),
                smartReplies: [
                    SmartReply(title: "Merci pour le service !", fullResponseText: "Bonjour,\n\nMerci beaucoup pour ces informations et pour la qualité de vos services hébergés en Suisse.\n\nBonne continuation.")
                ]
            ),
            
            // 4. Phishing Alert Flagged by AI (Yahoo)
            EmailMessage(
                accountId: yahoo.id,
                provider: .yahoo,
                senderName: "Securite-Banque-Alerte",
                senderEmail: "alerte-urgent@verification-login-secure.xyz",
                recipientEmail: yahoo.emailAddress,
                subject: "⚠️ URGENT : Votre compte bancaire est suspendu sous 24h",
                preview: "Cliquez immédiatement sur le lien pour confirmer votre identité bancaire...",
                bodyContent: """
                ATTENTION CLIENT,
                
                Une tentative inhabituelle a été détectée sur votre compte en ligne.
                Pour des raisons de sécurité, votre accès sera définitivement bloqué d'ici 24 heures si vous ne procédez pas à la régularisation de votre profil.
                
                Cliquez sans attendre sur : http://secure-banque-update.xyz/verify-login
                
                Entrez votre identifiant et votre mot de passe pour lever la restriction.
                
                Direction Sécurité Bancaire.
                """,
                timestamp: Calendar.current.date(byAdding: .hour, value: -14, to: Date()) ?? Date(),
                isRead: true,
                isStarred: false,
                category: .spam,
                aiSummary: AISummary(
                    tldr: "🚨 TENTATIVE DE PHISHING DÉTECTÉE ! Ne communiquez jamais vos identifiants.",
                    keyPoints: [
                        "Nom de domaine expéditeur frauduleux (.xyz)",
                        "Demande suspecte de mot de passe",
                        "Urgence artificielle (menace de suspension 24h)"
                    ],
                    actionItems: [
                        EmailActionItem(title: "Supprimer définitivement et bloquer le domaine", isCompleted: false)
                    ],
                    sentiment: .suspicious,
                    estimatedReadingTimeSeconds: 15,
                    securityScore: 0.05,
                    phishingExplanation: "Ce courriel provient d'un serveur malveillant non affilié à votre banque. L'IA a bloqué le chargement des images et des liens externes."
                ),
                smartReplies: []
            ),
            
            // 5. Travel & Tickets (iCloud)
            EmailMessage(
                accountId: icloud.id,
                provider: .icloud,
                senderName: "Air France",
                senderEmail: "reservations@airfrance.fr",
                recipientEmail: icloud.emailAddress,
                subject: "✈️ Votre réservation pour Tokyo (AF276) est confirmée",
                preview: "Vol Paris CDG - Tokyo Haneda HND du 14 Novembre. Siège 12A.",
                bodyContent: """
                Bonjour Florian,
                
                Votre vol à destination de Tokyo Haneda est confirmé !
                
                Détails du vol :
                - Vol : AF276
                - Départ : Paris Charles de Gaulle (Terminal 2E) à 13h10
                - Arrivée : Tokyo Haneda à 09h55 (+1 jour)
                - Siège : 12A (Fenêtre, classe Premium Economy)
                - Bagages : 2 x 23 kg inclus
                
                Vous pourrez vous enregistrer en ligne 30h avant le décollage.
                Votre carte d'embarquement Apple Wallet sera disponible dès l'enregistrement.
                
                Très bon vol avec Air France !
                """,
                timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                isRead: false,
                isStarred: true,
                attachments: [
                    EmailAttachment(filename: "E-Billet_Tokyo_AF276.pdf", fileSizeBytes: 185_000, fileType: "pdf")
                ],
                category: .receipts,
                aiSummary: AISummary(
                    tldr: "Confirmation du vol direct Paris-Tokyo du 14 Novembre. Siège 12A réservé.",
                    keyPoints: ["Vol AF276 au départ de CDG 2E à 13h10", "Enregistrement en ligne 30h avant le vol", "Ajout Apple Wallet disponible à l'enregistrement"],
                    actionItems: [
                        EmailActionItem(title: "Ajouter l'alerte d'enregistrement 30h avant le départ", isCompleted: false)
                    ],
                    sentiment: .positive,
                    estimatedReadingTimeSeconds: 30,
                    securityScore: 0.99
                ),
                smartReplies: [
                    SmartReply(title: "Ajouter au calendrier", fullResponseText: "Créer l'événement dans le calendrier Apple."),
                    SmartReply(title: "Partager l'itinéraire", fullResponseText: "Envoyer les horaires de vol aux proches.")
                ]
            ),
            
            // 6. Tech Weekly Newsletter (Gmail)
            EmailMessage(
                accountId: gmail.id,
                provider: .gmail,
                senderName: "SwiftUI & AI Digest",
                senderEmail: "weekly@swiftuicrafters.com",
                recipientEmail: gmail.emailAddress,
                subject: "📰 Nouveautés Liquid Glass, iOS 18 Shaders et Apple Intelligence",
                preview: "Comment concevoir des interfaces ultra-fluides avec le mesh gradient et les modèles locaux...",
                bodyContent: """
                Bienvenue dans l'édition #148 de votre veille hebdomadaire !
                
                Au sommaire cette semaine :
                1. Les secrets de l'effet 'Liquid Glass' : Combinaison de .ultraThinMaterial, réfraction de la lumière et Spring animations dynamiques.
                2. Intégrer les modèles LLM locaux sur iPhone sans impacter l'autonomie de la batterie.
                3. Comment Infomaniak et d'autres acteurs respectueux de la vie privée intègrent désormais des API IA zero-knowledge.
                
                Bonne lecture à tous les passionnés d'ergonomie Apple !
                """,
                timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                isRead: true,
                isStarred: false,
                category: .newsletters,
                aiSummary: AISummary(
                    tldr: "Newsletter technique axée sur les interfaces Liquid Glass et l'intégration d'IA locale sur iOS.",
                    keyPoints: ["Recette des shaders et reflets de verre", "Optimisation de l'autonomie avec l'IA locale"],
                    actionItems: [],
                    sentiment: .neutral,
                    estimatedReadingTimeSeconds: 120,
                    securityScore: 0.98
                ),
                smartReplies: []
            )
        ]
        
        self.emails = sampleList
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
            Haptics.light()
        }
    }
    
    public func toggleRead(for email: EmailMessage) {
        if let idx = emails.firstIndex(where: { $0.id == email.id }) {
            emails[idx].isRead.toggle()
            Haptics.light()
        }
    }
    
    public func markAsRead(emailId: UUID) {
        if let idx = emails.firstIndex(where: { $0.id == emailId }) {
            emails[idx].isRead = true
        }
    }
    
    public func archive(email: EmailMessage) {
        if let idx = emails.firstIndex(where: { $0.id == email.id }) {
            emails[idx].isArchived = true
            Haptics.medium()
        }
    }
    
    public func delete(email: EmailMessage) {
        if let idx = emails.firstIndex(where: { $0.id == email.id }) {
            emails.remove(at: idx)
            Haptics.warning()
        }
    }
    
    public func toggleActionItem(emailId: UUID, actionItemId: UUID) {
        if let emailIdx = emails.firstIndex(where: { $0.id == emailId }) {
            if let itemIdx = emails[emailIdx].aiSummary.actionItems.firstIndex(where: { $0.id == actionItemId }) {
                emails[emailIdx].aiSummary.actionItems[itemIdx].isCompleted.toggle()
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
                    // Send permanently
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
        
        // Add to sent messages in list
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
        self.pendingSend = nil
    }
    
    // MARK: - Add New Account
    public func addAccount(name: String, email: String, provider: EmailProvider) {
        let newAcc = EmailAccount(name: name, emailAddress: email, provider: provider, isActive: true)
        self.accounts.append(newAcc)
        Haptics.success()
    }
}
