//
//  NextEventPreferencesViewController.swift
//  NextEvent
//
//  Created by Paul Wong on 2/13/18.
//  Copyright © 2018 Paul Wong. All rights reserved.
//

import Cocoa
import EventKit


class NextEventPreferencesViewController: NSViewController {

    @IBOutlet weak var flash: NSButton!
    @IBOutlet weak var flashBlue: NSButton!
    @IBOutlet weak var alternateIcon: NSButton!
    @IBOutlet weak var systemAlert: NSButton!
    @IBOutlet weak var blockingAlert: NSButton!
    @IBOutlet weak var earlyWarning: NSPopUpButton!
    @IBOutlet weak var travelTime: NSButton!
    @IBOutlet weak var playChime: NSButton!
    @IBOutlet weak var showSeconds: NSButton!
    @IBOutlet weak var leadingZeros: NSButton!
    @IBOutlet weak var useFuzzyTime: NSButton!
    @IBOutlet weak var showTitle: NSButton!
    @IBOutlet weak var useTitleLimit: NSButton!
    @IBOutlet weak var showTime: NSButton!
    @IBOutlet weak var numberEvents: NSPopUpButton!

    @IBOutlet weak var tableView: NSTableView!

    var allCalendars: [EKCalendar] = []
    var calendars: [String] = []

    var settings: Settings!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        let appDelegate = NSApp.delegate as? AppDelegate
        settings = appDelegate?.settings

        self.tableView.delegate = self
        self.tableView.dataSource = self
    }

    override func viewDidAppear() {
        self.refresh()
    }

    func refresh() {
        allCalendars = CalendarTools().getAllCalendars() + CalendarTools().getAllReminderLists()

        flash.state = getState(value: settings.settings.useFlash)
        flashBlue.state = getState(value: settings.settings.useFlashBlue)
        alternateIcon.state = getState(value: settings.settings.useAltIcon)
        systemAlert.state = getState(value: settings.settings.useSystemAlert)
        blockingAlert.state = getState(value: settings.settings.useBlockingAlert)
        earlyWarning.selectItem(withTitle: String(settings.settings.earlyWarning))
        travelTime.state = getState(value: settings.settings.notifyTravelTime)
        playChime.state = getState(value: settings.settings.useSound)
        showSeconds.state = getState(value: settings.settings.showSeconds)
        leadingZeros.state = getState(value: settings.settings.leadingZeros)
        useFuzzyTime.state = getState(value: settings.settings.useFuzzyTime)
        showTitle.state = getState(value: settings.settings.showTitle)
        useTitleLimit.state = getState(value: settings.settings.useTitleLimit)
        showTime.state = getState(value: settings.settings.showTime)
        if settings.settings.showNumber == 0 {
            numberEvents.selectItem(withTitle: "Today only")
        } else if settings.settings.showNumber == -1 {
            numberEvents.selectItem(withTitle: "24 Hours")
        } else {
            numberEvents.selectItem(withTitle: String(settings.settings.showNumber))
        }
        calendars = settings.settings.calendarNames

        self.tableView.reloadData()
        
        enableButtons()
    }

    func enableButtons() {
        // enable buttons
        // time
        useFuzzyTime.isEnabled = settings.settings.showTime

        // title
        useTitleLimit.isEnabled = settings.settings.showTitle
        
        // blocking alert then pick the time
        earlyWarning.isEnabled = settings.settings.useBlockingAlert
    }
    
    func getState(value: Bool) -> NSControl.StateValue {
        if value == true {
            return .on
        }
        return .off
    }

    func getState(value: NSControl.StateValue) -> Bool {
        if value == .on {
            return true
        }
        return false
    }

    @IBAction func updateSettings(_ sender: Any) {
        settings.settings.useFlash = getState(value: flash.state)
        settings.settings.useFlashBlue = getState(value: flashBlue.state)
        settings.settings.useAltIcon = getState(value: alternateIcon.state)
        settings.settings.useSystemAlert = getState(value: systemAlert.state)
        settings.settings.useBlockingAlert = getState(value: blockingAlert.state)
        settings.settings.earlyWarning = Int((earlyWarning.selectedItem?.title)!)!
        settings.settings.notifyTravelTime = getState(value: travelTime.state)
        settings.settings.useSound = getState(value: playChime.state)
        settings.settings.showSeconds = getState(value: showSeconds.state)
        settings.settings.leadingZeros = getState(value: leadingZeros.state)
        settings.settings.useFuzzyTime = getState(value: useFuzzyTime.state)
        settings.settings.showTitle = getState(value: showTitle.state)
        settings.settings.useTitleLimit = getState(value: useTitleLimit.state)
        settings.settings.showTime = getState(value: showTime.state)
        if numberEvents.selectedItem?.title == "Today only" {
            settings.settings.showNumber = 0
        } else if numberEvents.selectedItem?.title == "24 Hours" {
            settings.settings.showNumber = -1
        } else {
             settings.settings.showNumber = Int((numberEvents.selectedItem?.title)!)!
        }
        settings.settings.calendarNames = calendars
        
        enableButtons()
        
        settings.needsDisplay = true
        settings.archive()
    }

    @IBAction func buttonClicked(_ sender: Any) {
        let checkButton: NSButton = (sender as! NSButton)
        let selectedRow = tableView.row(for: sender as! NSView)
        if checkButton.state == .on {
            calendars.append(allCalendars[selectedRow].title)
        } else {
            while let idx = calendars.firstIndex(of: allCalendars[selectedRow].title) {
                calendars.remove(at: idx)
            }
        }
        self.updateSettings(sender)
    }
}

extension NextEventPreferencesViewController: NSTableViewDataSource, NSTableViewDelegate {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return allCalendars.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if (tableColumn?.identifier)!.rawValue == "Check" {
            let result:NSButton = tableView.makeView(
                withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Check")
                , owner: self
            ) as! NSButton
            (result.cell as! NSButtonCell).backgroundColor = allCalendars[row].color
            if calendars.contains(allCalendars[row].title) {
                result.state = .on
            } else {
                result.state = .off
            }
            return result
        } else if (tableColumn?.identifier)!.rawValue == "Name" {
            let result = tableView.makeView(
                withIdentifier:(tableColumn?.identifier)!,
                owner: self
            ) as! NSTableCellView
            result.textField?.stringValue = allCalendars[row].title
            return result
        }
        return nil
    }

}
