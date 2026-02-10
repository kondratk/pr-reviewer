import Testing
import Foundation
@testable import pr_reviews

@Suite("GitHubAPIClient")
struct GitHubAPIClientTests {

    // MARK: - GitHubError

    @Test("unauthorized error has correct description")
    func unauthorizedErrorDescription() {
        let error = GitHubError.unauthorized
        #expect(error.errorDescription == "Invalid or expired GitHub token")
    }

    @Test("notFound error has correct description")
    func notFoundErrorDescription() {
        let error = GitHubError.notFound("/repos/test")
        #expect(error.errorDescription == "Repository not found. Ensure your token has the `repo` scope for private repositories.")
    }

    @Test("httpError includes status code")
    func httpErrorDescription() {
        let error = GitHubError.httpError(500)
        #expect(error.errorDescription == "GitHub API error (HTTP 500)")
    }

    // MARK: - ReviewState

    @Test("ReviewState raw values match GitHub API strings")
    func reviewStateRawValues() {
        #expect(ReviewState.approved.rawValue == "APPROVED")
        #expect(ReviewState.changesRequested.rawValue == "CHANGES_REQUESTED")
        #expect(ReviewState.commented.rawValue == "COMMENTED")
        #expect(ReviewState.dismissed.rawValue == "DISMISSED")
        #expect(ReviewState.pending.rawValue == "PENDING")
    }

    @Test("ReviewState initializes from valid raw value")
    func reviewStateFromRawValue() {
        #expect(ReviewState(rawValue: "APPROVED") == .approved)
        #expect(ReviewState(rawValue: "CHANGES_REQUESTED") == .changesRequested)
    }

    @Test("ReviewState returns nil for invalid raw value")
    func reviewStateInvalidRawValue() {
        #expect(ReviewState(rawValue: "INVALID") == nil)
    }

    // MARK: - API Response Decoding

    @Test("GitHubPRResponse decodes from snake_case JSON")
    func decodePRResponse() throws {
        let json = """
        {
            "id": 1,
            "number": 42,
            "title": "Fix bug",
            "user": {"login": "alice", "avatar_url": "https://example.com/avatar"},
            "created_at": "2026-01-15T10:00:00Z",
            "html_url": "https://github.com/owner/repo/pull/42",
            "draft": false,
            "labels": [{"id": 1, "name": "bug", "color": "d73a4a"}]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(GitHubPRResponse.self, from: json)

        #expect(response.id == 1)
        #expect(response.number == 42)
        #expect(response.title == "Fix bug")
        #expect(response.user.login == "alice")
        #expect(response.user.avatarUrl == "https://example.com/avatar")
        #expect(response.createdAt == "2026-01-15T10:00:00Z")
        #expect(response.htmlUrl == "https://github.com/owner/repo/pull/42")
        #expect(response.draft == false)
        #expect(response.labels.count == 1)
        #expect(response.labels[0].name == "bug")
    }

    @Test("GitHubReviewResponse decodes from snake_case JSON")
    func decodeReviewResponse() throws {
        let json = """
        {
            "id": 5,
            "user": {"login": "bob", "avatar_url": "https://example.com/bob"},
            "state": "APPROVED"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(GitHubReviewResponse.self, from: json)

        #expect(response.id == 5)
        #expect(response.user.login == "bob")
        #expect(response.state == "APPROVED")
    }

    @Test("GitHubUserResponse decodes from snake_case JSON")
    func decodeUserResponse() throws {
        let json = """
        {
            "login": "carol",
            "avatar_url": "https://example.com/carol"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(GitHubUserResponse.self, from: json)

        #expect(response.login == "carol")
        #expect(response.avatarUrl == "https://example.com/carol")
    }
}
