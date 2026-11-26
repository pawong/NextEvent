//
//  DateExtensionTests.swift
//  NextEventTests
//

import Foundation
import Testing
@testable import NextEvent

struct DateExtensionTests {

    let calendar = Calendar.current

    @Test func startOfDay() throws {
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 15, minute: 42)))
        let expected = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 14)))
        #expect(date.startOfDay == expected)
    }

    @Test func endOfDayIsLastSecondOfDay() throws {
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 15, minute: 42)))
        let expected = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 23, minute: 59, second: 59)))
        #expect(date.endOfDay == expected)
    }

    @Test func startOfNextDay() throws {
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 12, day: 31, hour: 8)))
        let expected = try #require(calendar.date(from: DateComponents(year: 2027, month: 1, day: 1)))
        #expect(date.startOfNextDay == expected)
    }

    @Test func endOfDayIsOneSecondBeforeStartOfNextDay() throws {
        let date = Date()
        let end = try #require(date.endOfDay)
        let next = try #require(date.startOfNextDay)
        #expect(next.timeIntervalSince(end) == 1)
    }
}
