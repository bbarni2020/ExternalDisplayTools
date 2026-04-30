# ExternalDisplayTools

ExternalDisplayTools is a small macOS app for turning the notch into something useful instead of leaving it empty.

I built it as a menu-bar style accessory app that keeps a notch view alive in the background, shows Now Playing artwork and music bars, surfaces battery and charging activity, and accepts external requests through a custom URL scheme.

## What it does

- Keeps a notch window pinned at the top of the main display
- Shows the current music state when nothing else is taking over
- Accepts external notch requests through `notch://show`
- Displays battery and charging activity in the notch
- Supports Bluetooth, keyboard remapping, haptic feedback, and launch-at-login settings
- Runs as an accessory app, so it stays out of the Dock in normal use

## Requirements

- macOS
- Xcode
- Accessibility and Input Monitoring permissions if you want keyboard remapping to work

## Run it locally

1. Open `ExternalDisplayTools.xcodeproj` in Xcode.
2. Build and run the `ExternalDisplayTools` scheme.
3. Open the app settings if you want to change launch-at-login, haptics, battery notifications, or charging animation behavior.

If you want the app to start automatically, turn on Launch at Login in Settings. The app registers itself with `SMAppService` when that setting changes.

## External notch requests

The app registers a custom URL scheme:

```text
notch://show?duration=5&content=text:Hello
```

The parser is strict about the request shape:

- `duration` is required and is clamped between 1 and 60 seconds
- `content` is required
- `left` is optional
- `right` is optional
- Only one external request can be active at a time
- Requests are ignored while the screen is locked or the screen saver is active

### Content formats

`content` supports:

- `text:Your message`
- `image:https://example.com/image.png`
- `gif:file:///tmp/animation.gif`

`right` supports:

- `text:LIVE`
- `icon:bolt.horizontal.fill`
- `image:https://example.com/image.png`
- `gif:file:///tmp/animation.gif`

`left` must be a bundle identifier for an installed app on the current machine.

### Examples

Show a short text message:

```text
open "notch://show?duration=6&content=text:Hello from the notch"
```

Show text with a right-side label:

```text
open "notch://show?duration=5&right=text:LIVE&content=text:Recording"
```

Show an image:

```text
open "notch://show?duration=8&content=image:https://example.com/pic.png"
```

## Settings

The Settings window is split into a few simple sections:

- General: launch at login and haptic feedback
- Battery: battery notifications and charging animation
- Keyboard: key remapping and permission checks

Keyboard remapping needs Accessibility and Input Monitoring permissions. If those permissions are missing, the app shows the prompt in Settings instead of trying to guess.

## Notes from development

This started as a practical macOS experiment, not a polished product. The code leans on SwiftUI, AppKit, and a small amount of window delegation to keep the notch pinned where it belongs.

The current implementation also keeps the notch responsive to screen lock state, screen saver activity, and wake/display changes so it does not drift out of place after the machine sleeps or the display setup changes.

## Known rough edges

- External requests do not queue up; they are ignored while one is already active
- Invalid URLs are rejected silently
- The left-side app icon only works if the bundle identifier resolves on the current machine
- The notch content is intentionally constrained, so oversized content will clip or shrink to fit

## Related files

- [Notch-implementation.md](Notch-implementation.md)
- [ExternalDisplayToolsApp.swift](ExternalDisplayTools/ExternalDisplayToolsApp.swift)
- [ExternalNotchRequestManager.swift](ExternalDisplayTools/Managers/ExternalNotchRequestManager.swift)
- [SettingsView.swift](ExternalDisplayTools/Views/Settings/SettingsView.swift)