import SwiftUI

@main
struct pr_reviewsApp: App {
    @State private var container = DependencyContainer()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(container.multiRepoViewModel)
        } label: {
            Image(systemName: "arrow.triangle.pull")
            Text("\(container.multiRepoViewModel.totalUnreviewedCount)")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(container.settingsViewModel)
        }
    }
}
