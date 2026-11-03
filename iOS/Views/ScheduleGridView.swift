import SwiftUI

/// 24-hour color-coded schedule grid adapted for touch.
struct ScheduleGridView: View {
    let title: String
    let schedule: DaySchedule
    let isToday: Bool
    let use24h: Bool
    /// Moment the grid renders for; drives the current-hour highlight.
    let now: Date

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
        .cardBackground()
    }

    private func slotCell(_ slot: HourSlot) -> some View {
        let isCurrent = isToday && slot.id == KyivTime.slotID(at: now)

        return VStack(spacing: 2) {
            Text(slot.shortHour(use24h: use24h))
                .font(.system(size: 10, weight: isCurrent ? .bold : .medium, design: .monospaced))
                .foregroundStyle(isCurrent ? .primary : .secondary)

            SlotFill(slot: slot, cornerRadius: 6)
                .frame(height: 28)
                .overlay {
                    if isCurrent {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.primary, lineWidth: 2)
                    }
                    if slot.status != .unknown {
                        Image(systemName: slot.status.symbolName)
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(slot.accessibilityText(use24h: use24h))
    }
}
