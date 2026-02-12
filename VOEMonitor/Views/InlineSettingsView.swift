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

    // MARK: - General

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("about.general")

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
