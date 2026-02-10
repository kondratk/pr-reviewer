import Foundation
import Testing
@testable import pr_reviews

@Suite("FilterOption")
struct FilterOptionTests {

    // MARK: - Test Data

    private func recentDate(daysAgo: Int = 1) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
    }

    private func oldDate() -> Date {
        Calendar.current.date(byAdding: .day, value: -14, to: Date())!
    }

    // MARK: - No Reviews Filter

    @Test("noReviews returns recent non-draft PRs without reviews")
    func noReviewsFilter() {
        let prs = [
            TestData.makePullRequest(id: 1, createdAt: recentDate(), reviews: []),
            TestData.makePullRequest(id: 2, createdAt: recentDate(), reviews: [
                TestData.makeReview(state: .approved),
            ]),
            TestData.makePullRequest(id: 3, createdAt: recentDate(), isDraft: true, reviews: []),
        ]

        let result = FilterOption.noReviews.apply(to: prs, currentUser: nil)

        #expect(result.count == 1)
        #expect(result[0].id == 1)
    }

    @Test("noReviews excludes PRs with only comment reviews")
    func noReviewsIncludesCommentOnlyPRs() {
        let prs = [
            TestData.makePullRequest(id: 1, createdAt: recentDate(), reviews: [
                TestData.makeReview(state: .commented),
            ]),
        ]

        let result = FilterOption.noReviews.apply(to: prs, currentUser: nil)

        #expect(result.count == 1)
    }

    @Test("noReviews excludes old PRs")
    func noReviewsExcludesOld() {
        let prs = [
            TestData.makePullRequest(id: 1, createdAt: oldDate(), reviews: []),
        ]

        let result = FilterOption.noReviews.apply(to: prs, currentUser: nil)

        #expect(result.isEmpty)
    }

    // MARK: - Not Reviewed By Me Filter

    @Test("notReviewedByMe returns PRs not reviewed by current user")
    func notReviewedByMe() {
        let prs = [
            TestData.makePullRequest(id: 1, createdAt: recentDate(), reviews: [
                TestData.makeReview(userLogin: "other", state: .approved),
            ]),
            TestData.makePullRequest(id: 2, createdAt: recentDate(), reviews: [
                TestData.makeReview(userLogin: "me", state: .approved),
            ]),
        ]

        let result = FilterOption.notReviewedByMe.apply(to: prs, currentUser: "me")

        #expect(result.count == 1)
        #expect(result[0].id == 1)
    }

    @Test("notReviewedByMe includes PRs where user only commented")
    func notReviewedByMeIncludesCommented() {
        let prs = [
            TestData.makePullRequest(id: 1, createdAt: recentDate(), reviews: [
                TestData.makeReview(userLogin: "me", state: .commented),
            ]),
        ]

        let result = FilterOption.notReviewedByMe.apply(to: prs, currentUser: "me")

        #expect(result.count == 1)
    }

    @Test("notReviewedByMe excludes PRs where user requested changes")
    func notReviewedByMeExcludesChangesRequested() {
        let prs = [
            TestData.makePullRequest(id: 1, createdAt: recentDate(), reviews: [
                TestData.makeReview(userLogin: "me", state: .changesRequested),
            ]),
        ]

        let result = FilterOption.notReviewedByMe.apply(to: prs, currentUser: "me")

        #expect(result.isEmpty)
    }

    @Test("notReviewedByMe returns all recent non-drafts when user is nil")
    func notReviewedByMeNilUser() {
        let prs = [
            TestData.makePullRequest(id: 1, createdAt: recentDate()),
            TestData.makePullRequest(id: 2, createdAt: recentDate()),
        ]

        let result = FilterOption.notReviewedByMe.apply(to: prs, currentUser: nil)

        #expect(result.count == 2)
    }

    // MARK: - All Open Filter

    @Test("allOpen returns all recent non-draft PRs")
    func allOpenFilter() {
        let prs = [
            TestData.makePullRequest(id: 1, createdAt: recentDate()),
            TestData.makePullRequest(id: 2, createdAt: recentDate(), isDraft: true),
            TestData.makePullRequest(id: 3, createdAt: oldDate()),
        ]

        let result = FilterOption.allOpen.apply(to: prs, currentUser: nil)

        #expect(result.count == 1)
        #expect(result[0].id == 1)
    }

    // MARK: - Drafts Filter

    @Test("drafts returns only draft PRs regardless of age")
    func draftsFilter() {
        let prs = [
            TestData.makePullRequest(id: 1, createdAt: recentDate(), isDraft: false),
            TestData.makePullRequest(id: 2, createdAt: recentDate(), isDraft: true),
            TestData.makePullRequest(id: 3, createdAt: oldDate(), isDraft: true),
        ]

        let result = FilterOption.drafts.apply(to: prs, currentUser: nil)

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.isDraft })
    }

    // MARK: - Edge Cases

    @Test("All filters handle empty input")
    func emptyInput() {
        for filter in FilterOption.allCases {
            let result = filter.apply(to: [], currentUser: "me")
            #expect(result.isEmpty)
        }
    }

    @Test("hasReviews is false for pending-only reviews")
    func hasReviewsPendingOnly() {
        let pr = TestData.makePullRequest(reviews: [
            TestData.makeReview(state: .pending),
        ])

        #expect(pr.hasReviews == false)
    }

    @Test("hasReviews is true for approved review")
    func hasReviewsApproved() {
        let pr = TestData.makePullRequest(reviews: [
            TestData.makeReview(state: .approved),
        ])

        #expect(pr.hasReviews == true)
    }
}
