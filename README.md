# PR Reviewer

A macOS menu bar application that monitors GitHub pull requests and helps you stay on top of code reviews. Built with SwiftUI and designed for teams using GitHub.

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Requirements](#requirements)
- [Getting Started](#getting-started)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Testing](#testing)
- [Contributing](#contributing)

## Features

- **Menu bar integration** -- lives in your macOS menu bar showing unreviewed PR count
- **Smart filtering** -- filter PRs by review status:
  - No Reviews: PRs with no substantive reviews
  - Not Reviewed by Me: PRs you haven't approved or requested changes on
  - All Open: All recent non-draft PRs
  - Drafts: Draft PRs only
- **Auto-refresh** -- polls for new PRs every 5 minutes
- **Review badges** -- see approval and change request counts at a glance
- **Token management** -- secure GitHub Personal Access Token storage with connection testing
- **One-click navigation** -- click any PR to open it in your browser

## Screenshots

*Menu bar app showing PR list with filter chips, review badges, and author info.*

## Requirements

- macOS 26.0 or later
- Xcode 26.0 or later
- A GitHub Personal Access Token with `repo` scope (for private repositories) or public access

## Getting Started

### 1. Clone the repository

```bash
git clone <repository-url>
cd pr-reviewer
```

### 2. Open in Xcode

```bash
open pr_reviews.xcodeproj
```

### 3. Build and run

Select the `pr_reviews` scheme and press `Cmd+R`. The app will appear in your menu bar.

### 4. Configure your GitHub token

1. Click the gear icon in the menu bar popover to open Settings
2. Enter your GitHub Personal Access Token
3. Click "Test Connection" to verify
4. Click "Save" to store the token and start fetching PRs

#### Creating a GitHub Personal Access Token

1. Go to [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Select the `repo` scope for private repositories (no scope needed for public repos)
4. Copy the generated token and paste it into the app's Settings

## Architecture

The app follows **SOLID principles** with a clean layered architecture:

```
┌─────────────────────────────────────────┐
│              Views (SwiftUI)            │
│   MenuBarView, SettingsView, PRRowView  │
├─────────────────────────────────────────┤
│            ViewModels (@Observable)      │
│   PRListViewModel, SettingsViewModel    │
├─────────────────────────────────────────┤
│         Protocols (Abstractions)        │
│  PRRepositoryProtocol                   │
│  GitHubAPIClientProtocol                │
│  SettingsStoreProtocol                  │
├─────────────────────────────────────────┤
│           Services (Implementations)    │
│  PRRepository, GitHubAPIClient,         │
│  SettingsStore                          │
├─────────────────────────────────────────┤
│          Models (Domain + API DTOs)     │
│  PullRequest, PRReview, PRLabel,        │
│  GitHubPRResponse, PullRequestMapper    │
└─────────────────────────────────────────┘
```

### Key Design Decisions

- **Dependency Inversion**: ViewModels depend on protocols, not concrete implementations. This makes the entire presentation layer testable with mock dependencies.
- **Single Responsibility**: Each file has one clear purpose. The original `GitHubService` god-class was split into `GitHubAPIClient` (networking), `SettingsStore` (persistence), `PRRepository` (data orchestration), and `PRListViewModel` (UI state).
- **DRY Filter Logic**: `FilterOption.apply(to:currentUser:)` centralizes all filtering logic in one place, eliminating the duplicated switch statements from the original code.
- **DI Container**: `DependencyContainer` wires all dependencies at the app entry point, making it easy to swap implementations.
- **Clean Domain Models**: `PullRequest` is a pure value type with no API coupling. Mapping from API responses is handled by `PullRequestMapper`.

## Project Structure

```
pr_reviews/
├── App/
│   ├── pr_reviewsApp.swift           # App entry point with MenuBarExtra
│   └── DependencyContainer.swift     # Wires all dependencies
│
├── Models/
│   ├── Domain/
│   │   ├── PullRequest.swift         # Core PR model
│   │   ├── PRLabel.swift             # Label model
│   │   ├── PRReview.swift            # Review model
│   │   ├── ReviewState.swift         # Review state enum
│   │   ├── FilterOption.swift        # Filter enum with strategy pattern
│   │   └── RepositoryConfig.swift    # Repository configuration
│   ├── API/
│   │   ├── GitHubPRResponse.swift    # Codable API response
│   │   ├── GitHubUserResponse.swift  # Codable API response
│   │   ├── GitHubLabelResponse.swift # Codable API response
│   │   └── GitHubReviewResponse.swift# Codable API response
│   └── Mappers/
│       └── PullRequestMapper.swift   # API response -> Domain model
│
├── Services/
│   ├── Networking/
│   │   ├── GitHubAPIClient.swift     # Protocol + HTTP implementation
│   │   └── GitHubError.swift         # Typed API errors
│   ├── Persistence/
│   │   └── SettingsStore.swift       # Protocol + UserDefaults implementation
│   └── Repository/
│       └── PRRepository.swift        # Protocol + data orchestration
│
├── ViewModels/
│   ├── PRListViewModel.swift         # PR list state management
│   └── SettingsViewModel.swift       # Settings state management
│
├── Views/
│   ├── MenuBarView.swift             # Main menu bar popover
│   ├── SettingsView.swift            # Token configuration form
│   ├── PRRowView.swift               # Single PR row component
│   └── FilterChipView.swift          # Filter chip component
│
├── Extensions/
│   ├── Color+Hex.swift               # Color from hex string
│   └── Date+Formatting.swift         # Relative date formatting
│
├── Assets.xcassets/                  # App icons and colors
└── pr_reviews.entitlements           # App Sandbox + network access

pr_reviewsTests/
├── Mocks/
│   ├── MockAPIClient.swift           # Mock for GitHubAPIClientProtocol
│   ├── MockRepository.swift          # Mock for PRRepositoryProtocol
│   └── MockSettingsStore.swift       # Mock for SettingsStoreProtocol
├── Helpers/
│   └── TestData.swift                # Factory methods for test fixtures
├── PullRequestMapperTests.swift      # Mapping logic tests
├── FilterOptionTests.swift           # Filter strategy tests
├── PRListViewModelTests.swift        # PR list ViewModel tests
├── SettingsViewModelTests.swift      # Settings ViewModel tests
├── PRRepositoryTests.swift           # Repository layer tests
├── SettingsStoreTests.swift          # Persistence layer tests
└── GitHubAPIClientTests.swift        # API client and model tests
```

## Configuration

The app currently monitors the `surgeventures/fresha-android` repository. To change the target repository, update the `repositoryOwner` and `repositoryName` properties in `SettingsStore.swift`.

### App Sandbox

The app runs in a sandboxed environment with the following entitlements:

- `com.apple.security.app-sandbox`: Enabled
- `com.apple.security.network.client`: Outbound network access for GitHub API calls

## Testing

The project uses **Swift Testing** framework with comprehensive coverage across all layers.

### Running Tests

```bash
# Run all tests from Xcode
Cmd+U

# Or from the command line
xcodebuild test \
  -project pr_reviews.xcodeproj \
  -scheme pr_reviews \
  -destination 'platform=macOS'
```

### Test Coverage

| Layer | Test File | Tests |
|-------|-----------|-------|
| Models/Mapping | `PullRequestMapperTests` | Field mapping, date parsing, label/review mapping, unknown states |
| Models/Filtering | `FilterOptionTests` | All 4 filter strategies, edge cases, `hasReviews` logic |
| ViewModels | `PRListViewModelTests` | Fetch, filter, error handling, property delegation |
| ViewModels | `SettingsViewModelTests` | Save, test connection, callbacks, init state |
| Services | `PRRepositoryTests` | Data orchestration with mock API client |
| Services | `SettingsStoreTests` | UserDefaults persistence, init, nil handling |
| Services | `GitHubAPIClientTests` | Error types, ReviewState, JSON decoding |

### Testing Approach

- **Protocol-based mocking**: All service boundaries use protocols, enabling lightweight mock implementations without third-party frameworks
- **Arrange-Act-Assert**: Every test follows a clear setup, execution, and verification structure
- **Factory test data**: `TestData` enum provides factory methods for consistent test fixtures
- **Isolated UserDefaults**: `SettingsStoreTests` uses per-test `UserDefaults` suites to prevent test pollution

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes following the existing architecture patterns
4. Add tests for new functionality
5. Ensure all tests pass (`Cmd+U`)
6. Submit a pull request
