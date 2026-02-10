import SwiftUI

struct PRRowView: View {
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
