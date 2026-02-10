import SwiftUI

@main
struct pr_reviewsApp: App {
    @State private var gitHubService = GitHubService()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(gitHubService)
        } label: {
            Image(systemName: "arrow.triangle.pull")
            Text("\(gitHubService.unreviewedCount)")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(gitHubService)
        }
    }
}
