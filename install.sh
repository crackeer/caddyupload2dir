#!/usr/bin/env bash
#
# install.sh - Install caddy (with the upload2dir plugin) as a systemd service.
#
# This script:
#   1. Copies the caddy binary and template.html to /usr/local/caddy/
#   2. Backs up and installs caddy.json under /usr/local/caddy/
#   3. Installs the systemd service unit file
#   4. Enables and starts the service via systemctl
#
# Run from the directory that contains caddy, template.html, caddy.json and
# caddyupload2dir.service (i.e. the dist/ directory produced by build.sh):
#
#   sudo ./install.sh
#
set -euo pipefail

INSTALL_DIR="/usr/local/caddy"
SERVICE_NAME="caddyupload2dir.service"
SERVICE_DEST="/etc/systemd/system/${SERVICE_NAME}"

# Directory of this script (source of the files to install).
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Must run as root because we write to /usr/local, /etc/systemd and use systemctl.
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: this installer must be run as root (try: sudo ./install.sh)" >&2
    exit 1
fi


echo ">> Creating install directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

echo ">> Installing caddy binary -> $INSTALL_DIR/caddy"
install -m 0755 "$SRC_DIR/caddy" "$INSTALL_DIR/caddy"

echo ">> Installing browse template -> $INSTALL_DIR/template.html"
install -m 0644 "$SRC_DIR/template.html" "$INSTALL_DIR/template.html"

# Install the packaged configuration on every deployment so changes to the
# root, port and handlers actually take effect. Preserve the previous config
# as a timestamped backup for rollback.
if [ ! -f "$SRC_DIR/caddy.json" ]; then
    echo "Error: required file 'caddy.json' not found in $SRC_DIR" >&2
    exit 1
fi

if [ -f "$INSTALL_DIR/caddy.json" ]; then
    CONFIG_BACKUP="$INSTALL_DIR/caddy.json.bak.$(date +%Y%m%d%H%M%S)"
    echo ">> Backing up existing config -> $CONFIG_BACKUP"
    cp -p "$INSTALL_DIR/caddy.json" "$CONFIG_BACKUP"
fi

echo ">> Installing caddy.json -> $INSTALL_DIR/caddy.json"
install -m 0644 "$SRC_DIR/caddy.json" "$INSTALL_DIR/caddy.json"

# Validate the exact installed configuration before restarting the service.
"$INSTALL_DIR/caddy" validate --config "$INSTALL_DIR/caddy.json"

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
