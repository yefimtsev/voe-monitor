import SwiftUI
import WidgetKit

// MARK: - Shared Helpers

private func colorForStatus(_ status: PowerStatus) -> Color {
    switch status {
    case .on: .green.opacity(0.7)
    case .off: .red.opacity(0.7)
    case .partial: .orange.opacity(0.7)
    case .unknown: .gray.opacity(0.2)
    }
}

private func isCurrentSlot(_ slotId: Int) -> Bool {
    var calendar = Calendar.current
    calendar.timeZone = ScheduleFetcher.kyivTimeZone
    let hour = calendar.component(.hour, from: Date())
    return slotId == hour + 1
}

private func slotAccessibilityText(for slot: HourSlot, use24h: Bool) -> String {
    let range = slot.hourRange(use24h: use24h)
    let statusName: String
    switch slot.status {
    case .on: statusName = String(localized: "status.on")
    case .off: statusName = String(localized: "status.off")
    case .partial: statusName = String(localized: "status.partial")
    case .unknown: statusName = String(localized: "status.unknown")
    }
    return "\(range), \(statusName)"
}

// MARK: - Shared Grid View

struct WidgetGrid: View {
    let slots: [HourSlot]
    let isToday: Bool
    let use24h: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 12)

    var body: some View {
        let amSlots = Array(slots.prefix(12))
        let pmSlots = Array(slots.suffix(12))

        VStack(spacing: 6) {
            gridRow(slots: amSlots, periodLabel: use24h ? nil : "AM")
            gridRow(slots: pmSlots, periodLabel: use24h ? nil : "PM")
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
                    let isCurrent = isToday && isCurrentSlot(slot.id)

                    VStack(spacing: 2) {
                        Text(slot.shortHour(use24h: use24h))
                            .font(.system(size: 8, weight: isCurrent ? .bold : .medium, design: .monospaced))
                            .foregroundStyle(isCurrent ? .primary : .secondary)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorForStatus(slot.status))
                            .frame(height: 18)
                            .overlay {
                                if isCurrent {
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(.white, lineWidth: 1.5)
                                }
                            }
                    }
                    .accessibilityLabel(slotAccessibilityText(for: slot, use24h: use24h))
                }
            }
        }
    }
}

// MARK: - Status Helpers (shared across view structs)

private func statusText(for status: PowerStatus) -> String {
    switch status {
    case .on: String(localized: "status.on")
    case .off: String(localized: "status.off")
    case .partial: String(localized: "status.partial")
    case .unknown: String(localized: "status.unknown")
    }
}

private func iconName(for status: PowerStatus) -> String {
    switch status {
    case .on: "bolt.fill"
    case .off: "bolt.slash.fill"
    case .partial: "bolt.badge.clock.fill"
    case .unknown: "questionmark.circle"
    }
}

private func statusColor(for status: PowerStatus) -> Color {
    switch status {
    case .on: .green
    case .off: .red
    case .partial: .orange
    case .unknown: .gray
    }
}

// MARK: - Small Widget

struct VOEWidgetSmallView: View {
    let entry: VOETimelineEntry

    var body: some View {
        if let error = entry.errorMessage {
            VStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
        } else {
            VStack(spacing: 8) {
                Image(systemName: iconName(for: entry.status))
                    .font(.system(size: 28))
                    .foregroundStyle(statusColor(for: entry.status))

                Text(statusText(for: entry.status))
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

// MARK: - Medium Widget

struct VOEWidgetMediumView: View {
    let entry: VOETimelineEntry

    var body: some View {
        if let error = entry.errorMessage {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        } else {
            VStack(spacing: 8) {
                // Compact status header
                HStack {
                    Image(systemName: iconName(for: entry.status))
                        .foregroundStyle(statusColor(for: entry.status))
                    Text(statusText(for: entry.status))
                        .font(.subheadline.bold())
                    Spacer()
                    Text(entry.queueName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Full-width today grid
                if let today = entry.todaySchedule {
                    WidgetGrid(slots: today.slots, isToday: true, use24h: entry.use24h)
                }
            }
            .padding()
        }
    }
}

// MARK: - Large Widget

struct VOEWidgetLargeView: View {
    let entry: VOETimelineEntry

    var body: some View {
        if let error = entry.errorMessage {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title)
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Image(systemName: iconName(for: entry.status))
                        .foregroundStyle(statusColor(for: entry.status))
                    Text(statusText(for: entry.status))
                        .font(.headline)
                    Spacer()
                    Text(entry.queueName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let today = entry.todaySchedule {
                    Text(String(localized: "schedule.today"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    WidgetGrid(slots: today.slots, isToday: true, use24h: entry.use24h)
                }

                if let tomorrow = entry.tomorrowSchedule {
                    Text(String(localized: "schedule.tomorrow"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    WidgetGrid(slots: tomorrow.slots, isToday: false, use24h: entry.use24h)
                }
            }
            .padding()
        }
    }
}
