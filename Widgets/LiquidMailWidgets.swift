import WidgetKit
import SwiftUI

// MARK: - Widget Timeline Entry
public struct MailWidgetEntry: TimelineEntry {
    public let date: Date
    public let unreadTotal: Int
    public let urgentActionCount: Int
    public let nextUrgentActionTitle: String
    public let nextUrgentSender: String
    public let icloudCount: Int
    public let gmailCount: Int
    public let yahooCount: Int
    public let ikmailCount: Int
    public let latestSummary: String
}

// MARK: - Widget Provider
public struct MailWidgetTimelineProvider: TimelineProvider {
    public func placeholder(in context: Context) -> MailWidgetEntry {
        MailWidgetEntry(
            date: Date(),
            unreadTotal: 4,
            urgentActionCount: 1,
            nextUrgentActionTitle: "Valider l'architecture iOS 18",
            nextUrgentSender: "Sophie Martin",
            icloudCount: 1,
            gmailCount: 2,
            yahooCount: 0,
            ikmailCount: 1,
            latestSummary: "Sophie attend ta validation urgente avant 15h."
        )
    }

    public func getSnapshot(in context: Context, completion: @escaping (MailWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<MailWidgetEntry>) -> Void) {
        // Read shared App Group data if available, or load current snapshot
        let sharedDefaults = UserDefaults(suiteName: "group.com.liquidmail.app")
        let unread = sharedDefaults?.integer(forKey: "unreadTotal") ?? 4
        let urgent = sharedDefaults?.integer(forKey: "urgentCount") ?? 1
        let urgentTitle = sharedDefaults?.string(forKey: "nextUrgentTitle") ?? "Valider l'architecture iOS 18"
        let urgentSender = sharedDefaults?.string(forKey: "nextUrgentSender") ?? "Sophie Martin"
        
        let entry = MailWidgetEntry(
            date: Date(),
            unreadTotal: unread == 0 ? 4 : unread,
            urgentActionCount: urgent == 0 ? 1 : urgent,
            nextUrgentActionTitle: urgentTitle,
            nextUrgentSender: urgentSender,
            icloudCount: 1,
            gmailCount: 2,
            yahooCount: 0,
            ikmailCount: 1,
            latestSummary: "Sophie attend ta validation urgente avant 15h."
        )

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Entry View
public struct LiquidMailWidgetEntryView: View {
    var entry: MailWidgetEntry
    @Environment(\.widgetFamily) var family

    public var body: some View {
        switch family {
        // Home Screen Small
        case .systemSmall:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle().fill(Color.cyan.opacity(0.25)).frame(width: 28, height: 28)
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    Spacer()
                    Text("\(entry.unreadTotal) non-lus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Circle().fill(Color.red).frame(width: 6, height: 6)
                        Text("\(entry.urgentActionCount) Action requise")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.red)
                    }
                    Text(entry.nextUrgentActionTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    Text("De : \(entry.nextUrgentSender)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
            .containerBackground(for: .widget) {
                LinearGradient(colors: [Color(red: 0.08, green: 0.10, blue: 0.22), Color(red: 0.04, green: 0.05, blue: 0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }

        // Home Screen Medium
        case .systemMedium:
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.cyan)
                        Text("LiquidMail")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("\(entry.unreadTotal) courriels à traiter")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                // Provider Pill Row
                HStack(spacing: 12) {
                    providerBadge(name: "iCloud", count: entry.icloudCount, color: Color.blue)
                    providerBadge(name: "Gmail", count: entry.gmailCount, color: Color.red)
                    providerBadge(name: "Yahoo", count: entry.yahooCount, color: Color.purple)
                    providerBadge(name: "ikmail", count: entry.ikmailCount, color: Color.green)
                }
                
                Divider().background(Color.white.opacity(0.15))
                
                // AI Highlight
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.cyan)
                        .font(.system(size: 12))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Action requise : \(entry.nextUrgentActionTitle)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(entry.latestSummary)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(14)
            .containerBackground(for: .widget) {
                LinearGradient(colors: [Color(red: 0.06, green: 0.08, blue: 0.20), Color(red: 0.02, green: 0.03, blue: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }

        // Lock Screen Circular
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 15))
                    Text("\(entry.unreadTotal)")
                        .font(.system(size: 14, weight: .bold))
                }
            }

        // Lock Screen Rectangular
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("LiquidMail • \(entry.urgentActionCount) Urgent")
                        .font(.system(size: 11, weight: .bold))
                }
                Text(entry.nextUrgentActionTitle)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text("De : \(entry.nextUrgentSender)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

        // Lock Screen Inline
        case .accessoryInline:
            HStack(spacing: 4) {
                Image(systemName: "envelope.fill")
                Text("\(entry.unreadTotal) non-lus • 1 action requise")
            }

        default:
            Text("\(entry.unreadTotal) e-mails")
        }
    }
    
    private func providerBadge(name: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Capsule().fill(Color.white.opacity(0.08)))
    }
}

// MARK: - Widget Definition
@main
public struct LiquidMailWidgetBundle: WidgetBundle {
    public init() {}
    
    public var body: some Widget {
        LiquidMailHomeWidget()
        LiquidMailLockScreenWidget()
    }
}

public struct LiquidMailHomeWidget: Widget {
    let kind: String = "LiquidMailHomeWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MailWidgetTimelineProvider()) { entry in
            LiquidMailWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("LiquidMail — Boîtes & Triage IA")
        .description("Surveillez vos boîtes de réception et actions requises en un coup d'œil.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

public struct LiquidMailLockScreenWidget: Widget {
    let kind: String = "LiquidMailLockScreenWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MailWidgetTimelineProvider()) { entry in
            LiquidMailWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("LiquidMail — Écran Verrouillé")
        .description("Consultez vos e-mails prioritaires directement sur votre écran verrouillé.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
