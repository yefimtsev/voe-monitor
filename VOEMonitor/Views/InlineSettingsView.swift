import ServiceManagement
import SwiftUI

/// Settings panel shown inline within the menubar popover.
struct InlineSettingsView: View {
    var service: ScheduleService
    @Binding var showSettings: Bool
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            VStack(spacing: 12) {
                queueSection
                notificationsSection
                generalSection
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                showSettings = false
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text(String(localized: "settings.back"))
                }
                .font(.system(size: 12))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(String(localized: "footer.settings"))
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            // Balance the back button width
            Color.clear.frame(width: 50, height: 1)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Queue

    private var queueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("settings.queue")

            Picker("settings.queue", selection: Binding(
                get: { service.config.selectedQueue },
                set: { service.config.selectedQueue = $0 }
            )) {
                Text("settings.select_queue").tag("")
                ForEach(Queue.all) { queue in
                    Text(queue.displayName).tag(queue.id)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .glassEffect(in: .rect(cornerRadius: 12))
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("settings.notifications")
                .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("settings.notifications_enabled", isOn: Binding(
                get: { service.config.notificationsEnabled },
                set: { service.config.notificationsEnabled = $0 }
            ))
            .font(.system(size: 12))

            if service.config.notificationsEnabled {
                Toggle("settings.warn_before_outage", isOn: Binding(
                    get: { service.config.upcomingOutageWarning },
                    set: { service.config.upcomingOutageWarning = $0 }
                ))
                .font(.system(size: 12))

                if service.config.upcomingOutageWarning {
                    Picker("settings.warning_time", selection: Binding(
                        get: { service.config.warningMinutes },
                        set: { service.config.warningMinutes = $0 }
                    )) {
                        Text("settings.minutes \(15)").tag(15)
                        Text("settings.minutes \(30)").tag(30)
                        Text("settings.minutes \(60)").tag(60)
                    }
                    .pickerStyle(.menu)
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(10)
        .glassEffect(in: .rect(cornerRadius: 12))
    }

    // MARK: - General

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("about.general")

            Picker("settings.language", selection: Binding(
                get: { service.config.language },
                set: { service.config.language = $0 }
            )) {
                Text("settings.language_system").tag(AppLanguage.system)
                Text("settings.language_en").tag(AppLanguage.en)
                Text("settings.language_uk").tag(AppLanguage.uk)
            }
            .pickerStyle(.menu)
            .font(.system(size: 12))
            .frame(maxWidth: .infinity, alignment: .leading)

            Picker("settings.time_format", selection: Binding(
                get: { service.config.use24HourTime },
                set: { service.config.use24HourTime = $0 }
            )) {
                Text("settings.time_24h").tag(true)
                Text("settings.time_12h").tag(false)
            }
            .pickerStyle(.menu)
            .font(.system(size: 12))
            .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("about.launch_at_login", isOn: $launchAtLogin)
                .font(.system(size: 12))
                .onChange(of: launchAtLogin) { _, newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }

            Text("v\(ScheduleService.appVersion)")
                .font(.system(size: 10))
                .foregroundStyle(.quaternary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(10)
        .glassEffect(in: .rect(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
    }
}
