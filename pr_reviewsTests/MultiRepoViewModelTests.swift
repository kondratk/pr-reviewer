import Foundation
import Testing
@testable import pr_reviews

@Suite("MultiRepoViewModel")
@MainActor
struct MultiRepoViewModelTests {

    // MARK: - Helpers

    private func makeSUT(
        repository: MockRepository = MockRepository(),
        settingsStore: MockSettingsStore = MockSettingsStore()
    ) -> (viewModel: MultiRepoViewModel, repository: MockRepository, store: MockSettingsStore) {
        let vm = MultiRepoViewModel(repository: repository, settingsStore: settingsStore)
        return (vm, repository, settingsStore)
    }

    // MARK: - VM Creation

    @Test("Creates one VM per configured repository")
    func createsVMPerRepo() {
        let store = MockSettingsStore()
        store.repositories = [
            RepositoryConfig(owner: "a", name: "b"),
            RepositoryConfig(owner: "c", name: "d"),
        ]
        let (vm, _, _) = makeSUT(settingsStore: store)

        #expect(vm.repoViewModels.count == 2)
        #expect(vm.repoViewModels[0].config.owner == "a")
        #expect(vm.repoViewModels[1].config.owner == "c")
    }

    // MARK: - Selection

    @Test("selectedViewModel returns first VM when no selection")
    func selectedDefaultsToFirst() {
        let store = MockSettingsStore()
        store.repositories = [
            RepositoryConfig(owner: "a", name: "b"),
            RepositoryConfig(owner: "c", name: "d"),
        ]
        let (vm, _, _) = makeSUT(settingsStore: store)

        #expect(vm.selectedViewModel?.config.owner == "a")
    }

    @Test("selectedViewModel returns VM matching selectedRepoId")
    func selectedMatchesId() {
        let store = MockSettingsStore()
        store.repositories = [
            RepositoryConfig(owner: "a", name: "b"),
            RepositoryConfig(owner: "c", name: "d"),
        ]
        let (vm, _, _) = makeSUT(settingsStore: store)
        vm.selectedRepoId = "c/d"

        #expect(vm.selectedViewModel?.config.owner == "c")
    }

    // MARK: - Total Count

    @Test("totalUnreviewedCount sums across all VMs")
    func totalCount() async {
        let repo = MockRepository()
        let store = MockSettingsStore()
        store.token = "ghp_valid"
        store.repositories = [
            RepositoryConfig(owner: "a", name: "b"),
            RepositoryConfig(owner: "c", name: "d"),
        ]
        let recentDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        repo.pullRequestsToReturn = [
            TestData.makePullRequest(id: 1, createdAt: recentDate, reviews: []),
            TestData.makePullRequest(id: 2, createdAt: recentDate, reviews: []),
        ]
        let (vm, _, _) = makeSUT(repository: repo, settingsStore: store)

        await vm.fetchAllRepositories()

        // Each VM gets 2 unreviewed PRs, total = 4
        #expect(vm.totalUnreviewedCount == 4)
    }

    // MARK: - Rebuild Preservation

    @Test("rebuildViewModels preserves existing VMs for unchanged repos")
    func rebuildPreservesExisting() {
        let store = MockSettingsStore()
        store.repositories = [
            RepositoryConfig(owner: "a", name: "b"),
        ]
        let (vm, _, _) = makeSUT(settingsStore: store)
        let originalVM = vm.repoViewModels[0]

        store.repositories.append(RepositoryConfig(owner: "c", name: "d"))
        vm.rebuildViewModels()

        #expect(vm.repoViewModels.count == 2)
        #expect(vm.repoViewModels[0] === originalVM)
    }

    @Test("rebuildViewModels resets selection when selected repo is removed")
    func rebuildResetsSelection() {
        let store = MockSettingsStore()
        store.repositories = [
            RepositoryConfig(owner: "a", name: "b"),
            RepositoryConfig(owner: "c", name: "d"),
        ]
        let (vm, _, _) = makeSUT(settingsStore: store)
        vm.selectedRepoId = "c/d"

        store.repositories = [RepositoryConfig(owner: "a", name: "b")]
        vm.rebuildViewModels()

        #expect(vm.selectedRepoId == "a/b")
        #expect(vm.repoViewModels.count == 1)
    }

    @Test("selectedViewModel is nil when no repos configured")
    func noReposSelectedIsNil() {
        let store = MockSettingsStore()
        store.repositories = []
        let (vm, _, _) = makeSUT(settingsStore: store)

        #expect(vm.selectedViewModel == nil)
        #expect(vm.repoViewModels.isEmpty)
    }
}
