import SwiftUI

public struct AccountsSheetView: View {
    @EnvironmentObject var mailStore: MailStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddAccountModal: Bool = false
    
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
                                                    Text("En direct • IMAP \(acc.serverConfig?.imapHost ?? acc.provider.imapHost)")
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
                                    
                                    Button(action: {
                                        mailStore.accounts.removeAll(where: { $0.id == acc.id })
                                        mailStore.emails.removeAll(where: { $0.accountId == acc.id })
                                        if mailStore.selectedAccount?.id == acc.id {
                                            mailStore.selectedAccount = nil
                                        }
                                        mailStore.persistAccounts()
                                        mailStore.persistEmails()
                                        Haptics.warning()
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red.opacity(0.7))
                                            .font(.system(size: 14))
                                            .padding(6)
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
            .sheet(isPresented: $showingAddAccountModal) {
                AddAccountView()
                    .environmentObject(mailStore)
            }
        }
    }
}

// MARK: - Add Account Sub-View with Real IMAP Authentication & Custom Settings
public struct AddAccountView: View {
    @EnvironmentObject var mailStore: MailStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProvider: EmailProvider = .customImap
    @State private var emailAddress: String = ""
    @State private var appPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    
    // Server Configuration state
    @State private var imapHost: String = ""
    @State private var imapPort: String = "993"
    @State private var imapUseSSL: Bool = true
    @State private var customUsername: String = ""
    @State private var smtpHost: String = ""
    @State private var smtpPort: String = "587"
    @State private var smtpUseSSL: Bool = true
    @State private var isAdvancedConfigExpanded: Bool = false
    
    // Progress & State
    @State private var isConnecting: Bool = false
    @State private var connectionStepText: String = "Connexion au serveur IMAP..."
    @State private var errorMessage: String? = nil
    @State private var showingErrorAlert: Bool = false
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidAmbientBackground(theme: mailStore.glassTheme)
                
                ScrollView {
                    VStack(spacing: 16) {
                        
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Connexion de boîte mail")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Connexion directe universelle TLS à vos serveurs de messagerie (Orange, Free, SFR, Gmail, iCloud, Yahoo, OVH, Infomaniak ou serveur privé).")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineSpacing(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Fast Provider Selectors
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                providerPill(provider: .gmail, title: "Gmail")
                                providerPill(provider: .icloud, title: "iCloud")
                                providerPill(provider: .outlook, title: "Outlook")
                                providerPill(provider: .yahoo, title: "Yahoo")
                                providerPill(provider: .ikmail, title: "Infomaniak")
                                providerPill(provider: .customImap, title: "Autre IMAP")
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // Credentials Box
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Adresse e-mail :")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.cyan)
                                    TextField("nom@domaine.fr", text: $emailAddress)
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .onChange(of: emailAddress) { _, newVal in
                                            handleEmailChange(newVal)
                                        }
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mot de passe ou mot de passe d'app :")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.cyan)
                                    if isPasswordVisible {
                                        TextField("Mot de passe", text: $appPassword)
                                            .autocapitalization(.none)
                                    } else {
                                        SecureField("Mot de passe", text: $appPassword)
                                    }
                                    
                                    Button(action: {
                                        isPasswordVisible.toggle()
                                    }) {
                                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 14))
                                    }
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                            }
                        }
                        
                        // Provider Security Helper
                        providerSecurityNotice
                        
                        // Advanced Server Settings
                        VStack(alignment: .leading, spacing: 10) {
                            Button(action: {
                                withAnimation(.spring()) {
                                    isAdvancedConfigExpanded.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "slider.horizontal.3")
                                        .foregroundColor(.cyan)
                                    Text("Paramètres avancés du serveur")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.cyan)
                                    Spacer()
                                    Image(systemName: isAdvancedConfigExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(.cyan)
                                }
                                .padding(12)
                                .liquidGlass(cornerRadius: 12, borderOpacity: 0.20)
                            }
                            .buttonStyle(.plain)
                            
                            if isAdvancedConfigExpanded {
                                VStack(spacing: 10) {
                                    // Custom username
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Nom d'utilisateur (si différent de l'e-mail) :")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.secondary)
                                        TextField("identifiant (optionnel)", text: $customUsername)
                                            .padding(10)
                                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                                            .autocapitalization(.none)
                                    }
                                    
                                    // IMAP Settings
                                    HStack(spacing: 8) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Serveur entrant IMAP :")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.secondary)
                                            TextField("imap.domaine.fr", text: $imapHost)
                                                .padding(10)
                                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                                                .autocapitalization(.none)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Port :")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.secondary)
                                            TextField("993", text: $imapPort)
                                                .keyboardType(.numberPad)
                                                .frame(width: 65)
                                                .padding(10)
                                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                                        }
                                    }
                                    
                                    Toggle("Chiffrement SSL / TLS (IMAP)", isOn: $imapUseSSL)
                                        .font(.system(size: 12))
                                        .tint(.cyan)
                                    
                                    Divider().background(Color.white.opacity(0.1))
                                    
                                    // SMTP Settings
                                    HStack(spacing: 8) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Serveur sortant SMTP :")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.secondary)
                                            TextField("smtp.domaine.fr", text: $smtpHost)
                                                .padding(10)
                                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                                                .autocapitalization(.none)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Port :")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.secondary)
                                            TextField("587", text: $smtpPort)
                                                .keyboardType(.numberPad)
                                                .frame(width: 65)
                                                .padding(10)
                                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                                        }
                                    }
                                }
                                .padding(12)
                                .liquidGlass(cornerRadius: 14, borderOpacity: 0.25)
                            }
                        }
                        
                        // Connect Button
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
                                    Image(systemName: "link.badge.plus")
                                    Text("Tester et Connecter")
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
    
    // MARK: - Provider Pills
    private func providerPill(provider: EmailProvider, title: String) -> some View {
        Button(action: {
            Haptics.light()
            selectedProvider = provider
            applyProviderDefaults(provider)
        }) {
            HStack(spacing: 6) {
                ProviderBrandBadge(provider: provider, size: 20)
                Text(title)
                    .font(.system(size: 12, weight: selectedProvider == provider ? .bold : .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .liquidGlass(
                cornerRadius: 12,
                borderOpacity: selectedProvider == provider ? 0.6 : 0.15,
                glowColor: selectedProvider == provider ? .cyan : .clear
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Security Notice View
    @ViewBuilder
    private var providerSecurityNotice: some View {
        if selectedProvider == .gmail {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundColor(.red)
                    Text("Sécurité Google (Mot de passe d'application)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                }
                Text("Google exige un 'Mot de passe d'application' (16 lettres) pour autoriser les logiciels de messagerie indépendants.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Link(destination: URL(string: "https://myaccount.google.com/apppasswords")!) {
                    HStack(spacing: 4) {
                        Text("Générer mon mot de passe d'app Google")
                            .font(.system(size: 11, weight: .bold))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.cyan)
                    .padding(.top, 2)
                }
            }
            .padding(12)
            .liquidGlass(cornerRadius: 14, borderOpacity: 0.3, glowColor: .red)
        } else if selectedProvider == .icloud {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "apple.logo")
                        .foregroundColor(.cyan)
                    Text("Sécurité Apple iCloud")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)
                }
                Text("Apple exige un 'Mot de passe pour application tierce' pour se connecter en direct à vos e-mails.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Link(destination: URL(string: "https://appleid.apple.com/account/manage")!) {
                    HStack(spacing: 4) {
                        Text("Générer sur Apple ID")
                            .font(.system(size: 11, weight: .bold))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.cyan)
                    .padding(.top, 2)
                }
            }
            .padding(12)
            .liquidGlass(cornerRadius: 14, borderOpacity: 0.3, glowColor: .cyan)
        } else if selectedProvider == .yahoo {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.purple)
                    Text("Sécurité Yahoo")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.purple)
                }
                Text("Yahoo requiert un 'Mot de passe d'application' tiers à générer dans la section Sécurité de votre compte.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Link(destination: URL(string: "https://login.yahoo.com/account/security")!) {
                    HStack(spacing: 4) {
                        Text("Gérer mes mots de passe d'application Yahoo")
                            .font(.system(size: 11, weight: .bold))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.cyan)
                    .padding(.top, 2)
                }
            }
            .padding(12)
            .liquidGlass(cornerRadius: 14, borderOpacity: 0.3, glowColor: .purple)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.circle.fill")
                        .foregroundColor(.green)
                    Text("Connexion directe chiffrée TLS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                }
                Text("Pour Orange, Free, SFR, OVH, Infomaniak et vos serveurs personnalisés, vos identifiants habituels fonctionnent directement.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .liquidGlass(cornerRadius: 14, borderOpacity: 0.20)
        }
    }
    
    // MARK: - Auto-Detection & Preset Helpers
    private func handleEmailChange(_ text: String) {
        if text.contains("@") && text.contains(".") {
            let config = MailAutoDiscovery.shared.discover(email: text)
            self.imapHost = config.imapHost
            self.imapPort = "\(config.imapPort)"
            self.imapUseSSL = config.imapUseSSL
            self.smtpHost = config.smtpHost
            self.smtpPort = "\(config.smtpPort)"
            self.smtpUseSSL = config.smtpUseSSL
            
            let lower = text.lowercased()
            withAnimation(.spring()) {
                if lower.contains("icloud.com") || lower.contains("me.com") || lower.contains("mac.com") {
                    self.selectedProvider = .icloud
                } else if lower.contains("gmail.com") || lower.contains("googlemail.com") {
                    self.selectedProvider = .gmail
                } else if lower.contains("yahoo.") || lower.contains("myyahoo.") {
                    self.selectedProvider = .yahoo
                } else if lower.contains("ik.me") || lower.contains("infomaniak") {
                    self.selectedProvider = .ikmail
                } else if lower.contains("outlook.") || lower.contains("hotmail.") || lower.contains("live.") {
                    self.selectedProvider = .outlook
                } else {
                    self.selectedProvider = .customImap
                }
            }
        }
    }
    
    private func applyProviderDefaults(_ provider: EmailProvider) {
        self.imapHost = provider.imapHost
        self.imapPort = "\(provider.imapPort)"
        self.imapUseSSL = true
        self.smtpHost = provider.smtpHost
        self.smtpPort = "\(provider.smtpPort)"
        self.smtpUseSSL = true
    }
    
    private func buildServerConfig() -> ServerConfig {
        let cleanImap = imapHost.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedImap = cleanImap.isEmpty ? selectedProvider.imapHost : cleanImap
        let cleanSmtp = smtpHost.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedSmtp = cleanSmtp.isEmpty ? selectedProvider.smtpHost : cleanSmtp
        let portInt = Int(imapPort) ?? 993
        let smtpPortInt = Int(smtpPort) ?? 587
        
        return ServerConfig(
            imapHost: resolvedImap,
            imapPort: portInt,
            imapUseSSL: imapUseSSL,
            smtpHost: resolvedSmtp,
            smtpPort: smtpPortInt,
            smtpUseSSL: smtpUseSSL,
            username: customUsername.isEmpty ? nil : customUsername
        )
    }
    
    // MARK: - Real Connection Process
    private func performRealConnection() async {
        Haptics.medium()
        let finalConfig = buildServerConfig()
        let cleanEmail = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPass = appPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        
        await MainActor.run {
            isConnecting = true
            connectionStepText = "Connexion sécurisée à \(finalConfig.imapHost)..."
        }
        
        do {
            let fetchedEmails = try await RealIMAPService.shared.authenticateAndFetch(
                email: cleanEmail,
                password: cleanPass,
                serverConfig: finalConfig
            )
            
            await MainActor.run {
                KeychainManager.shared.save(key: "account_pwd_\(cleanEmail)", data: cleanPass)
                
                let name = cleanEmail.components(separatedBy: "@").first?.capitalized ?? "Mon Compte"
                var newAcc = EmailAccount(
                    name: name,
                    emailAddress: cleanEmail,
                    provider: selectedProvider,
                    isActive: true,
                    serverConfig: finalConfig
                )
                newAcc.unreadCount = fetchedEmails.filter { !$0.isRead }.count
                mailStore.accounts.append(newAcc)
                mailStore.selectedAccount = newAcc
                
                if !fetchedEmails.isEmpty {
                    for email in fetchedEmails {
                        var modified = email
                        modified.accountId = newAcc.id
                        mailStore.emails.append(modified)
                    }
                } else {
                    let welcome = EmailMessage(
                        accountId: newAcc.id,
                        provider: selectedProvider,
                        senderName: "Assistant LiquidMail",
                        senderEmail: "assistant@liquidmail.app",
                        recipientEmail: cleanEmail,
                        subject: "Boîte \(cleanEmail) connectée ✨",
                        preview: "Connexion IMAP TLS réussie sur \(finalConfig.imapHost).",
                        bodyContent: "Votre compte \(cleanEmail) est désormais connecté en direct via IMAP TLS sur \(finalConfig.imapHost):\(finalConfig.imapPort).\n\nVous pouvez dès à présent synchroniser vos messages, profiter du triage intelligent par IA et composer de nouveaux e-mails.",
                        timestamp: Date(),
                        isRead: false,
                        isStarred: true,
                        category: .vip,
                        aiSummary: AISummary(tldr: "Boîte connectée avec succès.", sentiment: .positive)
                    )
                    mailStore.emails.append(welcome)
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
        let finalConfig = buildServerConfig()
        let cleanEmail = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPass = appPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        KeychainManager.shared.save(key: "account_pwd_\(cleanEmail)", data: cleanPass)
        
        let name = cleanEmail.components(separatedBy: "@").first?.capitalized ?? "Mon Compte"
        let newAcc = EmailAccount(
            name: name,
            emailAddress: cleanEmail,
            provider: selectedProvider,
            isActive: true,
            serverConfig: finalConfig
        )
        mailStore.accounts.append(newAcc)
        mailStore.selectedAccount = newAcc
        
        let welcome = EmailMessage(
            accountId: newAcc.id,
            provider: selectedProvider,
            senderName: "Assistant LiquidMail",
            senderEmail: "assistant@liquidmail.app",
            recipientEmail: cleanEmail,
            subject: "Compte \(cleanEmail) configuré",
            preview: "Compte enregistré avec serveur \(finalConfig.imapHost).",
            bodyContent: "Votre boîte a été enregistrée sur cet appareil.\n\nServeur configuré : \(finalConfig.imapHost):\(finalConfig.imapPort).\n\nPour synchroniser vos messages, tirez la boîte de réception vers le bas dès que votre connexion réseau est active.",
            timestamp: Date(),
            isRead: false,
            isStarred: false,
            category: .actionRequired,
            aiSummary: AISummary(tldr: "Compte enregistré localement.", sentiment: .neutral)
        )
        mailStore.emails.append(welcome)
        mailStore.persistAccounts()
        mailStore.persistEmails()
        dismiss()
    }
}
