import Foundation

@Observable
@MainActor
final class PRListViewModel {
    private(set) var pullRequests: [PullRequest] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var activeFilter: FilterOption = .noReviews

    let config: RepositoryConfig
    private let repository: PRRepositoryProtocol
    private let settingsStore: SettingsStoreProtocol

    init(config: RepositoryConfig, repository: PRRepositoryProtocol, settingsStore: SettingsStoreProtocol) {
        self.config = config
        self.repository = repository
        self.settingsStore = settingsStore
    }

    var filteredPRs: [PullRequest] {
        activeFilter.apply(to: pullRequests, currentUser: settingsStore.currentUser)
    }

    var unreviewedCount: Int {
        FilterOption.noReviews.apply(to: pullRequests, currentUser: settingsStore.currentUser).count
    }

    var token: String { settingsStore.token }
    var repositoryOwner: String { config.owner }
    var repositoryName: String { config.name }

    func count(for filter: FilterOption) -> Int {
        filter.apply(to: pullRequests, currentUser: settingsStore.currentUser).count
    }

    func fetchPullRequests() async {
        guard !settingsStore.token.isEmpty else {
            errorMessage = "GitHub token not configured. Open Settings to add your token."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            pullRequests = try await repository.fetchPullRequests(
                owner: config.owner,
                repo: config.name,
                token: settingsStore.token
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func fetchCurrentUser() async {
        guard !settingsStore.token.isEmpty else { return }
        do {
            let login = try await repository.fetchCurrentUser(token: settingsStore.token)
            settingsStore.currentUser = login
        } catch {
            // User info is optional
        }
    }
}
