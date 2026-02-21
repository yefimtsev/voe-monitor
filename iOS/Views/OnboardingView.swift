import SwiftUI

/// First-run onboarding: non-dismissable queue selection.
struct OnboardingView: View {
    @Bindable var service: IOSScheduleService
    @Binding var isPresented: Bool
    @State private var selectedQueue = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.yellow)

                Text("VOE Monitor")
                    .font(.title.bold())

                Text("onboarding.select_queue")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Picker("settings.queue", selection: $selectedQueue) {
                    Text("settings.select_queue").tag("")
                    ForEach(Queue.all) { queue in
                        Text(queue.displayName).tag(queue.id)
                    }
                }
                .pickerStyle(.wheel)

                Spacer()

                Button {
                    service.config.selectedQueue = selectedQueue
                    isPresented = false
                } label: {
                    Text("onboarding.continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selectedQueue.isEmpty)
            }
            .padding(24)
        }
    }
}
