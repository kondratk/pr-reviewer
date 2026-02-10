import Foundation
@testable import pr_reviews

enum TestData {
    static func makePullRequest(
        id: Int = 1,
        number: Int = 42,
        title: String = "Fix bug",
        authorLogin: String = "author",
        createdAt: Date = Date(),
        isDraft: Bool = false,
        labels: [PRLabel] = [],
        reviews: [PRReview] = []
    ) -> PullRequest {
        PullRequest(
            id: id,
            number: number,
            title: title,
            authorLogin: authorLogin,
            authorAvatarURL: URL(string: "https://avatars.githubusercontent.com/u/1"),
            createdAt: createdAt,
            htmlURL: URL(string: "https://github.com/owner/repo/pull/\(number)")!,
            isDraft: isDraft,
            labels: labels,
            reviews: reviews
        )
    }

    static func makeReview(
        id: Int = 1,
        userLogin: String = "reviewer",
        state: ReviewState = .approved
    ) -> PRReview {
        PRReview(id: id, userLogin: userLogin, state: state)
    }

    static func makeLabel(
        id: Int = 1,
        name: String = "bug",
        color: String = "d73a4a"
    ) -> PRLabel {
        PRLabel(id: id, name: name, color: color)
    }

    static func makeGitHubPRResponse(
        id: Int = 1,
        number: Int = 42,
        title: String = "Fix bug",
        login: String = "author",
        avatarUrl: String = "https://avatars.githubusercontent.com/u/1",
        createdAt: String = "2026-02-10T10:00:00Z",
        htmlUrl: String = "https://github.com/owner/repo/pull/42",
        draft: Bool = false,
        labels: [GitHubLabelResponse] = []
    ) -> GitHubPRResponse {
        GitHubPRResponse(
            id: id,
            number: number,
            title: title,
            user: GitHubUserResponse(login: login, avatarUrl: avatarUrl),
            createdAt: createdAt,
            htmlUrl: htmlUrl,
            draft: draft,
            labels: labels
        )
    }

    static func makeGitHubReviewResponse(
        id: Int = 1,
        login: String = "reviewer",
        state: String = "APPROVED"
    ) -> GitHubReviewResponse {
        GitHubReviewResponse(
            id: id,
            user: GitHubUserResponse(login: login, avatarUrl: "https://avatars.githubusercontent.com/u/2"),
            state: state
        )
    }
}
