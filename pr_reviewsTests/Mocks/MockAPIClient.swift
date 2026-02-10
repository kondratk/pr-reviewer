import Foundation
@testable import pr_reviews

final class MockAPIClient: GitHubAPIClientProtocol, @unchecked Sendable {
    var responses: [String: Any] = [:]
    var errorToThrow: Error?
    var fetchCallCount = 0
    var fetchedPaths: [String] = []

    func fetch<T: Decodable & Sendable>(_ path: String, token: String) async throws -> T {
        fetchCallCount += 1
        fetchedPaths.append(path)

        if let error = errorToThrow {
            throw error
        }

        guard let result = responses[path] as? T else {
            throw URLError(.resourceUnavailable)
        }

        return result
    }

    func setResponse<T: Sendable>(_ response: T, for path: String) {
        responses[path] = response
    }
}
