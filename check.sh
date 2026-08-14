#!/usr/bin/env bash
# Validates the repository. Runs everywhere with Nix; the real-machine build
# additionally needs the generated host files from install.sh.
set -euo pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
features=(--extra-experimental-features 'nix-command flakes')

command -v nix >/dev/null || { echo "nix is required." >&2; exit 1; }

echo "== shellcheck =="
if command -v shellcheck >/dev/null; then
  shellcheck "$repo_root"/install.sh "$repo_root"/update.sh "$repo_root"/remove.sh \
    "$repo_root"/check.sh "$repo_root"/scripts/nixdots-windowctl
else
  echo "shellcheck not installed; skipped"
fi

echo "== waybar JSONC =="
if command -v jq >/dev/null; then
  sed 's|//.*$||' "$repo_root/waybar/config.jsonc" | jq -e . >/dev/null
else
  echo "jq not installed; skipped"
fi

echo "== nix flake check (evaluates + builds the CI fixture system) =="
(cd "$repo_root" && nix "${features[@]}" flake check --show-trace)

if [[ -f "$repo_root/hosts/local.nix" && -f "$repo_root/hosts/hardware-configuration.nix" ]]; then
  echo "== real machine build =="
  git -C "$repo_root" add -N -f hosts/hardware-configuration.nix hosts/local.nix
  trap 'git -C "$repo_root" reset -- hosts/hardware-configuration.nix hosts/local.nix >/dev/null 2>&1 || true' EXIT
  sudo nixos-rebuild build --flake "path:$repo_root#nixdots" \
    --option experimental-features 'nix-command flakes'
else
  echo "== real machine build skipped (no generated host files; run install.sh first) =="
fi

echo "All checks passed."
