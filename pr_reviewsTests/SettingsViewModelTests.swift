import Foundation
import Testing
@testable import pr_reviews

@Suite("SettingsViewModel")
@MainActor
struct SettingsViewModelTests {

    // MARK: - Helpers

    private func makeSUT(
        repository: MockRepository = MockRepository(),
        settingsStore: MockSettingsStore = MockSettingsStore(),
        onTokenSaved: @escaping @MainActor () async -> Void = {}
    ) -> (viewModel: SettingsViewModel, repository: MockRepository, store: MockSettingsStore) {
        let vm = SettingsViewModel(
            repository: repository,
            settingsStore: settingsStore,
            onTokenSaved: onTokenSaved
        )
        return (vm, repository, settingsStore)
    }

    // MARK: - Initialization

    @Test("Initializes with token from settings store")
    func initWithToken() {
        let store = MockSettingsStore()
        store.token = "existing-token"
        let (vm, _, _) = makeSUT(settingsStore: store)

        #expect(vm.tokenInput == "existing-token")
    }

    @Test("Initializes with connected status when user exists")
    func initWithUser() {
        let store = MockSettingsStore()
        store.currentUser = "alice"
        let (vm, _, _) = makeSUT(settingsStore: store)

        if case .connected(let user) = vm.connectionStatus {
            #expect(user == "alice")
        } else {
            Issue.record("Expected .connected status")
        }
    }

    @Test("Initializes with unknown status when no user")
    func initNoUser() {
        let (vm, _, _) = makeSUT()

        if case .unknown = vm.connectionStatus {
            // Expected
        } else {
            Issue.record("Expected .unknown status")
        }
    }

    // MARK: - Save

    @Test("save updates token on settings store")
    func saveUpdatesToken() async {
        let store = MockSettingsStore()
        let (vm, _, _) = makeSUT(settingsStore: store)
        vm.tokenInput = "new-token"

        await vm.save()

        #expect(store.token == "new-token")
    }

    @Test("save fetches and stores current user")
    func saveFetchesUser() async {
        let repo = MockRepository()
        repo.userToReturn = "bob"
        let store = MockSettingsStore()
        let (vm, _, _) = makeSUT(repository: repo, settingsStore: store)
        vm.tokenInput = "valid-token"

        await vm.save()

        #expect(store.currentUser == "bob")
        #expect(repo.fetchUserCallCount == 1)
    }

    @Test("save sets connected status on success")
    func saveConnectedStatus() async {
        let repo = MockRepository()
        repo.userToReturn = "carol"
        let (vm, _, _) = makeSUT(repository: repo)
        vm.tokenInput = "valid-token"

        await vm.save()

        if case .connected(let user) = vm.connectionStatus {
            #expect(user == "carol")
        } else {
            Issue.record("Expected .connected status")
        }
    }

    @Test("save calls onTokenSaved callback")
    func saveCallsCallback() async {
        var callbackCalled = false
        let (vm, _, _) = makeSUT(onTokenSaved: {
            callbackCalled = true
        })
        vm.tokenInput = "token"

        await vm.save()

        #expect(callbackCalled)
    }

    @Test("save proceeds without user info on error")
    func saveContinuesOnUserFetchError() async {
        let repo = MockRepository()
        repo.errorToThrow = GitHubError.unauthorized
        var callbackCalled = false
        let (vm, _, _) = makeSUT(repository: repo, onTokenSaved: {
            callbackCalled = true
        })
        vm.tokenInput = "bad-token"

        await vm.save()

        #expect(callbackCalled)
    }

    // MARK: - Test Connection

    @Test("testConnection sets connected on success")
    func testConnectionSuccess() async {
        let repo = MockRepository()
        repo.userToReturn = "dave"
        let (vm, _, _) = makeSUT(repository: repo)
        vm.tokenInput = "valid-token"

        await vm.testConnection()

        if case .connected(let user) = vm.connectionStatus {
            #expect(user == "dave")
        } else {
            Issue.record("Expected .connected status")
        }
        #expect(vm.isTesting == false)
        #expect(repo.testTokenCallCount == 1)
    }

    @Test("testConnection sets invalid on failure")
    func testConnectionFailure() async {
        let repo = MockRepository()
        repo.errorToThrow = GitHubError.unauthorized
        let (vm, _, _) = makeSUT(repository: repo)
        vm.tokenInput = "bad-token"

        await vm.testConnection()

        if case .invalid = vm.connectionStatus {
            // Expected
        } else {
            Issue.record("Expected .invalid status")
        }
        #expect(vm.isTesting == false)
    }

    @Test("testConnection resets isTesting after completion")
    func testConnectionResetsIsTesting() async {
        let (vm, _, _) = makeSUT()
        vm.tokenInput = "token"

        await vm.testConnection()

        #expect(vm.isTesting == false)
    }
}
