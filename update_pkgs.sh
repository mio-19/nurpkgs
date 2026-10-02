#!/usr/bin/env bash
set -e
nix-update -f default.nix socketw --version 813375e || true
nix-update -f default.nix android-translation-layer --version aa80e74 || true
nix-update -f default.nix bilibili --version v1.19.0-3 || true
nix-update -f default.nix bionic-translation --version 6253dec || true
nix-update -f default.nix bitwarden-extension --version browser-v2026.9.3 || true
nix-update -f default.nix clice --version v0.1.2026100108 || true
nix-update -f default.nix floccus-firefox --version v5.11.0 || true
nix-update -f default.nix forkgram-desktop --version v7.2.10 || true
nix-update -f default.nix meru --version v3.62.0 || true
nix-update -f default.nix mesh-llm --version v0.77.0 || true
nix-update -f default.nix nlvm --version 40d7339 || true
nix-update -f default.nix terminal-browser --version v0.13.3 || true
nix-update -f default.nix unsloth-studio --version v0.1.902-beta || true
nix-update -f default.nix user-agent-switcher-firefox --version v1.4.107 || true
