# OpenMin

A lightweight macOS menu bar app that lets you minimize the frontmost window with a **3-finger swipe down** gesture on your trackpad.

![macOS](https://img.shields.io/badge/macOS-12.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **3-finger swipe down** to minimize the active window
- Lives in the menu bar (no Dock icon)
- Intelligent App Exposé detection — won't interfere when browsing windows
- Launch at login option
- Minimal resource usage

## Installation

1. Download the latest `OpenMin.dmg` from [Releases](../../releases)
2. Open the DMG and drag `openmin.app` to your Applications folder
3. Right-click the app and select **Open** (required on first launch since the app isn't notarized)
4. Grant **Accessibility** permissions when prompted (required for window management)

## Permissions

OpenMin requires the following permissions:

- **Accessibility**: To minimize windows via the Accessibility API
- **Input Monitoring**: To detect trackpad gestures (automatically granted with Accessibility on most systems)

To grant permissions: **System Settings → Privacy & Security → Accessibility** → Enable OpenMin

## How It Works

OpenMin uses Apple's private `MultitouchSupport.framework` to read raw trackpad touch data, detecting when 3+ fingers swipe downward. This approach works reliably because it reads touch positions directly, bypassing macOS gesture recognizers that would otherwise consume the input.

The app automatically suppresses the minimize action when you're in App Exposé (triggered by 3-finger swipe up), so you can browse your windows without accidentally minimizing them.

## Building from Source

### Requirements

- Xcode 14+
- macOS 12.0+

### Build

```bash
git clone https://github.com/yourusername/openmin.git
cd openmin
xcodebuild -scheme openmin -configuration Release build
```

The built app will be in `~/Library/Developer/Xcode/DerivedData/openmin-*/Build/Products/Release/`

### Create DMG

```bash
mkdir -p /tmp/openmin-dmg
cp -R ~/Library/Developer/Xcode/DerivedData/openmin-*/Build/Products/Release/openmin.app /tmp/openmin-dmg/
ln -s /Applications /tmp/openmin-dmg/Applications
hdiutil create -volname "OpenMin" -srcfolder /tmp/openmin-dmg -ov -format UDZO OpenMin.dmg
```

## Technical Notes

- App Sandbox is disabled to allow Accessibility API access
- Uses `MultitouchSupport.framework` (private API) — not suitable for Mac App Store distribution
- Gesture threshold: 0.08 normalized trackpad units (~8% of trackpad height)
- Exposé cooldown: 4 seconds after detecting a swipe-up

## Troubleshooting

**Windows aren't minimizing**
- Check that Accessibility permissions are granted in System Settings
- Some apps (like System Settings itself) may not support minimize

**Minimize triggers during App Exposé**
- This shouldn't happen with the built-in detection, but if it does, the cooldown may need adjustment

**Gesture feels too sensitive/insensitive**
- The threshold is set at 0.08 (8% of trackpad height). Modify `deltaY > 0.08` in `AppDelegate.swift` to adjust.

## License

MIT License - feel free to use, modify, and distribute.

## Acknowledgments

- Uses techniques documented by the [MultitouchSupport reverse engineering community](https://github.com/calftrail/Touch)
- Inspired by window management tools like BetterTouchTool and yabai
