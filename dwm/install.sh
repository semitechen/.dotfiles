#!/usr/bin/env bash
set -euo pipefail

# Build and install suckless dwm with dotfiles config.h
DWM_DIR="${HOME}/.local/src/dwm"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Preparing dwm source at ${DWM_DIR}..."
mkdir -p "$(dirname "${DWM_DIR}")"
if [ ! -d "${DWM_DIR}/.git" ]; then
    git clone https://git.suckless.org/dwm "${DWM_DIR}"
else
    git -C "${DWM_DIR}" pull --rebase || true
fi

echo "==> Applying dotfiles config.h..."
cp -f "${SCRIPT_DIR}/config.h" "${DWM_DIR}/config.h"

echo "==> Compiling and installing dwm..."
cd "${DWM_DIR}"
sudo make clean install

echo "==> dwm successfully built and installed!"
