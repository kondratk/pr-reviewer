import Foundation

@MainActor
final class DependencyContainer {
    let settingsStore: SettingsStore
    let apiClient: GitHubAPIClient
    let repository: PRRepository
    let multiRepoViewModel: MultiRepoViewModel
    private(set) var settingsViewModel: SettingsViewModel!

    init() {
        let settings = SettingsStore()
        let client = GitHubAPIClient()
        let repo = PRRepository(apiClient: client)
        let multiRepo = MultiRepoViewModel(repository: repo, settingsStore: settings)

        self.settingsStore = settings
        self.apiClient = client
        self.repository = repo
        self.multiRepoViewModel = multiRepo

        self.settingsViewModel = SettingsViewModel(
            repository: repo,
            settingsStore: settings,
            onTokenSaved: { [weak multiRepo] in
                await multiRepo?.fetchAllRepositories()
            },
            onRepositoriesChanged: { [weak multiRepo] in
                multiRepo?.rebuildViewModels()
            }
        )
    }
}
