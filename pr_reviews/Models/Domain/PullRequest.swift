import Foundation

nonisolated struct PullRequest: Identifiable, Sendable {
    let id: Int
    let number: Int
    let title: String
    let authorLogin: String
    let authorAvatarURL: URL?
    let createdAt: Date
    let htmlURL: URL
    let isDraft: Bool
    let labels: [PRLabel]
    var reviews: [PRReview]

    var hasReviews: Bool {
        reviews.contains { $0.state != .commented && $0.state != .pending }
    }
}
