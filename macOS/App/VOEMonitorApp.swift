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
                Image(systemName: menuBarIconName)
                    .symbolRenderingMode(.palette)
            }
        }
        .menuBarExtraStyle(.window)
    }

    // MARK: - Menubar Icon

    private var menuBarIconName: String {
        switch scheduleService.currentStatus {
        case .on:
            "bolt.fill"
        case .off:
            "bolt.slash.fill"
        case .partial:
            "bolt.badge.clock.fill"
        case .unknown:
            "bolt.trianglebadge.exclamationmark.fill"
        }
    }
}
