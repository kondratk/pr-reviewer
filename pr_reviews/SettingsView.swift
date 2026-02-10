import SwiftUI

struct SettingsView: View {
    @Environment(GitHubService.self) var service
    @State private var tokenInput = ""
    @State private var connectionStatus: ConnectionStatus = .unknown
    @State private var isTesting = false

    enum ConnectionStatus {
        case unknown
        case testing
        case connected(String)
        case invalid
    }

    var body: some View {
        Form {
            Section("GitHub Personal Access Token") {
                SecureField("ghp_xxxxxxxxxxxx", text: $tokenInput)
                    .textFieldStyle(.roundedBorder)

                Text("Needs `repo` scope for private repos, or just public access for public repos.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                HStack {
                    Button("Save") {
                        service.token = tokenInput
                        Task {
                            await service.fetchCurrentUser()
                            if let user = service.currentUser {
                                connectionStatus = .connected(user)
                            }
                            await service.fetchPullRequests()
                        }
                    }
                    .disabled(tokenInput.isEmpty)

                    Button("Test Connection") {
                        Task {
                            connectionStatus = .testing
                            isTesting = true
                            if let login = await service.testToken(tokenInput) {
                                connectionStatus = .connected(login)
                            } else {
                                connectionStatus = .invalid
                            }
                            isTesting = false
                        }
                    }
                    .disabled(tokenInput.isEmpty || isTesting)

                    Spacer()

                    statusView
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 200)
        .onAppear {
            tokenInput = service.token
            if let user = service.currentUser {
                connectionStatus = .connected(user)
            }
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch connectionStatus {
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
