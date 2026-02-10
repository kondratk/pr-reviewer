import Foundation
import Testing
@testable import pr_reviews

@Suite("PRListViewModel")
@MainActor
struct PRListViewModelTests {

    // MARK: - Helpers

    private static let defaultConfig = RepositoryConfig(owner: "test-owner", name: "test-repo")

    private func makeSUT(
        config: RepositoryConfig = defaultConfig,
        repository: MockRepository = MockRepository(),
        settingsStore: MockSettingsStore = MockSettingsStore()
    ) -> (viewModel: PRListViewModel, repository: MockRepository, store: MockSettingsStore) {
        let vm = PRListViewModel(config: config, repository: repository, settingsStore: settingsStore)
        return (vm, repository, settingsStore)
    }

    // MARK: - Initial State

    @Test("Initial state has empty pull requests")
    func initialState() {
        let (vm, _, _) = makeSUT()

        #expect(vm.pullRequests.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
        #expect(vm.activeFilter == .noReviews)
    }

    // MARK: - Fetch Pull Requests

    @Test("fetchPullRequests sets error when token is empty")
    func fetchWithEmptyToken() async {
        let (vm, repo, _) = makeSUT()

        await vm.fetchPullRequests()

        #expect(vm.errorMessage == "GitHub token not configured. Open Settings to add your token.")
        #expect(repo.fetchPRsCallCount == 0)
    }

    @Test("fetchPullRequests populates pull requests on success")
    func fetchSuccess() async {
        let repo = MockRepository()
        let store = MockSettingsStore()
        store.token = "ghp_valid"
        repo.pullRequestsToReturn = [
            TestData.makePullRequest(id: 1),
            TestData.makePullRequest(id: 2),
        ]
        let (vm, _, _) = makeSUT(repository: repo, settingsStore: store)

        await vm.fetchPullRequests()

        #expect(vm.pullRequests.count == 2)
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
    }

    @Test("fetchPullRequests sets error message on failure")
    func fetchFailure() async {
        let repo = MockRepository()
        let store = MockSettingsStore()
        store.token = "ghp_valid"
        repo.errorToThrow = GitHubError.unauthorized
        let (vm, _, _) = makeSUT(repository: repo, settingsStore: store)

        await vm.fetchPullRequests()

        #expect(vm.errorMessage != nil)
        #expect(vm.pullRequests.isEmpty)
        #expect(vm.isLoading == false)
    }

    @Test("fetchPullRequests clears previous error on new fetch")
    func fetchClearsPreviousError() async {
        let repo = MockRepository()
        let store = MockSettingsStore()
        store.token = "ghp_valid"
        repo.errorToThrow = GitHubError.unauthorized
        let (vm, _, _) = makeSUT(repository: repo, settingsStore: store)

        await vm.fetchPullRequests()
        #expect(vm.errorMessage != nil)

        repo.errorToThrow = nil
        repo.pullRequestsToReturn = [TestData.makePullRequest()]
        await vm.fetchPullRequests()

        #expect(vm.errorMessage == nil)
        #expect(vm.pullRequests.count == 1)
    }

    // MARK: - Fetch Current User

    @Test("fetchCurrentUser does nothing when token is empty")
    func fetchUserEmptyToken() async {
        let (vm, repo, _) = makeSUT()

        await vm.fetchCurrentUser()

        #expect(repo.fetchUserCallCount == 0)
    }

    @Test("fetchCurrentUser sets currentUser on settings store")
    func fetchUserSuccess() async {
        let repo = MockRepository()
        let store = MockSettingsStore()
        store.token = "ghp_valid"
        repo.userToReturn = "alice"
        let (vm, _, _) = makeSUT(repository: repo, settingsStore: store)

        await vm.fetchCurrentUser()

        #expect(store.currentUser == "alice")
    }

    @Test("fetchCurrentUser silently handles error")
    func fetchUserFailure() async {
        let repo = MockRepository()
        let store = MockSettingsStore()
        store.token = "ghp_valid"
        repo.errorToThrow = GitHubError.unauthorized
        let (vm, _, _) = makeSUT(repository: repo, settingsStore: store)

        await vm.fetchCurrentUser()

        #expect(store.currentUser == nil)
    }

    // MARK: - Filtering

    @Test("filteredPRs delegates to activeFilter.apply")
    func filteredPRs() async {
        let repo = MockRepository()
        let store = MockSettingsStore()
        store.token = "ghp_valid"
        let recentDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        repo.pullRequestsToReturn = [
            TestData.makePullRequest(id: 1, createdAt: recentDate, reviews: []),
            TestData.makePullRequest(id: 2, createdAt: recentDate, reviews: [
                TestData.makeReview(state: .approved),
            ]),
        ]
        let (vm, _, _) = makeSUT(repository: repo, settingsStore: store)

        await vm.fetchPullRequests()
        vm.activeFilter = .noReviews

        #expect(vm.filteredPRs.count == 1)
        #expect(vm.filteredPRs[0].id == 1)
    }

    @Test("unreviewedCount uses noReviews filter count")
    func unreviewedCount() async {
        let repo = MockRepository()
        let store = MockSettingsStore()
        store.token = "ghp_valid"
        let recentDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        repo.pullRequestsToReturn = [
            TestData.makePullRequest(id: 1, createdAt: recentDate, reviews: []),
            TestData.makePullRequest(id: 2, createdAt: recentDate, reviews: []),
        ]
        let (vm, _, _) = makeSUT(repository: repo, settingsStore: store)

        await vm.fetchPullRequests()

        #expect(vm.unreviewedCount == 2)
    }

    @Test("count(for:) returns correct count for each filter")
    func countForFilter() async {
        let repo = MockRepository()
        let store = MockSettingsStore()
        store.token = "ghp_valid"
        let recentDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        repo.pullRequestsToReturn = [
            TestData.makePullRequest(id: 1, createdAt: recentDate, isDraft: false, reviews: []),
            TestData.makePullRequest(id: 2, createdAt: recentDate, isDraft: true, reviews: []),
        ]
        let (vm, _, _) = makeSUT(repository: repo, settingsStore: store)

        await vm.fetchPullRequests()

        #expect(vm.count(for: .noReviews) == 1)
        #expect(vm.count(for: .allOpen) == 1)
        #expect(vm.count(for: .drafts) == 1)
    }

    // MARK: - Properties

    @Test("token delegates to settings store")
    func tokenProperty() {
        let store = MockSettingsStore()
        store.token = "my-token"
        let (vm, _, _) = makeSUT(settingsStore: store)

        #expect(vm.token == "my-token")
    }

    @Test("repositoryOwner delegates to config")
    func repositoryOwnerProperty() {
        let config = RepositoryConfig(owner: "custom-owner", name: "custom-repo")
        let (vm, _, _) = makeSUT(config: config)

        #expect(vm.repositoryOwner == "custom-owner")
    }

    @Test("repositoryName delegates to config")
    func repositoryNameProperty() {
        let config = RepositoryConfig(owner: "custom-owner", name: "custom-repo")
        let (vm, _, _) = makeSUT(config: config)

        #expect(vm.repositoryName == "custom-repo")
    }
}
