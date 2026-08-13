#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes' flake update)
(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes' flake check --no-build)
sudo nixos-rebuild switch --flake "path:$repo_root#nixdots"
