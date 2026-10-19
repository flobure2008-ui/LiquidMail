# 🫧 LiquidMail — Client E-mail Minimaliste Liquid Glass pour iPhone (iOS 17 & 18+)

**LiquidMail** est une application iOS au **design épuré et minimaliste "Liquid Glass"** (verre translucide ultra-fin, reflets spéculaires soignés, typographie San Francisco aérée) intégrant la connexion universelle à n'importe quelle adresse e-mail et une **API IA** pour trier et résumer automatiquement vos courriels.

Ce dépôt inclut un pipeline **CI/CD GitHub Actions** pour compiler automatiquement l'application en fichier **`.ipa`** prêt à être installé sur votre iPhone.

---

## ✨ Points Forts

### 1. 🪟 Design Minimaliste Liquid Glass & Icône Officielle
- **Esthétique Épurée** : Finies les surcharges visuelles. Des cartes en verre translucide haute fidélité (`.ultraThinMaterial`), des bordures irisées ultra-fines (0.8pt) et un fond obsidienne profond à lueurs subtiles.
- **Icône Minimaliste Officielle** : Icône en verre liquide 3D avec perle d'intelligence centrale, déclinée en 1024x1024 Retina et Display P3 dans `Assets.xcassets/AppIcon.appiconset`.
- **Widgets Écran d'Accueil et Écran Verrouillé** : Suivez vos e-mails prioritaires et actions requises en un coup d'œil (`WidgetKit`).

### 2. 🌐 Connexion Universelle (N'importe quelle adresse e-mail)
- **Moteur d'Auto-Découverte IMAP/SMTP** : Entrez simplement `utilisateur@domaine.fr` (Orange, SFR, Free, LaPoste, OVH, Gmail, iCloud, Yahoo, Infomaniak, etc.) et les serveurs sont détectés automatiquement.
- **Chiffrement Keychain Apple** : Tous vos identifiants sont chiffrés directement dans le Trousseau d'accès sécurisé de l'iPhone.

### 3. 🧠 API IA de Triage et Résumé
- **Modèles Supportés** : OpenAI (`gpt-4o-mini`, `gpt-4o`), Anthropic Claude (`3.5 Sonnet`), Google Gemini, Mistral AI, Ollama (serveur local) ou Apple Intelligence (On-Device).
- **Triage Automatique** : Catégorise vos courriels (*Action Requise, VIP, Factures, Newsletters, Anti-Spam*), résume en 25 mots et génère 3 réponses contextuelles en un clic.

---

## 🚀 Compiler en `.ipa` Automatiquement sur GitHub

Le fichier `.github/workflows/build-ipa.yml` est préconfiguré pour exécuter `xcodebuild` sur les serveurs Mac d'Apple (`macos-14`) de GitHub.

### 1. Envoyer le code sur votre GitHub

Dans votre terminal, exécutez ces deux commandes :

```bash
# 1. Liez votre dépôt GitHub (remplacez par votre URL de dépôt)
git remote add origin https://github.com/VOTRE_PSEUDO/LiquidMail.git

# 2. Poussez le code
git push -u origin main
```

### 2. Télécharger votre `.ipa`
1. Allez sur votre dépôt GitHub dans l'onglet **Actions**.
2. Cliquez sur le dernier workflow exécuté nommé **"Build iOS IPA (LiquidMail)"**.
3. Dans la section **Artifacts**, téléchargez le fichier `LiquidMail-iOS-IPA` qui contient votre `LiquidMail.ipa` !

---

## 📲 Installer le `.ipa` sur votre iPhone

Vous pouvez installer directement le fichier `LiquidMail.ipa` généré par GitHub Actions sur votre iPhone sans passer par l'App Store officiel :
- **AltStore** : Ouvrez AltStore sur votre iPhone > Onglet *My Apps* > Touchez le `+` > Sélectionnez `LiquidMail.ipa`.
- **Sideloadly** : Glissez `LiquidMail.ipa` dans Sideloadly sur votre Mac ou PC et entrez votre identifiant Apple.
- **TrollStore** : Si votre iPhone est compatible, installez l'IPA en 1 seconde sans expiration de certificat.
- **TestFlight / Compte Développeur Apple** : Via Xcode ou Transporter.

---

## 🖥️ Tester Sans Attendre dans le Navigateur
Ouvrez le fichier [`preview.html`](preview.html) dans votre navigateur pour manipuler la maquette interactive iPhone 16 Pro avec le design minimaliste Liquid Glass, les widgets iOS et le panneau de test d'API IA.
