# CouseBar

A macOS menu bar app for monitoring GitHub Copilot premium interaction usage.

## Features

- Menu bar icon with color-coded progress bar (green / yellow / orange / red overshoot)
- Over-usage visualization: red overshoot portion extends beyond the bar when over-limit
- Click to open a popover with detailed usage stats
- Auto-refresh every 15 minutes + manual refresh on click
- Shows used/entitlement, remaining (or "over by X"), and quota reset date
- No Dock icon -- lives entirely in the menu bar

## Install

```sh
brew tap oronbz/tap
brew install --cask cousebar
```

Or download `CouseBar.zip` from the [latest release](https://github.com/oronbz/CouseBar/releases/latest), unzip, and move `CouseBar.app` to `/Applications`.

## Requirements

- macOS 14.0 (Sonoma) or later
- A GitHub Copilot subscription with a token configured at `~/.config/github-copilot/apps.json` (automatically created by VS Code, Neovim, or JetBrains Copilot plugins)

## How It Works

CouseBar reads your Copilot OAuth token from `~/.config/github-copilot/apps.json` and calls the `https://api.github.com/copilot_internal/user` endpoint to fetch your `premium_interactions` quota snapshot. No additional login is required.

### Progress Bar Colors

| Usage     | Color          |
|-----------|----------------|
| 0-60%     | Green          |
| 60-85%    | Yellow         |
| 85-100%   | Orange         |
| Over 100% | Orange + Red overshoot |

## Building from Source

1. Clone the repo
2. Open `CouseBar.xcodeproj` in Xcode
3. Build and run (Cmd+R)

## Releasing a New Version

1. Build a Release archive:
   ```sh
   xcodebuild -project CouseBar.xcodeproj -scheme CouseBar -configuration Release \
     -archivePath /tmp/CouseBar.xcarchive archive
   ```
2. Zip the `.app`:
   ```sh
   cd /tmp/CouseBar.xcarchive/Products/Applications/
   ditto -c -k --sequesterRsrc --keepParent CouseBar.app /tmp/CouseBar.zip
   ```
3. Create a GitHub release:
   ```sh
   gh release create v1.x.0 /tmp/CouseBar.zip --repo oronbz/CouseBar --title "CouseBar v1.x.0"
   ```
4. Update the Homebrew tap formula at [`oronbz/homebrew-tap`](https://github.com/oronbz/homebrew-tap):
   - Update `version` and `sha256` in `Casks/cousebar.rb`
   - `sha256` can be computed with `shasum -a 256 /tmp/CouseBar.zip`
5. Users upgrade with `brew upgrade --cask cousebar`
