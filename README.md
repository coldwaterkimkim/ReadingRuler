# ReadingRuler

ReadingRuler is a macOS menu bar utility that adds a system-wide reading ruler overlay that follows the cursor.

## Features

- Hold-to-show ruler (global shortcut)
- Sticky toggle mode (global shortcut)
- 3 modes: Bar, Highlight, Spotlight
- Draggable quick-adjust handle for width/height, with `Option` drag to adjust offset
- Settings persistence via `UserDefaults`
- No screen recording, text capture, analytics, or network calls
- Lightweight runtime path: single overlay window and cursor tracking only while ruler is visible

## Build / Run

1. Open `Package.swift` in Xcode (Xcode treats this as a native Swift project).
2. Choose the `ReadingRuler` scheme.
3. Run on macOS 14+.

You can also build from terminal:

```bash
swift build
```

## Permissions

ReadingRuler uses global shortcuts and global cursor tracking for overlay rendering.

If shortcuts do not fire reliably, grant Accessibility permission:

1. Open **System Settings** → **Privacy & Security** → **Accessibility**.
2. Enable access for `ReadingRuler`.

You can open this page from the app Settings screen via **Open Accessibility Settings**.

## Default Shortcuts

- Hold-to-show: `Option + Space`
- Toggle sticky ruler: `Control + Command + R`

All shortcuts are configurable in Settings.

## Hold-to-Show Usage

- Press and hold the hold shortcut to show the ruler instantly.
- While held, the overlay follows the cursor.
- Release the shortcut to hide instantly.

## Privacy

ReadingRuler runs locally only:

- No network requests
- No text extraction
- No screenshots or screen recording
