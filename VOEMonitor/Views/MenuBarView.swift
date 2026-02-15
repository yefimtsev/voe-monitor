import SwiftUI

/// Main panel shown when the menubar icon is clicked.
struct MenuBarView: View {
    // swiftlint:disable:next force_unwrapping
    private static let kyiv = TimeZone(identifier: "Europe/Kyiv")!

    var service: ScheduleService
    @State private var showTomorrow = false
    @State private var showSettings = false
    @State private var settingsBounce = 0

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            if showSettings {
                InlineSettingsView(service: service, showSettings: $showSettings)
            } else {
                headerSection
                scheduleSection
                footerSection
            }
        }
        .padding(16)
        .frame(width: 340)
        .animation(.snappy(duration: 0.25), value: showSettings)
        .onAppear {
            service.refreshCurrentStatus()
            Task { await service.fetchIfStale() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.pulse, options: .repeating, isActive: service.currentStatus == .off)
                    .symbolEffect(.breathe, options: .repeating, isActive: service.currentStatus == .partial)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(statusColor)
                    .frame(width: 36, height: 36)

                Text(statusText)
                    .font(.system(size: 15, weight: .semibold))

                Spacer(minLength: 8)

                if !service.queue.isEmpty {
                    Text(service.queue)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .adaptiveGlass(in: .capsule)
                }
            }

            if !service.nextOutageText.isEmpty {
                Text(service.nextOutageText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Status Helpers

    private var statusText: String {
        switch service.currentStatus {
        case .on: String(localized: "status.on")
        case .off: String(localized: "status.off")
        case .partial: String(localized: "status.partial")
        case .unknown: String(localized: "status.unknown")
        }
    }

    private var iconName: String {
        switch service.currentStatus {
        case .on: "bolt.fill"
        case .off: "bolt.slash.fill"
        case .partial: "bolt.badge.clock.fill"
        case .unknown: "questionmark.circle"
        }
    }

    private var statusColor: Color {
        switch service.currentStatus {
        case .on: .green
        case .off: .red
        case .partial: .orange
        case .unknown: .gray
        }
    }

    // MARK: - Schedule Grid

    private var scheduleSection: some View {
        VStack(spacing: 10) {
            if let today = service.todaySchedule {
                dayCard(
                    title: "\(String(localized: "schedule.today")) — \(today.dateString)",
                    schedule: today,
                    isToday: true
                )
            }
            if let tomorrow = service.tomorrowSchedule {
                VStack(spacing: 0) {
                    HStack {
                        Text("\(String(localized: "schedule.tomorrow")) — \(tomorrow.dateString)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(showTomorrow ? 90 : 0))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.25)) {
                            showTomorrow.toggle()
                        }
                    }

                    if showTomorrow {
                        hourGrid(slots: tomorrow.slots, highlightCurrent: false)
                            .padding(10)
                            .transition(.opacity)
                    }
                }
                .clipped()
                .adaptiveGlass(in: .rect(cornerRadius: 12))
            }
            if service.todaySchedule == nil, service.tomorrowSchedule == nil {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        Group {
            if service.isLoading {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("schedule.loading")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if let error = service.lastError {
                Text(String(localized: "schedule.error \(error)"))
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                Text("schedule.no_data")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
    }

    private func dayCard(title: String, schedule: DaySchedule, isToday: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            hourGrid(slots: schedule.slots, highlightCurrent: isToday)
        }
        .padding(10)
        .adaptiveGlass(in: .rect(cornerRadius: 12))
    }

    private func hourGrid(slots: [HourSlot], highlightCurrent: Bool) -> some View {
        let kyiv = Self.kyiv
        var calendar = Calendar.current
        calendar.timeZone = kyiv
        let currentHour = calendar.component(.hour, from: Date())
        let currentSlot = currentHour + 1
        let use24h = service.config.use24HourTime

        let amSlots = Array(slots.prefix(12))
        let pmSlots = Array(slots.suffix(12))

        return VStack(spacing: use24h ? 3 : 6) {
            slotRow(slots: amSlots, highlightCurrent: highlightCurrent, currentSlot: currentSlot, use24h: use24h, periodLabel: use24h ? nil : "AM")
            slotRow(slots: pmSlots, highlightCurrent: highlightCurrent, currentSlot: currentSlot, use24h: use24h, periodLabel: use24h ? nil : "PM")
        }
    }

    private func slotRow(slots: [HourSlot], highlightCurrent: Bool, currentSlot: Int, use24h: Bool, periodLabel: String?) -> some View {
        VStack(spacing: 1) {
            if let label = periodLabel {
                Text(label)
                    .font(.system(size: 7, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 12), spacing: 3) {
                ForEach(slots) { slot in
                    let isCurrent = highlightCurrent && slot.id == currentSlot
                    VStack(spacing: 2) {
                        Text(slot.shortHour(use24h: use24h))
                            .font(.system(size: 8, weight: isCurrent ? .bold : .medium, design: .monospaced))
                            .foregroundStyle(isCurrent ? .primary : .secondary)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorForSlot(slot))
                            .frame(height: 18)
                            .overlay {
                                if isCurrent {
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(.white, lineWidth: 2)
                                }
                            }
                            .shadow(color: isCurrent ? statusColor.opacity(0.4) : .clear, radius: 3)
                    }
                }
            }
        }
    }

    private func colorForSlot(_ slot: HourSlot) -> Color {
        switch slot.status {
        case .on: .green.opacity(0.65)
        case .off: .red.opacity(0.65)
        case .partial: .orange.opacity(0.65)
        case .unknown: .gray.opacity(0.2)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            if let updated = service.lastUpdated {
                Text(String(localized: "footer.updated \(updated, format: .dateTime.hour().minute())"))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if service.lastError != nil, let retryAt = service.nextRetryAt {
                retryBanner(retryAt: retryAt)
            }

            if let version = service.availableUpdate {
                updateBanner(version: version)
            }

            actionButtons
        }
    }

    // MARK: - Retry Banner

    private func retryBanner(retryAt: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.arrow.trianglehead.counterclockwise.rotate.90")
                .foregroundStyle(.orange)
            Text(retryAt, style: .relative)
                .font(.system(size: 11, weight: .medium))
            Spacer()
            Button {
                service.retryNow()
            } label: {
                Text("retry.now")
                    .font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .adaptiveGlass(in: .rect(cornerRadius: 8))
    }

    // MARK: - Update Banner

    private func updateBanner(version: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(.blue)
            Text(String(localized: "update.available \(version)"))
                .font(.system(size: 11, weight: .medium))
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if let url = URL(string: "https://github.com/yefimtsev/voe-monitor/releases/latest") {
                NSWorkspace.shared.open(url)
            }
        }
        .adaptiveGlass(in: .rect(cornerRadius: 8))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button {
                Task { await service.fetch() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .symbolEffect(.rotate, value: service.fetchCount)
                    Text(String(localized: "footer.refresh"))
                }
                .font(.system(size: 11))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .adaptiveGlass(.interactive, in: .rect(cornerRadius: 8))

            Button {
                settingsBounce += 1
                showSettings = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "gear")
                        .symbolEffect(.rotate, value: settingsBounce)
                    Text(String(localized: "footer.settings"))
                }
                .font(.system(size: 11))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .adaptiveGlass(.interactive, in: .rect(cornerRadius: 8))

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle")
                    Text(String(localized: "about.quit"))
                }
                .font(.system(size: 11))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .adaptiveGlass(.interactive, in: .rect(cornerRadius: 8))
        }
    }
}
