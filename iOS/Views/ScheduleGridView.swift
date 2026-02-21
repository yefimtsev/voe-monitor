import SwiftUI

/// 24-hour color-coded schedule grid adapted for touch.
struct ScheduleGridView: View {
    let title: String
    let schedule: DaySchedule
    let isToday: Bool
    let use24h: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(schedule.slots) { slot in
                    slotCell(slot)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
    }

    private func slotCell(_ slot: HourSlot) -> some View {
        let isCurrent = isToday && isCurrentSlot(slot.id)

        return VStack(spacing: 2) {
            Text(slot.shortHour(use24h: use24h))
                .font(.system(size: 10, weight: isCurrent ? .bold : .medium, design: .monospaced))
                .foregroundStyle(isCurrent ? .primary : .secondary)

            RoundedRectangle(cornerRadius: 6)
                .fill(colorForStatus(slot.status))
                .frame(height: 28)
                .overlay {
                    if isCurrent {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.primary, lineWidth: 2)
                    }
                    // Status icon for accessibility — visible but subtle
                    statusIcon(for: slot.status)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.7))
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(for: slot))
    }

    private func isCurrentSlot(_ slotId: Int) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = ScheduleFetcher.kyivTimeZone
        let hour = calendar.component(.hour, from: Date())
        return slotId == hour + 1
    }

    private func colorForStatus(_ status: PowerStatus) -> Color {
        switch status {
        case .on: .green.opacity(0.7)
        case .off: .red.opacity(0.7)
        case .partial: .orange.opacity(0.7)
        case .unknown: .gray.opacity(0.2)
        }
    }

    @ViewBuilder
    private func statusIcon(for status: PowerStatus) -> some View {
        switch status {
        case .on: Image(systemName: "bolt.fill")
        case .off: Image(systemName: "bolt.slash.fill")
        case .partial: Image(systemName: "bolt.badge.clock.fill")
        case .unknown: EmptyView()
        }
    }

    private func accessibilityLabel(for slot: HourSlot) -> String {
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
}
