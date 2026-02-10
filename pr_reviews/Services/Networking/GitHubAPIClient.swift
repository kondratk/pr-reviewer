import Foundation

nonisolated protocol GitHubAPIClientProtocol: Sendable {
    func fetch<T: Decodable & Sendable>(_ path: String, token: String) async throws -> T
}

nonisolated final class GitHubAPIClient: GitHubAPIClientProtocol {
    private let session: URLSession
    private let baseURL: String

    init(session: URLSession = .shared, baseURL: String = "https://api.github.com") {
        self.session = session
        self.baseURL = baseURL
    }

    func fetch<T: Decodable & Sendable>(_ path: String, token: String) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            switch httpResponse.statusCode {
            case 401: throw GitHubError.unauthorized
            case 404: throw GitHubError.notFound(path)
            default:  throw GitHubError.httpError(httpResponse.statusCode)
            }
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}
