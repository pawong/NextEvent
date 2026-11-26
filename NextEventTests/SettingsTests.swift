//
//  SettingsTests.swift
//  NextEventTests
//

import Foundation
import Testing
@testable import NextEvent

/// Tests the Codable settings struct only. `Settings()` itself reads and writes
/// the user's real config file, so it is intentionally not instantiated here.
struct SettingsTests {

    @Test func defaultValues() {
        let settings = Settings.Settings()
        #expect(settings.useFlash == false)
        #expect(settings.earlyWarning == 1)
        #expect(settings.showNumber == 10)
        #expect(settings.showTime == true)
        #expect(settings.calendarNames.isEmpty)
    }

    @Test func codableRoundTrip() throws {
        var settings = Settings.Settings()
        settings.floatRight = true
        settings.useFuzzyTime = true
        settings.earlyWarning = 5
        settings.showNumber = 3
        settings.calendarNames = ["Work", "Home"]

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(Settings.Settings.self, from: data)

        #expect(decoded.floatRight == true)
        #expect(decoded.useFuzzyTime == true)
        #expect(decoded.earlyWarning == 5)
        #expect(decoded.showNumber == 3)
        #expect(decoded.calendarNames == ["Work", "Home"])
    }
}
