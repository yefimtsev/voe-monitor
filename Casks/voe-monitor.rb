cask "voe-monitor" do
  version "1.2.1"
  sha256 "387c1aa2771fc773d732e6af07c21149a0726882bee9fa3d740a937bc090284c"

  url "https://github.com/yefimtsev/voe-monitor/releases/download/v#{version}/VOEMonitor.dmg"
  name "VOE Monitor"
  desc "Power outage schedule for Vinnytsia region in your menubar"
  homepage "https://github.com/yefimtsev/voe-monitor"

  depends_on macos: :sequoia

  app "VOE Monitor.app"

  zap trash: [
    "~/Library/Application Support/VOEMonitor",
    "~/Library/Caches/VOEMonitor",
    "~/Library/Preferences/com.github.yefimtsev.VOEMonitor.plist",
  ]
end
