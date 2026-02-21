import SwiftUI

@main
struct VOEMonitorIOSApp: App {
    @State private var service = IOSScheduleService()

    var body: some Scene {
        WindowGroup {
            ContentView(service: service)
        }
    }
}
