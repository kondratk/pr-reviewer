import Foundation

@Observable
@MainActor
final class MultiRepoViewModel {
    private(set) var repoViewModels: [PRListViewModel] = []
    var selectedRepoId: String?

    private let repository: PRRepositoryProtocol
    private let settingsStore: SettingsStoreProtocol

    init(repository: PRRepositoryProtocol, settingsStore: SettingsStoreProtocol) {
        self.repository = repository
        self.settingsStore = settingsStore
        rebuildViewModels()
    }

    var selectedViewModel: PRListViewModel? {
        if let id = selectedRepoId {
            return repoViewModels.first { $0.config.id == id }
        }
        return repoViewModels.first
    }

    var totalUnreviewedCount: Int {
        repoViewModels.reduce(0) { $0 + $1.unreviewedCount }
    }

    func rebuildViewModels() {
        let configs = settingsStore.repositories
        var newViewModels: [PRListViewModel] = []

        for config in configs {
            if let existing = repoViewModels.first(where: { $0.config == config }) {
                newViewModels.append(existing)
            } else {
                newViewModels.append(PRListViewModel(config: config, repository: repository, settingsStore: settingsStore))
            }
        }

        repoViewModels = newViewModels

        if let selectedId = selectedRepoId,
           !repoViewModels.contains(where: { $0.config.id == selectedId }) {
            selectedRepoId = repoViewModels.first?.config.id
        }
    }

    func fetchAllRepositories() async {
        await withTaskGroup(of: Void.self) { group in
            for vm in repoViewModels {
                group.addTask { @MainActor in
                    await vm.fetchCurrentUser()
                    await vm.fetchPullRequests()
                }
            }
        }
    }
}
