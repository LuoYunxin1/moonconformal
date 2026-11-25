#!/usr/bin/env bash
set -euo pipefail
if [[ $# != 1 || -z "$1" || "$1" == / ]]; then
  echo 'usage: install-toolchain.sh NEW_TOOLCHAIN_DIRECTORY' >&2
  exit 2
fi
dest="$1"
if [[ -e "$dest" ]]; then
  echo 'toolchain directory already exists; choose a fresh directory' >&2
  exit 2
fi
mkdir -p "$dest/lib"
archive_dir="$(mktemp -d)"
trap 'rm -rf -- "$archive_dir"' EXIT
curl --fail --location --retry 2 --connect-timeout 20 --max-time 300 \
  'https://cli.moonbitlang.com/binaries/0.10.22%2B124d61d05/moonbit-linux-x86_64.tar.gz' -o "$archive_dir/moonbit.tar.gz"
curl --fail --location --retry 2 --connect-timeout 20 --max-time 120 \
  'https://cli.moonbitlang.com/cores/core-0.10.22%2B124d61d05.tar.gz' -o "$archive_dir/core.tar.gz"
(cd "$archive_dir" && printf '%s\n' \
  'aeb78ded1d5e25185ed788328cacef5e843a9ab923145523b7652e8d082f74fb  moonbit.tar.gz' \
  'a22977f3d346e4a189fe521b2d265b2fbb6c00e3ff80342246fb6f8f26c9f156  core.tar.gz' | sha256sum --check)
tar -xzf "$archive_dir/moonbit.tar.gz" -C "$dest"
tar -xzf "$archive_dir/core.tar.gz" -C "$dest/lib"
# Official archives may omit executable bits; Linux filesystems enforce them.
chmod +x "$dest"/bin/*
if [[ -d "$dest/lib/llvm/bin" ]]; then
  chmod +x "$dest"/lib/llvm/bin/*
fi
export MOON_HOME="$dest"
export MOON_TOOLCHAIN_ROOT="$dest"
export PATH="$dest/bin:$PATH"
moon version --all
moonc -v | grep -F 'v0.10.22+124d61d05'
moon -C "$dest/lib/core" bundle --all
