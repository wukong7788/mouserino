# Mouserino (MX Master 3)

A minimal macOS Logitech Options alternative prototype built with SwiftUI.

## Current features

- Simple settings UI
- Enable/disable global remapping
- Mapping for:
  - Side Back button
  - Side Forward button
  - Middle Click
- Action options:
  - No Action
  - Mission Control
  - App Expose
  - Launchpad
  - Show Desktop
- Settings persisted via `UserDefaults`
- Optional smooth scrolling (Logi Options style approximation)

## Run (Development)

```bash
cd MouserinoApp
swift run
```

## Build Release (App Bundle & DMG)

To build a standalone macOS application and a distributable installer, simply run the included packaging script:

```bash
cd MouserinoApp
bash build_app.sh
```

This will automatically:
1. Compile a release build using Swift Package Manager.
2. Bundle the executable, localizations, and `mouserino_icon.icns` into `MouserinoApp.app`.
3. Create a mounted `MouserinoApp.dmg` installer with an `Applications` folder shortcut.

## Required permission

This app needs Accessibility permission to listen to and remap global mouse events:

- macOS Settings -> Privacy & Security -> Accessibility
- Add and allow the app process

You can also click `Request Permission` in the app.

## Notes

- This is intentionally minimal and focused on MX Master 3 side/middle button remap.
- Thumb wheel and app-specific profiles are not implemented yet.
