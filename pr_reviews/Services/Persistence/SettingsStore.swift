import Foundation

protocol SettingsStoreProtocol: AnyObject {
    var token: String { get set }
    var currentUser: String? { get set }
    var repositoryOwner: String { get }
    var repositoryName: String { get }
    var repositories: [RepositoryConfig] { get set }
}

@Observable
final class SettingsStore: SettingsStoreProtocol {
    var token: String {
        didSet { defaults.set(token, forKey: "github_token") }
    }
    var currentUser: String? {
        didSet { defaults.set(currentUser, forKey: "github_user") }
    }
    var repositories: [RepositoryConfig] {
        didSet { persistRepositories() }
    }

    var repositoryOwner: String { repositories.first?.owner ?? "surgeventures" }
    var repositoryName: String { repositories.first?.name ?? "fresha-android" }

    private let defaults: UserDefaults

    private static let repositoriesKey = "configured_repositories"
    private static let legacyRepo = RepositoryConfig(owner: "surgeventures", name: "fresha-android")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.token = defaults.string(forKey: "github_token") ?? ""
        self.currentUser = defaults.string(forKey: "github_user")

        if let data = defaults.data(forKey: Self.repositoriesKey),
           let decoded = try? JSONDecoder().decode([RepositoryConfig].self, from: data),
           !decoded.isEmpty {
            self.repositories = decoded
        } else {
            self.repositories = [Self.legacyRepo]
            persistRepositories()
        }
    }

    private func persistRepositories() {
        if let data = try? JSONEncoder().encode(repositories) {
            defaults.set(data, forKey: Self.repositoriesKey)
        }
    }
}
