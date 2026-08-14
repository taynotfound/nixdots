#!/usr/bin/env bash
# Updates NixDots itself (git, --ff-only) and its flake inputs, then builds
# the full system before switching.
set -euo pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
features=(--extra-experimental-features 'nix-command flakes')

command -v nix >/dev/null || { echo "nix is required." >&2; exit 1; }
if ! command -v git >/dev/null; then
  if [[ "${NIXDOTS_BOOTSTRAPPED:-}" != 1 ]]; then
    exec env NIXDOTS_BOOTSTRAPPED=1 nix "${features[@]}" shell nixpkgs#git --command "$repo_root/update.sh" "$@"
  fi
  echo "git is unavailable." >&2; exit 1
fi

# Refuse to clobber local modifications (generated host files are ignored).
if [[ -n "$(git -C "$repo_root" status --porcelain)" ]]; then
  echo "Repository has local changes; commit or stash them first:" >&2
  git -C "$repo_root" status --short >&2
  exit 1
fi

git -C "$repo_root" pull --ff-only

# Update flake inputs intentionally (skip with NIXDOTS_NO_INPUT_UPDATE=1).
if [[ "${NIXDOTS_NO_INPUT_UPDATE:-}" != 1 ]]; then
  (cd "$repo_root" && nix "${features[@]}" flake update)
fi

cleanup_git_visibility() {
  git -C "$repo_root" reset -- hosts/hardware-configuration.nix hosts/local.nix >/dev/null 2>&1 || true
}
trap cleanup_git_visibility EXIT
git -C "$repo_root" add -N -f hosts/hardware-configuration.nix hosts/local.nix

(cd "$repo_root" && nix "${features[@]}" flake check --no-build)
sudo nixos-rebuild build --flake "path:$repo_root#nixdots" \
  --option experimental-features 'nix-command flakes'
sudo nixos-rebuild switch --flake "path:$repo_root#nixdots" \
  --option experimental-features 'nix-command flakes'
