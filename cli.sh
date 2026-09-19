#!/usr/bin/env bash
# Resolve the ironfang-rig binary for a composite step and print
# `bin=<path>` for $GITHUB_OUTPUT. Two ways, in order: a binary the caller
# built or cached (INPUT_BINARY), or a release (INPUT_VERSION=x.y.z),
# downloaded for this runner and verified against the release's SHA-256
# sums before anything runs.
set -euo pipefail
if [ -n "${INPUT_BINARY:-}" ]; then
    echo "bin=$INPUT_BINARY"
    exit 0
fi
version="${INPUT_VERSION:?a release version is required}"
dir="${RUNNER_TEMP:-/tmp}/ironfang-rig"
mkdir -p "$dir"
os="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"
case "$os" in
    linux|darwin) ;;
    *) echo "ironfang-rig: this action runs on Linux and macOS runners; pass \`binary\` on $os" >&2; exit 1 ;;
esac
case "$arch" in
    x86_64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "unsupported architecture $arch" >&2; exit 1 ;;
esac
name="ironfang-rig_${version}_${os}_${arch}"
base="https://github.com/ironfang-ltd/rig-action/releases/download/rig-cli/v${version}"
if [ ! -x "$dir/$name/ironfang-rig" ]; then
    curl -fsSL --retry 3 -o "$dir/$name.tar.gz" "$base/$name.tar.gz" >&2
    curl -fsSL --retry 3 -o "$dir/checksums.txt" "$base/ironfang-rig_${version}_checksums.txt" >&2
    (cd "$dir" && sha256sum -c checksums.txt --ignore-missing --status) || { echo "checksum mismatch for $name" >&2; exit 1; }
    tar -C "$dir" -xzf "$dir/$name.tar.gz"
fi
echo "bin=$dir/$name/ironfang-rig"
