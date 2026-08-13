#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
features=(--extra-experimental-features 'nix-command flakes')

if ! command -v nix >/dev/null; then
  echo "nix is required. Run this on an installed NixOS system." >&2
  exit 1
fi
if ! command -v git >/dev/null; then
  if [[ "${NIXDOTS_BOOTSTRAPPED:-}" != 1 ]]; then
    echo "git is missing; bootstrapping it through Nix..."
    exec env NIXDOTS_BOOTSTRAPPED=1 nix "${features[@]}" shell nixpkgs#git --command "$repo_root/install.sh" "$@"
  fi
  echo "git is still unavailable inside the Nix environment." >&2
  exit 1
fi

if [[ ! -e /etc/NIXOS ]]; then
  echo "This installer is for an installed NixOS system." >&2
  exit 1
fi
if [[ ! -f /etc/nixos/hardware-configuration.nix ]]; then
  echo "Missing /etc/nixos/hardware-configuration.nix. Finish a normal NixOS install first." >&2
  exit 1
fi
if ! command -v sudo >/dev/null; then
  echo "sudo is required." >&2
  exit 1
fi

username="${NIXDOTS_USER:-${SUDO_USER:-$USER}}"
[[ "$username" != root ]] || { echo "Run as a normal user, not root." >&2; exit 1; }
host_name="${NIXDOTS_HOSTNAME:-$(hostnamectl --static 2>/dev/null || hostname)}"
time_zone="${NIXDOTS_TIMEZONE:-$(timedatectl show -p Timezone --value 2>/dev/null || true)}"
time_zone="${time_zone:-Europe/Berlin}"

has_nvidia=false
for vendor_file in /sys/bus/pci/devices/*/vendor; do
  [[ -r "$vendor_file" ]] && [[ "$(<"$vendor_file")" == 0x10de ]] && has_nvidia=true
 done

printf 'Preparing NixDots for %s on %s (NVIDIA: %s)\n' "$username" "$host_name" "$has_nvidia"
cp /etc/nixos/hardware-configuration.nix "$repo_root/hosts/hardware-configuration.nix"
printf '{\n  username = "%s";\n  hostName = "%s";\n  timeZone = "%s";\n  hasNvidia = %s;\n}\n' "$username" "$host_name" "$time_zone" "$has_nvidia" > "$repo_root/hosts/local.nix"

(cd "$repo_root" && nix "${features[@]}" flake lock && nix "${features[@]}" flake check --no-build)
sudo nixos-rebuild switch \
  --flake "path:$repo_root#nixdots" \
  --option experimental-features 'nix-command flakes' \
  --option extra-substituters 'https://hyprland.cachix.org' \
  --option extra-trusted-public-keys 'hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc='

cat <<'DONE'

NixDots is installed. Log out and choose Hyprland in SDDM, or reboot.
Use SUPER+D for apps, SUPER+Q for a terminal, SUPER+F to maximize,
SUPER+M / SUPER+SHIFT+M to minimize and restore, and SUPER+H / SUPER+SHIFT+H to hide and restore.
Run ./update.sh for future updates.
DONE
