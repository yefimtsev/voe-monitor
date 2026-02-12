# VOE Monitor

Power outage schedule for Vinnytsia region, right in your menubar.

Tired of checking voe.com.ua? This app puts that info one click away. Pick your queue, and it shows you what's happening now and what's coming next.

## What it looks like

The menubar icon changes based on your current power status:

- **Green bolt** — power is on
- **Red bolt (pulsing)** — power is off
- **Orange bolt** — partial outage (half-hour cutoff)

Click the icon to see a detailed hourly schedule for today and tomorrow.

## Install

**Homebrew** (recommended):

```bash
brew tap yefimtsev/tap
brew install --cask voe-monitor
```

**Manual**: Download the latest `.zip` from [Releases](https://github.com/yefimtsev/voe-monitor/releases), unzip, drag to Applications.

First launch (manual install): right-click the app → Open (needed once because the app isn't code-signed).

Requires **macOS 26 (Tahoe)** or later.

## Usage

1. Launch the app — it lives in the menubar, no dock icon.
2. Click the bolt icon → Settings → pick your queue.
3. That's it. The schedule refreshes automatically every 10 minutes.

The app tells you when the next outage or restoration is expected, so you can plan around it. If there's an app update available, a blue banner will show up in the panel.

Turn on "Launch at Login" in settings if you want it always running.

## Where the data comes from

The schedule is fetched from a [community-maintained JSON file](https://github.com/vn-progr/gpv-voe-vinnytsia) that mirrors the official Вінницяобленерго outage data. It's updated every ~10 minutes by a separate project — this app just reads and displays it.

## Building from source

You'll need Xcode with macOS 26 SDK and [xcodegen](https://github.com/yonaskolb/XcodeGen).

```bash
# Generate the Xcode project
xcodegen generate

# Build
xcodebuild -project VOEMonitor.xcodeproj -scheme VOEMonitor build
```

No external dependencies. Pure Swift and SwiftUI.

## Tech details

- Swift 6 with strict concurrency
- SwiftUI + Observation framework
- Liquid Glass UI (macOS Tahoe)
- Localized in English and Ukrainian
- Sandboxed, network-only (outbound HTTPS to GitHub)
- Zero external packages

## License

MIT

## Acknowledgments

Schedule data provided by the [vn-progr/gpv-voe-vinnytsia](https://github.com/vn-progr/gpv-voe-vinnytsia) project.
