import SwiftUI

/// App entry point — renders a menubar-only window with the schedule panel.
@main
struct VOEMonitorApp: App {
    @State private var scheduleService = ScheduleService()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(service: scheduleService)
                .environment(\.locale, scheduleService.config.language.resolvedLocale)
        } label: {
            Label {
                Text("VOE Monitor")
            } icon: {
                Image(systemName: scheduleService.currentStatus.symbolName)
                    .symbolRenderingMode(.palette)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
