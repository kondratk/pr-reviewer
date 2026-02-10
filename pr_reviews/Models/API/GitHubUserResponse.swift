import Foundation

nonisolated struct GitHubUserResponse: Codable, Sendable {
    let login: String
    let avatarUrl: String
}
