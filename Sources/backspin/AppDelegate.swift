import AppKit
import ApplicationServices
import ScrollCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let menu = NSMenu()
    private let defaults = UserDefaults.standard
    private let loginAccess = LoginItemAccess.system
    private let tap = ScrollTap()
    private let stateItem = NSMenuItem()
    private let enableItem = NSMenuItem(title: "Reverse Mouse Wheel", action: #selector(toggleEnabled), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private let permissionItem = NSMenuItem()
    private let requestItem = NSMenuItem(title: "Grant Accessibility Access…", action: #selector(requestAccessibility), keyEquivalent: "")
    private let trackpadItem = NSMenuItem(title: "Open Trackpad Settings…", action: #selector(openTrackpadSettings), keyEquivalent: "")
    private var statusItem: NSStatusItem?
    private var refreshTimer: Timer?

    private var requestedEnabled: Bool { defaults.bool(forKey: "enabled") }

    override init() {
        super.init()
        defaults.register(defaults: ["enabled": true])
        menu.autoenablesItems = false
        menu.delegate = self
        addInfo("backspin")
        stateItem.isEnabled = false
        menu.addItem(stateItem)
        menu.addItem(.separator())
        for item in [enableItem, loginItem] {
            item.target = self
            menu.addItem(item)
        }
        menu.addItem(.separator())
        permissionItem.isEnabled = false
        menu.addItem(permissionItem)
        requestItem.target = self
        menu.addItem(requestItem)
        addAction("Open Accessibility Settings…", #selector(openAccessibilitySettings))
        trackpadItem.target = self
        menu.addItem(trackpadItem)
        menu.addItem(.separator())
        addAction("Quit backspin", #selector(quit), key: "q")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.menu = menu
        item.button?.setAccessibilityLabel("backspin")
        statusItem = item
        if !AXIsProcessTrusted() { requestAccessibility() }
        refresh()
        // Accessibility grants and the Natural scrolling toggle arrive without any notification.
        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in self?.refresh() }
        refreshTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTimer?.invalidate()
        tap.stop()
    }

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
    }

    @objc private func refresh() {
        let trusted = AXIsProcessTrusted()
        let natural = ScrollFlip.systemNaturalScrolling()
        tap.naturalScrolling = natural
        if requestedEnabled && trusted { _ = tap.start() } else { tap.stop() }

        enableItem.state = requestedEnabled ? .on : .off
        let login = loginAccess.status()
        loginItem.state = login == .enabled ? .on : login == .requiresApproval ? .mixed : .off
        permissionItem.title = "Accessibility: \(trusted ? "Allowed" : "Not allowed")"
        requestItem.isHidden = trusted
        trackpadItem.isHidden = natural

        let status: String
        let symbol: String
        if !requestedEnabled {
            (status, symbol) = ("Paused", "pause.circle")
        } else if !trusted {
            (status, symbol) = ("Accessibility required", "exclamationmark.circle")
        } else if !tap.isRunning {
            (status, symbol) = ("Scroll events unavailable", "exclamationmark.circle")
        } else if !natural {
            (status, symbol) = ("Turn on Natural scrolling for the trackpad", "exclamationmark.circle")
        } else {
            (status, symbol) = ("Mouse traditional, trackpad natural", "computermouse")
        }
        stateItem.title = "Status: \(status)"
        if let button = statusItem?.button {
            let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "backspin")
            image?.isTemplate = true
            button.image = image
            button.title = image == nil ? "SS" : ""
            button.toolTip = "backspin — \(status)"
        }
    }

    @objc private func toggleEnabled() {
        defaults.set(!requestedEnabled, forKey: "enabled")
        refresh()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            switch loginAccess.status() {
            case .enabled, .requiresApproval: try loginAccess.unregister()
            default: try loginAccess.register()
            }
        } catch {
            showAlert("Could not change Launch at Login", error.localizedDescription)
        }
        refresh()
    }

    @objc private func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    @objc private func openAccessibilitySettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
             fallback: "Open System Settings → Privacy & Security → Accessibility and enable backspin.")
    }

    @objc private func openTrackpadSettings() {
        open("x-apple.systempreferences:com.apple.Trackpad-Settings.extension",
             fallback: "Open System Settings → Trackpad → Scroll & Zoom and turn on Natural scrolling.")
    }

    private func open(_ link: String, fallback: String) {
        guard let url = URL(string: link), NSWorkspace.shared.open(url) else {
            showAlert("Open System Settings", fallback)
            return
        }
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        NSApplication.shared.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func addInfo(_ title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    private func addAction(_ title: String, _ action: Selector, key: String = "") {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
    }
}
