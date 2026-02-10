import Foundation

nonisolated enum FilterOption: String, CaseIterable, Sendable {
    case noReviews = "No Reviews"
    case notReviewedByMe = "Not Reviewed by Me"
    case allOpen = "All Open"
    case drafts = "Drafts"

    func apply(to pullRequests: [PullRequest], currentUser: String?) -> [PullRequest] {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentNonDraft = pullRequests.filter { !$0.isDraft && $0.createdAt > oneWeekAgo }

        switch self {
        case .noReviews:
            return recentNonDraft.filter { !$0.hasReviews }
        case .notReviewedByMe:
            guard let user = currentUser else { return recentNonDraft }
            return recentNonDraft.filter { pr in
                !pr.reviews.contains { review in
                    review.userLogin == user
                        && (review.state == .approved || review.state == .changesRequested)
                }
            }
        case .allOpen:
            return recentNonDraft
        case .drafts:
            return pullRequests.filter { $0.isDraft }
        }
    }
}
