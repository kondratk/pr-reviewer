import Foundation

nonisolated protocol PRRepositoryProtocol: Sendable {
    func fetchPullRequests(owner: String, repo: String, token: String) async throws -> [PullRequest]
    func fetchCurrentUser(token: String) async throws -> String
    func testToken(_ token: String) async throws -> String
}

nonisolated final class PRRepository: PRRepositoryProtocol {
    private let apiClient: GitHubAPIClientProtocol

    init(apiClient: GitHubAPIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchPullRequests(owner: String, repo: String, token: String) async throws -> [PullRequest] {
        let prs: [GitHubPRResponse] = try await apiClient.fetch(
            "/repos/\(owner)/\(repo)/pulls?state=open&per_page=100", token: token
        )

        var results: [PullRequest] = []
        for pr in prs {
            let reviews: [GitHubReviewResponse] = try await apiClient.fetch(
                "/repos/\(owner)/\(repo)/pulls/\(pr.number)/reviews", token: token
            )
            results.append(PullRequestMapper.map(response: pr, reviews: reviews))
        }
        return results
    }

    func fetchCurrentUser(token: String) async throws -> String {
        let user: GitHubUserResponse = try await apiClient.fetch("/user", token: token)
        return user.login
    }

    func testToken(_ token: String) async throws -> String {
        let user: GitHubUserResponse = try await apiClient.fetch("/user", token: token)
        return user.login
    }
}
