import SwiftUI

public enum MainTab: Int, CaseIterable, Identifiable {
    case inbox = 0
    case aiAssistant = 1
    case accounts = 2
    case settings = 3
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .inbox: return "Boîte"
        case .aiAssistant: return "Copilote IA"
        case .accounts: return "Comptes"
        case .settings: return "Réglages"
        }
    }
    
    public var iconName: String {
        switch self {
        case .inbox: return "tray.fill"
        case .aiAssistant: return "sparkles"
        case .accounts: return "person.crop.circle.badge.plus"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct MainTabView: View {
    @EnvironmentObject var mailStore: MailStore
    @State private var selectedTab: MainTab = .inbox
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Active Tab View
            Group {
                switch selectedTab {
                case .inbox:
                    InboxView()
                case .aiAssistant:
                    AIAssistantView()
                case .accounts:
                    AccountsSheetView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // MARK: - Floating Liquid Glass Dock Bar
            HStack(spacing: 0) {
                ForEach(MainTab.allCases) { tab in
                    Button(action: {
                        Haptics.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: tab.iconName)
                                    .font(.system(size: 20, weight: selectedTab == tab ? .bold : .regular))
                                    .foregroundColor(selectedTab == tab ? .cyan : .secondary)
                                    .scaleEffect(selectedTab == tab ? 1.15 : 1.0)
                                
                                // Badge count for inbox
                                if tab == .inbox {
                                    let unread = mailStore.emails.filter { !$0.isRead }.count
                                    if unread > 0 {
                                        Text("\(unread)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(4)
                                            .background(Circle().fill(Color.red))
                                            .offset(x: 12, y: -6)
                                    }
                                }
                            }
                            
                            Text(tab.title)
                                .font(.system(size: 11, weight: selectedTab == tab ? .bold : .medium, design: .rounded))
                                .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .liquidGlass(cornerRadius: 30, borderOpacity: 0.45, glowColor: .cyan)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
