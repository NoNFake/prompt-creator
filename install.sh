#!/usr/bin/env bash
# Install prompt.md as /prompt for opencode and/or fuckcode.
# Local:  ./install.sh
# Remote: curl -fsSL https://raw.githubusercontent.com/NoNFake/prompt-creator/main/install.sh | bash
set -euo pipefail

file="prompt.md"
raw="${PROMPT_CREATOR_RAW:-https://raw.githubusercontent.com/NoNFake/prompt-creator/main}"
raw="${raw%/}"

self="${BASH_SOURCE[0]:-}"
work=""
if [ -n "$self" ] && [ -f "$self" ]; then
  work="$(cd "$(dirname "$self")" && pwd)"
else
  command -v curl >/dev/null 2>&1 || { echo "error: curl is required" >&2; exit 1; }
  work="$(mktemp -d)"
  trap 'rm -rf "$work"' EXIT
  curl -fsSL "$raw/$file" -o "$work/$file" \
    || { echo "error: failed to download $file" >&2; exit 1; }
fi

src="$work/$file"
[ -f "$src" ] || { echo "error: missing $src" >&2; exit 1; }

config="${XDG_CONFIG_HOME:-$HOME/.config}"
found=0

for tool in opencode fuckcode; do
  command -v "$tool" >/dev/null 2>&1 || { echo "skip: $tool not in PATH"; continue; }
  found=1
  dir="$config/$tool/commands"
  mkdir -p "$dir"
  dest="$dir/$file"

  if [ -e "$dest" ] && ! cmp -s "$src" "$dest"; then
    backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
    cp -p "$dest" "$backup"
    echo "backup: $backup"
  fi

  cp "$src" "$dest"
  chmod 644 "$dest"
  echo "installed: $dest"
done

[ "$found" -eq 1 ] || { echo "error: neither opencode nor fuckcode found in PATH" >&2; exit 1; }
