import Foundation

nonisolated enum GitHubError: LocalizedError {
    case unauthorized
    case notFound(String)
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Invalid or expired GitHub token"
        case .notFound:
            return "Repository not found. Ensure your token has the `repo` scope for private repositories."
        case .httpError(let code):
            return "GitHub API error (HTTP \(code))"
        }
    }
}
