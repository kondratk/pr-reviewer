import Foundation

@Observable
@MainActor
final class PRListViewModel {
    private(set) var pullRequests: [PullRequest] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var activeFilter: FilterOption = .noReviews

    private let repository: PRRepositoryProtocol
    private let settingsStore: SettingsStoreProtocol

    init(repository: PRRepositoryProtocol, settingsStore: SettingsStoreProtocol) {
        self.repository = repository
        self.settingsStore = settingsStore
    }

    var filteredPRs: [PullRequest] {
        activeFilter.apply(to: pullRequests, currentUser: settingsStore.currentUser)
    }

    var unreviewedCount: Int {
        filteredPRs.count
    }

    var token: String { settingsStore.token }
    var repositoryOwner: String { settingsStore.repositoryOwner }
    var repositoryName: String { settingsStore.repositoryName }

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
                owner: settingsStore.repositoryOwner,
                repo: settingsStore.repositoryName,
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
