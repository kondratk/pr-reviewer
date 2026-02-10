import Foundation

@Observable
@MainActor
final class SettingsViewModel {
    var tokenInput: String = ""
    private(set) var connectionStatus: ConnectionStatus = .unknown
    private(set) var isTesting = false

    enum ConnectionStatus {
        case unknown, testing, connected(String), invalid
    }

    private let repository: PRRepositoryProtocol
    private let settingsStore: SettingsStoreProtocol
    private let onTokenSaved: @MainActor () async -> Void

    init(
        repository: PRRepositoryProtocol,
        settingsStore: SettingsStoreProtocol,
        onTokenSaved: @escaping @MainActor () async -> Void
    ) {
        self.repository = repository
        self.settingsStore = settingsStore
        self.onTokenSaved = onTokenSaved
        self.tokenInput = settingsStore.token
        if let user = settingsStore.currentUser {
            self.connectionStatus = .connected(user)
        }
    }

    func save() async {
        settingsStore.token = tokenInput
        do {
            let login = try await repository.fetchCurrentUser(token: tokenInput)
            settingsStore.currentUser = login
            connectionStatus = .connected(login)
        } catch {
            // proceed without user info
        }
        await onTokenSaved()
    }

    func testConnection() async {
        connectionStatus = .testing
        isTesting = true
        do {
            let login = try await repository.testToken(tokenInput)
            connectionStatus = .connected(login)
        } catch {
            connectionStatus = .invalid
        }
        isTesting = false
    }
}
