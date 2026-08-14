#!/usr/bin/env bash
# "Removing" NixDots means switching the system back to a non-NixDots
# configuration. This script does NOT delete anything by itself.
set -euo pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

[[ -e /etc/NIXOS ]] || { echo "This script is for NixOS installations." >&2; exit 1; }

cat <<'EOF'
NixDots removal
===============
Rolling back one generation is NOT a reliable uninstall: the previous
generation may also have been built from NixDots.

To actually remove NixDots:
  1. List generations and find the last pre-NixDots one:
       sudo nix-env --list-generations -p /nix/var/nix/profiles/system
  2. Switch to it:
       sudo nix-env --switch-generation <N> -p /nix/var/nix/profiles/system
       sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
     ...or rebuild from your own /etc/nixos configuration:
       sudo nixos-rebuild switch
  3. Only after confirming the system boots and works without NixDots,
     delete this repository.

EOF
sudo nix-env --list-generations -p /nix/var/nix/profiles/system | tail -15
echo
echo "Repository location: $repo_root (delete manually once you're off NixDots)."
