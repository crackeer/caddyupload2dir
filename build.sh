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
#   - caddy-upload2dir.service  (the systemd unit file)
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
DIST_DIR="$SCRIPT_DIR/dist"
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
xcaddy build "$CADDY_VERSION" \
    --with "$MODULE_PATH=$SCRIPT_DIR" \
    --embed template:./template \
    --output "$SCRIPT_DIR/caddy"

echo ">> Assembling distribution in $DIST_DIR ..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

cp "$SCRIPT_DIR/caddy"                     "$DIST_DIR/caddy"
cp "$SCRIPT_DIR/template/template.html"    "$DIST_DIR/template.html"
cp "$SCRIPT_DIR/caddy.json"                "$DIST_DIR/caddy.json"
cp "$SCRIPT_DIR/caddy-upload2dir.service"  "$DIST_DIR/caddy-upload2dir.service"
cp "$SCRIPT_DIR/install.sh"                "$DIST_DIR/install.sh"

chmod +x "$DIST_DIR/caddy" "$DIST_DIR/install.sh"

echo ""
echo ">> Build complete. Distribution package is ready in: $DIST_DIR"
echo "   To install on the target machine, copy the dist/ directory over and run:"
echo "     sudo ./install.sh"
