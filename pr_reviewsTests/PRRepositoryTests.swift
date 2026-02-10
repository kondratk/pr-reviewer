import Testing
@testable import pr_reviews

@Suite("PRRepository")
struct PRRepositoryTests {

    // MARK: - Fetch Pull Requests

    @Test("fetchPullRequests fetches PRs and reviews then maps them")
    func fetchPullRequestsSuccess() async throws {
        let client = MockAPIClient()
        let prResponse = [TestData.makeGitHubPRResponse(number: 10)]
        let reviewResponse = [TestData.makeGitHubReviewResponse(login: "bob", state: "APPROVED")]

        client.setResponse(prResponse, for: "/repos/owner/repo/pulls?state=open&per_page=100")
        client.setResponse(reviewResponse, for: "/repos/owner/repo/pulls/10/reviews")

        let repo = PRRepository(apiClient: client)
        let results = try await repo.fetchPullRequests(owner: "owner", repo: "repo", token: "token")

        #expect(results.count == 1)
        #expect(results[0].number == 10)
        #expect(results[0].reviews.count == 1)
        #expect(results[0].reviews[0].userLogin == "bob")
        #expect(results[0].reviews[0].state == .approved)
        #expect(client.fetchCallCount == 2)
    }

    @Test("fetchPullRequests fetches reviews for each PR")
    func fetchPullRequestsMultiplePRs() async throws {
        let client = MockAPIClient()
        let prResponse = [
            TestData.makeGitHubPRResponse(id: 1, number: 10),
            TestData.makeGitHubPRResponse(id: 2, number: 20),
        ]

        client.setResponse(prResponse, for: "/repos/o/r/pulls?state=open&per_page=100")
        client.setResponse([GitHubReviewResponse](), for: "/repos/o/r/pulls/10/reviews")
        client.setResponse([GitHubReviewResponse](), for: "/repos/o/r/pulls/20/reviews")

        let repo = PRRepository(apiClient: client)
        let results = try await repo.fetchPullRequests(owner: "o", repo: "r", token: "t")

        #expect(results.count == 2)
        #expect(client.fetchCallCount == 3) // 1 for PRs + 2 for reviews
    }

    @Test("fetchPullRequests propagates API error")
    func fetchPullRequestsError() async {
        let client = MockAPIClient()
        client.errorToThrow = GitHubError.unauthorized

        let repo = PRRepository(apiClient: client)

        do {
            _ = try await repo.fetchPullRequests(owner: "o", repo: "r", token: "t")
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is GitHubError)
        }
    }

    @Test("fetchPullRequests propagates review fetch error")
    func fetchPullRequestsReviewError() async {
        let client = MockAPIClient()
        let prResponse = [TestData.makeGitHubPRResponse(number: 10)]
        client.setResponse(prResponse, for: "/repos/o/r/pulls?state=open&per_page=100")
        client.errorToThrow = nil

        // The MockAPIClient will fail for the reviews path since it has no response set
        let repo = PRRepository(apiClient: client)

        do {
            _ = try await repo.fetchPullRequests(owner: "o", repo: "r", token: "t")
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected: reviews endpoint not configured in mock
        }
    }

    // MARK: - Fetch Current User

    @Test("fetchCurrentUser returns login from API")
    func fetchCurrentUserSuccess() async throws {
        let client = MockAPIClient()
        let userResponse = GitHubUserResponse(login: "alice", avatarUrl: "https://example.com/avatar")
        client.setResponse(userResponse, for: "/user")

        let repo = PRRepository(apiClient: client)
        let login = try await repo.fetchCurrentUser(token: "token")

        #expect(login == "alice")
        #expect(client.fetchedPaths.contains("/user"))
    }

    @Test("fetchCurrentUser propagates error")
    func fetchCurrentUserError() async {
        let client = MockAPIClient()
        client.errorToThrow = GitHubError.unauthorized

        let repo = PRRepository(apiClient: client)

        do {
            _ = try await repo.fetchCurrentUser(token: "bad")
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is GitHubError)
        }
    }

    // MARK: - Test Token

    @Test("testToken returns login on valid token")
    func testTokenSuccess() async throws {
        let client = MockAPIClient()
        let userResponse = GitHubUserResponse(login: "bob", avatarUrl: "https://example.com/avatar")
        client.setResponse(userResponse, for: "/user")

        let repo = PRRepository(apiClient: client)
        let login = try await repo.testToken("valid-token")

        #expect(login == "bob")
    }

    @Test("testToken throws on invalid token")
    func testTokenError() async {
        let client = MockAPIClient()
        client.errorToThrow = GitHubError.unauthorized

        let repo = PRRepository(apiClient: client)

        do {
            _ = try await repo.testToken("invalid")
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is GitHubError)
        }
    }
}
