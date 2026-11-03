cask "voe-monitor" do
  version "1.3.0"
  sha256 "beea47bb5e2208e050655bb536af649642d34baf18de78969c1b3d59c6ba4f10"

  url "https://github.com/yefimtsev/voe-monitor/releases/download/v#{version}/VOEMonitor.dmg"
  name "VOE Monitor"
  desc "Power outage schedule for Vinnytsia region in your menubar"
  homepage "https://github.com/yefimtsev/voe-monitor"

  depends_on macos: :tahoe

  app "VOE Monitor.app"

  zap trash: [
    "~/Library/Application Support/VOEMonitor",
    "~/Library/Caches/VOEMonitor",
    "~/Library/Preferences/com.github.yefimtsev.VOEMonitor.plist",
  ]
end
