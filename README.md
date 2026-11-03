# VOE Monitor

Power outage schedule for Vinnytsia region, right in your menubar.

Tired of checking voe.com.ua? This app puts that info one click away. Pick your queue, and it shows you what's happening now and what's coming next.

## What it looks like

The menubar icon changes based on your current power status:

- **Bolt** — power is on
- **Crossed-out bolt** — power is off
- **Bolt with a warning badge** — no schedule for right now (no queue picked, or no data yet)

Click the icon to see a detailed hourly schedule for today and tomorrow. An hour with a 30-minute outage is drawn half red, half green, and the status flips on the half hour.

## Install

**Homebrew** (recommended):

```bash
brew tap yefimtsev/voe-monitor https://github.com/yefimtsev/voe-monitor
brew install --cask yefimtsev/voe-monitor/voe-monitor
```

The full name in the second command is what tells Homebrew to trust this cask (Homebrew 6+ asks for explicit trust in third-party taps).

Installed it from the old `yefimtsev/tap` before? Switch once with `brew uninstall --cask voe-monitor && brew untap yefimtsev/tap`, then run the two commands above.

**Manual**: Download the latest `.dmg` from [Releases](https://github.com/yefimtsev/voe-monitor/releases), open it, drag to Applications.

Requires **macOS 26 (Tahoe)** or later. On Sequoia, stay on [1.2.1](https://github.com/yefimtsev/voe-monitor/releases/tag/v1.2.1).

**iPhone**: an iOS app with home and lock screen widgets is in TestFlight beta.

## Usage

1. Launch the app — it lives in the menubar, no dock icon.
2. Click the bolt icon → Settings → pick your queue.
3. That's it. The schedule refreshes automatically every 10 minutes.

The app tells you when the next outage or restoration is expected, with a countdown (`~2h 35m`) so you can plan around it. If there's an app update available, a banner will show up in the panel.

In settings you can also:

- Turn on **notifications** for power going off and coming back, and a warning 15, 30 or 60 minutes before an outage. They are scheduled ahead from the timetable, so they don't depend on the app refreshing at the right moment
- Switch between **English and Ukrainian** (or follow system language)
- Choose **12-hour or 24-hour** time format
- Enable **Launch at Login**

## Where the data comes from

The schedule is fetched from a [community-maintained JSON file](https://github.com/vn-progr/gpv-voe-vinnytsia) that mirrors the official Вінницяобленерго outage data. It's updated every ~10 minutes by a separate project — this app just reads and displays it.

## Building from source

You'll need Xcode 26+.

```bash
# macOS app
xcodebuild -project VOEMonitor.xcodeproj -scheme VOEMonitor build

# iOS app and widget
xcodebuild -project VOEMonitor.xcodeproj -scheme VOEMonitorIOS -destination 'generic/platform=iOS Simulator' build

# Tests for the shared schedule logic
swift test
```

No external dependencies. Pure Swift and SwiftUI.

## Tech details

- Swift 6 with strict concurrency
- SwiftUI + Observation framework
- Liquid Glass on macOS 26 and iOS 26 (material fallback on iOS 18–25)
- Localized in English and Ukrainian with a String Catalog (in-app override on macOS)
- Network access is outbound HTTPS to GitHub only. The macOS app is a notarized Developer ID build, not sandboxed
- Zero external packages

## License

MIT

## Acknowledgments

Schedule data provided by the [vn-progr/gpv-voe-vinnytsia](https://github.com/vn-progr/gpv-voe-vinnytsia) project.
