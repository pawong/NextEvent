//
//  AppDelegate.swift
//  NextEvent
//
//  Created by Paul Wong on 1/28/18.
//  Copyright © 2018 Paul Wong. All rights reserved.
//

import Cocoa
import EventKit
import UserNotifications


@main
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, UNUserNotificationCenterDelegate {

    let GLOW_INTERVAL   = 0.1

    @IBOutlet weak var mainMenu: NSMenu!

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    let eventMenu = NSMenu()

    var timer: Timer!
    var preferenceController: NSWindowController!
    var aboutBoxController: NSWindowController!
    var aboutBoxView: MZAboutBoxViewController!
    var settings: Settings!
    var viewController: NextEventViewController!

    var icon: NSImage!
    var glowIcon: NSImage!
    var isGlowing: Bool = false
    var isEventMenuOpen: Bool = false
    var yesterday: Date?

    var glowTimer: Timer!
    var imageTrans: CGFloat!
    var glowSpeed: CGFloat = 0.05
    var fadeOut: Bool = false


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

        // notifications: show banners even though this is a menu bar app
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }

        // load settings
        settings = Settings()
        self.processCommandLine()
        viewController = NextEventViewController(settings: settings)

        self.setIcons()
        yesterday = getMidnight(date: Date())

        if let button = statusItem.button {
            button.action = #selector(self.onClickStatusItem)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem.button?.menu = mainMenu
        eventMenu.delegate = self

        // check for access and request notification
        if CalendarTools().requestAccess() == false {
            self.accessErrorDialog()
            exit(0)
        }
        self.registerNotification()
        //CalendarTools().registerNotification(#selector(itemsChanged(_:)))

        // Last things to do
        timer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(fireTimer(_:)),
            userInfo: nil,
            repeats: true
        )
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func fireTimer(_ sender: Any?) {
        self.update()
    }

    func setIcons() {
        if settings.settings.useAltIcon {
            icon = NSImage(named:"mazookie_mb")!
            if settings.settings.useFlashBlue {
                glowIcon = NSImage(named:"mazookie_mb_blue")!
            } else {
                glowIcon = NSImage(named:"mazookie_mb_orange")!
            }
        } else {
            icon = NSImage(named:"next_event_mb")!

            if settings.settings.useFlashBlue {
                glowIcon = NSImage(named:"next_event_mb_blue")!
            } else {
                glowIcon = NSImage(named:"next_event_mb_orange")!
            }
        }
    }

    func getMidnight(date: Date) -> Date {
        let today = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month, .day], from: date)
        )
        return today!
    }

    func update() {

        let now = getMidnight(date: Date())
        if yesterday != now {
            yesterday = now
            viewController.refreshAll(self)
        }

        if viewController.update() == true {
            self.setIcons()
            statusItem.button?.image = icon
        }
        statusItem.button?.attributedTitle = NSAttributedString(
            string: viewController.getNextEventStatus(),
            attributes: [NSAttributedString.Key.font:  NSFont(name: "Helvetica Neue", size: 13)!]
        )
        // keep countdowns live while the drop-down is open
        if isEventMenuOpen {
            viewController.refreshMenuTitles(eventMenu)
        }
        if viewController.shouldGlow {
            if !isGlowing {
                self.startGlow()
            }
        } else if isGlowing {
            self.stopGlow()
        }
    }
    
    @objc func onClickStatusItem(sender: NSButton) {
        let event = NSApp.currentEvent!

        if event.type == NSEvent.EventType.leftMouseUp {
            // Left button click
            showEventMenu()
        } else {
            // Right button click
            NSMenu.popUpContextMenu(sender.menu!, with: event, for: sender)
        }
    }

    @IBAction func refreshAll(_ sender: Any?) {
        viewController.refreshAll(self)
    }

    @objc func itemsChanged(_ notification: Notification) {
        viewController.refreshAll(self)
    }

    @IBAction func openAbout(_ sender: Any?) {
        if aboutBoxController == nil {
            let mainStoryboard = NSStoryboard.init(name: "MZAboutBox", bundle: nil)
            aboutBoxController = mainStoryboard.instantiateController(
                withIdentifier: "MZ About Box") as? NSWindowController
            aboutBoxView = mainStoryboard.instantiateController(
                withIdentifier: "MZ AboutBox Controller"
                ) as? MZAboutBoxViewController
            aboutBoxController.contentViewController = aboutBoxView
            aboutBoxView.setMacId(newMacId: "id879985307")
        }
        aboutBoxController.showWindow(self)
        aboutBoxController.window?.makeKeyAndOrderFront(self)
        aboutBoxView.forceHelp(force: false)
        NSApp.activate(ignoringOtherApps: true)
    }

    @IBAction func openHelp(_ sender: Any?) {
        if aboutBoxController == nil {
            let mainStoryboard = NSStoryboard.init(name: "MZAboutBox", bundle: nil)
            self.aboutBoxController = mainStoryboard.instantiateController(
                withIdentifier: "MZ About Box") as? NSWindowController
            aboutBoxView = mainStoryboard.instantiateController(
                withIdentifier: "MZ AboutBox Controller"
                ) as? MZAboutBoxViewController
            aboutBoxController.contentViewController = aboutBoxView
            aboutBoxView.setMacId(newMacId: "id879985307")
        }
        aboutBoxController.showWindow(self)
        aboutBoxController.window?.makeKeyAndOrderFront(self)
        aboutBoxView.forceHelp(force: true)
        NSApp.activate(ignoringOtherApps: true)
    }

    @IBAction func openNextEventPreferencePanel(_ sender: Any?) {
        if preferenceController == nil {
            let mainStoryboard = NSStoryboard.init(name: "NextEventPreferences", bundle: nil)
            preferenceController = mainStoryboard.instantiateController(withIdentifier: "Preference Panel") as? NSWindowController
        }
        preferenceController.showWindow(self)
        preferenceController.window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Drops the event menu down from the status item. The menu is attached
    /// only while it is shown so right-clicks still get the context menu.
    func showEventMenu() {
        statusItem.menu = eventMenu
        statusItem.button?.performClick(nil)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        viewController.populateMenu(menu)
    }

    func menuWillOpen(_ menu: NSMenu) {
        isEventMenuOpen = true
    }

    func menuDidClose(_ menu: NSMenu) {
        isEventMenuOpen = false
        statusItem.menu = nil
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping @Sendable (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func registerNotification() {
        let eventStore = EKEventStore()
        // Observers are registered once per granted permission (events, reminders),
        // matching the previous behavior.
        Task { @MainActor in
            if (try? await eventStore.requestFullAccessToEvents()) == true {
                self.addStoreObserver()
            }
            if (try? await eventStore.requestFullAccessToReminders()) == true {
                self.addStoreObserver()
            }
        }
    }

    private func addStoreObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.itemsChanged(_:)),
            name: .EKEventStoreChanged,
            object: nil
        )
    }

    func accessErrorDialog() {
        let alert = NSAlert()
        alert.informativeText = "Please enable access in System Preferences - Security and Privacy, then restart."
        alert.messageText = "Access to calendar or reminder data has been denied!"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func processCommandLine() {
        let arguments = ProcessInfo.processInfo.arguments
        // reset takes takes priority
        for i in 0..<arguments.count {
            if (arguments[i] == "-R") {
                settings.reset()
            }
        }
        // now handle the rest
        for i in 0..<arguments.count {
            if (arguments[i] == "-F:1") {
                settings.settings.floatRight = true
            }
            else if (arguments[i] == "-F:0") {
                settings.settings.floatRight = false
            }
        }
    }

    func combineImages(base: NSImage, overlay: NSImage, fraction: CGFloat) -> NSImage {

        let aImage: NSImage = NSImage(size: base.size)
        aImage.lockFocus()

        base.draw(in: CGRect(origin: CGPoint.zero, size: base.size))
        overlay.draw(
            in: CGRect(origin: CGPoint.zero, size: overlay.size),
            from: CGRect(origin: CGPoint.zero, size: overlay.size),
            operation: NSCompositingOperation.overlay,
            fraction: fraction
        )

        aImage.unlockFocus()
        return aImage
    }

    func startGlow() {
        if glowTimer == nil {
            isGlowing = true
            // Set up our timer to periodically call the glow: method.
            glowTimer = Timer.scheduledTimer(
                timeInterval: GLOW_INTERVAL,
                target: self,
                selector: #selector(glow(_:)),
                userInfo: nil,
                repeats: true
            )
            RunLoop.current.add(glowTimer, forMode: RunLoop.Mode.common)
            fadeOut = false
            imageTrans = 1.0
        }
    }

    func stopGlow() {
        // kill timer
        if glowTimer != nil {
            isGlowing = false
            glowTimer.invalidate()
            glowTimer = nil
            statusItem.button?.image = icon
        }
    }

    @objc func glow(_ sender: Any?) {
        if fadeOut && imageTrans >= glowSpeed {
            // If window is still partially opaque, reduce its opacity.
            imageTrans = imageTrans - glowSpeed
        }
        else if !fadeOut && (imageTrans < (1.0 - glowSpeed)) {
            // If window is still partially opaque, increase its opacity.
            imageTrans = imageTrans + glowSpeed
        }
        else {
            fadeOut = !fadeOut
        }

        // redraw icon
        statusItem.button?.image = self.combineImages(base: icon, overlay: glowIcon, fraction: imageTrans)
    }

}
