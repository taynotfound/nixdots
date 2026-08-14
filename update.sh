#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v nix >/dev/null; then
  echo "nix is required. Run this on an installed NixOS system." >&2
  exit 1
fi
if ! command -v git >/dev/null; then
  if [[ "${NIXDOTS_BOOTSTRAPPED:-}" != 1 ]]; then
    echo "git is missing; bootstrapping it through Nix..."
    exec env NIXDOTS_BOOTSTRAPPED=1 nix --extra-experimental-features 'nix-command flakes' \
      shell nixpkgs#git --command "$repo_root/update.sh" "$@"
  fi
  echo "git is still unavailable inside the Nix environment." >&2
  exit 1
fi

# Flakes only expose Git-visible files. Keep machine-local files uncommitted,
# but add intent-to-add entries while Nix evaluates the flake.
cleanup_git_visibility() {
  git -C "$repo_root" reset -- hosts/hardware-configuration.nix hosts/local.nix >/dev/null 2>&1 || true
}
trap cleanup_git_visibility EXIT
git -C "$repo_root" add -N -f hosts/hardware-configuration.nix hosts/local.nix

# Refuse to evaluate the old archive/config by accident.
if git -C "$repo_root" grep -n -E 'hyprland\.lua|configType|hl\.(bind|monitor|window_rule)' HEAD -- home nixos hypr waybar scripts hosts flake.nix; then
  echo "Legacy Hyprland Lua configuration found in $repo_root. Pull the current NixDots main branch." >&2
  exit 1
fi

(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes' flake update)
(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes' flake check --no-build)
sudo nixos-rebuild dry-build \
  --flake "path:$repo_root#nixdots" \
  --option experimental-features 'nix-command flakes'
sudo nixos-rebuild switch --flake "path:$repo_root#nixdots"
