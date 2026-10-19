import SwiftUI

public enum MainTab: Int, CaseIterable, Identifiable {
    case inbox = 0
    case aiAssistant = 1
    case settings = 2
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .inbox: return "Boîte"
        case .aiAssistant: return "Copilote IA"
        case .settings: return "Réglages"
        }
    }
    
    public var iconName: String {
        switch self {
        case .inbox: return "tray.fill"
        case .aiAssistant: return "sparkles"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct MainTabView: View {
    @EnvironmentObject var mailStore: MailStore
    @State private var selectedTab: MainTab = .inbox
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            InboxView()
                .tabItem {
                    Label("Boîte", systemImage: "tray.fill")
                }
                .tag(MainTab.inbox)
                .badge(mailStore.emails.filter { !$0.isRead }.count)
            
            AIAssistantView()
                .tabItem {
                    Label("Copilote IA", systemImage: "sparkles")
                }
                .tag(MainTab.aiAssistant)
            
            SettingsView()
                .tabItem {
                    Label("Réglages", systemImage: "gearshape.fill")
                }
                .tag(MainTab.settings)
        }
        .tint(.cyan)
    }
}
