#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -e /etc/NIXOS ]]; then
  echo "This script is for NixOS installations." >&2
  exit 1
fi
read -r -p "Roll back the active NixOS generation and remove $repo_root? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }

sudo nixos-rebuild switch --rollback
cd "$(dirname "$repo_root")"
rm -rf -- "$repo_root"
echo "NixDots removed; the previous NixOS generation is active."
