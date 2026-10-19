import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var mailStore: MailStore
    @StateObject private var aiService = AIProviderService.shared
    
    @State private var showingAddAccountModal: Bool = false
    @State private var isAIAutoTriageEnabled: Bool = true
    @State private var isSummaryEnabled: Bool = true
    @State private var isPhishingAutoShieldEnabled: Bool = true
    @State private var hapticEnabled: Bool = true
    @State private var tempApiKey: String = ""
    @State private var isKeyVisible: Bool = false
    @State private var showingCacheCleanAlert: Bool = false
    @State private var previewLineCount: Int = 2
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidAmbientBackground(theme: mailStore.glassTheme)
                
                List {
                    // MARK: - Section 1: Connected Accounts
                    Section {
                        if mailStore.accounts.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Aucune boîte e-mail connectée")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text("Connectez votre première adresse pour recevoir et trier vos courriels.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(mailStore.accounts) { acc in
                                HStack(spacing: 12) {
                                    ProviderBrandBadge(provider: acc.provider, size: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(acc.name)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.primary)
                                        Text(acc.emailAddress)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Circle().fill(Color.green).frame(width: 8, height: 8)
                                }
                                .padding(.vertical, 2)
                                .listRowBackground(Color.clear)
                            }
                            .onDelete { indexSet in
                                mailStore.removeAccount(at: indexSet)
                            }
                        }
                        
                        Button(action: {
                            Haptics.medium()
                            showingAddAccountModal = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.cyan)
                                Text("Ajouter un compte e-mail...")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.cyan)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.clear)
                    } header: {
                        Text("Comptes de messagerie")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    
                    // MARK: - Section 2: Artificial Intelligence & Triage Engine
                    Section {
                        // AI Provider Selection
                        Picker("Moteur d'IA", selection: $aiService.activeProvider) {
                            ForEach(AIModelProvider.allCases) { provider in
                                Text(provider.rawValue).tag(provider)
                            }
                        }
                        .listRowBackground(Color.clear)
                        
                        // API Key Configuration (if external API)
                        if aiService.activeProvider != .appleIntelligence {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Clé API")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button(action: { isKeyVisible.toggle() }) {
                                        Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                HStack {
                                    if isKeyVisible {
                                        TextField("sk-...", text: $tempApiKey)
                                            .font(.system(size: 13, design: .monospaced))
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                    } else {
                                        SecureField("sk-...", text: $tempApiKey)
                                            .font(.system(size: 13, design: .monospaced))
                                    }
                                }
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                                
                                // Test API Key Button
                                HStack {
                                    Button(action: {
                                        Haptics.medium()
                                        aiService.saveSettings(provider: aiService.activeProvider, key: tempApiKey)
                                        Task {
                                            _ = await aiService.testConnection()
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            if aiService.isTestingConnection {
                                                ProgressView().tint(.cyan)
                                            } else {
                                                Image(systemName: "checkmark.circle")
                                            }
                                            Text("Tester la clé")
                                                .font(.system(size: 12, weight: .bold))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Capsule().fill(Color.cyan.opacity(0.2)))
                                        .foregroundColor(.cyan)
                                    }
                                    
                                    if let msg = aiService.connectionStatusMessage {
                                        Text(msg)
                                            .font(.system(size: 11))
                                            .foregroundColor(msg.contains("✓") ? .green : .red)
                                    }
                                }
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.clear)
                        }
                        
                        Toggle("Triage automatique à la réception", isOn: $isAIAutoTriageEnabled)
                            .tint(.cyan)
                            .listRowBackground(Color.clear)
                        
                        Toggle("Générer les résumés exécutifs TL;DR", isOn: $isSummaryEnabled)
                            .tint(.cyan)
                            .listRowBackground(Color.clear)
                        
                        Toggle("Bouclier Anti-Phishing & Arnaques", isOn: $isPhishingAutoShieldEnabled)
                            .tint(.cyan)
                            .listRowBackground(Color.clear)
                    } header: {
                        Text("Intelligence Artificielle & Triage")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    
                    // MARK: - Section 3: Liquid Glass & Display
                    Section {
                        Picker("Thème Liquid Glass", selection: $mailStore.glassTheme) {
                            ForEach(GlassTheme.allCases) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .listRowBackground(Color.clear)
                        
                        Picker("Lignes d'aperçu des messages", selection: $previewLineCount) {
                            Text("1 ligne").tag(1)
                            Text("2 lignes").tag(2)
                            Text("3 lignes").tag(3)
                        }
                        .listRowBackground(Color.clear)
                        
                        Toggle("Retours haptiques Apple", isOn: $hapticEnabled)
                            .tint(.cyan)
                            .listRowBackground(Color.clear)
                    } header: {
                        Text("Apparence & Affichage")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    
                    // MARK: - Section 4: Security & Sending
                    Section {
                        Toggle("Verrouillage Face ID", isOn: $mailStore.isFaceIDEnabled)
                            .tint(.cyan)
                            .listRowBackground(Color.clear)
                        
                        Picker("Délai d'annulation d'envoi", selection: $mailStore.undoSendDuration) {
                            Text("5 secondes").tag(5)
                            Text("10 secondes").tag(10)
                            Text("30 secondes").tag(30)
                        }
                        .listRowBackground(Color.clear)
                        
                        Button(action: {
                            Haptics.warning()
                            showingCacheCleanAlert = true
                        }) {
                            Text("Vider le cache hors-ligne")
                                .foregroundColor(.red)
                        }
                        .listRowBackground(Color.clear)
                    } header: {
                        Text("Sécurité & Envoi")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                    } footer: {
                        VStack(spacing: 4) {
                            Text("LiquidMail pour iPhone • Version 1.0.1")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("Chiffrement Apple Keychain & Modèles IA Privés")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 14)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddAccountModal) {
                AddAccountView()
                    .environmentObject(mailStore)
            }
            .alert("Cache vidé", isPresented: $showingCacheCleanAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Les données en cache ont été supprimées.")
            }
            .onAppear {
                tempApiKey = aiService.apiKey
            }
        }
    }
}
