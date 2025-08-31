#!/bin/sh
set -e

# Ensure a runtime dir exists (silences warnings and fixes some apps)
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-brave}"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null || true

# Start a DBus session bus for this user (suppress noisy DBus errors)
if command -v dbus-launch >/dev/null 2>&1; then
  # dbus-launch outputs shell exports for DBUS_SESSION_BUS_ADDRESS / DBUS_SESSION_BUS_PID
  eval "$(dbus-launch --sh-syntax)"
fi

# Run Brave with any passed flags
exec brave-browser "$@"
