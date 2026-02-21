import SwiftUI
import WidgetKit

struct VOEWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: VOETimelineEntry

    var body: some View {
        if entry.isPlaceholder {
            placeholderView
                .redacted(reason: .placeholder)
        } else {
            switch family {
            case .systemSmall:
                VOEWidgetSmallView(entry: entry)
            case .systemMedium:
                VOEWidgetMediumView(entry: entry)
            default:
                VOEWidgetLargeView(entry: entry)
            }
        }
    }

    @ViewBuilder
    private var placeholderView: some View {
        switch family {
        case .systemSmall:
            VOEWidgetSmallView(entry: entry)
        case .systemMedium:
            VOEWidgetMediumView(entry: entry)
        default:
            VOEWidgetLargeView(entry: entry)
        }
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
