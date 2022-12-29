//
//  CalendarTools.swift
//  NextEvent
//
//  Created by Paul Wong on 2/7/18.
//  Copyright © 2018 Paul Wong. All rights reserved.
//

import Foundation
import EventKit
import Cocoa


extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date? {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)
    }

    var startOfNextDay: Date? {
        var components = DateComponents()
        components.day = 1
        return Calendar.current.date(byAdding: components, to: startOfDay)
    }
}

class CalendarTools: NSObject {

    let eventStore = EKEventStore()

    func getEventsAndReminderOnDay(day: Date, calendars: [EKCalendar], reminders: [EKCalendar]) -> [EKCalendarItem] {
        var all: [EKCalendarItem:Date] = [:]

        for reminder in getReminders(start: day.startOfDay, end: day.endOfDay!, calendars: reminders) {
            let dc = ((reminder) as! EKReminder).dueDateComponents
            let date = Calendar.current.date(from: dc!)
            if (date != nil && date! >= day.startOfDay && date! < day.endOfDay!) {
                all[reminder] = date!
            }
        }
        for event in getEvents(start: day.startOfDay, end: day.endOfDay!, calendars: calendars) {
            let date = ((event) as! EKEvent).startDate
            if (date != nil && date! >= day.startOfDay && date! <= day.endOfDay!) {
                all[event] = date!
            }
        }

        let sortedKeys = Array(all.keys).sorted{all[$0]! < all[$1]!}

        return sortedKeys
    }

    func getTopN(n: Int, calendars: [EKCalendar], reminders: [EKCalendar]) -> [EKCalendarItem] {
        var results: [EKCalendarItem] = []
        var all: [EKCalendarItem:Date] = [:]
        let now = Date()
        let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: now)

        for reminder in getReminders(start: now, end: oneYearFromNow!, calendars: reminders) {
            let dc = ((reminder) as! EKReminder).dueDateComponents
            let date = Calendar.current.date(from: dc!)
            if (date != nil && date! > now) {
                all[reminder] = date
            }
        }
        
        for event in getEvents(start: now, end: oneYearFromNow!, calendars: calendars) {
            //print(((event) as! EKEvent).title, event.value(forKey: "travelTime")!)
            let date = ((event) as! EKEvent).startDate
            if (date != nil && date! > now) {
                all[event] = date!
            }
        }

        let sortedKeys = Array(all.keys).sorted{all[$0]! < all[$1]!}

        var count = 0
        for item in sortedKeys {
            //print(item.calendar as Any))
            results.append(item)
            count += 1
            if count >= n {
                break
            }
        }

        if results.count <= 0 {
            let store = EKEventStore()
            let newItem = EKEvent(eventStore: store)
            newItem.title = "N/A"
            results.append(newItem)
        }
        
        return results
    }

    func getTodayAll(calendars: [EKCalendar], reminders: [EKCalendar]) -> [EKCalendarItem] {
        var results: [EKCalendarItem] = []
        var all: [EKCalendarItem:Date] = [:]
        let startDate = Calendar.current.date(
            from: Calendar.current.dateComponents(
                [.year, .month, .day],
                from: Date()
            )
        )!.addingTimeInterval(-1)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!

        for reminder in getReminders(start: startDate, end: endDate, calendars: reminders) {
            let dc = ((reminder) as! EKReminder).dueDateComponents
            let date = Calendar.current.date(from: dc!)
            if (date != nil && date! > startDate) {
                all[reminder] = date
            }
        }
        
        for event in getEvents(start: startDate, end: endDate, calendars: calendars) {
            let date = ((event) as! EKEvent).startDate
            if (date != nil && date! > startDate) {
                all[event] = date!
            }
        }

        let sortedKeys = Array(all.keys).sorted{all[$0]! < all[$1]!}

        for item in sortedKeys {
            results.append(item)
        }
        
        if results.count <= 0 {
            let store = EKEventStore()
            let newItem = EKEvent(eventStore: store)
            newItem.title = "N/A"
            results.append(newItem)
        }
        
        return results
    }

    func get24Hours(calendars: [EKCalendar], reminders: [EKCalendar]) -> [EKCalendarItem] {
        var results: [EKCalendarItem] = []
        var all: [EKCalendarItem:Date] = [:]
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .second, value: 86400, to: startDate)!

        for reminder in getReminders(start: startDate, end: endDate, calendars: reminders) {
            let dc = ((reminder) as! EKReminder).dueDateComponents
            let date = Calendar.current.date(from: dc!)
            if (date != nil && date! > startDate) {
                all[reminder] = date
            }
        }
        
        for event in getEvents(start: startDate, end: endDate, calendars: calendars) {
            let date = ((event) as! EKEvent).startDate
            if (date != nil && date! > startDate) {
                all[event] = date!
            }
        }

        let sortedKeys = Array(all.keys).sorted{all[$0]! < all[$1]!}

        for item in sortedKeys {
            results.append(item)
        }

        if results.count <= 0 {
            let store = EKEventStore()
            let newItem = EKEvent(eventStore: store)
            newItem.title = "N/A"
            results.append(newItem)
        }

        return results
    }

    func getReminders(start: Date, end: Date, calendars: [EKCalendar]) -> [EKCalendarItem] {
        var results: [EKReminder] = []
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: start,
            ending: end,
            calendars: calendars
        )
        let group = DispatchGroup()

        group.enter()
        eventStore.fetchReminders(matching: predicate, completion: { (reminders: [EKReminder]?) -> Void in
            DispatchQueue.global().sync {
                results = reminders!
                group.leave()
            }
        })
        group.wait()

        return results
    }

    func getEvents(start: Date, end: Date, calendars: [EKCalendar]) -> [EKCalendarItem] {
        var results: [EKEvent] = []
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
        let events = eventStore.events(matching: predicate)

        for event in events {
            if !results.contains(event) {
                results.append(event)
            }
        }
        return results
    }

    func hasRemindersOnDay(day: Date) -> Bool {
        var retval = false
        var results: [EKReminder] = []
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: day.startOfDay,
            ending: day.endOfDay,
            calendars: nil
        )
        let group = DispatchGroup()

        group.enter()
        eventStore.fetchReminders(matching: predicate, completion: { (reminders: [EKReminder]?) -> Void in
            DispatchQueue.global().sync {
                results = reminders!
                group.leave()
            }
        })
        group.wait()

        if results.count > 0 {
            retval = true
        }

        return retval
    }

    func hasEventsOnDay(day: Date, calendars: [EKCalendar]) -> Bool {
        var results = false
        let predicate = eventStore.predicateForEvents(
            withStart: day.startOfDay,
            end: day.endOfDay!,
            calendars: calendars
        )
        let events = eventStore.events(matching: predicate)

        if events.count > 0 {
            results = true
        }

        return results
    }
    
    // calendars and reminder lists

    func getAllCalendars() -> [EKCalendar] {
        let calendars = eventStore.calendars(for: EKEntityType.event)
        return calendars
    }
    
    func getAllReminderLists() -> [EKCalendar] {
        let list = eventStore.calendars(for: EKEntityType.reminder)
        return list
    }

    func getCalendarByNames(names: [String]) -> [EKCalendar] {
        var results: [EKCalendar] = []
        let calendars = eventStore.calendars(for: EKEntityType.event)
        for calendar in calendars {
            if names.contains(calendar.title) {
                results.append(calendar)
            }
        }
        return results
    }

    func getReminderListByNames(names: [String]) -> [EKCalendar] {
        var results: [EKCalendar] = []
        let calendars = eventStore.calendars(for: EKEntityType.reminder)
        for calendar in calendars {
            if names.contains(calendar.title) {
                results.append(calendar)
            }
        }
        return results
    }
    
    func getCalendarByIdentifier(identifiers: [String]) -> [EKCalendar] {
        var results: [EKCalendar] = []
        let calendars = eventStore.calendars(for: EKEntityType.event)
        for calendar in calendars {
            if identifiers.contains(calendar.calendarIdentifier) {
                results.append(calendar)
            }
        }
        return results
    }

    func getReminderListByIdentifier(identifiers: [String]) -> [EKCalendar] {
        var results: [EKCalendar] = []
        let calendars = eventStore.calendars(for: EKEntityType.reminder)
        for calendar in calendars {
            if identifiers.contains(calendar.calendarIdentifier) {
                results.append(calendar)
            }
        }
        return results
    }
    
    func getCalendarNames() -> [String] {
        var results: [String] = []
        let calendars = eventStore.calendars(for: EKEntityType.event)
        for calendar in calendars {
            if !results.contains(calendar.title) {
                results.append(calendar.title)
            }
        }
        return results
    }
    
    func getReminderListNames() -> [String] {
        var results: [String] = []
        let calendars = eventStore.calendars(for: EKEntityType.event)
        for calendar in calendars {
            if !results.contains(calendar.title) {
                results.append(calendar.title)
            }
        }
        return results
    }

    func getCalendarColorByName(name: String) -> NSColor {
        let calendars = eventStore.calendars(for: EKEntityType.event)
        for calendar in calendars {
            if name == calendar.title {
                return calendar.color
            }
        }
        return NSColor.clear
    }

    func getReminderListColorByName(name: String) -> NSColor {
        let calendars = eventStore.calendars(for: EKEntityType.reminder)
        for calendar in calendars {
            if name == calendar.title {
                return calendar.color
            }
        }
        return NSColor.clear
    }
    
    // currently not working not sure why, moved to appDelegate
    func registerNotification(_ selector: Selector) {
        eventStore.requestAccess(to: .event, completion: {
            (_ granted: Bool, _ error: Error?) -> Void in
            if granted {
                NotificationCenter.default.addObserver(
                    self,
                    selector: selector,
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
                    selector: selector,
                    name: .EKEventStoreChanged,
                    object: nil
                )
            }
        })
    }

    func requestAccess() -> Bool {
        var result = true
        eventStore.requestAccess(to: EKEntityType.event, completion: {
            (accessGranted: Bool, error: Error?) in

            if accessGranted == true {
                DispatchQueue.main.async(execute: {
                    // access granted
                })
            } else {
                DispatchQueue.main.async(execute: {
                    // access denied
                    result = false
                })
            }
        })
        eventStore.requestAccess(to: EKEntityType.reminder, completion: {
            (accessGranted: Bool, error: Error?) in

            if accessGranted == true {
                DispatchQueue.main.async(execute: {
                    // access granted
                })
            } else {
                DispatchQueue.main.async(execute: {
                    // access denied
                    result = false
                })
            }
        })
        return result
    }
}
