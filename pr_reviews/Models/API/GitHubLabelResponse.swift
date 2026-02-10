import Foundation

nonisolated struct GitHubLabelResponse: Codable, Sendable {
    let id: Int
    let name: String
    let color: String
}
