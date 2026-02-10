import Foundation

@Observable
@MainActor
final class SettingsViewModel {
    var tokenInput: String = ""
    var newRepoOwner: String = ""
    var newRepoName: String = ""
    private(set) var connectionStatus: ConnectionStatus = .unknown
    private(set) var isTesting = false

    enum ConnectionStatus {
        case unknown, testing, connected(String), invalid
    }

    private let repository: PRRepositoryProtocol
    private let settingsStore: SettingsStoreProtocol
    private let onTokenSaved: @MainActor () async -> Void
    let onRepositoriesChanged: @MainActor () -> Void

    init(
        repository: PRRepositoryProtocol,
        settingsStore: SettingsStoreProtocol,
        onTokenSaved: @escaping @MainActor () async -> Void,
        onRepositoriesChanged: @escaping @MainActor () -> Void = {}
    ) {
        self.repository = repository
        self.settingsStore = settingsStore
        self.onTokenSaved = onTokenSaved
        self.onRepositoriesChanged = onRepositoriesChanged
        self.tokenInput = settingsStore.token
        if let user = settingsStore.currentUser {
            self.connectionStatus = .connected(user)
        }
    }

    var repositories: [RepositoryConfig] {
        settingsStore.repositories
    }

    var canAddRepository: Bool {
        let owner = newRepoOwner.trimmingCharacters(in: .whitespaces)
        let name = newRepoName.trimmingCharacters(in: .whitespaces)
        guard !owner.isEmpty, !name.isEmpty else { return false }
        let candidate = RepositoryConfig(owner: owner, name: name)
        return !settingsStore.repositories.contains(candidate)
    }

    func addRepository() {
        let owner = newRepoOwner.trimmingCharacters(in: .whitespaces)
        let name = newRepoName.trimmingCharacters(in: .whitespaces)
        guard !owner.isEmpty, !name.isEmpty else { return }
        let config = RepositoryConfig(owner: owner, name: name)
        guard !settingsStore.repositories.contains(config) else { return }
        settingsStore.repositories.append(config)
        newRepoOwner = ""
        newRepoName = ""
        onRepositoriesChanged()
    }

    func removeRepository(_ config: RepositoryConfig) {
        settingsStore.repositories.removeAll { $0 == config }
        onRepositoriesChanged()
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
