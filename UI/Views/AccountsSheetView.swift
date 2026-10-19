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
                                    .padding(14)
                                    .liquidGlass(
                                        cornerRadius: 16,
                                        borderOpacity: mailStore.selectedAccount?.id == acc.id ? 0.45 : 0.15,
                                        glowColor: .cyan
                                    )
                                }
                                .buttonStyle(.plain)
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

// MARK: - Add Account Sub-View with Real IMAP Connection
public struct AddAccountView: View {
    @EnvironmentObject var mailStore: MailStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProvider: EmailProvider = .customImap
    @State private var accountName: String = ""
    @State private var emailAddress: String = ""
    @State private var appPassword: String = ""
    @State private var discoveredConfig: ServerConfig = ServerConfig(imapHost: "", smtpHost: "")
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
                            
                            Text("LiquidMail se connecte directement et de façon sécurisée à vos serveurs de messagerie (Orange, Free, SFR, OVH, Gmail, iCloud, Yahoo, ikmail...).")
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
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                            }
                        }
                        
                        // Provider App Password hint
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.cyan)
                                Text("Astuce de connexion sécurisée")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.cyan)
                            }
                            Text("Pour Gmail, Yahoo et iCloud, la sécurité exige un 'Mot de passe d'application' (généré en 30 secondes dans les paramètres de sécurité de votre compte Google, Apple ou Yahoo).")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineSpacing(2)
                        }
                        .padding(12)
                        .liquidGlass(cornerRadius: 14, borderOpacity: 0.20)
                        
                        // Auto-discovered host info
                        if autoDiscoveryDetected {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Serveur : \(discoveredConfig.imapHost):\(discoveredConfig.imapPort) (SSL)")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(12)
                            .liquidGlass(cornerRadius: 12, borderOpacity: 0.35, glowColor: .green)
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
    
    private func autoDetect(_ text: String) {
        if text.contains("@") && text.contains(".") {
            let config = MailAutoDiscovery.shared.discover(email: text)
            withAnimation(.spring()) {
                self.discoveredConfig = config
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
        await MainActor.run {
            isConnecting = true
            connectionStepText = "Connexion à \(discoveredConfig.imapHost)..."
        }
        
        do {
            let fetchedEmails = try await RealIMAPService.shared.authenticateAndFetch(
                email: emailAddress,
                password: appPassword,
                serverConfig: discoveredConfig
            )
            
            await MainActor.run {
                // Save password securely in Keychain
                KeychainManager.shared.save(key: "account_pwd_\(emailAddress)", data: appPassword)
                
                let name = emailAddress.components(separatedBy: "@").first?.capitalized ?? "Mon Compte"
                let newAcc = EmailAccount(name: name, emailAddress: emailAddress, provider: selectedProvider, isActive: true)
                mailStore.accounts.append(newAcc)
                
                // Add real messages
                for email in fetchedEmails {
                    var modified = email
                    modified.accountId = newAcc.id
                    mailStore.emails.append(modified)
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
        KeychainManager.shared.save(key: "account_pwd_\(emailAddress)", data: appPassword)
        let name = emailAddress.components(separatedBy: "@").first?.capitalized ?? "Mon Compte"
        mailStore.addAccount(name: name, email: emailAddress, provider: selectedProvider)
        dismiss()
    }
}
