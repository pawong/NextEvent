//
//  NextEventViewController.swift
//  NextEvent
//
//  Created by Paul Wong on 1/28/18.
//  Copyright © 2018 Paul Wong. All rights reserved.
//

import Cocoa
import EventKit


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

class KSTableCellView: NSTableCellView {

    @IBOutlet weak var eventTitle: NSTextField!
    @IBOutlet weak var eventDate: NSTextField!
    @IBOutlet weak var eventLocation: NSTextField!
    @IBOutlet weak var eventTime: NSTextField!
    @IBOutlet weak var calendarColor: NSTextField!
    @IBOutlet weak var leadTime: NSTextField!
    @IBOutlet weak var leadTimeUnit: NSTextField!
}

class NextEventViewController: NSViewController {

    @IBOutlet var controllerView: NSView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var tableView: NSTableView!
    var calendarItems: [EKCalendarItem] = []
    var settings: Settings!
    var shouldGlow: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        let appDelegate = NSApp.delegate as? AppDelegate
        settings = appDelegate?.settings

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.refreshAll(self)
    }

    //override func viewWillAppear() {
    //    super.viewWillAppear()
    //    self.refreshAll(self)
    //}
    
    func setControllerViewSize(_ count: Int) {
        var final_count = count

        if final_count < 1 {
            final_count = 10
        }

        DispatchQueue.main.async { [weak self] in
            var cf: NSRect = (self?.controllerView.frame)!
            cf.size.height = CGFloat(82 * final_count + 38)
            self?.controllerView.frame = cf
            self?.view.window?.setContentSize(cf.size)
            let appDelegate = NSApp.delegate as? AppDelegate
            appDelegate?.popover.contentSize = cf.size
        }
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
            let reminder = (item as! EKReminder)
            if reminder.hasAlarms {
                for alarm in reminder.alarms! {
                    let firstLocation = alarm.structuredLocation?.title
                    if firstLocation != nil {
                        location = firstLocation!
                        break;
                    }
                }
            } else {
                location = reminder.location ?? "   "
            }
            
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

    @IBAction func openHelp(_ sender: Any?) {
        let appDelegate = NSApp.delegate as? AppDelegate
        appDelegate?.openHelp(Any?.self)
    }

    @IBAction func openNextEventPreferencePanel(_ sender: Any?) {
        let appDelegate = NSApp.delegate as? AppDelegate
        appDelegate?.openNextEventPreferencePanel(Any?.self)
    }

    func update() -> Bool {
        var has_changed: Bool = false

        if self.view.window?.occlusionState.contains(.visible) ?? false  {
            if settings.needsDisplay == true {

                self.refreshAll(self)

                settings.needsDisplay = false
                has_changed = true
            } else {
                tableView.reloadData()
            }
        }
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

    func notify() {
        var notification: NSUserNotification?

        if settings.settings.useSystemAlert || settings.settings.useBlockingAlert {

            for item in calendarItems {
                
                let now: Date = Date()
                let itemDate:Date? = getDateFromEventItem(item)
                let itemLocation: String = getLocationFromEventItem(item)
                var color: NSColor = NSColor.black
                if item.calendar != nil {
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
                                notification = NSUserNotification()
                                notification?.title = "Time to leave for \(item.title ?? "Next Event")"
                                notification?.informativeText = "\(itemDate!.description(with: .current))"
                                notification?.deliveryDate = now
                                // play sound
                                if settings.settings.useSound {
                                    notification?.soundName = NSUserNotificationDefaultSoundName
                                } else {
                                    notification?.soundName = nil
                                }
                                let center = NSUserNotificationCenter.default
                                center.scheduleNotification(notification!)
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
                        notification = NSUserNotification()
                        notification?.title = item.title
                        notification?.informativeText = "\(itemDate!.description(with: .current))"
                        notification?.deliveryDate = now
                        // play sound
                        if settings.settings.useSound {
                            notification?.soundName = NSUserNotificationDefaultSoundName
                        } else {
                            notification?.soundName = nil
                        }
                        let center = NSUserNotificationCenter.default
                        center.scheduleNotification(notification!)
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
        self.setControllerViewSize(calendarItems.count)
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }

    @IBAction func launchCalendar(_ sender: Any) {
        NSWorkspace.shared.launchApplication("iCal")
    }

    @IBAction func launchReminders(_ sender: Any) {
        NSWorkspace.shared.launchApplication("Reminders")
    }
}

extension NextEventViewController {
    static func freshController() -> NextEventViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = "NextEventViewController"

        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? NextEventViewController else {
            fatalError("Why can't i find NextEventViewController? - Check Main.storyboard")
        }
        return viewcontroller
    }
}

extension NextEventViewController: NSTableViewDataSource, NSTableViewDelegate {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return calendarItems.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let result:KSTableCellView = tableView.makeView(
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "defaultColumn"),
            owner: self
        ) as! KSTableCellView

        let copyCalendarItems = calendarItems
        if copyCalendarItems.count - 1 < row {
            return result
        }

        let now = Date()
        let itemDate: Date? = getDateFromEventItem(copyCalendarItems[row])
        let travelTime = getTravelTimeFromEventItem(copyCalendarItems[row])
        let itemLocation: String = getLocationFromEventItem(copyCalendarItems[row])
        let allDay = isAllDay(copyCalendarItems[row])

        if itemDate == nil || itemDate! < now {
            result.eventTitle.textColor = NSColor.lightGray
            result.eventLocation.textColor = NSColor.lightGray
            result.eventDate.textColor = NSColor.lightGray
            result.eventTime.textColor = NSColor.lightGray
            result.leadTime.textColor = NSColor.lightGray
            result.leadTimeUnit.textColor = NSColor.lightGray
        } else {
            result.eventTitle.textColor = result.calendarColor.textColor
            result.eventLocation.textColor = result.calendarColor.textColor
            result.eventDate.textColor = result.calendarColor.textColor
            result.eventTime.textColor = result.calendarColor.textColor
            result.leadTime.textColor = result.calendarColor.textColor
            result.leadTimeUnit.textColor = result.calendarColor.textColor
        }
        result.eventTitle.stringValue = copyCalendarItems[row].title!
        result.eventLocation.stringValue = itemLocation
        if (itemDate == nil) {
            result.eventTime.stringValue = "   "
            result.eventDate.stringValue = "   "
            result.leadTime.stringValue = "   "
            result.leadTimeUnit.stringValue = "   "
        } else {
            result.eventTime.stringValue = getTimeString(itemDate)
            if allDay {
                result.eventDate.stringValue = DateFormatter.localizedString(
                    from: itemDate!,
                    dateStyle: .short,
                    timeStyle: .none
                ) + ", All Day"
            } else {
                result.eventDate.stringValue = DateFormatter.localizedString(
                    from: itemDate!,
                    dateStyle: .short,
                    timeStyle: .short
                )
            }
            if travelTime != 0 {
                result.eventDate.stringValue =
                    result.eventDate.stringValue +
                    ", TT +" +
                    TimeStringTools().getTimeStringFromSeconds(
                        travelTime,
                        showSeconds: false,
                        leadingZeros: false
                    )
            }
            (result.leadTime.stringValue, result.leadTimeUnit.stringValue) = getLeadTimeStrings(itemDate)
        }

        if copyCalendarItems[row].calendar != nil {
            result.calendarColor.backgroundColor = copyCalendarItems[row].calendar.color
        } else {
            result.calendarColor.backgroundColor = result.eventTitle.backgroundColor
        }

        return result;
    }
}
