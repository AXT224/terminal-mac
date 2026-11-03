#!/bin/bash
# Release settings. Nothing personal lives in this file: the signing identity is read from your
# Keychain and notarization credentials stay in a notarytool Keychain profile.
if [[ -z "${SIGN_IDENTITY:-}" ]]; then
  SIGN_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | sed -n 's/.*"\(Developer ID Application: .*\)"$/\1/p' | head -1)"
fi
export SIGN_IDENTITY
# Name of a profile created with: xcrun notarytool store-credentials PROFILE
export NOTARY_PROFILE="${NOTARY_PROFILE:-}"
# GitHub repository (owner/name) that hosts releases; the tap is owner/homebrew-tap.
export GITHUB_REPO="${GITHUB_REPO:-govijr/terminal-mac}"
