//
//  AppDelegate.swift
//  NextEvent
//
//  Created by Paul Wong on 1/28/18.
//  Copyright © 2018 Paul Wong. All rights reserved.
//

import Cocoa
import EventKit


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let GLOW_INTERVAL   = 0.1

    @IBOutlet weak var mainMenu: NSMenu!

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    let popover = NSPopover()

    var timer: Timer!
    var preferenceController: NSWindowController!
    var aboutBoxController: NSWindowController!
    var aboutBoxView: MZAboutBoxViewController!
    var settings: Settings!
    var viewController: NextEventViewController!

    var icon: NSImage!
    var glowIcon: NSImage!
    var isGlowing: Bool = false
    var yesterday: Date?

    var glowTimer: Timer!
    var imageTrans: CGFloat!
    var glowSpeed: CGFloat = 0.05
    var fadeOut: Bool = false


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

        // load settings
        settings = Settings()
        self.processCommandLine()
        viewController = NextEventViewController.freshController()

        self.setIcons()
        yesterday = getMidnight(date: Date())

        if let button = statusItem.button {
            button.action = #selector(self.onClickStatusItem)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem.button?.menu = mainMenu
        popover.contentViewController = viewController
        popover.behavior = NSPopover.Behavior.transient
        popover.animates = true

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
            togglePopover(self)
        } else {
            // Right button click
            NSMenu.popUpContextMenu(sender.menu!, with: event, for: sender)
        }
    }

    @IBAction func refreshAll(_ sender: Any?) {
        viewController.refreshAll(Any?.self)
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

    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }

    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            NSApplication.shared.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }

    func closePopover(sender: Any?) {
        popover.performClose(sender)
    }

    func registerNotification() {
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: .event, completion: {
            (_ granted: Bool, _ error: Error?) -> Void in
            if granted {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.itemsChanged(_:)),
                    name: .EKEventStoreChanged,
                    object: nil
                )
            }
        })
        eventStore.requestAccess(to: .reminder, completion: {
            (_ granted: Bool, _ error: Error?) -> Void in
            if granted {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.itemsChanged(_:)),
                    name: .EKEventStoreChanged,
                    object: nil
                )
            }
        })
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
