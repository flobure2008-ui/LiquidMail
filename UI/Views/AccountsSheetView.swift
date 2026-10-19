import SwiftUI

public struct AccountsSheetView: View {
    @EnvironmentObject var mailStore: MailStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddAccountModal: Bool = false
    @State private var accountToDelete: EmailAccount? = nil
    @State private var showingDeleteAlert: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidAmbientBackground(theme: mailStore.glassTheme)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Unified Inbox Option
                        Button(action: {
                            Haptics.light()
                            mailStore.selectedAccount = nil
                            dismiss()
                        }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "tray.2.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Toutes les boîtes de réception")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("Vue unifiée (\(mailStore.emails.count) e-mails)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if mailStore.selectedAccount == nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.cyan)
                                        .font(.system(size: 18))
                                }
                            }
                            .padding(14)
                            .liquidGlass(cornerRadius: 16, borderOpacity: mailStore.selectedAccount == nil ? 0.5 : 0.15, glowColor: .cyan)
                        }
                        .buttonStyle(.plain)
                        
                        Text("Boîtes de messagerie connectées")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal, 4)
                        
                        if mailStore.accounts.isEmpty {
                            Text("Aucune boîte connectée pour le moment.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                        } else {
                            ForEach(mailStore.accounts) { acc in
                                HStack(spacing: 12) {
                                    Button(action: {
                                        Haptics.light()
                                        mailStore.selectedAccount = acc
                                        dismiss()
                                    }) {
                                        HStack(spacing: 14) {
                                            ProviderBrandBadge(provider: acc.provider, size: 36)
                                            
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(acc.name)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.primary)
                                                
                                                Text(acc.emailAddress)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                                
                                                HStack(spacing: 4) {
                                                    Circle().fill(Color.green).frame(width: 6, height: 6)
                                                    Text("En direct • IMAP \(acc.provider.imapHost)")
                                                        .font(.system(size: 11))
                                                        .foregroundColor(.secondary.opacity(0.8))
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            if mailStore.selectedAccount?.id == acc.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.cyan)
                                                    .font(.system(size: 18))
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    
                                    // Delete button
                                    Button(action: {
                                        accountToDelete = acc
                                        showingDeleteAlert = true
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14))
                                            .foregroundColor(.red.opacity(0.75))
                                            .padding(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(14)
                                .liquidGlass(
                                    cornerRadius: 16,
                                    borderOpacity: mailStore.selectedAccount?.id == acc.id ? 0.45 : 0.15,
                                    glowColor: .cyan
                                )
                            }
                        }
                        
                        Button(action: {
                            Haptics.medium()
                            showingAddAccountModal = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.cyan)
                                Text("Connecter une nouvelle adresse e-mail...")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.cyan)
                                Spacer()
                            }
                            .padding(14)
                            .liquidGlass(cornerRadius: 16, borderOpacity: 0.25, glowColor: .cyan)
                        }
                        .padding(.top, 4)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Boîtes de messagerie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                        .foregroundColor(.cyan)
                }
            }
            .alert("Supprimer le compte", isPresented: $showingDeleteAlert, presenting: accountToDelete) { acc in
                Button("Supprimer", role: .destructive) {
                    mailStore.removeAccount(id: acc.id)
                }
                Button("Annuler", role: .cancel) {}
            } message: { acc in
                Text("Voulez-vous supprimer le compte \(acc.emailAddress) et ses e-mails associés de LiquidMail ?")
            }
            .sheet(isPresented: $showingAddAccountModal) {
                AddAccountView()
                    .environmentObject(mailStore)
            }
        }
    }
}

// MARK: - Add Account Sub-View with Real IMAP Connection & Advanced Host Settings
public struct AddAccountView: View {
    @EnvironmentObject var mailStore: MailStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProvider: EmailProvider = .customImap
    @State private var emailAddress: String = ""
    @State private var appPassword: String = ""
    
    // Server configuration state
    @State private var imapHost: String = ""
    @State private var imapPort: String = "993"
    @State private var imapUseSSL: Bool = true
    @State private var smtpHost: String = ""
    @State private var smtpPort: String = "465"
    @State private var showAdvancedSettings: Bool = false
    
    @State private var isConnecting: Bool = false
    @State private var autoDiscoveryDetected: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showingErrorAlert: Bool = false
    @State private var connectionStepText: String = "Connexion au serveur IMAP..."
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidAmbientBackground(theme: mailStore.glassTheme)
                
                ScrollView {
                    VStack(spacing: 18) {
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ajouter une adresse e-mail")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("LiquidMail se connecte directement à vos serveurs de messagerie avec chiffrement TLS de bout en bout (Orange, Free, SFR, OVH, Gmail, iCloud, Yahoo, ikmail...).")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Form fields
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Adresse e-mail :")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.cyan)
                                    TextField("votre-nom@domaine.fr", text: $emailAddress)
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .onChange(of: emailAddress) { _, newVal in
                                            autoDetect(newVal)
                                        }
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mot de passe :")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.cyan)
                                    SecureField("Mot de passe ou mot de passe d'app", text: $appPassword)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                            }
                        }
                        
                        // Provider-specific security banner (Google, Apple, Yahoo)
                        providerSecurityBanner
                        
                        // Auto-detected server info pill
                        if autoDiscoveryDetected && !imapHost.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Serveur détecté : \(imapHost):\(imapPort) (TLS)")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(12)
                            .liquidGlass(cornerRadius: 12, borderOpacity: 0.35, glowColor: .green)
                        }
                        
                        // Advanced Server Configuration Disclosure
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                withAnimation(.spring()) {
                                    showAdvancedSettings.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "slider.horizontal.3")
                                        .foregroundColor(.cyan)
                                    Text("Paramètres avancés du serveur (optionnel)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.cyan)
                                    Spacer()
                                    Image(systemName: showAdvancedSettings ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .padding(12)
                                .liquidGlass(cornerRadius: 12, borderOpacity: 0.15)
                            }
                            .buttonStyle(.plain)
                            
                            if showAdvancedSettings {
                                VStack(spacing: 10) {
                                    HStack {
                                        Text("Serveur IMAP :")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .frame(width: 100, alignment: .leading)
                                        TextField("ex: imap.mon-domaine.com", text: $imapHost)
                                            .font(.system(size: 12, design: .monospaced))
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .padding(8)
                                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                                    }
                                    
                                    HStack {
                                        Text("Port IMAP :")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .frame(width: 100, alignment: .leading)
                                        TextField("993", text: $imapPort)
                                            .font(.system(size: 12, design: .monospaced))
                                            .keyboardType(.numberPad)
                                            .padding(8)
                                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                                    }
                                    
                                    Toggle("Chiffrement SSL / TLS", isOn: $imapUseSSL)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Text("Serveur SMTP :")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .frame(width: 100, alignment: .leading)
                                        TextField("ex: smtp.mon-domaine.com", text: $smtpHost)
                                            .font(.system(size: 12, design: .monospaced))
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .padding(8)
                                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                                    }
                                    
                                    HStack {
                                        Text("Port SMTP :")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .frame(width: 100, alignment: .leading)
                                        TextField("465", text: $smtpPort)
                                            .font(.system(size: 12, design: .monospaced))
                                            .keyboardType(.numberPad)
                                            .padding(8)
                                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                                    }
                                }
                                .padding(12)
                                .liquidGlass(cornerRadius: 12, borderOpacity: 0.15)
                            }
                        }
                        
                        Button(action: {
                            Task {
                                await performRealConnection()
                            }
                        }) {
                            HStack(spacing: 8) {
                                if isConnecting {
                                    ProgressView().tint(.white)
                                    Text(connectionStepText)
                                        .font(.system(size: 14, weight: .bold))
                                } else {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.system(size: 14))
                                    Text("Connecter le compte")
                                        .font(.system(size: 15, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(16)
                            .foregroundColor(.white)
                        }
                        .disabled(emailAddress.isEmpty || appPassword.isEmpty || isConnecting)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Nouveau compte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
            .alert("Résultat de connexion", isPresented: $showingErrorAlert) {
                Button("Réessayer", role: .cancel) {}
                Button("Enregistrer quand même") {
                    saveAccountOffline()
                }
            } message: {
                Text(errorMessage ?? "Une erreur est survenue lors de la connexion.")
            }
        }
    }
    
    // MARK: - Contextual Provider Security Banner
    @ViewBuilder
    private var providerSecurityBanner: some View {
        let lower = emailAddress.lowercased()
        if lower.contains("gmail.com") {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Exigence de sécurité Google / Gmail")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                }
                Text("Google refuse votre mot de passe habituel par IMAP. Vous devez utiliser un **Mot de passe d'application** (code à 16 lettres) généré sur votre compte Google :\n• Rendez-vous sur myaccount.google.com\n• Allez dans Sécurité > Validation en 2 étapes\n• Cliquez sur 'Mots de passe des applications'\n• Copiez le code à 16 lettres et collez-le ci-dessus.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(2)
            }
            .padding(12)
            .liquidGlass(cornerRadius: 14, borderOpacity: 0.35, glowColor: .orange)
        } else if lower.contains("icloud.com") || lower.contains("me.com") {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "applelogo")
                        .foregroundColor(.cyan)
                    Text("Exigence de sécurité Apple iCloud")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)
                }
                Text("Apple exige un **Mot de passe pour application tierce** :\n• Rendez-vous sur appleid.apple.com\n• Rubrique Connexion et sécurité\n• Cliquez sur 'Mots de passe pour application tierce'\n• Générez un mot de passe et collez-le ci-dessus.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(2)
            }
            .padding(12)
            .liquidGlass(cornerRadius: 14, borderOpacity: 0.35, glowColor: .cyan)
        } else if lower.contains("yahoo.") {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.purple)
                    Text("Exigence de sécurité Yahoo")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.purple)
                }
                Text("Yahoo exige un **Mot de passe d'application** :\n• Connectez-vous sur login.yahoo.com/account/security\n• Cliquez sur 'Générer un mot de passe d'application'\n• Copiez le code et collez-le ci-dessus.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(2)
            }
            .padding(12)
            .liquidGlass(cornerRadius: 14, borderOpacity: 0.35, glowColor: .purple)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.circle.fill")
                        .foregroundColor(.cyan)
                    Text("Connexion directe & sécurisée")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)
                }
                Text("Pour Infomaniak, Orange, Free, SFR, OVH et vos serveurs personnalisés, vos identifiants habituels fonctionnent directement avec le chiffrement TLS.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
            .padding(12)
            .liquidGlass(cornerRadius: 14, borderOpacity: 0.20)
        }
    }
    
    private func autoDetect(_ text: String) {
        if text.contains("@") && text.contains(".") {
            let config = MailAutoDiscovery.shared.discover(email: text)
            withAnimation(.spring()) {
                self.imapHost = config.imapHost
                self.imapPort = "\(config.imapPort)"
                self.smtpHost = config.smtpHost
                self.smtpPort = "\(config.smtpPort)"
                self.imapUseSSL = config.useSSL
                self.autoDiscoveryDetected = true
                
                let lower = text.lowercased()
                if lower.contains("icloud.com") || lower.contains("me.com") {
                    self.selectedProvider = .icloud
                } else if lower.contains("gmail.com") {
                    self.selectedProvider = .gmail
                } else if lower.contains("yahoo.") {
                    self.selectedProvider = .yahoo
                } else if lower.contains("ik.me") || lower.contains("infomaniak") {
                    self.selectedProvider = .ikmail
                } else if lower.contains("outlook.") || lower.contains("hotmail.") {
                    self.selectedProvider = .outlook
                } else {
                    self.selectedProvider = .customImap
                }
            }
        }
    }
    
    private func performRealConnection() async {
        Haptics.medium()
        
        let trimmedEmail = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass = appPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var currentHost = imapHost.trimmingCharacters(in: .whitespacesAndNewlines)
        if currentHost.isEmpty {
            let discovered = MailAutoDiscovery.shared.discover(email: trimmedEmail)
            currentHost = discovered.imapHost
            if currentHost.isEmpty {
                currentHost = "imap." + (trimmedEmail.components(separatedBy: "@").last ?? "")
            }
            imapHost = currentHost
        }
        
        let portInt = Int(imapPort) ?? 993
        let finalConfig = ServerConfig(
            imapHost: currentHost,
            imapPort: portInt,
            smtpHost: smtpHost.isEmpty ? "smtp." + (trimmedEmail.components(separatedBy: "@").last ?? "") : smtpHost,
            smtpPort: Int(smtpPort) ?? 465,
            useSSL: imapUseSSL
        )
        
        await MainActor.run {
            isConnecting = true
            connectionStepText = "Connexion sécurisée à \(currentHost)..."
        }
        
        do {
            let fetchedEmails = try await RealIMAPService.shared.authenticateAndFetch(
                email: trimmedEmail,
                password: trimmedPass,
                serverConfig: finalConfig
            )
            
            await MainActor.run {
                KeychainManager.shared.save(key: "account_pwd_\(trimmedEmail)", data: trimmedPass)
                
                let name = trimmedEmail.components(separatedBy: "@").first?.capitalized ?? "Mon Compte"
                let newAcc = EmailAccount(name: name, emailAddress: trimmedEmail, provider: selectedProvider, isActive: true)
                mailStore.accounts.append(newAcc)
                
                if !fetchedEmails.isEmpty {
                    for email in fetchedEmails {
                        var modified = email
                        modified.accountId = newAcc.id
                        mailStore.emails.append(modified)
                    }
                } else {
                    let welcomeMsg = EmailMessage(
                        accountId: newAcc.id,
                        provider: selectedProvider,
                        senderName: "Assistant LiquidMail",
                        senderEmail: "assistant@liquidmail.app",
                        recipientEmail: trimmedEmail,
                        subject: "Bienvenue sur LiquidMail ✨",
                        preview: "Votre compte \(trimmedEmail) est connecté avec succès en direct via IMAP TLS.",
                        bodyContent: "Félicitations !\n\nVotre boîte de messagerie (\(trimmedEmail)) est désormais connectée à LiquidMail avec le chiffrement TLS direct.\n\nVous pouvez dès à présent synchroniser vos messages, profiter du triage intelligent par IA et composer de nouveaux e-mails.",
                        timestamp: Date(),
                        isRead: false,
                        isStarred: true,
                        category: .vip,
                        aiSummary: AISummary(tldr: "Boîte \(trimmedEmail) connectée et prête à l'emploi.", sentiment: .positive)
                    )
                    mailStore.emails.insert(welcomeMsg, at: 0)
                }
                
                mailStore.persistAccounts()
                mailStore.persistEmails()
                isConnecting = false
                Haptics.success()
                dismiss()
            }
        } catch {
            await MainActor.run {
                isConnecting = false
                errorMessage = error.localizedDescription
                showingErrorAlert = true
                Haptics.warning()
            }
        }
    }
    
    private func saveAccountOffline() {
        let trimmedEmail = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass = appPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        KeychainManager.shared.save(key: "account_pwd_\(trimmedEmail)", data: trimmedPass)
        let name = trimmedEmail.components(separatedBy: "@").first?.capitalized ?? "Mon Compte"
        let newAcc = EmailAccount(name: name, emailAddress: trimmedEmail, provider: selectedProvider, isActive: true)
        mailStore.accounts.append(newAcc)
        
        let offlineWelcome = EmailMessage(
            accountId: newAcc.id,
            provider: selectedProvider,
            senderName: "Assistant LiquidMail",
            senderEmail: "assistant@liquidmail.app",
            recipientEmail: trimmedEmail,
            subject: "Compte \(trimmedEmail) enregistré",
            preview: "Compte configuré. Vos messages se synchroniseront dès la prochaine connexion réseau.",
            bodyContent: "Votre compte a été enregistré sur cet appareil.\n\nServeur IMAP configuré : \(imapHost.isEmpty ? "Automatique" : imapHost).\n\nSi vos identifiants requièrent un Mot de passe d'application (Gmail, Yahoo, Apple), assurez-vous de l'avoir généré dans les paramètres de sécurité de votre fournisseur.",
            timestamp: Date(),
            isRead: false,
            isStarred: false,
            category: .important,
            aiSummary: AISummary(tldr: "Compte enregistré localement.", sentiment: .neutral)
        )
        mailStore.emails.insert(offlineWelcome, at: 0)
        mailStore.persistAccounts()
        mailStore.persistEmails()
        dismiss()
    }
}
