import Foundation

nonisolated enum PullRequestMapper {
    static func map(response: GitHubPRResponse, reviews: [GitHubReviewResponse]) -> PullRequest {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdAt = formatter.date(from: response.createdAt)
            ?? ISO8601DateFormatter().date(from: response.createdAt)
            ?? Date()

        return PullRequest(
            id: response.id,
            number: response.number,
            title: response.title,
            authorLogin: response.user.login,
            authorAvatarURL: URL(string: response.user.avatarUrl),
            createdAt: createdAt,
            htmlURL: URL(string: response.htmlUrl) ?? URL(string: "https://github.com")!,
            isDraft: response.draft,
            labels: response.labels.map { PRLabel(id: $0.id, name: $0.name, color: $0.color) },
            reviews: reviews.map { review in
                PRReview(
                    id: review.id,
                    userLogin: review.user.login,
                    state: ReviewState(rawValue: review.state) ?? .commented
                )
            }
        )
    }
}
