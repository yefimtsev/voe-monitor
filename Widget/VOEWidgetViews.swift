import SwiftUI
import WidgetKit

// MARK: - Shared Grid View

struct WidgetGrid: View {
    let slots: [HourSlot]
    /// Highlighted slot id, or `nil` for a day other than today.
    let currentSlot: Int?
    let use24h: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 12)

    var body: some View {
        VStack(spacing: 6) {
            gridRow(slots: Array(slots.prefix(12)), periodLabel: use24h ? nil : "AM")
            gridRow(slots: Array(slots.suffix(12)), periodLabel: use24h ? nil : "PM")
        }
    }

    private func gridRow(slots: [HourSlot], periodLabel: String?) -> some View {
        VStack(spacing: 1) {
            if let label = periodLabel {
                Text(label)
                    .font(.system(size: 7, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(slots) { slot in
                    let isCurrent = slot.id == currentSlot

                    VStack(spacing: 2) {
                        Text(slot.shortHour(use24h: use24h))
                            .font(.system(size: 8, weight: isCurrent ? .bold : .medium, design: .monospaced))
                            .foregroundStyle(isCurrent ? .primary : .secondary)

                        SlotFill(slot: slot, cornerRadius: 4)
                            .frame(height: 18)
                            .overlay {
                                if isCurrent {
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(.white, lineWidth: 1.5)
                                }
                            }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(slot.accessibilityText(use24h: use24h))
                }
            }
        }
    }
}

// MARK: - Pieces

private struct ErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

private struct StatusHeader: View {
    let entry: VOETimelineEntry

    var body: some View {
        HStack {
            Image(systemName: entry.status.symbolName)
                .foregroundStyle(entry.status.color)
            Text(entry.status.title)
                .font(.subheadline.bold())
            Spacer()
            Text(entry.queueName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Home Screen

struct VOEWidgetSmallView: View {
    let entry: VOETimelineEntry

    var body: some View {
        if let error = entry.errorMessage {
            ErrorView(message: error)
        } else {
            VStack(spacing: 8) {
                Image(systemName: entry.status.symbolName)
                    .font(.system(size: 28))
                    .foregroundStyle(entry.status.color)

                Text(entry.status.title)
                    .font(.headline)

                Text(entry.queueName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .accessibilityElement(children: .combine)
        }
    }
}

struct VOEWidgetMediumView: View {
    let entry: VOETimelineEntry

    var body: some View {
        if let error = entry.errorMessage {
            ErrorView(message: error)
        } else {
            VStack(spacing: 8) {
                StatusHeader(entry: entry)
                if let today = entry.todaySchedule {
                    WidgetGrid(slots: today.slots, currentSlot: KyivTime.slotID(at: entry.date), use24h: entry.use24h)
                }
            }
            .padding()
        }
    }
}

struct VOEWidgetLargeView: View {
    let entry: VOETimelineEntry

    var body: some View {
        if let error = entry.errorMessage {
            ErrorView(message: error)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                StatusHeader(entry: entry)

                if let today = entry.todaySchedule {
                    Text(String(localized: "schedule.today"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    WidgetGrid(slots: today.slots, currentSlot: KyivTime.slotID(at: entry.date), use24h: entry.use24h)
                }

                if let tomorrow = entry.tomorrowSchedule {
                    Text(String(localized: "schedule.tomorrow"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    WidgetGrid(slots: tomorrow.slots, currentSlot: nil, use24h: entry.use24h)
                }
            }
            .padding()
        }
    }
}

// MARK: - Lock Screen

struct VOEWidgetAccessoryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: VOETimelineEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: entry.status.symbolName)
                    .font(.title2)
            }
            .accessibilityLabel(entry.status.title)
        case .accessoryInline:
            Label(entry.nextEventText.isEmpty ? entry.status.title : entry.nextEventText, systemImage: entry.status.symbolName)
        default:
            VStack(alignment: .leading, spacing: 2) {
                Label(entry.status.title, systemImage: entry.status.symbolName)
                    .font(.headline)
                    .widgetAccentable()
                Text(entry.nextEventText.isEmpty ? entry.queueName : entry.nextEventText)
                    .font(.caption)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
