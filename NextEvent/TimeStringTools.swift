//
//  TimeStringTools.swift
//  NextEvent
//
//  Created by Paul Wong on 2/20/18.
//  Copyright © 2018 Paul Wong. All rights reserved.
//

import Foundation


class TimeStringTools: NSObject {

    let MINUTE_SECONDS =  60.0
    let HOUR_SECONDS   =  3600.0
    let DAY_SECONDS    =  86400.0
    let WEEK_SECONDS   =  604800.0
    let MONTH_SECONDS  =  2628000.0
    let YEAR_SECONDS   =  31536000.0

    let ONE_QUARTER    =  " and a quarter"
    let ONE_THIRD      =  " and a third"
    let ONE_HALF       =  " and a half"
    let TWO_THIRDS     =  " and two third"
    let THREE_QUARTERS =  " and three quarter"
    let NADA           =  ""

    func getExtraBits(_ theWhole: Double) -> String {
        let theBits: Double = theWhole - Double(Int(theWhole))
        if theBits > 3.0 / 4 {
            return THREE_QUARTERS
        }
        else if theBits >= 2.0 / 3 {
            return TWO_THIRDS
        }
        else if theBits >= 1.0 / 2 {
            return ONE_HALF
        }
        else if theBits >= 1.0 / 3 {
            return ONE_THIRD
        }
        else if theBits >= 1.0 / 4 {
            return ONE_QUARTER
        }

        return NADA
    }

    func getStatusString(_ breakdownInfo: DateComponents, showSeconds: Bool) -> String {
        var retval = ""
        // days
        retval = retval + ("\(breakdownInfo.day!)")
        // hours
        retval = retval + (String(format: ":%02ld", breakdownInfo.hour!))
        // minutes
        retval = retval + (String(format: ":%02ld", breakdownInfo.minute!))
        if showSeconds {
            // seconds
            retval = retval + (String(format: ":%02ld", breakdownInfo.second!))
        }
        return retval
    }

    func getLeadTime(_ breakdownInfo: DateComponents) -> (leadTime: String, leadTimeUnit: String) {
        var leadTime = ""
        var leadTimeUnit = ""
        
        // days
        if let days = breakdownInfo.day {
            if days != 0 {
                leadTime = "\(days)"
                if abs(days) == 1 {
                    leadTimeUnit = "DAY"
                } else {
                    leadTimeUnit = "DAYS"
                }
                return (leadTime, leadTimeUnit)
            }
        }

        // hours
        if let hours = breakdownInfo.hour {
            if hours != 0 {
                leadTime = "\(hours)"
                if abs(hours) == 1 {
                    leadTimeUnit = "HOUR"
                } else {
                    leadTimeUnit = "HOURS"
                }
                return (leadTime, leadTimeUnit)
            }
        }

        // minutes
        if let minutes = breakdownInfo.minute {
            if minutes != 0 {
                leadTime = "\(minutes)"
                if abs(minutes) == 1 {
                    leadTimeUnit = "MINUTE"
                } else {
                    leadTimeUnit = "MINUTES"
                }
                return (leadTime, leadTimeUnit)
            }
        }

        // seconds
        if let seconds = breakdownInfo.second {
            leadTime = "\(seconds)"
            if abs(seconds) == 1 {
                leadTimeUnit = "SECOND"
            } else {
                leadTimeUnit = "SECONDS"
            }
            return (leadTime, leadTimeUnit)
        }
        
        return (leadTime, leadTimeUnit)
    }
    
    func getTimeString(_ breakdownInfo: DateComponents, showSeconds: Bool, leadingZeros: Bool = true) -> String {
        var retval = ""
        var prior = false
        // days
        if let days = breakdownInfo.day {
            if days != 0 || leadingZeros {
                if abs(days) == 1 {
                    retval = retval + ("\(days) day ")
                } else {
                    retval = retval + ("\(days) days ")
                }
                prior = true
            }
        }

        // hours
        if let hours = breakdownInfo.hour {
            if hours != 0 || leadingZeros || prior {
                if abs(hours) == 1 {
                    retval = retval + ("\(hours) hour ")
                } else {
                    retval = retval + ("\(hours) hours ")
                }
                prior = true
            }
        }

        // minutes
        if let minutes = breakdownInfo.minute {
            if minutes != 0 || prior || leadingZeros {
                if abs(minutes) == 1 {
                    retval = retval + ("\(minutes) minute ")
                } else {
                    retval = retval + ("\(minutes) minutes ")
                }
                prior = true
            }
        }

        // seconds
        if showSeconds || retval == "" {
            if let seconds = breakdownInfo.second {
                if abs(seconds) == 1 {
                    retval = retval + ("\(seconds) second ")
                } else {
                    retval = retval + ("\(seconds) seconds ")
                }
            }
        }
        return retval
    }

    func getTimeStringFromSeconds(_ seconds: Double, showSeconds: Bool, leadingZeros: Bool = true) -> String {
        var retval = ""
        var prior = false
        var remainding = seconds

        // days
        let days = Int(seconds/DAY_SECONDS)
        if days != 0 || leadingZeros {
            if abs(days) == 1 {
                retval = retval + ("\(days) day ")
            } else {
                retval = retval + ("\(days) days ")
            }
            prior = true
            remainding = remainding - Double(days)*DAY_SECONDS
        }

        // hours
        let hours = Int(remainding/HOUR_SECONDS)
        if hours != 0 || leadingZeros || prior {
            if abs(hours) == 1 {
                retval = retval + ("\(hours) hour ")
            } else {
                retval = retval + ("\(hours) hours ")
            }
            prior = true
            remainding = remainding - Double(hours)*HOUR_SECONDS
        }

        // minutes
        let minutes = Int(remainding/MINUTE_SECONDS)
        if minutes != 0 || prior || leadingZeros {
            if abs(minutes) == 1 {
                retval = retval + ("\(minutes) minute ")
            } else {
                retval = retval + ("\(minutes) minutes ")
            }
            prior = true
            remainding = remainding - Double(minutes)*MINUTE_SECONDS
        }

        // seconds
        if showSeconds || retval == "" {
            let seconds = Int(remainding)
            if abs(seconds) == 1 {
                retval = retval + ("\(seconds) second ")
            } else {
                retval = retval + ("\(seconds) seconds ")
            }
        }
        return retval
    }
    
    func getFuzzyTimeString(_ seconds: TimeInterval) -> String {
        var theWhole: Double
        var theFuzzyBits: String
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut

        theWhole = seconds / YEAR_SECONDS
        if theWhole >= 1 {
            theFuzzyBits = getExtraBits(theWhole)
            if theWhole < 2 && (theFuzzyBits == NADA) {
                return "next year"
            }
            return "\(String(describing: formatter.string(from: NSNumber(value: theWhole))))\(theFuzzyBits) years"
        }
        theWhole = seconds / MONTH_SECONDS
        if theWhole >= 1 {
            theFuzzyBits = getExtraBits(theWhole)
            if theWhole < 2 && (theFuzzyBits == NADA) {
                return "next month"
            }
            return "\(String(describing: formatter.string(from: NSNumber(value: theWhole))))\(theFuzzyBits) months"
        }
        theWhole = Double(seconds / WEEK_SECONDS)
        if theWhole >= 1 {
            theFuzzyBits = getExtraBits(theWhole)
            if theWhole < 2 && (theFuzzyBits == NADA) {
                return "next week"
            }
            return "\(String(describing: formatter.string(from: NSNumber(value: theWhole))))\(theFuzzyBits) weeks"
        }
        theWhole = seconds / DAY_SECONDS
        if theWhole >= 1 {
            theFuzzyBits = getExtraBits(theWhole)
            if theWhole < 2 && (theFuzzyBits == NADA) {
                return "tomorrow"
            }
            return "\(String(describing: formatter.string(from: NSNumber(value: theWhole))))\(theFuzzyBits) days"
        }
        theWhole = seconds / HOUR_SECONDS
        if theWhole >= 1 {
            theFuzzyBits = getExtraBits(theWhole)
            if theWhole < 2 && (theFuzzyBits == NADA) {
                return "one hour"
            }
            return "\(String(describing: formatter.string(from: NSNumber(value: theWhole))))\(theFuzzyBits) hours"
        }
        theWhole = seconds / MINUTE_SECONDS
        if theWhole > 1 {
            theFuzzyBits = getExtraBits(theWhole)
            if theWhole < 2 && (theFuzzyBits == NADA) {
                return "one minute"
            }
            return "\(String(describing: formatter.string(from: NSNumber(value: theWhole))))\(theFuzzyBits) minutes"
        } else {
            if Int(seconds) == 1 {
                return "one second"
            }
            return "\(String(describing: formatter.string(from: NSNumber(value: theWhole)))) seconds"
        }
    }

    func getFuzzyStatusString(_ seconds: TimeInterval) -> String {
        var retval: String = ""
        var theWhole: Double = 0

        theWhole = (seconds / YEAR_SECONDS)
        if theWhole >= 1 {
            retval = String(format: "%d years", Int(round(theWhole)))
            if retval == "1 years" {
                retval = "next year"
            }
            return retval
        }
        theWhole = (seconds / MONTH_SECONDS)
        if theWhole >= 1 {
            retval = String(format: "%d months", Int(round(theWhole)))
            if retval == "1 months" {
                retval = "next month"
            }
            return retval
        }
        theWhole = (seconds / WEEK_SECONDS)
        if theWhole >= 1 {
            retval = String(format: "%d weeks", Int(round(theWhole)))
            if retval == "1 weeks" {
                retval = "next week"
            }
            return retval
        }
        theWhole = (seconds / DAY_SECONDS)
        if theWhole >= 1 {
            retval = String(format: "%d days", Int(round(theWhole)))
            if retval == "1 days" {
                retval = "tomorrow"
            }
            return retval
        }
        theWhole = (seconds / HOUR_SECONDS)
        if theWhole >= 1 {
            retval = String(format: "%d hours", Int(round(theWhole)))
            if retval == "1 hours" {
                retval = "1 hour"
            }
            return retval
        }
        theWhole = (seconds / MINUTE_SECONDS)
        if theWhole >= 1 {
            retval = String(format: "%d minutes", Int(round(theWhole)))
            if retval == "1 minutes" {
                retval = "1 minute"
            }
            return retval
        }
        retval = String(format: "%d seconds", Int(seconds))
        if retval == "1 seconds" {
            retval = "1 second"
        }

        return retval
    }
    
    func getShortTimeString(_ startDate: Date, endDate: Date? = nil) -> String {
        var retval: String = ""
        let formatter = DateFormatter()

        if endDate == nil {
            formatter.dateFormat = "h:mm a"
            retval = formatter.string(from: startDate)
        } else {
            let unitFlags = Set<Calendar.Component>([.year, .month, .day])
            let startDateComponents: DateComponents? = Calendar.current.dateComponents(unitFlags, from: startDate)
            let endDateComponents: DateComponents? = Calendar.current.dateComponents(unitFlags, from: endDate!)
            if startDateComponents?.year == endDateComponents?.year &&
                startDateComponents?.month == endDateComponents?.month &&
                startDateComponents?.day == endDateComponents?.day {
                formatter.dateFormat = "h:mm a"
                retval = formatter.string(from: startDate) + " - " + formatter.string(from: endDate!)
            } else {
                let longFormatter = DateFormatter()
                longFormatter.dateFormat = "M/dd h:mm a"
                formatter.dateFormat = "h:mm a"
                retval = "Today " + formatter.string(from: startDate) + " - " + longFormatter.string(from: endDate!)
            }
        }

        return retval
    }
    
    func getFullTimeString(startDate: Date, endDate: Date, showSeconds: Bool = false, leadingZeros: Bool = true) -> String {
        
        let seconds = endDate.timeIntervalSince(startDate)
        
        return TimeStringTools().getTimeStringFromSeconds(
            seconds,
            showSeconds: showSeconds,
            leadingZeros: leadingZeros
        )
    }
    
}
