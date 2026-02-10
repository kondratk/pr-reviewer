import Foundation

protocol SettingsStoreProtocol: AnyObject {
    var token: String { get set }
    var currentUser: String? { get set }
    var repositoryOwner: String { get }
    var repositoryName: String { get }
}

@Observable
final class SettingsStore: SettingsStoreProtocol {
    var token: String {
        didSet { defaults.set(token, forKey: "github_token") }
    }
    var currentUser: String? {
        didSet { defaults.set(currentUser, forKey: "github_user") }
    }
    var repositoryOwner: String { "surgeventures" }
    var repositoryName: String { "fresha-android" }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.token = defaults.string(forKey: "github_token") ?? ""
        self.currentUser = defaults.string(forKey: "github_user")
    }
}
