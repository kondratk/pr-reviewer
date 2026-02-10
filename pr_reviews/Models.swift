import Foundation

// MARK: - App Models

struct PullRequest: Identifiable {
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

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    init(from response: GitHubPRResponse, reviews: [GitHubReviewResponse]) {
        self.id = response.id
        self.number = response.number
        self.title = response.title
        self.authorLogin = response.user.login
        self.authorAvatarURL = URL(string: response.user.avatarUrl)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.createdAt = formatter.date(from: response.createdAt)
            ?? ISO8601DateFormatter().date(from: response.createdAt)
            ?? Date()

        self.htmlURL = URL(string: response.htmlUrl) ?? URL(string: "https://github.com")!
        self.isDraft = response.draft
        self.labels = response.labels.map { PRLabel(id: $0.id, name: $0.name, color: $0.color) }
        self.reviews = reviews.map { review in
            PRReview(
                id: review.id,
                userLogin: review.user.login,
                state: ReviewState(rawValue: review.state) ?? .commented
            )
        }
    }
}

struct PRLabel: Identifiable {
    let id: Int
    let name: String
    let color: String
}

struct PRReview: Identifiable {
    let id: Int
    let userLogin: String
    let state: ReviewState
}

enum ReviewState: String {
    case approved = "APPROVED"
    case changesRequested = "CHANGES_REQUESTED"
    case commented = "COMMENTED"
    case dismissed = "DISMISSED"
    case pending = "PENDING"
}

enum FilterOption: String, CaseIterable {
    case noReviews = "No Reviews"
    case notReviewedByMe = "Not Reviewed by Me"
    case allOpen = "All Open"
    case drafts = "Drafts"
}

// MARK: - GitHub API Response Models

struct GitHubPRResponse: Codable {
    let id: Int
    let number: Int
    let title: String
    let user: GitHubUserResponse
    let createdAt: String
    let htmlUrl: String
    let draft: Bool
    let labels: [GitHubLabelResponse]
}

struct GitHubUserResponse: Codable {
    let login: String
    let avatarUrl: String
}

struct GitHubLabelResponse: Codable {
    let id: Int
    let name: String
    let color: String
}

struct GitHubReviewResponse: Codable {
    let id: Int
    let user: GitHubUserResponse
    let state: String
}
