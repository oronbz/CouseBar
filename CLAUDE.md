# CLAUDE.md

This file provides context for AI assistants working on this codebase.

## Project Overview

Cousebara is a macOS menu bar app that monitors GitHub Copilot premium interaction usage. It reads the OAuth token from `~/.config/github-copilot/apps.json` and polls the GitHub API for quota data.

## Architecture

- **`CousebaraApp.swift`** -- App entry point. Uses `MenuBarExtra` with `.window` style (popover). No `WindowGroup`, no Dock icon (`LSUIElement = YES`).
- **`CopilotService.swift`** -- `@Observable` service class. Reads token, calls `api.github.com/copilot_internal/user`, parses the `premium_interactions` quota snapshot. Auto-refreshes every 15 minutes via `Timer`.
- **`MenuBarLabel.swift`** -- Custom menu bar label: Copilot icon + compact color-coded progress bar. Handles normal and over-limit states.
- **`PopoverView.swift`** -- Popover content shown on click. Displays percentage, large progress bar, used/entitlement, remaining or overage, reset date, refresh and quit buttons.
- **`ContentView.swift`** -- Thin wrapper around `PopoverView` for SwiftUI previews.

## Key Design Decisions

- **No App Sandbox** -- The app needs to read `~/.config/github-copilot/apps.json` which is outside the sandbox. Since distribution is via Homebrew (not the Mac App Store), sandbox is disabled.
- **Deployment target: macOS 14.0** -- `MenuBarExtra` requires macOS 13+, `@Observable` requires macOS 14+. Set to 14.0 for broad compatibility.
- **Filesystem-synced Xcode project** (objectVersion 77) -- Files added to the `Cousebara/` directory are automatically included in the build. No need to manually edit `project.pbxproj` for new source files.
- **`@Observable` over `ObservableObject`** -- Modern approach, avoids `@Published` boilerplate.

## API Response Shape

The service focuses on `quota_snapshots.premium_interactions`:

```json
{
  "entitlement": 1000,
  "overage_count": 0,
  "overage_permitted": true,
  "percent_remaining": -54.099,
  "quota_remaining": -540.99,
  "remaining": -540,
  "unlimited": false
}
```

Negative `remaining` and `percent_remaining` values indicate over-usage.

## Build

```sh
xcodebuild -project Cousebara.xcodeproj -scheme Cousebara -configuration Debug build
```

## Release Process

1. Archive a Release build:
   ```sh
   xcodebuild -project Cousebara.xcodeproj -scheme Cousebara -configuration Release \
     -archivePath /tmp/Cousebara.xcarchive archive
   ```
2. Zip the app:
   ```sh
   cd /tmp/Cousebara.xcarchive/Products/Applications/
   ditto -c -k --sequesterRsrc --keepParent Cousebara.app /tmp/Cousebara.zip
   ```
3. Create a GitHub release:
   ```sh
   gh release create v1.x.0 /tmp/Cousebara.zip --repo oronbz/Cousebara --title "Cousebara v1.x.0"
   ```
4. Update `version` and `sha256` in the Homebrew tap formula at [`oronbz/homebrew-tap/Casks/cousebara.rb`](https://github.com/oronbz/homebrew-tap/blob/main/Casks/cousebara.rb).

## Distribution

Distributed via Homebrew Cask:

```sh
brew tap oronbz/tap
brew install --cask cousebara
```

The tap repo is at https://github.com/oronbz/homebrew-tap.
