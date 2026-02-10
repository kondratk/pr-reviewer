import Foundation

nonisolated struct PRReview: Identifiable, Sendable {
    let id: Int
    let userLogin: String
    let state: ReviewState
}
