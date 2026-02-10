import SwiftUI

struct SettingsView: View {
    @Environment(SettingsViewModel.self) var viewModel

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
        .frame(width: 450, height: 200)
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
