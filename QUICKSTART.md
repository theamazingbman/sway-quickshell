# Sway-min03 + Quickshell quick start

This setup uses the ButterSway Quickshell shell with its Sway IPC backend. The wallpaper picker changes the wallpaper only; the shell palette is fixed and there is no theme switcher or wallpaper-generated color system.

## Main shortcuts

| Shortcut | Action |
|---|---|
| Super + Space | Quickshell app launcher |
| Super + / | Quickshell settings panel |
| Super + Shift + T | Layout settings |
| Super + Shift + P | Wallpaper picker (image only) |
| Super + Shift + N | Network / Wi-Fi / VPN / Bluetooth app |
| Super + Shift + M | Quick settings and system controls |
| Super + V | Clipboard history |
| Super + X | Power menu |
| Super + Escape | Quickshell lock screen |
| Super + Ctrl + B | Hide/show Quickshell bar |
| Super + S | Full screenshot |
| Super + Shift + S | Region screenshot |
| Super + Shift + R | Reload Sway configuration |

Workspace shortcuts cover 1–12: Super+1–9, 0, minus, and equal switch workspaces; add Shift to move the focused window.

## Included Quickshell features

- Per-output workspace bar with live workspace occupancy and optional app icons
- App launcher, command menu, tray, clock, calendar, media controls, weather, CPU/RAM/disk metrics
- PipeWire volume and microphone controls, output selection and audio profiles
- NetworkManager Wi-Fi, Ethernet, VPN and Bluetooth controls, plus Wi-Fi QR sharing
- Power profiles, brightness, night light, keep-awake, pomodoro, DND and battery status
- Settings panel for keybindings, window rules, layout/gaps, bar modules, displays and wallpaper selection
- Quickshell PAM lock screen, clipboard history, screenshots and display-layout persistence

## Fedora packages

The installer uses Fedora's `quickshell` package and installs the supporting utilities for PipeWire, NetworkManager, Dunst, cliphist, screenshots, display management, power controls and system metrics.

## Notes

- Foot remains the terminal. The Quickshell code's terminal launches have been adapted from Kitty to Foot.
- Dunst is used instead of SwayNotificationCenter because the ButterSway notification history and DND controls use `dunstctl`. Do not start both notification daemons.
- Waybar configuration files remain in the repository for reference, but Waybar is not installed or started by this configuration.
- The Quickshell code is installed under `~/.local/share/sway-min03`; persistent settings live under `~/.local/state/sway-min03`.
