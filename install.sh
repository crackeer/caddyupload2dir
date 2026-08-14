#!/usr/bin/env bash
#
# install.sh - Install caddy (with the upload2dir plugin) as a systemd service.
#
# This script:
#   1. Copies the caddy binary and template.html to /usr/local/caddy/
#   2. Copies caddy.json (config) to /usr/local/caddy/ if not already present
#   3. Installs the systemd service unit file
#   4. Enables and starts the service via systemctl
#
# Run from the directory that contains caddy, template.html, caddy.json and
# caddy-upload2dir.service (i.e. the dist/ directory produced by build.sh):
#
#   sudo ./install.sh
#
set -euo pipefail

INSTALL_DIR="/usr/local/caddy"
SERVICE_NAME="caddy-upload2dir.service"
SERVICE_DEST="/etc/systemd/system/${SERVICE_NAME}"

# Directory of this script (source of the files to install).
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Must run as root because we write to /usr/local, /etc/systemd and use systemctl.
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: this installer must be run as root (try: sudo ./install.sh)" >&2
    exit 1
fi

# Verify required files exist next to this script.
for f in caddy template.html "$SERVICE_NAME"; do
    if [ ! -f "$SRC_DIR/$f" ]; then
        echo "Error: required file '$f' not found in $SRC_DIR" >&2
        exit 1
    fi
done

echo ">> Creating install directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

echo ">> Installing caddy binary -> $INSTALL_DIR/caddy"
install -m 0755 "$SRC_DIR/caddy" "$INSTALL_DIR/caddy"

echo ">> Installing template.html -> $INSTALL_DIR/template.html"
install -m 0644 "$SRC_DIR/template.html" "$INSTALL_DIR/template.html"

# Install the config only if it does not already exist, so we don't clobber
# a configuration the operator has customized on the target machine.
if [ -f "$SRC_DIR/caddy.json" ]; then
    if [ -f "$INSTALL_DIR/caddy.json" ]; then
        echo ">> Existing config found, leaving $INSTALL_DIR/caddy.json untouched"
    else
        echo ">> Installing caddy.json -> $INSTALL_DIR/caddy.json"
        install -m 0644 "$SRC_DIR/caddy.json" "$INSTALL_DIR/caddy.json"
    fi
fi

echo ">> Installing systemd unit -> $SERVICE_DEST"
install -m 0644 "$SRC_DIR/$SERVICE_NAME" "$SERVICE_DEST"

echo ">> Reloading systemd daemon"
systemctl daemon-reload

echo ">> Enabling and starting $SERVICE_NAME"
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

echo ""
echo ">> Installation complete."
echo "   Check status with:  systemctl status $SERVICE_NAME"
echo "   View logs with:     journalctl -u $SERVICE_NAME -f"
