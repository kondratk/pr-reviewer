import Foundation
@testable import pr_reviews

final class MockRepository: PRRepositoryProtocol, @unchecked Sendable {
    var pullRequestsToReturn: [PullRequest] = []
    var userToReturn: String = "testuser"
    var errorToThrow: Error?
    var fetchPRsCallCount = 0
    var fetchUserCallCount = 0
    var testTokenCallCount = 0

    func fetchPullRequests(owner: String, repo: String, token: String) async throws -> [PullRequest] {
        fetchPRsCallCount += 1
        if let error = errorToThrow { throw error }
        return pullRequestsToReturn
    }

    func fetchCurrentUser(token: String) async throws -> String {
        fetchUserCallCount += 1
        if let error = errorToThrow { throw error }
        return userToReturn
    }

    func testToken(_ token: String) async throws -> String {
        testTokenCallCount += 1
        if let error = errorToThrow { throw error }
        return userToReturn
    }
}
