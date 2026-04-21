#!/usr/bin/env bash
set -euo pipefail

MARKER_FILE="${HOME}/.config/rxterminal/.session-setup-complete"
AUTOSTART_FILE="${HOME}/.config/autostart/rxterminal-first-login.desktop"
INSTALLER="/opt/RxTerminal/resources/scripts/install-ubuntu.sh"

mkdir -p "$(dirname "${MARKER_FILE}")"

if [[ -f "${MARKER_FILE}" ]]; then
  rm -f "${AUTOSTART_FILE}"
  exit 0
fi

if [[ ! -x "${INSTALLER}" ]]; then
  logger -t rxterminal-session-setup "Installer not found at ${INSTALLER}"
  exit 1
fi

# This runs inside the user's graphical session, which is required for gsettings.
"${INSTALLER}"

touch "${MARKER_FILE}"
rm -f "${AUTOSTART_FILE}"
