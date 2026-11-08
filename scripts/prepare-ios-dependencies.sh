#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "$0")/.." && pwd -P)"
engine_version=0.1.1
engine_checksum=24905c0484b2e5c886c2685ce03e5f5585c3dc6096c65c59948b35be56ae4dc0
engine_root="${NUVIO_ENGINE_ROOT:-${repository_root}/../nuvio-engine}"
engine_framework="${engine_root}/platform/apple/NuvioEngine.xcframework"

if [[ ! -f "${repository_root}/MPVKit/Package.swift" ]]; then
    git -C "${repository_root}" submodule update --init --depth 1 MPVKit
fi

if [[ -f "${engine_framework}/Info.plist" ]]; then
    exit 0
fi

temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/nuvio-ios-dependencies.XXXXXX")"
trap 'rm -rf "${temporary_directory}"' EXIT

archive="${temporary_directory}/nuvio-engine-apple-${engine_version}.zip"
release_asset_url="https://github.com/NuvioMedia/nuvio-engine/releases/download/v${engine_version}/nuvio-engine-apple-${engine_version}.zip"
api_asset_url="https://api.github.com/repos/NuvioMedia/nuvio-engine/releases/assets/497211532"

# GitHub's release-download CDN can intermittently return HTTP 504 in CI.
# Retry with backoff, then fall back to the GitHub Releases API asset endpoint.
if ! curl --fail --location --retry 8 --retry-all-errors --retry-delay 3 \
    --retry-max-time 300 --connect-timeout 30 --max-time 600 \
    --silent --show-error --user-agent "Nuvio-iOS-CI" \
    --output "${archive}" "${release_asset_url}"; then
    echo "Release CDN download failed; retrying through the GitHub Releases API…" >&2
    rm -f "${archive}"
    curl --fail --location --retry 5 --retry-all-errors --retry-delay 3 \
        --retry-max-time 240 --connect-timeout 30 --max-time 600 \
        --silent --show-error --user-agent "Nuvio-iOS-CI" \
        --header "Accept: application/octet-stream" \
        --output "${archive}" "${api_asset_url}"
fi

actual_checksum="$(shasum -a 256 "${archive}" | awk '{print $1}')"
if [[ "${actual_checksum}" != "${engine_checksum}" ]]; then
    echo "Nuvio Engine Apple package checksum mismatch." >&2
    exit 1
fi

extraction_root="${temporary_directory}/extracted"
mkdir -p "${extraction_root}"
unzip -q "${archive}" -d "${extraction_root}"
source_framework="$(find "${extraction_root}" -type d -name NuvioEngine.xcframework -print -quit)"
if [[ -z "${source_framework}" || ! -f "${source_framework}/Info.plist" ]]; then
    echo "Nuvio Engine Apple package does not contain NuvioEngine.xcframework." >&2
    exit 1
fi
if [[ ! -f "${source_framework}/ios-arm64/libCNuvioEngine.a" ]]; then
    echo "Nuvio Engine Apple package does not contain the iOS arm64 library." >&2
    exit 1
fi

mkdir -p "$(dirname "${engine_framework}")"
ditto "${source_framework}" "${engine_framework}"
