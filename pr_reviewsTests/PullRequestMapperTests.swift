import Foundation
import Testing
@testable import pr_reviews

@Suite("PullRequestMapper")
struct PullRequestMapperTests {

    @Test("Maps basic PR fields correctly")
    func mapsBasicFields() {
        let response = TestData.makeGitHubPRResponse(
            id: 101,
            number: 7,
            title: "Add feature",
            login: "alice",
            draft: false
        )

        let result = PullRequestMapper.map(response: response, reviews: [])

        #expect(result.id == 101)
        #expect(result.number == 7)
        #expect(result.title == "Add feature")
        #expect(result.authorLogin == "alice")
        #expect(result.isDraft == false)
        #expect(result.reviews.isEmpty)
        #expect(result.labels.isEmpty)
    }

    @Test("Maps avatar URL")
    func mapsAvatarURL() {
        let response = TestData.makeGitHubPRResponse(
            avatarUrl: "https://avatars.githubusercontent.com/u/999"
        )

        let result = PullRequestMapper.map(response: response, reviews: [])

        #expect(result.authorAvatarURL == URL(string: "https://avatars.githubusercontent.com/u/999"))
    }

    @Test("Maps HTML URL with fallback")
    func mapsHtmlURL() {
        let response = TestData.makeGitHubPRResponse(
            htmlUrl: "https://github.com/org/repo/pull/1"
        )

        let result = PullRequestMapper.map(response: response, reviews: [])

        #expect(result.htmlURL == URL(string: "https://github.com/org/repo/pull/1"))
    }

    @Test("Parses ISO8601 date with fractional seconds")
    func parsesDateWithFractionalSeconds() {
        let response = TestData.makeGitHubPRResponse(
            createdAt: "2026-01-15T14:30:00.123Z"
        )

        let result = PullRequestMapper.map(response: response, reviews: [])

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expected = formatter.date(from: "2026-01-15T14:30:00.123Z")!

        #expect(result.createdAt == expected)
    }

    @Test("Parses ISO8601 date without fractional seconds")
    func parsesDateWithoutFractionalSeconds() {
        let response = TestData.makeGitHubPRResponse(
            createdAt: "2026-01-15T14:30:00Z"
        )

        let result = PullRequestMapper.map(response: response, reviews: [])

        let formatter = ISO8601DateFormatter()
        let expected = formatter.date(from: "2026-01-15T14:30:00Z")!

        #expect(result.createdAt == expected)
    }

    @Test("Maps labels correctly")
    func mapsLabels() {
        let labels = [
            GitHubLabelResponse(id: 1, name: "bug", color: "d73a4a"),
            GitHubLabelResponse(id: 2, name: "enhancement", color: "a2eeef"),
        ]
        let response = TestData.makeGitHubPRResponse(labels: labels)

        let result = PullRequestMapper.map(response: response, reviews: [])

        #expect(result.labels.count == 2)
        #expect(result.labels[0].name == "bug")
        #expect(result.labels[0].color == "d73a4a")
        #expect(result.labels[1].name == "enhancement")
    }

    @Test("Maps reviews with valid states")
    func mapsReviews() {
        let reviews = [
            TestData.makeGitHubReviewResponse(id: 1, login: "bob", state: "APPROVED"),
            TestData.makeGitHubReviewResponse(id: 2, login: "carol", state: "CHANGES_REQUESTED"),
        ]
        let response = TestData.makeGitHubPRResponse()

        let result = PullRequestMapper.map(response: response, reviews: reviews)

        #expect(result.reviews.count == 2)
        #expect(result.reviews[0].userLogin == "bob")
        #expect(result.reviews[0].state == .approved)
        #expect(result.reviews[1].userLogin == "carol")
        #expect(result.reviews[1].state == .changesRequested)
    }

    @Test("Maps unknown review state to commented")
    func mapsUnknownReviewState() {
        let reviews = [
            TestData.makeGitHubReviewResponse(id: 1, state: "UNKNOWN_STATE"),
        ]
        let response = TestData.makeGitHubPRResponse()

        let result = PullRequestMapper.map(response: response, reviews: reviews)

        #expect(result.reviews[0].state == .commented)
    }

    @Test("Maps draft PR")
    func mapsDraft() {
        let response = TestData.makeGitHubPRResponse(draft: true)

        let result = PullRequestMapper.map(response: response, reviews: [])

        #expect(result.isDraft == true)
    }
}
