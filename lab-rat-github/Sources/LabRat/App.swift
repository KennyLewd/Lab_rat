import AppKit
import SwiftUI
import UserNotifications

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var store: LabStore!
    private var workspace: NSWindow!
    private var companion: NSPanel!
    private var statusItem: NSStatusItem!
    private var statusExperiment: NSMenuItem!
    private var statusFocus: NSMenuItem!
    private var statusSamples: NSMenuItem!
    private var pauseItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        if let iconURL = Bundle.main.url(forResource: "LabRat", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = icon
        }
        UNUserNotificationCenter.current().delegate = self
        store = LabStore()
        createWorkspace(); createCompanion(); createMenu()
        store.onTick = { [weak self] in self?.updateMenu() }
        store.onPreferencesChanged = { [weak self] in self?.applyPreferences() }
        applyPreferences(); updateMenu(); showWorkspace()
    }
    private func createWorkspace() {
        workspace = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1040, height: 780), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        workspace.title = "Lab Rat · Research companion"
        workspace.isReleasedWhenClosed = false
        workspace.minSize = NSSize(width: 980, height: 748)
        workspace.backgroundColor = NSColor(srgbRed: 0.09, green: 0.1, blue: 0.095, alpha: 1)
        workspace.appearance = NSAppearance(named: .darkAqua)
        workspace.contentView = NSHostingView(rootView: Dashboard(store: store, showCompanion: { [weak self] in self?.showCompanion() }))
        workspace.center()
    }
    private func createCompanion() {
        companion = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 284, height: 460), styleMask: [.titled, .closable, .utilityWindow, .nonactivatingPanel], backing: .buffered, defer: false)
        companion.title = "Lab Rat"
        companion.isReleasedWhenClosed = false
        companion.isFloatingPanel = true
        companion.hidesOnDeactivate = false
        companion.isMovableByWindowBackground = true
        companion.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        companion.appearance = NSAppearance(named: .darkAqua)
        companion.backgroundColor = NSColor(srgbRed: 0.133, green: 0.149, blue: 0.141, alpha: 1)
        companion.contentView = NSHostingView(rootView: CompanionView(store: store, showWorkspace: { [weak self] in self?.showWorkspace() }, hide: { [weak self] in self?.companion.orderOut(nil) }))
        if let frame = NSScreen.main?.visibleFrame { companion.setFrameOrigin(NSPoint(x: frame.maxX - 310, y: frame.maxY - 505)) }
        companion.setFrameAutosaveName("LabRatCompanion")
    }
    private func createMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = mouseMenuIcon()
        statusItem.button?.imagePosition = .imageLeading
        let menu = NSMenu()
        statusExperiment = NSMenuItem(title: "No experiment selected", action: nil, keyEquivalent: ""); menu.addItem(statusExperiment)
        statusFocus = NSMenuItem(title: "Run · 25:00", action: nil, keyEquivalent: ""); menu.addItem(statusFocus)
        statusSamples = NSMenuItem(title: "No samples on the clock", action: nil, keyEquivalent: ""); menu.addItem(statusSamples)
        menu.addItem(.separator())
        addMenuItem(menu, "Open workspace", #selector(openWorkspace), "o")
        addMenuItem(menu, "Show floating buddy", #selector(openCompanion), "b")
        pauseItem = addMenuItem(menu, "Start run", #selector(toggleRun), "p")
        addMenuItem(menu, "Reset focus timer", #selector(resetRun), "")
        menu.addItem(.separator())
        addMenuItem(menu, "Quit Lab Rat", #selector(quitApp), "q")
        statusItem.menu = menu
        let main = NSMenu(); let appItem = NSMenuItem(); main.addItem(appItem)
        let appMenu = NSMenu(); appItem.submenu = appMenu
        addMenuItem(appMenu, "About Lab Rat", #selector(about), "")
        appMenu.addItem(.separator())
        addMenuItem(appMenu, "Open workspace", #selector(openWorkspace), "o")
        addMenuItem(appMenu, "Show floating buddy", #selector(openCompanion), "b")
        appMenu.addItem(.separator())
        addMenuItem(appMenu, "Hide Lab Rat", #selector(hideApp), "h")
        addMenuItem(appMenu, "Quit Lab Rat", #selector(quitApp), "q")
        let fileItem = NSMenuItem(); fileItem.title = "File"; main.addItem(fileItem)
        let fileMenu = NSMenu(title: "File"); fileItem.submenu = fileMenu
        fileMenu.addItem(NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        let editItem = NSMenuItem(); editItem.title = "Edit"; main.addItem(editItem)
        let editMenu = NSMenu(title: "Edit"); editItem.submenu = editMenu
        for (title, action, key) in [("Undo", Selector(("undo:")), "z"), ("Cut", #selector(NSText.cut(_:)), "x"), ("Copy", #selector(NSText.copy(_:)), "c"), ("Paste", #selector(NSText.paste(_:)), "v"), ("Select All", #selector(NSText.selectAll(_:)), "a")] { editMenu.addItem(NSMenuItem(title: title, action: action, keyEquivalent: key)) }
        NSApp.mainMenu = main
    }
    private func mouseMenuIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 18), flipped: false) { _ in
            NSColor.black.setFill()
            for rect in [NSRect(x: 1, y: 9, width: 8, height: 8), NSRect(x: 11, y: 9, width: 8, height: 8), NSRect(x: 4, y: 1, width: 12, height: 13)] {
                NSBezierPath(ovalIn: rect).fill()
            }
            let whiskers = NSBezierPath(); whiskers.lineWidth = 1; whiskers.lineCapStyle = .round
            for y: CGFloat in [4, 7] {
                whiskers.move(to: NSPoint(x: 0.5, y: y + 1)); whiskers.line(to: NSPoint(x: 5, y: y))
                whiskers.move(to: NSPoint(x: 15, y: y)); whiskers.line(to: NSPoint(x: 19.5, y: y + 1))
            }
            NSColor.black.setStroke(); whiskers.stroke()
            if let context = NSGraphicsContext.current?.cgContext {
                context.saveGState(); context.setBlendMode(.clear)
                for rect in [CGRect(x: 6.5, y: 8, width: 2, height: 2.5), CGRect(x: 11.5, y: 8, width: 2, height: 2.5), CGRect(x: 9, y: 3.5, width: 2, height: 1.5)] { context.fillEllipse(in: rect) }
                context.restoreGState()
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Lab Rat mouse"
        return image
    }
    @discardableResult private func addMenuItem(_ menu: NSMenu, _ title: String, _ action: Selector, _ key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key); item.target = self; menu.addItem(item); return item
    }
    private func updateMenu() {
        let title = store.selected?.title ?? "Lab Rat"
        let short = title.count > 20 ? String(title.prefix(19)) + "…" : title
        let overdue = store.activeTimers.filter { $0.deadline <= store.now }.count
        statusItem.button?.title = " \(short)" + (store.runRunning ? " · \(clockText(store.runSeconds))" : "") + (overdue > 0 ? " !" : "")
        statusItem.button?.toolTip = "Lab Rat · \(title)"
        statusExperiment.title = store.selected?.title ?? "No experiment selected"
        statusFocus.title = "\(store.state.run.phase.rawValue) · \(clockText(store.runSeconds))\(store.runRunning ? " · running" : " · paused")"
        statusSamples.title = "\(store.activeTimers.count) sample timers · \(overdue) overdue"
        pauseItem.title = "\(store.runRunning ? "Pause" : "Start") \(store.state.run.phase.rawValue.lowercased())"
    }
    private func applyPreferences() { companion.level = store.state.alwaysOnTop ? .floating : .normal }
    func showWorkspace() { workspace.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    func showCompanion() { companion.orderFrontRegardless() }
    @objc private func openWorkspace() { showWorkspace() }
    @objc private func openCompanion() { showCompanion() }
    @objc private func toggleRun() { store.toggleRun() }
    @objc private func resetRun() { store.resetRun() }
    @objc private func hideApp() { NSApp.hide(nil) }
    @objc private func quitApp() { NSApp.terminate(nil) }
    @objc private func about() { NSApp.orderFrontStandardAboutPanel(options: [.applicationName: "Lab Rat", .applicationVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.1", .credits: NSAttributedString(string: "A little company for a lot of science.\nLocal notebook · floating buddy · lab calculations")]) }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { showWorkspace(); return true }
    func applicationWillTerminate(_ notification: Notification) { store.save() }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) { completionHandler([.banner]) }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) { Task { @MainActor in self.showWorkspace() }; completionHandler() }
}

@main struct LabRatLauncher {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate(); app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
