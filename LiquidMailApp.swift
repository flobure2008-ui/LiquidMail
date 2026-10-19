import SwiftUI

@main
public struct LiquidMailApp: App {
    @StateObject private var mailStore = MailStore()
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(mailStore)
                .preferredColorScheme(.dark) // Liquid Glass shines brilliantly in deep dark / obsidian
        }
    }
}
