import Foundation
@testable import pr_reviews

final class MockSettingsStore: SettingsStoreProtocol, @unchecked Sendable {
    var token: String = ""
    var currentUser: String?
    var repositoryOwner: String { "test-owner" }
    var repositoryName: String { "test-repo" }
}
