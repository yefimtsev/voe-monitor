import SwiftUI

extension PowerStatus {
    var title: String {
        switch self {
        case .on: String(localized: "status.on")
        case .off: String(localized: "status.off")
        case .partial: String(localized: "status.partial")
        case .unknown: String(localized: "status.unknown")
        }
    }

    var symbolName: String {
        switch self {
        case .on: "bolt.fill"
        case .off: "bolt.slash.fill"
        case .partial: "bolt.badge.clock.fill"
        case .unknown: "bolt.trianglebadge.exclamationmark.fill"
        }
    }

    var color: Color {
        switch self {
        case .on: .green
        case .off: .red
        case .partial: .orange
        case .unknown: .gray
        }
    }

    /// Fill for schedule grid cells.
    var fill: Color {
        self == .unknown ? .gray.opacity(0.2) : color.opacity(0.7)
    }
}

extension HourSlot {
    func accessibilityText(use24h: Bool) -> String {
        "\(hourRange(use24h: use24h)), \(status.title)"
    }
}

/// Hour cell split into halves, so a 30-minute outage looks like one.
struct SlotFill: View {
    let slot: HourSlot
    let cornerRadius: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            slot.firstHalf.fill
            slot.secondHalf.fill
        }
        .clipShape(.rect(cornerRadius: cornerRadius))
    }
}
