import Foundation
@testable import pr_reviews

final class MockSettingsStore: SettingsStoreProtocol, @unchecked Sendable {
    var token: String = ""
    var currentUser: String?
    var repositoryOwner: String { repositories.first?.owner ?? "test-owner" }
    var repositoryName: String { repositories.first?.name ?? "test-repo" }
    var repositories: [RepositoryConfig] = [
        RepositoryConfig(owner: "test-owner", name: "test-repo")
    ]
}
