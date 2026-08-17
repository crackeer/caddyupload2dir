#!/usr/bin/env bash
#
# build.sh - Build the caddy binary with the upload2dir plugin and
# assemble an installable distribution package.
#
# The resulting dist/ directory contains everything needed to install
# caddy as a systemd service:
#   - caddy                     (the compiled binary)
#   - template.html             (the file_server browse page)
#   - caddy.json                (the caddy configuration)
#   - caddyupload2dir.service  (the systemd unit file)
#   - install.sh                (the installer script)
#
# Usage:
#   ./build.sh [caddy_version]
#
# Example:
#   ./build.sh            # builds against caddy master
#   ./build.sh v2.6.4     # builds against a specific caddy version
#
set -euo pipefail

# Directory of this script (repo root).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CADDY_VERSION="${1:-master}"
PACKAGE_NAME="caddyupload2dir"
STAGING_DIR="$SCRIPT_DIR/dist"
DIST_DIR="$STAGING_DIR/$PACKAGE_NAME"
ARCHIVE_PATH="$SCRIPT_DIR/${PACKAGE_NAME}.zip"
MODULE_PATH="github.com/crackeer/caddyupload2dir"

echo ">> Ensuring xcaddy is installed..."
if ! command -v xcaddy >/dev/null 2>&1; then
    echo "   xcaddy not found, installing..."
    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
fi

# Make sure GOPATH/bin is on PATH so a freshly installed xcaddy is found.
GOBIN="$(go env GOPATH)/bin"
export PATH="$GOBIN:$PATH"

echo ">> Building caddy ($CADDY_VERSION) with $MODULE_PATH ..."
# Build using the local checkout of this module so local changes are used.
# NOTE: the file_server browse template is read from disk (not the embedded
# FS), so template.html is shipped in the distribution and installed to disk
# rather than embedded into the binary.
xcaddy build "$CADDY_VERSION" \
    --with "$MODULE_PATH=$SCRIPT_DIR" \
    --output "$SCRIPT_DIR/caddy"

echo ">> Assembling distribution in $DIST_DIR ..."
rm -rf "$STAGING_DIR"
mkdir -p "$DIST_DIR"

cp "$SCRIPT_DIR/caddy"                    "$DIST_DIR/caddy"
cp "$SCRIPT_DIR/caddy.json"               "$DIST_DIR/caddy.json"
cp "$SCRIPT_DIR/caddyupload2dir.service"  "$DIST_DIR/caddyupload2dir.service"
cp "$SCRIPT_DIR/install.sh"               "$DIST_DIR/install.sh"
cp "$SCRIPT_DIR/template.html"            "$DIST_DIR/template.html"

chmod +x "$DIST_DIR/caddy" "$DIST_DIR/install.sh"

rm -f "$ARCHIVE_PATH"
(cd "$STAGING_DIR" && zip -r "$ARCHIVE_PATH" "$PACKAGE_NAME")
echo ">> Build complete. Distribution package is ready in: $ARCHIVE_PATH"
echo ">> The archive extracts to the top-level directory: $PACKAGE_NAME/"
echo ">> Unpacked distribution remains available in: $DIST_DIR"