#!/usr/bin/env bash
# Sway-min03 + ButterSway Quickshell session startup.
set -u

# Export the live Wayland/Sway session to D-Bus and systemd user services.
systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP
dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP
systemctl --user restart xdg-desktop-portal-wlr xdg-desktop-portal-gtk xdg-desktop-portal >/dev/null 2>&1 || true

# Notification daemon used by the Quickshell notification history and DND UI.
pkill -x dunst 2>/dev/null || true
dunst >/dev/null 2>&1 &

# Ensure the MATE PolicyKit authentication agent is available.
if [[ -x /usr/libexec/polkit-mate-authentication-agent-1 ]]; then
  pgrep -f polkit-mate-authentication-agent-1 >/dev/null || /usr/libexec/polkit-mate-authentication-agent-1 &
fi

# Clipboard history service.
if command -v wl-paste >/dev/null 2>&1 && command -v cliphist >/dev/null 2>&1; then
  pgrep -af 'wl-paste --watch cliphist store' >/dev/null || wl-paste --watch cliphist store &
fi

# Restore monitor layout, distribute workspaces, and launch the shell.
"$HOME/.local/share/sway-min03/scripts/wallpaper" restore || true
"$HOME/.local/share/sway-min03/scripts/displays" apply || true
"$HOME/.local/share/sway-min03/scripts/monitor-workspaces" --watch >/dev/null 2>&1 &
"$HOME/.local/share/sway-min03/scripts/idle" >/dev/null 2>&1 &
"$HOME/.local/share/sway-min03/scripts/bar" start
