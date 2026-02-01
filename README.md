## What is this?

The goal of this project is to take [doomgeneric](https://github.com/ozkl/doomgeneric) and port it over to Apple devices. This was mostly a weekend hack and may not progress any further.

[YouTube video of it running on an Apple Watch.](https://youtube.com/shorts/Z2bWLXOEflI)

| macOS | Apple Watch |
| - | - |
| <img alt="DOOM on macOS" src="https://github.com/twstokes/DarwinDOOM/assets/2092798/40b54b8c-ac1b-49a7-bbc7-c0674d4b82fe"> | <img alt="DOOM on watchOS" src="https://github.com/twstokes/DarwinDOOM/assets/2092798/cf3ae161-735a-422a-9ad8-1fd11f6f83f6"> |




- macOS has sound via AVFoundation (SFX + MIDI music).
- iOS has sound via AVFoundation (SFX + MIDI music; uses bundled soundfont). Note: the iOS Simulator's MIDI instruments can sound rough; on-device playback is fine.
- watchOS: experimental SFX sound scaffolding (AVFoundation). Music is disabled for now.
- macOS includes an optional Face Control mode (menu bar toggle) that uses the camera to drive the Doom Guy’s face.
  Supported expressions: forward, look left, look right, grin, mouth open, eyebrow raise (left), eyebrow raise (right).

## Setup (macOS)

1) Build and run.

2) (Optional) Replace the bundled shareware WAD by dropping another WAD into `DarwinDOOM/WADs`.


## Controls

iOS and Watch apps have touch controls.

The full screen is divided into a 3x3 grid:

```
left  |  up  |  right 
----------------------
left  |  up  |  right
----------------------
action | down | fire
----------------------
```

**Action** changes based on game state: ENTER (Menu) or USE (In-Game)

**Fire** also changes based on game state: ESCAPE (Menu) or FIRE (In-Game)

Keyboard controls (macOS + iOS with a hardware keyboard):
- Arrow keys: move/turn
- Control: fire
- Space: fire (or space when typing)
- E: use (or "e" when typing)
- Enter: menu/select
- Escape: back
- Tab: automap
- Shift: run
- Backspace: backspace when typing

Controls can be adjusted in `TouchToKeyManager.swift`.
