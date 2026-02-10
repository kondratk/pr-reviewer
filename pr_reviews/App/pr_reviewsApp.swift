import SwiftUI

@main
struct pr_reviewsApp: App {
    @State private var container = DependencyContainer()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(container.prListViewModel)
        } label: {
            Image(systemName: "arrow.triangle.pull")
            Text("\(container.prListViewModel.unreviewedCount)")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(container.settingsViewModel)
        }
    }
}
