import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(SettingsViewModel.self) var viewModel
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        @Bindable var viewModel = viewModel

        Form {
            Section("GitHub Personal Access Token") {
                SecureField("ghp_xxxxxxxxxxxx", text: $viewModel.tokenInput)
                    .textFieldStyle(.roundedBorder)

                Text("Needs `repo` scope for private repos, or just public access for public repos.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                        }
                    }
            }

            Section {
                HStack {
                    Button("Save") {
                        Task { await viewModel.save() }
                    }
                    .disabled(viewModel.tokenInput.isEmpty)

                    Button("Test Connection") {
                        Task { await viewModel.testConnection() }
                    }
                    .disabled(viewModel.tokenInput.isEmpty || viewModel.isTesting)

                    Spacer()

                    statusView
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 280)
        .onAppear {
            // Workaround for a known Apple bug (FB10184971) where MenuBarExtra apps open
            // settings behind other windows. The .accessory activation policy prevents windows
            // from coming to front, so we temporarily switch to .regular and revert on disappear.
            NSApp.setActivationPolicy(.regular)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.isVisible && window.styleMask.contains(.titled) {
                    window.orderFrontRegardless()
                }
            }
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch viewModel.connectionStatus {
        case .unknown:
            Label("Not verified", systemImage: "questionmark.circle")
                .font(.caption)
                .foregroundColor(.secondary)
        case .testing:
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.6)
                Text("Testing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        case .connected(let user):
            Label("Connected as \(user)", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
        case .invalid:
            Label("Invalid token", systemImage: "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(.red)
        }
    }
}
