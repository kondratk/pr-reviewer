import SwiftUI

@Observable
class GitHubService {
    var token: String = UserDefaults.standard.string(forKey: "github_token") ?? "" {
        didSet { UserDefaults.standard.set(token, forKey: "github_token") }
    }
    var pullRequests: [PullRequest] = []
    var isLoading = false
    var errorMessage: String?
    var currentUser: String? = UserDefaults.standard.string(forKey: "github_user")
    var activeFilter: FilterOption = .noReviews

    private let owner = "surgeventures"
    private let repo = "fresha-android"

    private var recentNonDraftPRs: [PullRequest] {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return pullRequests.filter { !$0.isDraft && $0.createdAt > oneWeekAgo }
    }

    var filteredPRs: [PullRequest] {
        switch activeFilter {
        case .noReviews:
            return recentNonDraftPRs.filter { !$0.hasReviews }
        case .notReviewedByMe:
            guard let user = currentUser else { return recentNonDraftPRs }
            return recentNonDraftPRs.filter { pr in
                !pr.reviews.contains { review in
                    review.userLogin == user
                        && (review.state == .approved || review.state == .changesRequested)
                }
            }
        case .allOpen:
            return recentNonDraftPRs
        case .drafts:
            return pullRequests.filter { $0.isDraft }
        }
    }

    var unreviewedCount: Int {
        filteredPRs.count
    }

    func count(for filter: FilterOption) -> Int {
        switch filter {
        case .noReviews:
            return recentNonDraftPRs.filter { !$0.hasReviews }.count
        case .notReviewedByMe:
            guard let user = currentUser else { return recentNonDraftPRs.count }
            return recentNonDraftPRs.filter { pr in
                !pr.reviews.contains { review in
                    review.userLogin == user
                        && (review.state == .approved || review.state == .changesRequested)
                }
            }.count
        case .allOpen:
            return recentNonDraftPRs.count
        case .drafts:
            return pullRequests.filter { $0.isDraft }.count
        }
    }

    func fetchPullRequests() async {
        guard !token.isEmpty else {
            errorMessage = "GitHub token not configured. Open Settings to add your token."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let prs: [GitHubPRResponse] = try await fetchAPI(
                "/repos/\(owner)/\(repo)/pulls?state=open&per_page=100")

            var results: [PullRequest] = []
            for pr in prs {
                let reviews: [GitHubReviewResponse] = try await fetchAPI(
                    "/repos/\(owner)/\(repo)/pulls/\(pr.number)/reviews")
                results.append(PullRequest(from: pr, reviews: reviews))
            }

            pullRequests = results
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func fetchCurrentUser() async {
        guard !token.isEmpty else { return }
        do {
            let user: GitHubUserResponse = try await fetchAPI("/user")
            currentUser = user.login
            UserDefaults.standard.set(user.login, forKey: "github_user")
        } catch {
            // Silently fail — user info is optional
        }
    }

    func testToken(_ tokenToTest: String) async -> String? {
        do {
            let user: GitHubUserResponse = try await fetchAPI("/user", withToken: tokenToTest)
            return user.login
        } catch {
            return nil
        }
    }

    private func fetchAPI<T: Decodable>(
        _ path: String, withToken tokenOverride: String? = nil
    ) async throws -> T {
        let tokenToUse = tokenOverride ?? token
        guard let url = URL(string: "https://api.github.com\(path)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(tokenToUse)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw GitHubError.unauthorized
            }
            if httpResponse.statusCode == 404 {
                throw GitHubError.notFound(path)
            }
            throw GitHubError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}

enum GitHubError: LocalizedError {
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
