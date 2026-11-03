import SwiftUI

struct ContentView: View {
    @Bindable var service: IOSScheduleService
    @State private var showOnboarding: Bool
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale

    init(service: IOSScheduleService) {
        self.service = service
        _showOnboarding = State(initialValue: service.config.selectedQueue.isEmpty)
    }

    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { context in
                ScrollView {
                    VStack(spacing: 16) {
                        statusHeader(now: context.date)
                        scheduleSection(now: context.date)
                    }
                    .padding()
                }
                .onChange(of: context.date) { _, now in
                    service.apply(now: now)
                }
            }
            .refreshable {
                await service.fetch()
            }
            .navigationTitle("VOE Monitor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView(service: service)
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(service: service, isPresented: $showOnboarding)
                .interactiveDismissDisabled()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            service.apply()
            Task { await service.fetchIfStale() }
        }
    }

    // MARK: - Status Header

    private func statusHeader(now: Date) -> some View {
        let status = service.timeline.status(at: now)
        let nextEvent = ScheduleText.nextEvent(
            timeline: service.timeline,
            now: now,
            use24h: service.config.use24HourTime,
            locale: locale
        )

        return HStack(spacing: 12) {
            Image(systemName: status.symbolName)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(status.color)
                .symbolEffect(.pulse, options: .repeating, isActive: status == .off)

            VStack(alignment: .leading, spacing: 2) {
                Text(status.title)
                    .font(.headline)

                if !service.config.selectedQueue.isEmpty {
                    Text(String(localized: "settings.queue") + " \(service.config.selectedQueue)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !nextEvent.isEmpty {
                    Text(nextEvent)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .cardBackground()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Schedule

    private func scheduleSection(now: Date) -> some View {
        VStack(spacing: 12) {
            if let today = service.todaySchedule {
                ScheduleGridView(
                    title: String(localized: "schedule.today") + " — " + today.dateString(locale: locale),
                    schedule: today,
                    isToday: true,
                    use24h: service.config.use24HourTime,
                    now: now
                )
            }

            if let tomorrow = service.tomorrowSchedule {
                ScheduleGridView(
                    title: String(localized: "schedule.tomorrow") + " — " + tomorrow.dateString(locale: locale),
                    schedule: tomorrow,
                    isToday: false,
                    use24h: service.config.use24HourTime,
                    now: now
                )
            }

            if service.todaySchedule == nil, service.tomorrowSchedule == nil {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        Group {
            if service.isLoading {
                ProgressView()
                    .padding(.vertical, 40)
            } else if let error = service.lastError {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("footer.refresh") {
                        Task { await service.fetch() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 40)
            } else {
                Text("schedule.no_data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 40)
            }
        }
    }
}
