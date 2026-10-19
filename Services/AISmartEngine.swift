import SwiftUI

// MARK: - AI Tone Options for Draft Rewriter
public enum AIToneStyle: String, CaseIterable, Identifiable {
    case professional = "Professionnel"
    case concise = "Concis & Direct"
    case friendly = "Chaleureux"
    case executive = "Direction Exécutive"
    case diplomatic = "Diplomatique"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .professional: return "briefcase.fill"
        case .concise: return "bolt.fill"
        case .friendly: return "heart.fill"
        case .executive: return "crown.fill"
        case .diplomatic: return "scale.3d"
        }
    }
}

// MARK: - AI Smart Engine
public class AISmartEngine: ObservableObject {
    public static let shared = AISmartEngine()
    
    @Published public var isAnalyzing: Bool = false
    @Published public var aiModelName: String = "Apple Intelligence Neural Engine (On-Device)"
    @Published public var totalMinutesSaved: Int = 184 // Productivity metric
    
    public init() {}
    
    // MARK: - Smart Triage & Categorization
    public func triage(emailSubject: String, body: String, sender: String) -> (category: AICategory, summary: AISummary, replies: [SmartReply]) {
        let lowerSub = emailSubject.lowercased()
        let lowerBody = body.lowercased()
        let lowerSender = sender.lowercased()
        
        // 1. Phishing / Spam detection
        if lowerSub.contains("urgent: compte bloqué") || lowerBody.contains("virement immédiat") || lowerSender.contains("securite-banque-update.com") || lowerBody.contains("cliquez ici pour ne pas perdre vos accès") {
            let summary = AISummary(
                tldr: "Tentative probable de phishing usurpant un service officiel.",
                keyPoints: ["Demande de mise à jour urgente de coordonnées", "Nom de domaine expéditeur non concordant"],
                actionItems: [EmailActionItem(title: "Ne cliquer sur aucun lien et bloquer l'expéditeur")],
                sentiment: .suspicious,
                estimatedReadingTimeSeconds: 15,
                securityScore: 0.12,
                phishingExplanation: "Ce courriel utilise un sentiment d'urgence artificiel et provient d'un domaine externe non vérifié."
            )
            return (.spam, summary, [])
        }
        
        // 2. Receipts & Invoices
        if lowerSub.contains("facture") || lowerSub.contains("reçu") || lowerSub.contains("commande") || lowerSub.contains("billet") || lowerBody.contains("tva") || lowerBody.contains("montant réglé") {
            let summary = AISummary(
                tldr: "Justificatif de commande et facturation acquittée.",
                keyPoints: ["Achat validé et débité avec succès", "Justificatif PDF disponible en pièce jointe"],
                actionItems: [EmailActionItem(title: "Archiver pour la comptabilité")],
                sentiment: .positive,
                estimatedReadingTimeSeconds: 20,
                securityScore: 0.99
            )
            let replies = [
                SmartReply(title: "Bien reçu, merci", fullResponseText: "Bonjour,\n\nBien reçu, je vous remercie pour l'envoi de la facture.\n\nBien cordialement."),
                SmartReply(title: "Transmettre au comptable", fullResponseText: "Bonjour,\n\nMerci, je transmets immédiatement cette pièce au service comptabilité.\n\nBonne journée.")
            ]
            return (.receipts, summary, replies)
        }
        
        // 3. Action Required
        if lowerSub.contains("urgent") || lowerSub.contains("validation") || lowerSub.contains("signature") || lowerBody.contains("pourriez-vous me confirmer") || lowerBody.contains("date limite") {
            let summary = AISummary(
                tldr: "Action ou validation attendue de votre part dans les plus brefs délais.",
                keyPoints: ["Confirmation de disponibilité demandée", "Décision requise avant la fin de semaine"],
                actionItems: [
                    EmailActionItem(title: "Valider le document ou proposer un créneau", isCompleted: false, dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()))
                ],
                sentiment: .urgent,
                estimatedReadingTimeSeconds: 35,
                securityScore: 0.97
            )
            let replies = [
                SmartReply(title: "C'est validé pour moi !", fullResponseText: "Bonjour,\n\nJ'ai bien pris connaissance des éléments. Tout est validé de mon côté pour poursuivre le projet.\n\nExcellente journée !"),
                SmartReply(title: "Proposer un appel rapide", fullResponseText: "Bonjour,\n\nSeriez-vous disponible pour un court point de 10 minutes aujourd'hui afin de caler les derniers détails ?\n\nÀ très vite."),
                SmartReply(title: "Besoin d'un délai", fullResponseText: "Bonjour,\n\nBien reçu. Je reviens vers vous avec un retour complet d'ici demain midi.\n\nMerci pour votre patience.")
            ]
            return (.actionRequired, summary, replies)
        }
        
        // 4. Newsletters
        if lowerSub.contains("newsletter") || lowerBody.contains("se désabonner") || lowerBody.contains("unsubscribe") || lowerSub.contains("hebdo") {
            let summary = AISummary(
                tldr: "Édition hebdomadaire récapitulative des actualités et tendances.",
                keyPoints: ["Nouvelles sorties technologiques", "Analyses de marché et conseils pratiques"],
                actionItems: [],
                sentiment: .neutral,
                estimatedReadingTimeSeconds: 90,
                securityScore: 0.95
            )
            return (.newsletters, summary, [])
        }
        
        // 5. Default / VIP
        let summary = AISummary(
            tldr: "Message de coordination générale.",
            keyPoints: ["Mise au point sur les dossiers en cours", "Aucun blocage majeur signalé"],
            actionItems: [EmailActionItem(title: "Prendre note des informations")],
            sentiment: .positive,
            estimatedReadingTimeSeconds: 25,
            securityScore: 0.98
        )
        let replies = [
            SmartReply(title: "Parfait, merci !", fullResponseText: "Bonjour,\n\nC'est bien noté, un grand merci pour ces précisions.\n\nBien à toi."),
            SmartReply(title: "Je m'en occupe", fullResponseText: "Bonjour,\n\nBien reçu ! Je prends le point en charge dès maintenant et te tiens au courant.\n\nBonne continuation.")
        ]
        return (.vip, summary, replies)
    }
    
    // MARK: - AI Tone Rewriter
    public func rewriteText(_ draft: String, in tone: AIToneStyle) -> String {
        guard !draft.isEmpty else { return "" }
        switch tone {
        case .professional:
            return "Bonjour,\n\nJe me permets de vous contacter afin de donner suite à nos derniers échanges. \(draft)\n\nJe reste à votre entière disposition pour tout complément d'information.\n\nBien cordialement,\nFlorian"
        case .concise:
            return "Bonjour,\n\nPour faire court : \(draft)\n\nMerci et bonne journée."
        case .friendly:
            return "Hello !\n\nJ'espère que tu passes une excellente semaine ! Petit mot rapide : \(draft)\n\nÀ très vite et prends soin de toi !"
        case .executive:
            return "Bonjour,\n\nVoici le point stratégique à retenir : \(draft)\n\nLes prochaines étapes s'exécuteront conformément au calendrier validé.\n\nCordialement."
        case .diplomatic:
            return "Bonjour,\n\nJe comprends parfaitement la situation et les impératifs évoqués. Concernant ce point : \(draft)\n\nTrouvons ensemble la solution la plus adaptée.\n\nBien à vous."
        }
    }
    
    // MARK: - Natural Language Search Filter
    public func matchesSemanticSearch(email: EmailMessage, query: String) -> Bool {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return true }
        
        // Exact tokens
        if email.subject.lowercased().contains(q) ||
            email.senderName.lowercased().contains(q) ||
            email.senderEmail.lowercased().contains(q) ||
            email.bodyContent.lowercased().contains(q) ||
            email.aiSummary.tldr.lowercased().contains(q) {
            return true
        }
        
        // Semantic intents
        if (q.contains("facture") || q.contains("achat") || q.contains("argent")) && email.category == .receipts {
            return true
        }
        if (q.contains("urgent") || q.contains("action") || q.contains("faire")) && email.category == .actionRequired {
            return true
        }
        if (q.contains("spam") || q.contains("arnaque") || q.contains("danger")) && (email.category == .spam || email.isPhishingAlert) {
            return true
        }
        if (q.contains("icloud") && email.provider == .icloud) ||
           (q.contains("gmail") && email.provider == .gmail) ||
           (q.contains("yahoo") && email.provider == .yahoo) ||
           (q.contains("ikmail") || q.contains("infomaniak")) && email.provider == .ikmail {
            return true
        }
        
        return false
    }
}
