import Combine
import SwiftUI

struct MenuBarView: View {
    @Environment(GitHubService.self) var service

    let timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("fresha-android")
                        .font(.headline)
                    Text("surgeventures")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if service.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }

                Button(action: { Task { await service.fetchPullRequests() } }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(service.isLoading)

                SettingsLink {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Divider()

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(FilterOption.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            count: countForFilter(filter),
                            isSelected: service.activeFilter == filter
                        ) {
                            service.activeFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)

            Divider()

            // Content
            if service.isLoading && service.pullRequests.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading pull requests...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if let error = service.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if service.token.isEmpty {
                        SettingsLink {
                            Text("Open Settings")
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Retry") {
                            Task { await service.fetchPullRequests() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if service.filteredPRs.isEmpty {
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
                        ForEach(service.filteredPRs) { pr in
                            PRRow(pr: pr)
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
        }
        .frame(width: 380)
        .task {
            if service.pullRequests.isEmpty {
                await service.fetchCurrentUser()
                await service.fetchPullRequests()
            }
        }
        .onReceive(timer) { _ in
            Task { await service.fetchPullRequests() }
        }
    }

    private func countForFilter(_ filter: FilterOption) -> Int {
        service.count(for: filter)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                Text("\(count)")
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PR Row

struct PRRow: View {
    let pr: PullRequest

    var body: some View {
        Button(action: {
            NSWorkspace.shared.open(pr.htmlURL)
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text("#\(pr.number)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(pr.title)
                        .font(.system(.body, weight: .medium))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    if pr.isDraft {
                        Text("Draft")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 6) {
                    AsyncImage(url: pr.authorAvatarURL) { image in
                        image.resizable()
                    } placeholder: {
                        Circle().fill(Color.secondary.opacity(0.3))
                    }
                    .frame(width: 16, height: 16)
                    .clipShape(Circle())

                    Text(pr.authorLogin)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\u{00B7}")
                        .foregroundColor(.secondary)

                    Text(pr.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    reviewBadges
                }

                if !pr.labels.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(pr.labels) { label in
                            Text(label.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: label.color).opacity(0.3))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var reviewBadges: some View {
        let approvals = pr.reviews.filter { $0.state == .approved }.count
        let changes = pr.reviews.filter { $0.state == .changesRequested }.count

        if approvals > 0 {
            HStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("\(approvals)")
            }
            .font(.caption)
        }

        if changes > 0 {
            HStack(spacing: 2) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("\(changes)")
            }
            .font(.caption)
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (128, 128, 128)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
