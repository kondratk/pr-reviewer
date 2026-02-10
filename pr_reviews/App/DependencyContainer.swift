import Foundation

@MainActor
final class DependencyContainer {
    let settingsStore: SettingsStore
    let apiClient: GitHubAPIClient
    let repository: PRRepository
    let prListViewModel: PRListViewModel
    private(set) var settingsViewModel: SettingsViewModel!

    init() {
        let settings = SettingsStore()
        let client = GitHubAPIClient()
        let repo = PRRepository(apiClient: client)
        let listVM = PRListViewModel(repository: repo, settingsStore: settings)

        self.settingsStore = settings
        self.apiClient = client
        self.repository = repo
        self.prListViewModel = listVM

        self.settingsViewModel = SettingsViewModel(
            repository: repo,
            settingsStore: settings,
            onTokenSaved: { [weak listVM] in
                await listVM?.fetchCurrentUser()
                await listVM?.fetchPullRequests()
            }
        )
    }
}
