import Foundation

nonisolated struct GitHubPRResponse: Codable, Sendable {
    let id: Int
    let number: Int
    let title: String
    let user: GitHubUserResponse
    let createdAt: String
    let htmlUrl: String
    let draft: Bool
    let labels: [GitHubLabelResponse]
}
