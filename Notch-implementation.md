# Notch API - Let Your App Shine in the Notch

Hey, I threw this together to solve a problem I had: letting other apps trigger that cool notch animation like the music player does. It's small, opinionated, and works for my use cases. If it fits yours, great.

## Quick Start

Want to show something in the notch? Hit this URL:

```
notch://show?duration=5&left=com.yourapp.bundle&content=text:Your message here
```

Boom. Notch expands, shows your stuff, then closes after 5 seconds.

## What It Does

- Pops open the notch with your content
- Keeps music art + bars visible when closed
- Only one thing at a time (no fighting over the notch)
- Auto-closes when time's up

## Parameters

| Param | Type | Must Have | What It Does |
|-------|------|-----------|-------------|
| `duration` | number | yep | How long to show (1-60 seconds, we clamp it) |
| `left` | string | yep | App bundle ID for the icon (like `com.apple.findmy`) |
| `right` | string | nah | Right side: `text:...`, `icon:...`, `image:...`, or `gif:...` |
| `content` | string | yep | Main stuff: `text:...`, `image:...`, or `gif:...` |

For images/GIFs, use file:// or https:// URLs. If the image doesn't load, well, that's on you.

## Examples

Basic text:

```
open "notch://show?duration=6&left=com.apple.findmy&right=text:LIVE&content=text:Hello from the notch"
```

Icon on right, image in middle:

```
open "notch://show?duration=4&left=com.apple.findmy&right=icon:bolt.horizontal.fill&content=image:https://example.com/pic.png"
```

GIF right, text main:

```
open "notch://show?duration=5&left=com.apple.findmy&right=gif:file:///tmp/blink.gif&content=text:Loading..."
```

Swift snippet I use:

```swift
func showInNotch() {
    let params = [
        "duration": "6",
        "left": Bundle.main.bundleIdentifier ?? "com.unknown",
        "right": "text:ALERT",
        "content": "text:Check this out"
    ]
    var comps = URLComponents(string: "notch://show")!
    comps.queryItems = params.map { URLQueryItem(name: $0, value: $1) }
    if let url = comps.url {
        NSWorkspace.shared.open(url)
    }
}
```

## How It Behaves

1. New requests get ignored if something's already showing.
2. Duration gets forced between 1-60.
3. Left icon needs a real app bundle on the machine.
4. Right/content must be valid types with good values.
5. Text shrinks and wraps to fit.

Music keeps playing - closed notch shows art + bars, open shows your content.

## Visual Stuff

- Left icon is tiny, matches music style.
- Content fills the notch width, clips if too big.
- Images/GIFs fit to aspect.

## Gotchas

- No saving after timeout.
- Can't click or interact.
- One at a time, no line waiting.

## Notes from Development

Built this while messing around with macOS APIs. URL schemes are dead simple - no servers, no permissions drama. Used SwiftUI for the views, Metal for animations (overkill, but fun). Tested on my M1 MacBook, YMMV.
