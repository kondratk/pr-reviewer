import Foundation

nonisolated struct GitHubReviewResponse: Codable, Sendable {
    let id: Int
    let user: GitHubUserResponse
    let state: String
}
