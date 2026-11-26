//
//  NextEventViewController.swift
//  NextEvent
//
//  Created by Paul Wong on 1/28/18.
//  Copyright © 2018 Paul Wong. All rights reserved.
//

import Cocoa
import EventKit
import UserNotifications


extension Date {

    // Convert UTC (or GMT) to local time
    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }

    // Convert local time to UTC (or GMT)
    func toGlobalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = -TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
    func toString( dateFormat format  : String ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}

/// Loads calendar items, drives notifications, and builds the drop-down
/// menu shown when the status item is clicked.
@MainActor
class NextEventViewController: NSObject {

    var calendarItems: [EKCalendarItem] = []
    var settings: Settings!
    var shouldGlow: Bool = false

    init(settings: Settings) {
        self.settings = settings
        super.init()
    }

    func getDateFromEventItem(_ item: EKCalendarItem) -> Date? {
        var itemDate:Date? = nil
        let type_name = String(describing: type(of: item))
        if type_name == "EKEvent" {
            itemDate = (item as! EKEvent).startDate
        } else if type_name == "EKReminder" {
            let dc = (item as! EKReminder).dueDateComponents
            itemDate = Calendar.current.date(from: dc!)!
        }
        return itemDate
    }
    
    func getLocationFromEventItem(_ item: EKCalendarItem) -> String {
        var location: String = "   "
        let type_name = String(describing: type(of: item))
        if type_name == "EKEvent" {
            location = (item as! EKEvent).location ?? "   "
        } else if type_name == "EKReminder" {
            // Don't read the reminder's alarms (where location-based reminders
            // keep their place): EventKit can throw an Objective-C exception
            // ("-[__NSSetM addObject:]: object cannot be nil") building that list,
            // which Swift can't catch.
            location = (item as! EKReminder).location ?? "   "
        }
        return location
    }
    
    func getTravelTimeFromEventItem(_ item: EKCalendarItem) -> TimeInterval {
        var travelTime: TimeInterval = 0
        let type_name = String(describing: type(of: item))
        if type_name == "EKEvent" {
            travelTime = (item as! EKEvent).value(forKey: "travelTime") as! TimeInterval
        }

        return travelTime
    }

    func isAllDay(_ item: EKCalendarItem) -> Bool {
        var retval: Bool = false
        let type_name = String(describing: type(of: item))
        if type_name == "EKEvent" {
            retval = (item as! EKEvent).isAllDay
        }

        return retval
    }


    func getTimeString(_ itemDate: Date?) -> String {
        var fullTime: String = ""
        if itemDate != nil {
            let now = Date()
            // Get conversion to months, days, hours, minutes
            let unitFlags = Set<Calendar.Component>([.day, .hour, .minute, .second])
            let breakdownInfo: DateComponents? = Calendar.current.dateComponents(unitFlags, from: now,  to: itemDate!)
            fullTime = TimeStringTools().getTimeString(
                breakdownInfo!,
                showSeconds: settings.settings.showSeconds,
                leadingZeros: settings.settings.leadingZeros
            )
        }
        return fullTime
    }
    
    func getLeadTimeStrings(_ itemDate: Date?) -> (leadTime: String, leadTimeUnit: String) {
        var leadTime: String = ""
        var leadTimeUnit: String = ""
        if itemDate != nil {
            let now = Date()
            // Get conversion to months, days, hours, minutes
            let unitFlags = Set<Calendar.Component>([.day, .hour, .minute, .second])
            let breakdownInfo: DateComponents? = Calendar.current.dateComponents(unitFlags, from: now,  to: itemDate!)
            (leadTime, leadTimeUnit) = TimeStringTools().getLeadTime(
                breakdownInfo!
            )
        }
        return (leadTime, leadTimeUnit)
    }

    func getTimeString(_ item: EKCalendarItem) -> String {
        var fullTime: String = ""
        let itemDate: Date? = getDateFromEventItem(item)
        if itemDate != nil {
            let now = Date()
            // Get conversion to months, days, hours, minutes
            let unitFlags = Set<Calendar.Component>([.day, .hour, .minute, .second])
            let breakdownInfo: DateComponents? = Calendar.current.dateComponents(unitFlags, from: now,  to: itemDate!)
            fullTime = TimeStringTools().getTimeString(
                breakdownInfo!,
                showSeconds: settings.settings.showSeconds,
                leadingZeros: settings.settings.leadingZeros
            )
        }
        return fullTime
    }

    func getNextEvent() -> Int {
        for i in 0 ..< calendarItems.count {
            let itemDate: Date? = getDateFromEventItem(calendarItems[i])

            if (itemDate != nil) && itemDate! > Date() {
                return i
            }
        }
        return -1
    }

    func getNextEventStatus() -> String {
        var statusString: String = ""

        if settings.settings.showTitle || settings.settings.showTime {
            let n = getNextEvent()
            if n >= 0 {
                let item = calendarItems[n]
                let itemDate: Date? = getDateFromEventItem(item)
                let now = Date()
                // Get conversion to months, days, hours, minutes
                let unitFlags = Set<Calendar.Component>([.day, .hour, .minute, .second])
                let breakdownInfo: DateComponents? = Calendar.current.dateComponents(unitFlags, from: now,  to: itemDate!)

                // should glow?
                if settings.settings.useFlash && !shouldGlow {
                    if (itemDate?.timeIntervalSinceNow)! <= 900 {
                        shouldGlow = true
                    }
                }

                if settings.settings.showTime {
                    if settings.settings.useFuzzyTime {
                        statusString = TimeStringTools().getFuzzyStatusString((itemDate?.timeIntervalSinceNow)!)
                        //if #available(OSX 10.15, *) {
                        //    statusString = RelativeDateTimeFormatter().localizedString(for: itemDate!, relativeTo: now)
                        //} else {
                        //    statusString = TimeStringTools().getFuzzyStatusString((itemDate?.timeIntervalSinceNow)!)
                        //}
                    } else {
                        statusString = TimeStringTools().getStatusString(
                            breakdownInfo!,
                            showSeconds: settings.settings.showSeconds
                        )
                    }
                }
                if settings.settings.showTitle {
                    var title = item.title
                    if settings.settings.useTitleLimit && item.title.count > 20 {
                        title = item.title[..<item.title.index(item.title.startIndex, offsetBy: 20)] + "..."
                    }
                    if statusString.isEmpty {
                        statusString = title!
                    } else if statusString.contains("tomorrow") || statusString.contains("next") {
                        statusString = title! + " " + statusString
                    } else {
                        statusString = title! + " in " + statusString
                    }
                }
                
            } else {
                statusString = "N/A"
                shouldGlow = false
            }
        }
        return statusString
    }

    func update() -> Bool {
        var has_changed: Bool = false

        if settings.needsDisplay == true {

            self.refreshAll(self)

            settings.needsDisplay = false
            has_changed = true
        }

        self.notify()
        return has_changed
    }

    func alert(title: String, date: Date, location: String, color: NSColor, playSound: Bool = false) {
        DispatchQueue.main.async {
            
            var alertBoxWindow: MZAlertBoxWindowController!
            var alertBoxView: MZAlertBoxViewController!

            let mainStoryboard = NSStoryboard.init(name: "MZAlertBox", bundle: nil)
            
            alertBoxWindow = mainStoryboard.instantiateController(
                withIdentifier: "MZ Alert Box Window Controller"
            ) as? MZAlertBoxWindowController
            
            alertBoxView = mainStoryboard.instantiateController(
                withIdentifier: "MZ Alert Box Controller"
            ) as? MZAlertBoxViewController
            
            alertBoxWindow!.contentViewController = alertBoxView

            alertBoxView!.eventTitleString = title
            alertBoxView!.eventDate = date
            alertBoxView!.playSound = playSound
            alertBoxView!.eventDateTextField.stringValue = "\(date.description(with: .current))"
            let fixLocation = location.replacingOccurrences(
                of: "\n",
                with: ", ",
                options: .regularExpression
            )
            alertBoxView!.eventLocationButton.title = fixLocation
            if (URL(string: fixLocation) == nil) {
                alertBoxView!.eventLocationButton.isEnabled = false
                if let cell = alertBoxView!.eventLocationButton.cell as? NSButtonCell {
                    cell.imageDimsWhenDisabled = false
                }
            }
            alertBoxView!.calendarColorTextField.backgroundColor = color

            alertBoxWindow!.window?.collectionBehavior = .moveToActiveSpace
            alertBoxWindow!.window?.makeKeyAndOrderFront(self)
            alertBoxWindow!.window?.collectionBehavior = .canJoinAllSpaces
            alertBoxWindow!.showWindow(self)
                      
            NSApp.activate(ignoringOtherApps: true)
        }
        
    }

    /// Posts an immediate user notification via UserNotifications.
    func postNotification(title: String, body: String, sound: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound ? .default : nil
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func notify() {
        if settings.settings.useSystemAlert || settings.settings.useBlockingAlert {

            for item in calendarItems {
                
                let now: Date = Date()
                let itemDate:Date? = getDateFromEventItem(item)
                let itemLocation: String = getLocationFromEventItem(item)
                var color: NSColor = NSColor.white
                if item.calendar != nil && item.calendar!.color != nil{
                    color = item.calendar!.color
                }

                if item.title.isEmpty || item.title == "N/A" || itemDate! < now {
                    shouldGlow = false
                    continue
                }
                
                // notify travel
                if settings.settings.notifyTravelTime {
                    let travelTime = getTravelTimeFromEventItem(item)

                    if travelTime > 0 {
                        let tt = ceil((itemDate!.addingTimeInterval(0-travelTime)).timeIntervalSinceReferenceDate)
                        if ceil(now.timeIntervalSinceReferenceDate) == tt {
                            if settings.settings.useSystemAlert {
                                postNotification(
                                    title: "Time to leave for \(item.title ?? "Next Event")",
                                    body: "\(itemDate!.description(with: .current))",
                                    sound: settings.settings.useSound
                                )
                            } else if settings.settings.useSound {
                                NSSound.beep()
                            }
                            
                            if settings.settings.useBlockingAlert {
                                self.alert(title: "Time to leave for \(item.title ?? "Next Event")", date: itemDate!, location: itemLocation, color: color)
                            }
                            
                            shouldGlow = true
                        }
                    }
                }

                // notify event
                //print("\(ceil(now.timeIntervalSinceReferenceDate)) == \(ceil(itemDate.timeIntervalSinceReferenceDate)), \(item.title ?? "No title")")
                if ceil(now.timeIntervalSinceReferenceDate) == ceil(itemDate!.timeIntervalSinceReferenceDate) {
                    
                    if settings.settings.useSystemAlert {
                        postNotification(
                            title: item.title,
                            body: "\(itemDate!.description(with: .current))",
                            sound: settings.settings.useSound
                        )
                    } else if settings.settings.useSound {
                        NSSound.beep()
                    }
                    
                    if settings.settings.useBlockingAlert && settings.settings.earlyWarning == 0 {
                        self.alert(title: item.title, date: itemDate!, location: itemLocation, color: color)
                    }
                    
                    shouldGlow = false
                    self.refreshAll(self)
                }
                
                // notify early warning
                if settings.settings.earlyWarning > 0 && settings.settings.useBlockingAlert {
                    let tt = ceil((itemDate!.addingTimeInterval(0-TimeInterval(settings.settings.earlyWarning*60) )).timeIntervalSinceReferenceDate)
                    if ceil(now.timeIntervalSinceReferenceDate) == tt {
                        self.alert(title: item.title, date: itemDate!, location: itemLocation, color: color, playSound: settings.settings.useSound)
                    }
                }
            }
        }
    }

    @IBAction func refreshAll(_ sender: Any?) {
        shouldGlow = false
        if settings == nil {
            let appDelegate = NSApp.delegate as? AppDelegate
            settings = appDelegate?.settings
        }

        let calendars = CalendarTools().getCalendarByNames(names: settings.settings.calendarNames)
        let reminderLists = CalendarTools().getReminderListByNames(names: settings.settings.calendarNames)
        if settings.settings.showNumber > 0 {
            calendarItems = CalendarTools().getTopN(
                n: settings.settings.showNumber,
                calendars: calendars,
                reminders: reminderLists
            )
        } else if settings.settings.showNumber == 0 {
            calendarItems = CalendarTools().getTodayAll(
                calendars: calendars,
                reminders: reminderLists
            )
        } else {
            calendarItems = CalendarTools().get24Hours(
                calendars: calendars,
                reminders: reminderLists
            )
        }
    }

    @IBAction func launchCalendar(_ sender: Any) {
        launchApp(bundleIdentifier: "com.apple.iCal")
    }

    @IBAction func launchReminders(_ sender: Any) {
        launchApp(bundleIdentifier: "com.apple.reminders")
    }

    private func launchApp(bundleIdentifier: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}

extension NextEventViewController {

    /// Rebuilds the drop-down menu: one item per calendar item, followed by the
    /// app actions that used to live in the popover's gear menu.
    func populateMenu(_ menu: NSMenu) {
        menu.removeAllItems()

        if calendarItems.isEmpty {
            let emptyItem = NSMenuItem(title: "No upcoming events", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        }
        for item in calendarItems {
            // the "N/A" placeholder CalendarTools adds when nothing is found has
            // no date, so it gets a plain line rather than the lead time box
            if getDateFromEventItem(item) == nil {
                let placeholderItem = NSMenuItem(title: item.title ?? "N/A", action: nil, keyEquivalent: "")
                placeholderItem.isEnabled = false
                menu.addItem(placeholderItem)
                continue
            }
            let menuItem = NSMenuItem(title: item.title ?? "", action: #selector(openCalendarItem(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = item
            menuItem.attributedTitle = attributedTitle(for: item)
            menuItem.image = leadTimeImage(for: item)
            menu.addItem(menuItem)
        }

        menu.addItem(NSMenuItem.separator())
        let calendarItem = NSMenuItem(title: "Open Calendar", action: #selector(launchCalendar(_:)), keyEquivalent: "")
        calendarItem.target = self
        calendarItem.image = NSImage(named: "calendar_button")
        menu.addItem(calendarItem)
        let remindersItem = NSMenuItem(title: "Open Reminders", action: #selector(launchReminders(_:)), keyEquivalent: "")
        remindersItem.target = self
        remindersItem.image = NSImage(named: "reminder_button")
        menu.addItem(remindersItem)

        menu.addItem(NSMenuItem.separator())
        let appDelegate = NSApp.delegate as? AppDelegate
        for (title, action) in [
            ("Refresh", #selector(AppDelegate.refreshAll(_:))),
            ("Preferences...", #selector(AppDelegate.openNextEventPreferencePanel(_:))),
            ("Help...", #selector(AppDelegate.openHelp(_:))),
        ] {
            let actionItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
            actionItem.target = appDelegate
            menu.addItem(actionItem)
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    /// Refreshes the countdowns of an open menu in place, so it stays live
    /// while the user is looking at it.
    func refreshMenuTitles(_ menu: NSMenu) {
        for menuItem in menu.items {
            if let item = menuItem.representedObject as? EKCalendarItem {
                menuItem.attributedTitle = attributedTitle(for: item)
                menuItem.image = leadTimeImage(for: item)
            }
        }
    }

    /// Tile shown on the left of each menu item: the large lead time number with
    /// its unit underneath, topped by a strip in the calendar's color.
    func leadTimeImage(for item: EKCalendarItem) -> NSImage {
        let itemDate: Date? = getDateFromEventItem(item)
        let isPast = itemDate == nil || itemDate! < Date()
        let (leadTime, leadTimeUnit) = getLeadTimeStrings(itemDate)
        let calendarColor = item.calendar?.color ?? NSColor.white

        let size = NSSize(width: 52, height: 44)
        // drawn lazily so the system colors resolve for the current appearance
        return NSImage(size: size, flipped: true) { rect in
            let tile = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 4, yRadius: 4)
            NSColor.separatorColor.setStroke()
            tile.stroke()

            NSGraphicsContext.saveGraphicsState()
            tile.addClip()
            calendarColor.setFill()
            NSRect(x: 0, y: 0, width: rect.width, height: 4).fill()
            NSGraphicsContext.restoreGraphicsState()

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let textColor = isPast ? NSColor.secondaryLabelColor : NSColor.labelColor
            leadTime.draw(
                in: NSRect(x: 0, y: 4, width: rect.width, height: 26),
                withAttributes: [
                    .font: NSFont(name: "Helvetica Neue", size: 22) ?? NSFont.systemFont(ofSize: 22),
                    .foregroundColor: textColor,
                    .paragraphStyle: paragraph,
                ]
            )
            leadTimeUnit.draw(
                in: NSRect(x: 0, y: 29, width: rect.width, height: 12),
                withAttributes: [
                    .font: NSFont(name: "Helvetica Neue", size: 9) ?? NSFont.systemFont(ofSize: 9),
                    .foregroundColor: textColor,
                    .paragraphStyle: paragraph,
                ]
            )
            return true
        }
    }

    /// Two-line menu title: the title, then the date, time remaining, and
    /// location. Past items are dimmed.
    func attributedTitle(for item: EKCalendarItem) -> NSAttributedString {
        let itemDate: Date? = getDateFromEventItem(item)
        let isPast = itemDate == nil || itemDate! < Date()
        let primaryColor = isPast ? NSColor.secondaryLabelColor : NSColor.labelColor

        let titleFont = NSFont.menuFont(ofSize: 0)
        let detailFont = NSFont.menuFont(ofSize: NSFont.smallSystemFontSize)

        // Fixed line heights make the text exactly as tall as the lead time tile
        // (18 + 13 + 13 = 44), so the title sits at the top instead of the menu
        // centering a shorter block of text against the tile.
        func lineStyle(height: CGFloat) -> NSParagraphStyle {
            let style = NSMutableParagraphStyle()
            style.minimumLineHeight = height
            style.maximumLineHeight = height
            style.lineBreakMode = .byTruncatingTail
            return style
        }
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: detailFont,
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: lineStyle(height: 13),
        ]

        let result = NSMutableAttributedString()
        result.append(NSAttributedString(
            string: item.title ?? "",
            attributes: [
                .font: NSFontManager.shared.convert(titleFont, toHaveTrait: .boldFontMask),
                .foregroundColor: primaryColor,
                .paragraphStyle: lineStyle(height: 18),
            ]
        ))

        // second line: date and time remaining
        var dateLine = ""
        if let itemDate = itemDate {
            dateLine = DateFormatter.localizedString(
                from: itemDate,
                dateStyle: .short,
                timeStyle: isAllDay(item) ? .none : .short
            )
            if isAllDay(item) {
                dateLine += ", All Day"
            }
            let travelTime = getTravelTimeFromEventItem(item)
            if travelTime != 0 {
                dateLine += ", TT +" + TimeStringTools().getTimeStringFromSeconds(
                    travelTime,
                    showSeconds: false,
                    leadingZeros: false
                )
            }
            if !isPast {
                dateLine += "  ·  in " + getTimeString(itemDate)
            }
        }
        result.append(NSAttributedString(string: "\n" + dateLine, attributes: detailAttributes))

        // third line: location, kept even when empty so every item is the same height
        let location = getLocationFromEventItem(item)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: ", ")
        // a non-breaking space stops an empty last line from collapsing
        result.append(NSAttributedString(
            string: "\n" + (location.isEmpty ? "\u{00A0}" : location),
            attributes: detailAttributes
        ))
        return result
    }

    /// Opens the selected event in Calendar or reminder in Reminders. Falls
    /// back to just launching the app if a link to the item can't be built.
    @objc func openCalendarItem(_ sender: NSMenuItem) {
        if let reminder = sender.representedObject as? EKReminder {
            if let url = URL(string: "x-apple-reminderkit://REMCDReminder/\(reminder.calendarItemIdentifier)"),
               NSWorkspace.shared.open(url) {
                return
            }
            launchReminders(sender)
        } else if let event = sender.representedObject as? EKEvent {
            showInCalendar(event)
        }
    }

    /// Scripts Calendar to switch to day view on the event's date and select
    /// the event. Calendar's URL scheme opens the app but doesn't navigate.
    func showInCalendar(_ event: EKEvent) {
        guard let startDate = event.startDate else {
            launchCalendar(event)
            return
        }
        // AppleScript string literals need backslashes and quotes escaped
        func quoted(_ string: String) -> String {
            "\"" + string
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"") + "\""
        }
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: startDate)
        let secondsIntoDay = (parts.hour ?? 0) * 3600 + (parts.minute ?? 0) * 60
        // the date is built field by field so it doesn't depend on the locale;
        // day is set to 1 first so changing the month can't overflow
        let source = """
            set targetDate to current date
            set day of targetDate to 1
            set year of targetDate to \(parts.year ?? 2000)
            set month of targetDate to \(parts.month ?? 1)
            set day of targetDate to \(parts.day ?? 1)
            set time of targetDate to \(secondsIntoDay)
            tell application "Calendar"
                activate
                switch view to day view
                view calendar at targetDate
                try
                    set matches to (every event of calendar \(quoted(event.calendar.title)) whose uid is \(quoted(event.calendarItemExternalIdentifier ?? "")))
                    if matches is not {} then show item 1 of matches
                end try
            end tell
            """
        // selecting the event can take a moment on large calendars, so keep it
        // off the main thread
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&error)
            if let error = error {
                print("Calendar script failed: \(error)")
                DispatchQueue.main.async {
                    let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal")
                    if let url = url {
                        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
                    }
                }
            }
        }
    }
}
