import Foundation

struct RepositoryConfig: Codable, Identifiable, Hashable, Equatable, Sendable {
    let owner: String
    let name: String

    var id: String { "\(owner)/\(name)" }
    var displayName: String { "\(owner)/\(name)" }
}
