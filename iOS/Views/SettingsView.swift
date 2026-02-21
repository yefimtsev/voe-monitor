import SwiftUI

struct SettingsView: View {
    @Bindable var service: IOSScheduleService

    var body: some View {
        Form {
            Section {
                Picker("settings.queue", selection: $service.config.selectedQueue) {
                    Text("settings.select_queue").tag("")
                    ForEach(Queue.all) { queue in
                        Text(queue.displayName).tag(queue.id)
                    }
                }
            } header: {
                Text("settings.queue")
            }

            Section {
                Toggle("settings.notifications_enabled", isOn: $service.config.notificationsEnabled)
            } header: {
                Text("settings.notifications")
            }

            Section {
                Picker("settings.time_format", selection: $service.config.use24HourTime) {
                    Text("settings.time_24h").tag(true)
                    Text("settings.time_12h").tag(false)
                }
            } header: {
                Text("about.general")
            }
        }
        .navigationTitle("footer.settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
