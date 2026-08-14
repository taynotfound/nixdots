#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

command -v nix >/dev/null || { echo "nix is required; run this on NixOS." >&2; exit 1; }
command -v git >/dev/null || { echo "git is required." >&2; exit 1; }

if git -C "$repo_root" grep -n -E 'hyprland\.lua|configType|hl\.(bind|monitor|window_rule)' HEAD -- home nixos hypr waybar scripts hosts flake.nix; then
  echo "unsupported legacy Hyprland configuration found" >&2
  exit 1
fi

(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes' flake check --no-build)
sudo nixos-rebuild dry-build \
  --flake "path:$repo_root#nixdots" \
  --option experimental-features 'nix-command flakes'
