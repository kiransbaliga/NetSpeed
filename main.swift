import Cocoa

// MARK: - Network Monitor

class NetworkMonitor {
    private var lastBytesIn: UInt64 = 0
    private var lastBytesOut: UInt64 = 0
    private var lastTime: Date = Date()
    private var isFirstSample = true

    struct Speed {
        let download: Double // bits per second
        let upload: Double   // bits per second
    }

    func sample() -> Speed {
        let (bytesIn, bytesOut) = readBytes()
        let now = Date()
        let elapsed = now.timeIntervalSince(lastTime)

        var speed = Speed(download: 0, upload: 0)

        if !isFirstSample && elapsed > 0 {
            let deltaIn = bytesIn >= lastBytesIn ? bytesIn - lastBytesIn : bytesIn
            let deltaOut = bytesOut >= lastBytesOut ? bytesOut - lastBytesOut : bytesOut
            speed = Speed(
                download: Double(deltaIn) * 8.0 / elapsed,
                upload: Double(deltaOut) * 8.0 / elapsed
            )
        }

        lastBytesIn = bytesIn
        lastBytesOut = bytesOut
        lastTime = now
        isFirstSample = false

        return speed
    }

    private func readBytes() -> (UInt64, UInt64) {
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return (0, 0)
        }
        defer { freeifaddrs(ifaddr) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = cursor {
            let name = String(cString: addr.pointee.ifa_name)
            // Skip loopback
            if name != "lo0" && addr.pointee.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                if let data = addr.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self)
                    totalIn += UInt64(networkData.pointee.ifi_ibytes)
                    totalOut += UInt64(networkData.pointee.ifi_obytes)
                }
            }
            cursor = addr.pointee.ifa_next
        }

        return (totalIn, totalOut)
    }
}

// MARK: - Formatting

func formatSpeed(_ bps: Double) -> String {
    if bps >= 1_000_000_000 {
        return String(format: "%.1f Gbps", bps / 1_000_000_000)
    } else if bps >= 1_000_000 {
        return String(format: "%.1f Mbps", bps / 1_000_000)
    } else {
        return String(format: "%.0f Kbps", bps / 1_000)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var monitor = NetworkMonitor()
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // No dock icon
        NSApplication.shared.setActivationPolicy(.accessory)

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
            button.title = "↑ 0 Kbps  ↓ 0 Kbps"
        }

        // Build menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit NetSpeed", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu

        // First sample (baseline)
        _ = monitor.sample()

        // Poll every 2 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateSpeed()
        }
    }

    private func updateSpeed() {
        let speed = monitor.sample()
        let up = formatSpeed(speed.upload)
        let down = formatSpeed(speed.download)
        statusItem.button?.title = "↑ \(up)  ↓ \(down)"
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Main

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
