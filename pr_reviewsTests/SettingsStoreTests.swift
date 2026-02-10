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

    @Test("repositoryOwner returns expected value")
    func repositoryOwner() {
        let store = SettingsStore(defaults: makeTestDefaults())

        #expect(store.repositoryOwner == "surgeventures")
    }

    @Test("repositoryName returns expected value")
    func repositoryName() {
        let store = SettingsStore(defaults: makeTestDefaults())

        #expect(store.repositoryName == "fresha-android")
    }
}
