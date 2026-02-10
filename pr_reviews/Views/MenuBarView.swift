import Combine
import SwiftUI

struct MenuBarView: View {
    @Environment(PRListViewModel.self) var viewModel

    let timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            filterSection
            Divider()
            contentSection
        }
        .frame(width: 380)
        .task {
            if viewModel.pullRequests.isEmpty {
                await viewModel.fetchCurrentUser()
                await viewModel.fetchPullRequests()
            }
        }
        .onReceive(timer) { _ in
            Task { await viewModel.fetchPullRequests() }
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.repositoryName)
                    .font(.headline)
                Text(viewModel.repositoryOwner)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            }

            Button(action: { Task { await viewModel.fetchPullRequests() } }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.isLoading)

            SettingsLink {
                Image(systemName: "gear")
            }
            .buttonStyle(.borderless)
        }
        .padding()
    }

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(FilterOption.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        count: viewModel.count(for: filter),
                        isSelected: viewModel.activeFilter == filter
                    ) {
                        viewModel.activeFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var contentSection: some View {
        if viewModel.isLoading && viewModel.pullRequests.isEmpty {
            VStack(spacing: 8) {
                ProgressView()
                Text("Loading pull requests...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        } else if let error = viewModel.errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if viewModel.token.isEmpty {
                    SettingsLink {
                        Text("Open Settings")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Retry") {
                        Task { await viewModel.fetchPullRequests() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        } else if viewModel.filteredPRs.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
                Text("No PRs match this filter")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredPRs) { pr in
                        PRRowView(pr: pr)
                        Divider()
                    }
                }
            }
            .frame(maxHeight: 400)
        }
    }
}
