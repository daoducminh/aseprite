#!/usr/bin/env bash
# Installs Aseprite (from the adjacent ./output folder) to /opt/aseprite
# and registers a desktop entry / icon so it shows up in app launchers.
#
# Usage: sudo ./install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/output"
INSTALL_DIR="/opt/aseprite"
BIN_LINK="/usr/local/bin/aseprite"

if [ "$(id -u)" -ne 0 ]; then
  echo "This installer needs root privileges (writes to /opt and /usr/share). Try: sudo $0" >&2
  exit 1
fi

if [ ! -d "$SRC_DIR" ] || [ ! -x "$SRC_DIR/aseprite" ]; then
  echo "Error: expected an 'output' folder with the aseprite binary next to this script." >&2
  exit 1
fi

# Detect distro so we pick the desktop-entry tooling/paths that actually
# exist on this system (desktop file *location* is the same XDG path
# everywhere, but the post-install refresh commands differ per distro).
DISTRO_ID="unknown"
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  DISTRO_ID="${ID:-unknown}"
fi
echo "==> Detected distro: $DISTRO_ID"

DESKTOP_DIR="/usr/share/applications"
ICON_DIR="/usr/share/pixmaps"

echo "==> Installing to $INSTALL_DIR"
if [ -d "$INSTALL_DIR" ]; then
  echo "==> Existing install found, removing $INSTALL_DIR"
  rm -rf "$INSTALL_DIR"
fi
mkdir -p "$INSTALL_DIR"
cp -a "$SRC_DIR/." "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/aseprite"

echo "==> Linking $BIN_LINK -> $INSTALL_DIR/aseprite"
ln -sf "$INSTALL_DIR/aseprite" "$BIN_LINK"

if [ -f "$INSTALL_DIR/data/icons/ase256.png" ]; then
  ICON_SRC="$INSTALL_DIR/data/icons/ase256.png"
elif [ -f "$INSTALL_DIR/data/icons/ase128.png" ]; then
  ICON_SRC="$INSTALL_DIR/data/icons/ase128.png"
else
  ICON_SRC="$(find "$INSTALL_DIR/data/icons" -name '*.png' 2>/dev/null | sort | tail -1 || true)"
fi

ICON_NAME="aseprite"
if [ -n "${ICON_SRC:-}" ]; then
  mkdir -p "$ICON_DIR"
  cp -f "$ICON_SRC" "$ICON_DIR/${ICON_NAME}.png"
else
  echo "==> Warning: no icon found under $INSTALL_DIR/data/icons, desktop entry will use a generic icon"
  ICON_NAME="utilities-terminal"
fi

echo "==> Writing desktop entry to $DESKTOP_DIR/aseprite.desktop"
mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_DIR/aseprite.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Aseprite
Comment=Animated sprite editor & pixel art tool
Exec=$INSTALL_DIR/aseprite %F
Icon=$ICON_NAME
Terminal=false
Categories=Graphics;2DGraphics;RasterGraphics;
MimeType=image/x-aseprite;
StartupWMClass=aseprite
EOF
chmod 644 "$DESKTOP_DIR/aseprite.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1 && [ -d /usr/share/icons/hicolor ]; then
  gtk-update-icon-cache /usr/share/icons/hicolor >/dev/null 2>&1 || true
fi

echo "==> Done. Launch with 'aseprite' or from your app launcher."
