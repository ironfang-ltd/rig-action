#!/usr/bin/env bash
# Resolve the ironfang binary for a composite step and print `bin=<path>`
# for $GITHUB_OUTPUT: a binary the caller built (INPUT_BINARY), or the
# release named by INPUT_VERSION, downloaded from ironfang-ltd/cli for this
# runner and verified against the release's SHA-256 sums before anything
# runs.
set -euo pipefail
if [ -n "${INPUT_BINARY:-}" ]; then
    echo "bin=$INPUT_BINARY"
    exit 0
fi
version="${INPUT_VERSION:?a release version is required}"
dir="${RUNNER_TEMP:-/tmp}/ironfang-cli"
mkdir -p "$dir"
os="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"
case "$arch" in
    x86_64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "unsupported architecture $arch" >&2; exit 1 ;;
esac
name="ironfang_${version}_${os}_${arch}"
base="https://github.com/ironfang-ltd/cli/releases/download/cli/v${version}"
if [ ! -x "$dir/$name/ironfang" ]; then
    curl -fsSL --retry 3 -o "$dir/$name.tar.gz" "$base/$name.tar.gz" >&2
    curl -fsSL --retry 3 -o "$dir/checksums.txt" "$base/ironfang_${version}_checksums.txt" >&2
    (cd "$dir" && sha256sum -c checksums.txt --ignore-missing --status) || { echo "checksum mismatch for $name" >&2; exit 1; }
    tar -C "$dir" -xzf "$dir/$name.tar.gz"
fi
echo "bin=$dir/$name/ironfang"
