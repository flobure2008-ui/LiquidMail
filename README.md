# 🫧 LiquidMail — Client E-mail iPhone "Liquid Glass" & Intelligence Artificielle

**LiquidMail** est une application iOS moderne conçue pour iPhone (iOS 17 & 18+) alliant le design iconique **Apple "Liquid Glass"** (matériaux translucides, réfraction de la lumière, dégradés d'ambiance dynamiques, micro-interactions haptiques) avec un moteur de tri et d'assistance propulsé par l'**Intelligence Artificielle (Apple Intelligence / On-Device Neural Engine)**.

---

## ✨ Points Clés & Fonctionnalités

### 1. 🪟 Design Apple "Liquid Glass" & Glassmorphism
- **Matériaux Translucides** : Utilisation de `.ultraThinMaterial` avec surcouches spéculaires irisées et reflets de lumière subtils.
- **Mesh Gradients Fluides** : Arrière-plans ambiants animés avec 5 thèmes au choix : *Aurore Boréale, Obsidienne Minuit, Opale Nacrée, Quartz Rose, Liquid Cyber*.
- **Dock Flottant Verre Liquide** : Barre d'onglets inférieure flottante avec badges de notifications et rebonds dynamiques (Spring animations).
- **Retour Haptique Immersif** : Générateurs haptiques sur les gestes de glissement (swipes), les taps et les validations IA.

### 2. 📬 Multi-Comptes & Fournisseurs E-mail Universels
LiquidMail gère simultanément et de façon unifiée :
- **☁️ iCloud Mail** : Synchronisation native Apple avec mot de passe d'application ou authentification Apple ID.
- **🔴 Google Gmail & Workspace** : Prise en charge OAuth2 et IMAP/SMTP (`imap.gmail.com`).
- **🟣 Yahoo Mail & myYahoo** : Détection automatique des flux Yahoo (`imap.mail.yahoo.com`).
- **🟢 Infomaniak (ikmail & ik.me)** : Boîtes mails éthiques suisses souveraines chiffrées (`mail.infomaniak.com`).
- **🔵 Microsoft Outlook / 365** : Prise en charge des comptes Microsoft.
- **⚙️ IMAP / SMTP Personnalisé** : Connexion à n'importe quel hébergeur ou serveur privé.

### 3. 🧠 Moteur d'IA & Triage Intelligent (Apple Intelligence Ready)
- **Triage Automatique par Catégorie** :
  - 🚨 **Action Requise** : Détecte les urgences, questions ouvertes, demandes de validation et échéances.
  - ⭐ **VIP & Prioritaire** : Identifie les contacts clés et collaborateurs réguliers.
  - 🧾 **Factures & Achats** : Isole les reçus Apple, billets de train/avion, factures avec extraction du montant et PJ PDF.
  - 📰 **Newsletters** : Regroupe les lettres d'information avec option de désinscription rapide.
  - ⚠️ **Bouclier Anti-Phishing** : Analyse heuristique des domaines suspects (.xyz, liens frauduleux, chantage) avec explication pédagogique du danger.
- **Résumé Exécutif TL;DR** : Synthèse de chaque e-mail long en 2 puces clés avec extraction des actions sous forme de to-do list interactive.
- **Réponses Intelligentes (Smart Quick Replies)** : 3 propositions de réponses contextuelles générées en temps réel (ex: "Valider", "Demander un délai", "Décliner poliment").
- **Assistant de Rédaction & Réécriture de Ton** : Reformulation magique d'un brouillon selon le ton voulu (*Professionnel, Concis & Direct, Chaleureux, Direction Exécutive, Diplomatique*).
- **Copilote IA Conversationnel (Tab dédié)** : Posez des questions en langage naturel :
  - *"Qu'ai-je d'urgent à traiter aujourd'hui ?"*
  - *"Fais-moi la synthèse de mes factures d'octobre"*
  - *"Y a-t-il des alertes de sécurité ?"*

### 4. 🚀 Options Cool Supplémentaires
- **⏱️ Annuler l'envoi (Undo Send)** : Bannière flottante avec compte à rebours paramétrable (5s, 10s ou 30s) pour annuler un message envoyé trop vite.
- **🔒 Sécurité Face ID** : Verrouillage biométrique des boîtes sensibles.
- **🔍 Recherche Sémantique IA** : Tapez *"billet avion"* ou *"facture téléphone"* pour trouver instantanément le bon e-mail sans connaître les mots-clés exacts.
- **📊 Inbox Zero Wellness** : Compteur de temps économisé grâce aux résumés d'IA.

---

## 📂 Architecture du Projet

```
LiquidMail/
├── Package.swift                    # Configuration Swift Package Manager (iOS 17+)
├── LiquidMailApp.swift              # Point d'entrée de l'application SwiftUI
├── Models/
│   ├── EmailAccount.swift           # Définition des comptes & fournisseurs (iCloud, Gmail, Yahoo, ikmail)
│   ├── AICategory.swift             # Catégories IA, Sentiments, To-do list & Smart Replies
│   └── EmailMessage.swift           # Modèle des courriels, pièces jointes et badges de sécurité
├── Services/
│   ├── AISmartEngine.swift          # Cerveau IA : Triage, Résumés, Détection de Phishing, Réécriture
│   └── MailStore.swift              # Gestionnaire d'état, comptes, Undo Send et données de démonstration
└── UI/
    ├── Components/
    │   └── GlassComponents.swift    # Modificateurs Liquid Glass, Gradients ambiants, Badges, Haptics
    └── Views/
        ├── InboxView.swift          # Boîte unifiée, filtres de catégories, swipe actions & bannières
        ├── EmailDetailView.swift    # Vue détaillée, résumé TL;DR, alertes de sécurité, Smart Replies
        ├── ComposeMailView.swift    # Compositeur verre liquide avec réécriture de ton IA
        ├── AccountsSheetView.swift  # Gestion et ajout de comptes (iCloud, Gmail, Yahoo, ikmail...)
        ├── AIAssistantView.swift    # Copilote IA interactif pour dialoguer avec sa boîte mail
        ├── SettingsView.swift       # Choix du thème verre liquide, délai Undo Send, Face ID
        └── MainTabView.swift        # Dock flottant verre liquide et navigation globale
```

---

## 📲 Comment l'exécuter dans Xcode

1. Ouvrez le dossier `LiquidMail` dans **Xcode** (sur macOS) en ouvrant `Package.swift` ou en créant un nouveau projet iOS et en y glissant les fichiers.
2. Choisissez un simulateur (ex: **iPhone 16 Pro** sous iOS 18).
3. Cliquez sur **Run (⌘R)**.
4. L'application démarre immédiatement avec 4 comptes pré-configurés (iCloud, Google Workspace, Yahoo, Infomaniak ikmail) et des données de démonstration ultra-réalistes !
