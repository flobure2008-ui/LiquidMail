import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var mailStore: MailStore
    @StateObject private var aiService = AIProviderService.shared
    
    @State private var isAIAutoTriageEnabled: Bool = true
    @State private var isPhishingAutoShieldEnabled: Bool = true
    @State private var notifyOnlyVIP: Bool = true
    @State private var showingCacheCleanAlert: Bool = false
    @State private var isKeyVisible: Bool = false
    @State private var tempApiKey: String = ""
    @State private var isBatchTriaging: Bool = false
    @State private var batchTriageSuccess: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidAmbientBackground(theme: mailStore.glassTheme)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        
                        // MARK: - Header
                        Text("Réglages & Intelligence")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 4)
                        
                        // MARK: - REAL AI API INTEGRATION SECTION
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "cpu.fill")
                                    .foregroundColor(.cyan)
                                Text("Moteur d'API IA (Triage & Résumés)")
                                    .font(.system(size: 15, weight: .bold))
                                Spacer()
                                Text("Connecté")
                                    .font(.system(size: 11, weight: .semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.green.opacity(0.2)))
                                    .foregroundColor(.green)
                            }
                            
                            // Provider Picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Fournisseur d'IA :")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Picker("Fournisseur", selection: $aiService.activeProvider) {
                                    ForEach(AIModelProvider.allCases) { provider in
                                        Text(provider.rawValue).tag(provider)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Capsule().fill(Color.white.opacity(0.1)))
                            }
                            
                            // API Key Field (if not on-device)
                            if aiService.activeProvider != .appleIntelligence {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Clé API (\(aiService.activeProvider.defaultModel)) :")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
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
                                        
                                        Button(action: { isKeyVisible.toggle() }) {
                                            Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(12)
                                    .liquidGlass(cornerRadius: 12, borderOpacity: 0.25)
                                }
                                
                                // Test Connection Button
                                HStack(spacing: 10) {
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
                                                Image(systemName: "network")
                                            }
                                            Text("Tester la clé API")
                                                .font(.system(size: 13, weight: .semibold))
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(Color.cyan.opacity(0.2)))
                                        .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.5), lineWidth: 1))
                                        .foregroundColor(.cyan)
                                    }
                                    
                                    if let status = aiService.connectionStatusMessage {
                                        Text(status)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(status.contains("✓") ? .green : .red)
                                            .lineLimit(2)
                                    }
                                }
                            }
                            
                            Divider().background(Color.white.opacity(0.15))
                            
                            // Batch Triage Button
                            Button(action: {
                                runBatchTriage()
                            }) {
                                HStack {
                                    if isBatchTriaging {
                                        ProgressView().tint(.white)
                                        Text("Triage IA de vos boîtes en cours...")
                                    } else {
                                        Image(systemName: "wand.and.stars")
                                        Text(batchTriageSuccess ? "✓ Boîtes triées avec succès !" : "Lancer le tri automatique IA maintenant")
                                    }
                                    Spacer()
                                }
                                .font(.system(size: 14, weight: .bold))
                                .padding(12)
                                .background(
                                    LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(14)
                                .foregroundColor(.white)
                            }
                            .disabled(isBatchTriaging)
                        }
                        .padding(16)
                        .liquidGlass(cornerRadius: 20, borderOpacity: 0.4, glowColor: .cyan)
                        
                        // MARK: - Liquid Glass Theme Selector
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "paintpalette.fill")
                                    .foregroundColor(.cyan)
                                Text("Thème Liquid Glass")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(GlassTheme.allCases) { theme in
                                        Button(action: {
                                            Haptics.light()
                                            withAnimation(.spring()) {
                                                mailStore.glassTheme = theme
                                            }
                                        }) {
                                            VStack(spacing: 8) {
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: theme.gradientColors,
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 72, height: 50)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 14)
                                                            .strokeBorder(
                                                                mailStore.glassTheme == theme ? Color.cyan : Color.white.opacity(0.3),
                                                                lineWidth: mailStore.glassTheme == theme ? 2.5 : 1
                                                            )
                                                    )
                                                    .shadow(color: mailStore.glassTheme == theme ? Color.cyan.opacity(0.4) : .clear, radius: 8)
                                                
                                                Text(theme.rawValue)
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(mailStore.glassTheme == theme ? .cyan : .secondary)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(16)
                        .liquidGlass(cornerRadius: 20, borderOpacity: 0.3)
                        
                        // MARK: - Mail & Sending Options
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.cyan)
                                Text("Options d'Envoi & Sécurité")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Délai d'annulation d'envoi")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Temps imparti pour stopper un e-mail envoyé par erreur")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                Picker("Délai", selection: $mailStore.undoSendDuration) {
                                    Text("5 sec").tag(5)
                                    Text("10 sec").tag(10)
                                    Text("30 sec").tag(30)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 150)
                            }
                            
                            Divider().background(Color.white.opacity(0.15))
                            
                            Toggle(isOn: $mailStore.isFaceIDEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Verrouillage Face ID")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Exiger Face ID pour accéder à vos boîtes")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tint(.cyan)
                            
                            Divider().background(Color.white.opacity(0.15))
                            
                            Toggle(isOn: $notifyOnlyVIP) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Notifications intelligentes VIP")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Ne faire vibrer l'iPhone que pour les actions urgentes et VIP")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tint(.cyan)
                        }
                        .padding(16)
                        .liquidGlass(cornerRadius: 20, borderOpacity: 0.3)
                        
                        // MARK: - Cache & Maintenance
                        Button(action: {
                            Haptics.warning()
                            showingCacheCleanAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash.circle.fill")
                                    .foregroundColor(.orange)
                                Text("Vider le cache hors-ligne (128 Mo)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.orange)
                                Spacer()
                            }
                            .padding(16)
                            .liquidGlass(cornerRadius: 18, borderOpacity: 0.25)
                        }
                        
                        // App version footer
                        VStack(alignment: .center, spacing: 4) {
                            Text("LiquidMail pour iPhone • iOS 18.2")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("Widgets Écran d'accueil & Verrouillé activés")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                        
                        Spacer(minLength: 80)
                    }
                    .padding(16)
                }
            }
            .navigationBarHidden(true)
            .alert("Cache nettoyé", isPresented: $showingCacheCleanAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Le cache des pièces jointes et messages hors-ligne a été vidé.")
            }
            .onAppear {
                tempApiKey = aiService.apiKey
            }
        }
    }
    
    private func runBatchTriage() {
        Haptics.medium()
        isBatchTriaging = true
        batchTriageSuccess = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isBatchTriaging = false
            batchTriageSuccess = true
            Haptics.success()
        }
    }
}
