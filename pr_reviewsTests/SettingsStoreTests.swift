import Testing
import Foundation
@testable import pr_reviews

@Suite("SettingsStore")
@MainActor
struct SettingsStoreTests {

    private func makeTestDefaults() -> UserDefaults {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    // MARK: - Initialization

    @Test("Initializes with empty token when no stored value")
    func initEmptyToken() {
        let defaults = makeTestDefaults()
        let store = SettingsStore(defaults: defaults)

        #expect(store.token == "")
    }

    @Test("Initializes with stored token")
    func initWithStoredToken() {
        let defaults = makeTestDefaults()
        defaults.set("ghp_stored", forKey: "github_token")
        let store = SettingsStore(defaults: defaults)

        #expect(store.token == "ghp_stored")
    }

    @Test("Initializes with nil currentUser when no stored value")
    func initNilUser() {
        let defaults = makeTestDefaults()
        let store = SettingsStore(defaults: defaults)

        #expect(store.currentUser == nil)
    }

    @Test("Initializes with stored currentUser")
    func initWithStoredUser() {
        let defaults = makeTestDefaults()
        defaults.set("alice", forKey: "github_user")
        let store = SettingsStore(defaults: defaults)

        #expect(store.currentUser == "alice")
    }

    // MARK: - Persistence

    @Test("Setting token persists to UserDefaults")
    func tokenPersistence() {
        let defaults = makeTestDefaults()
        let store = SettingsStore(defaults: defaults)

        store.token = "ghp_new_token"

        #expect(defaults.string(forKey: "github_token") == "ghp_new_token")
    }

    @Test("Setting currentUser persists to UserDefaults")
    func currentUserPersistence() {
        let defaults = makeTestDefaults()
        let store = SettingsStore(defaults: defaults)

        store.currentUser = "bob"

        #expect(defaults.string(forKey: "github_user") == "bob")
    }

    @Test("Setting currentUser to nil persists nil")
    func currentUserNilPersistence() {
        let defaults = makeTestDefaults()
        defaults.set("existing", forKey: "github_user")
        let store = SettingsStore(defaults: defaults)

        store.currentUser = nil

        #expect(defaults.string(forKey: "github_user") == nil)
    }

    // MARK: - Repository Config

    @Test("repositoryOwner returns first repository owner")
    func repositoryOwner() {
        let store = SettingsStore(defaults: makeTestDefaults())

        #expect(store.repositoryOwner == "surgeventures")
    }

    @Test("repositoryName returns first repository name")
    func repositoryName() {
        let store = SettingsStore(defaults: makeTestDefaults())

        #expect(store.repositoryName == "fresha-android")
    }

    // MARK: - Repositories

    @Test("Seeds legacy repository on first launch")
    func seedsLegacyRepo() {
        let defaults = makeTestDefaults()
        let store = SettingsStore(defaults: defaults)

        #expect(store.repositories.count == 1)
        #expect(store.repositories[0].owner == "surgeventures")
        #expect(store.repositories[0].name == "fresha-android")
    }

    @Test("Persists repositories to UserDefaults as JSON")
    func repositoriesPersistence() {
        let defaults = makeTestDefaults()
        let store = SettingsStore(defaults: defaults)

        let newRepo = RepositoryConfig(owner: "org", name: "new-repo")
        store.repositories.append(newRepo)

        let data = defaults.data(forKey: "configured_repositories")!
        let decoded = try! JSONDecoder().decode([RepositoryConfig].self, from: data)

        #expect(decoded.count == 2)
        #expect(decoded[1].owner == "org")
        #expect(decoded[1].name == "new-repo")
    }

    @Test("Loads persisted repositories on init")
    func loadsPersistedRepos() {
        let defaults = makeTestDefaults()
        let repos = [
            RepositoryConfig(owner: "a", name: "b"),
            RepositoryConfig(owner: "c", name: "d"),
        ]
        let data = try! JSONEncoder().encode(repos)
        defaults.set(data, forKey: "configured_repositories")

        let store = SettingsStore(defaults: defaults)

        #expect(store.repositories.count == 2)
        #expect(store.repositories[0].owner == "a")
        #expect(store.repositories[1].owner == "c")
    }

    @Test("Falls back to legacy repo when stored data is empty array")
    func fallsBackOnEmptyArray() {
        let defaults = makeTestDefaults()
        let data = try! JSONEncoder().encode([RepositoryConfig]())
        defaults.set(data, forKey: "configured_repositories")

        let store = SettingsStore(defaults: defaults)

        #expect(store.repositories.count == 1)
        #expect(store.repositories[0].owner == "surgeventures")
    }
}
