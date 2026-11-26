//
//  TimeStringToolsTests.swift
//  NextEventTests
//

import Foundation
import Testing
@testable import NextEvent

struct TimeStringToolsTests {

    let tools = TimeStringTools()

    private func components(day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int? = nil) -> DateComponents {
        var dc = DateComponents()
        dc.day = day
        dc.hour = hour
        dc.minute = minute
        dc.second = second
        return dc
    }

    // MARK: - getExtraBits

    @Test(arguments: [
        (1.0, ""),
        (1.1, ""),
        (1.25, " and a quarter"),
        (1.4, " and a third"),
        (1.5, " and a half"),
        (1.7, " and two thirds"),
        (1.8, " and three quarters"),
    ])
    func extraBits(value: Double, expected: String) {
        #expect(tools.getExtraBits(value) == expected)
    }

    // MARK: - getStatusString

    @Test func statusStringWithoutSeconds() {
        let dc = components(day: 1, hour: 2, minute: 3, second: 4)
        #expect(tools.getStatusString(dc, showSeconds: false) == "1:02:03")
    }

    @Test func statusStringWithSeconds() {
        let dc = components(day: 1, hour: 2, minute: 3, second: 4)
        #expect(tools.getStatusString(dc, showSeconds: true) == "1:02:03:04")
    }

    // MARK: - getLeadTime

    @Test func leadTimeUsesLargestNonZeroUnit() {
        #expect(tools.getLeadTime(components(day: 2, hour: 5, minute: 1, second: 0)) == ("2", "DAYS"))
        #expect(tools.getLeadTime(components(day: 1, hour: 5)) == ("1", "DAY"))
        #expect(tools.getLeadTime(components(day: 0, hour: 1, minute: 30)) == ("1", "HOUR"))
        #expect(tools.getLeadTime(components(day: 0, hour: 3)) == ("3", "HOURS"))
        #expect(tools.getLeadTime(components(day: 0, hour: 0, minute: 1)) == ("1", "MINUTE"))
        #expect(tools.getLeadTime(components(day: 0, hour: 0, minute: 45)) == ("45", "MINUTES"))
        #expect(tools.getLeadTime(components(day: 0, hour: 0, minute: 0, second: 1)) == ("1", "SECOND"))
        #expect(tools.getLeadTime(components(day: 0, hour: 0, minute: 0, second: 0)) == ("0", "SECONDS"))
    }

    @Test func leadTimeSingularForNegativeOne() {
        #expect(tools.getLeadTime(components(day: 0, hour: 0, minute: -1)) == ("-1", "MINUTE"))
    }

    @Test func leadTimeEmptyComponents() {
        #expect(tools.getLeadTime(DateComponents()) == ("", ""))
    }

    // MARK: - getTimeString

    @Test func timeStringWithLeadingZeros() {
        let dc = components(day: 0, hour: 2, minute: 1, second: 4)
        #expect(tools.getTimeString(dc, showSeconds: false, leadingZeros: true) == "0 days 2 hours 1 minute ")
    }

    @Test func timeStringWithoutLeadingZeros() {
        let dc = components(day: 0, hour: 0, minute: 5, second: 10)
        #expect(tools.getTimeString(dc, showSeconds: false, leadingZeros: false) == "5 minutes ")
        #expect(tools.getTimeString(dc, showSeconds: true, leadingZeros: false) == "5 minutes 10 seconds ")
    }

    @Test func timeStringKeepsZeroUnitsAfterNonZeroUnit() {
        let dc = components(day: 1, hour: 0, minute: 0, second: 0)
        #expect(tools.getTimeString(dc, showSeconds: false, leadingZeros: false) == "1 day 0 hours 0 minutes ")
    }

    @Test func timeStringFallsBackToSecondsWhenEmpty() {
        let dc = components(day: 0, hour: 0, minute: 0, second: 30)
        #expect(tools.getTimeString(dc, showSeconds: false, leadingZeros: false) == "30 seconds ")
    }

    // MARK: - getTimeStringFromSeconds

    @Test func timeStringFromSecondsWithLeadingZeros() {
        #expect(tools.getTimeStringFromSeconds(90061, showSeconds: false) == "1 day 1 hour 1 minute ")
        #expect(tools.getTimeStringFromSeconds(90061, showSeconds: true) == "1 day 1 hour 1 minute 1 second ")
        #expect(tools.getTimeStringFromSeconds(120, showSeconds: false) == "0 days 0 hours 2 minutes ")
    }

    @Test func timeStringFromSecondsWithoutLeadingZeros() {
        #expect(tools.getTimeStringFromSeconds(3661, showSeconds: true, leadingZeros: false) == "1 hour 1 minute 1 second ")
        #expect(tools.getTimeStringFromSeconds(45, showSeconds: false, leadingZeros: false) == "45 seconds ")
    }

    // MARK: - getFuzzyStatusString

    @Test(arguments: [
        (1.0, "1 second"),
        (30.0, "30 seconds"),
        (60.0, "1 minute"),
        (150.0, "3 minutes"),
        (3_600.0, "1 hour"),
        (7_200.0, "2 hours"),
        (86_400.0, "tomorrow"),
        (172_800.0, "2 days"),
        (604_800.0, "next week"),
        (1_209_600.0, "2 weeks"),
        (2_628_000.0, "next month"),
        (31_536_000.0, "next year"),
        (63_072_000.0, "2 years"),
    ])
    func fuzzyStatusString(seconds: TimeInterval, expected: String) {
        #expect(tools.getFuzzyStatusString(seconds) == expected)
    }

    // MARK: - getFuzzyTimeString

    @Test(arguments: [
        (1.0, "one second"),
        (3_600.0, "one hour"),
        (86_400.0, "tomorrow"),
        (604_800.0, "next week"),
        (2_628_000.0, "next month"),
        (31_536_000.0, "next year"),
    ])
    func fuzzyTimeStringSingleUnits(seconds: TimeInterval, expected: String) {
        #expect(tools.getFuzzyTimeString(seconds) == expected)
    }

    @Test(arguments: [
        (0.0, "zero seconds"),
        (30.0, "thirty seconds"),
        (60.0, "one minute"),
        (90.0, "one and a half minutes"),
        (300.0, "five minutes"),
        (5_400.0, "one and a half hours"),
        (172_800.0, "two days"),
        (129_600.0, "one and a half days"),
        (233_280.0, "two and two thirds days"),
        (241_920.0, "two and three quarters days"),
        (1_814_400.0, "three weeks"),
        (94_608_000.0, "three years"),
    ])
    func fuzzyTimeStringMultipleUnits(seconds: TimeInterval, expected: String) {
        #expect(tools.getFuzzyTimeString(seconds) == expected)
    }

    // MARK: - getShortTimeString

    @Test func shortTimeStringStartOnly() throws {
        let start = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 9, minute: 5)))
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        #expect(tools.getShortTimeString(start) == formatter.string(from: start))
    }

    @Test func shortTimeStringSameDay() throws {
        let start = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 9, minute: 5)))
        let end = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 10, minute: 30)))
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let expected = formatter.string(from: start) + " - " + formatter.string(from: end)
        #expect(tools.getShortTimeString(start, endDate: end) == expected)
    }

    @Test func shortTimeStringDifferentDay() throws {
        let start = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 9, minute: 5)))
        let end = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 15, hour: 10, minute: 30)))
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let longFormatter = DateFormatter()
        longFormatter.dateFormat = "M/dd h:mm a"
        let expected = "Today " + formatter.string(from: start) + " - " + longFormatter.string(from: end)
        #expect(tools.getShortTimeString(start, endDate: end) == expected)
    }

    // MARK: - getFullTimeString

    @Test func fullTimeString() {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let end = start.addingTimeInterval(3_720)
        #expect(tools.getFullTimeString(startDate: start, endDate: end) == "0 days 1 hour 2 minutes ")
        #expect(tools.getFullTimeString(startDate: start, endDate: end, leadingZeros: false) == "1 hour 2 minutes ")
        #expect(tools.getFullTimeString(startDate: start, endDate: end.addingTimeInterval(5), showSeconds: true, leadingZeros: false) == "1 hour 2 minutes 5 seconds ")
    }
}
