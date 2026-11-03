# Releasing terminal-mac

The customer package contains precompiled signed apps and a user-local installer. Customers do not need Swift, Xcode, Homebrew, or a separately downloaded helper. macOS itself is fetched from Apple on first run, rather than bundled into the CLI archive.

## Commands

```sh
# Local-only ad-hoc package:
VERSION=0.2.0 BUILD_NUMBER=4 bash scripts/release.sh --local

# Developer ID signed candidate; no application upload:
VERSION=0.2.0 BUILD_NUMBER=4 bash scripts/release.sh --signed-local

# Production-sign, upload to Apple for notarization, staple, assess and package:
VERSION=0.2.0 BUILD_NUMBER=4 bash scripts/release.sh
```

Increment the positive integer `BUILD_NUMBER` for each build. `VERSION` uses `major.minor.patch`. Archives are immutable; the scripts refuse to replace an existing release with the same version/build/mode. Local and signed-local candidates are not notarized public releases.

Public defaults in `scripts/release-config.sh`:

- Certificate: the first `Developer ID Application` identity in your Keychain, or `SIGN_IDENTITY`.
- Notary Keychain profile: `NOTARY_PROFILE`, created once with `xcrun notarytool store-credentials PROFILE`.
- Host bundle: `dev.terminal-mac.host`; guest bundle: `dev.terminal-mac.guest`.
- Architecture: arm64; minimum macOS: 14.
- Artifacts: `dist/releases/terminal-mac-VERSION-BUILD-macos-arm64.zip` and `.zip.sha256` (local candidates have a mode suffix).

Override `SIGN_IDENTITY` / `NOTARY_PROFILE` for another signing team. Credentials belong in the Keychain profile, never source or command arguments. `xcrun notarytool store-credentials PROFILE` configures a profile through its secure prompts.

The build signs each app independently with Hardened Runtime and a secure timestamp. The guest has no Virtualization entitlement; the host has `com.apple.security.virtualization`. The production path notarizes/staples the guest separately because users install it inside their VM, re-seals the host, then notarizes/staples and assesses the host. It rejects any notarization result other than `Accepted`; it never silently falls back to ad-hoc signing. Sparkle is not added to this command-line product; upgrades use the installer and preserve VM data.

## Test the package

Extract the release ZIP into a clean temporary location, then:

```sh
bash install.sh --prefix /tmp/terminal-mac-install-test
/tmp/terminal-mac-install-test/bin/terminal-mac --version
/tmp/terminal-mac-install-test/bin/terminal-mac doctor
/tmp/terminal-mac-install-test/bin/terminal-mac up --plan
```

The installed launcher points to a complete versioned app bundle under `PREFIX/lib/terminal-mac`. Do not distribute only the inner executable: that loses the signed resources and bundled guest tools. The installer switches the launcher to the new version and leaves VM data under the user's Library untouched. It does not overwrite unrelated executables or edit shell profiles.

Before announcing production readiness, finish the live guest checklist in `docs/VALIDATION.md`, ideally on a separate clean Mac. Notarization verifies distribution signing; it does not prove VM boot, guest setup, privacy grants, input or terminal rendering work correctly.

## Publishing (GitHub Releases, Homebrew, curl)

The repository is `GITHUB_REPO` in `scripts/release-config.sh` (default `govijr/terminal-mac`). With it set, `release.sh` also writes `dist/releases/NAME-publish/`, which contains:

- the archive and its `.sha256`;
- `get.sh`, the curl installer, pinned to this archive's URL and checksum;
- `terminal-mac.rb`, the Homebrew formula, pinned the same way.

To publish a release:

```sh
# 1. GitHub release (tag vVERSION-BUILD) with the archive, its checksum and get.sh:
gh release create v0.2.0-4 dist/releases/terminal-mac-0.2.0-4-macos-arm64-publish/{*.zip,*.sha256,get.sh} --title "terminal-mac 0.2.0"
# 2. Homebrew tap: govijr/homebrew-tap, file Formula/terminal-mac.rb
cp dist/releases/terminal-mac-0.2.0-4-macos-arm64-publish/terminal-mac.rb ../homebrew-tap/Formula/ && (cd ../homebrew-tap && git commit -am "terminal-mac 0.2.0-4" && git push)
brew install govijr/tap/terminal-mac && brew test terminal-mac
```

Users then install with `brew install govijr/tap/terminal-mac`, or with `curl -fsSL https://github.com/govijr/terminal-mac/releases/latest/download/get.sh | bash`. Because `get.sh` is attached to each release, `latest/download/get.sh` always installs the newest release. A public release should be the notarized production build: Homebrew and curl do not quarantine downloads, but users who download the ZIP in a browser do.

The repository is also a Claude Code plugin marketplace. `.claude-plugin/plugin.json` registers the MCP server (`terminal-mac mcp`, which must be on PATH) and the skill in `skills/`. Users run `/plugin install terminal-mac --marketplace govijr/terminal-mac`. Check with `claude plugin validate .`, and keep `plugin.json`'s version in step with `VERSION`. The same `skills/` folder works with `npx skills add govijr/terminal-mac --skill terminal-mac`.

## Hosting and current release status

Releases go to `govijr/terminal-mac` with the tap `govijr/homebrew-tap`. Release scripts produce local immutable artifacts and upload-ready files; they never publish. Once a download host is selected, publish the production ZIP and its checksum there; do not advertise a placeholder installation URL.

During the November 1, 2026 preparation, automatic approval review rejected running the production path because it would upload the host and guest app binaries to Apple's notarization service without explicit authorization for that payload and destination. The signed-local path performs no application upload. User authorization for the Apple notarization upload is pending.
