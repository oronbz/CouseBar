#!/bin/bash
set -euo pipefail

# ─── Configuration ──────────────────────────────────────────────────────────────
REPO="oronbz/Cousebara"
TAP_REPO="oronbz/homebrew-tap"
CASK_FILE="Casks/cousebara.rb"
PROJECT="Cousebara.xcodeproj"
SCHEME="Cousebara"
ARCHIVE_PATH="/tmp/Cousebara.xcarchive"
ZIP_PATH="/tmp/Cousebara.zip"
TAP_CLONE="/tmp/homebrew-tap-release"

# ─── Helpers ────────────────────────────────────────────────────────────────────
red()   { printf '\033[1;31m%s\033[0m\n' "$*"; }
green() { printf '\033[1;32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

die() { red "Error: $*" >&2; exit 1; }

cleanup() {
    rm -rf "$ARCHIVE_PATH" "$ZIP_PATH" "$TAP_CLONE"
}

# ─── Preflight checks ──────────────────────────────────────────────────────────
command -v gh        >/dev/null 2>&1 || die "gh CLI is required (brew install gh)"
command -v xcodebuild >/dev/null 2>&1 || die "xcodebuild is required (install Xcode)"
command -v ditto     >/dev/null 2>&1 || die "ditto is required"

[[ -f "$PROJECT/project.pbxproj" ]] || die "Run this script from the project root"

if [[ -n "$(git status --porcelain)" ]]; then
    die "Working tree is not clean. Commit or stash changes first."
fi

# ─── Determine version ──────────────────────────────────────────────────────────
CURRENT_VERSION=$(grep -m1 'MARKETING_VERSION = ' "$PROJECT/project.pbxproj" \
    | sed 's/.*= //; s/;.*//' | tr -d '[:space:]')

if [[ -n "${1:-}" ]]; then
    NEW_VERSION="$1"
else
    bold "Current version: $CURRENT_VERSION"
    printf "New version: "
    read -r NEW_VERSION
fi

[[ -n "$NEW_VERSION" ]] || die "Version cannot be empty"
[[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Version must be semver (e.g. 1.5.0)"
[[ "$NEW_VERSION" != "$CURRENT_VERSION" ]] || die "New version is the same as current ($CURRENT_VERSION)"

bold "Releasing v$NEW_VERSION (current: $CURRENT_VERSION)"
echo

# ─── Step 1: Bump version in source files ───────────────────────────────────────
bold "[1/7] Bumping version to $NEW_VERSION..."

# project.pbxproj — only the app target lines (matched by surrounding context)
sed -i '' "s/MARKETING_VERSION = $CURRENT_VERSION;/MARKETING_VERSION = $NEW_VERSION;/g" \
    "$PROJECT/project.pbxproj"

# VersionClient.swift — preview value
sed -i '' "s/currentVersion: { \"$CURRENT_VERSION\" }/currentVersion: { \"$NEW_VERSION\" }/" \
    Cousebara/Dependencies/VersionClient.swift

sed -i '' "s|tagName: \"v$CURRENT_VERSION\"|tagName: \"v$NEW_VERSION\"|" \
    Cousebara/Dependencies/VersionClient.swift

sed -i '' "s|releases/tag/v$CURRENT_VERSION|releases/tag/v$NEW_VERSION|" \
    Cousebara/Dependencies/VersionClient.swift

# PopoverView.swift — preview helper
sed -i '' "s/currentVersion: \"$CURRENT_VERSION\"/currentVersion: \"$NEW_VERSION\"/g" \
    Cousebara/Features/Popover/PopoverView.swift

green "  Version bumped in source files"

# ─── Step 2: Run tests ─────────────────────────────────────────────────────────
bold "[2/7] Running tests..."

xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination 'platform=macOS' \
    -skipMacroValidation \
    CODE_SIGNING_ALLOWED=NO \
    -quiet \
    || die "Tests failed. Fix them before releasing."

green "  All tests passed"

# ─── Step 3: Commit and push ───────────────────────────────────────────────────
bold "[3/7] Committing and pushing..."

git add -A
git commit -m "Bump version to $NEW_VERSION"
git push

green "  Pushed to origin/main"

# ─── Step 4: Build Release archive ─────────────────────────────────────────────
bold "[4/7] Building Release archive..."

cleanup

xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    archive \
    -quiet \
    || die "Archive build failed"

green "  Archive built"

# ─── Step 5: Zip and compute sha256 ────────────────────────────────────────────
bold "[5/7] Creating zip..."

ditto -c -k --sequesterRsrc --keepParent \
    "$ARCHIVE_PATH/Products/Applications/Cousebara.app" \
    "$ZIP_PATH"

SHA256=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')

green "  Zip created (sha256: $SHA256)"

# ─── Step 6: Create GitHub release ─────────────────────────────────────────────
bold "[6/7] Creating GitHub release v$NEW_VERSION..."

gh release create "v$NEW_VERSION" "$ZIP_PATH" \
    --repo "$REPO" \
    --title "Cousebara v$NEW_VERSION" \
    --generate-notes

RELEASE_URL="https://github.com/$REPO/releases/tag/v$NEW_VERSION"
green "  Release created: $RELEASE_URL"

# ─── Step 7: Update Homebrew tap ───────────────────────────────────────────────
bold "[7/7] Updating Homebrew tap..."

git clone --depth 1 "git@github.com:$TAP_REPO.git" "$TAP_CLONE" 2>/dev/null

CASK="$TAP_CLONE/$CASK_FILE"
[[ -f "$CASK" ]] || die "Cask file not found at $CASK"

# Read the old version from the cask to do a precise replacement
OLD_CASK_VERSION=$(grep -m1 'version "' "$CASK" | sed 's/.*version "//; s/".*//')

sed -i '' "s/version \"$OLD_CASK_VERSION\"/version \"$NEW_VERSION\"/" "$CASK"

OLD_SHA=$(grep -m1 'sha256 "' "$CASK" | sed 's/.*sha256 "//; s/".*//')
sed -i '' "s/sha256 \"$OLD_SHA\"/sha256 \"$SHA256\"/" "$CASK"

(
    cd "$TAP_CLONE"
    git add -A
    git commit -m "Update cousebara to $NEW_VERSION"
    git push
)

green "  Homebrew tap updated"

# ─── Done ───────────────────────────────────────────────────────────────────────
cleanup

echo
green "========================================="
green "  Released Cousebara v$NEW_VERSION"
green "========================================="
echo
echo "  GitHub:   $RELEASE_URL"
echo "  Homebrew: brew update && brew upgrade --cask cousebara"
echo
