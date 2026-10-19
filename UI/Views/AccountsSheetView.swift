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
                        
                        // MARK: - Unified Inbox Option
                        Button(action: {
                            Haptics.light()
                            mailStore.selectedAccount = nil
                            dismiss()
                        }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "tray.2.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Toutes les boîtes de réception")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("Vue unifiée (\(mailStore.emails.count) e-mails)")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if mailStore.selectedAccount == nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.cyan)
                                        .font(.system(size: 20))
                                }
                            }
                            .padding(14)
                            .liquidGlass(cornerRadius: 18, borderOpacity: mailStore.selectedAccount == nil ? 0.6 : 0.2, glowColor: .cyan)
                        }
                        .buttonStyle(.plain)
                        
                        Text("Boîtes de messagerie connectées")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal, 4)
                        
                        // MARK: - Connected Accounts List
                        ForEach(mailStore.accounts) { acc in
                            Button(action: {
                                Haptics.light()
                                mailStore.selectedAccount = acc
                                dismiss()
                            }) {
                                HStack(spacing: 14) {
                                    ProviderBrandBadge(provider: acc.provider, size: 40)
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(acc.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Text(acc.emailAddress)
                                            .font(.system(size: 13))
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
                                            .font(.system(size: 20))
                                    }
                                }
                                .padding(14)
                                .liquidGlass(
                                    cornerRadius: 18,
                                    borderOpacity: mailStore.selectedAccount?.id == acc.id ? 0.5 : 0.2,
                                    glowColor: .cyan
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // MARK: - Add New Universal Account Button
                        Button(action: {
                            Haptics.medium()
                            showingAddAccountModal = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.cyan)
                                Text("Connecter n'importe quelle adresse e-mail...")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.cyan)
                                Spacer()
                            }
                            .padding(16)
                            .liquidGlass(cornerRadius: 18, borderOpacity: 0.35, glowColor: .cyan)
                        }
                        .padding(.top, 6)
                        
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Comptes de messagerie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
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

// MARK: - Add Account Sub-View with Auto-Discovery
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
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidAmbientBackground(theme: mailStore.glassTheme)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Email input with Auto-Discovery
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Entrez n'importe quelle adresse e-mail")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("LiquidMail détecte automatiquement les serveurs IMAP et SMTP de votre fournisseur (Orange, Free, SFR, OVH, Gmail, iCloud, Yahoo, ikmail...).")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineSpacing(3)
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.cyan)
                                TextField("vous@n-importe-quel-domaine.fr", text: $emailAddress)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .onChange(of: emailAddress) { _, newVal in
                                        autoDetect(newVal)
                                    }
                            }
                            .padding(14)
                            .liquidGlass(cornerRadius: 14, borderOpacity: 0.35, glowColor: .cyan)
                        }
                        
                        // Password input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mot de passe ou mot de passe d'application")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            SecureField("Mot de passe sécurisé", text: $appPassword)
                                .padding(14)
                                .liquidGlass(cornerRadius: 14, borderOpacity: 0.2)
                        }
                        
                        // Auto-Discovered Server Specs
                        if autoDiscoveryDetected {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                    Text("Configuration détectée automatiquement")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.green)
                                }
                                
                                HStack {
                                    Text("Serveur IMAP entrant :")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(discoveredConfig.imapHost):\(discoveredConfig.imapPort)")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.cyan)
                                }
                                
                                HStack {
                                    Text("Serveur SMTP sortant :")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(discoveredConfig.smtpHost):\(discoveredConfig.smtpPort)")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.cyan)
                                }
                            }
                            .padding(14)
                            .liquidGlass(cornerRadius: 16, borderOpacity: 0.4, glowColor: .green)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                        
                        // Keychain notice
                        HStack(spacing: 10) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.cyan)
                            Text("Stockage sécurisé dans le Trousseau d'accès Apple (Keychain)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            connectAccount()
                        }) {
                            HStack {
                                if isConnecting {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Connecter le compte")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(18)
                            .foregroundColor(.white)
                        }
                        .disabled(emailAddress.isEmpty || appPassword.isEmpty || isConnecting)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Connexion Universelle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
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
    
    private func connectAccount() {
        Haptics.medium()
        isConnecting = true
        
        // Save password into Keychain
        KeychainManager.shared.save(key: "account_pwd_\(emailAddress)", data: appPassword)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let name = emailAddress.components(separatedBy: "@").first?.capitalized ?? "Mon Compte"
            mailStore.addAccount(
                name: name,
                email: emailAddress,
                provider: selectedProvider
            )
            isConnecting = false
            dismiss()
        }
    }
}
