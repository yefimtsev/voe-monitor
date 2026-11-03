import SwiftUI
import WidgetKit

struct VOEWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: VOETimelineEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                VOEWidgetSmallView(entry: entry)
            case .systemMedium:
                VOEWidgetMediumView(entry: entry)
            case .systemLarge:
                VOEWidgetLargeView(entry: entry)
            default:
                VOEWidgetAccessoryView(entry: entry)
            }
        }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }
}

struct VOEWidget: Widget {
    let kind = "VOEWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectQueueIntent.self,
            provider: VOETimelineProvider()
        ) { entry in
            VOEWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("widget.name")
        .description("widget.description")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline,
        ])
    }
}
