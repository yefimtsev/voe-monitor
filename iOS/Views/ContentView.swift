import SwiftUI

struct ContentView: View {
    @Bindable var service: IOSScheduleService
    @State private var showOnboarding: Bool

    init(service: IOSScheduleService) {
        self.service = service
        _showOnboarding = State(initialValue: service.config.selectedQueue.isEmpty)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statusHeader
                    scheduleSection
                }
                .padding()
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
    }

    // MARK: - Status Header

    private var statusHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(statusColor)
                .symbolEffect(.pulse, options: .repeating, isActive: service.currentStatus == .off)

            VStack(alignment: .leading, spacing: 2) {
                Text(statusText)
                    .font(.headline)

                if !service.config.selectedQueue.isEmpty {
                    Text(String(localized: "settings.queue") + " \(service.config.selectedQueue)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

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

    // MARK: - Schedule

    private var scheduleSection: some View {
        VStack(spacing: 12) {
            if let today = service.todaySchedule {
                ScheduleGridView(
                    title: String(localized: "schedule.today") + " — " + today.dateString,
                    schedule: today,
                    isToday: true,
                    use24h: service.config.use24HourTime
                )
            }

            if let tomorrow = service.tomorrowSchedule {
                ScheduleGridView(
                    title: String(localized: "schedule.tomorrow") + " — " + tomorrow.dateString,
                    schedule: tomorrow,
                    isToday: false,
                    use24h: service.config.use24HourTime
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
