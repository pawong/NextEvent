//
//  MZNESettings.swift
//  NextEvent
//
//  Created by Paul Wong on 2/4/18.
//  Copyright © 2018 Paul Wong. All rights reserved.
//

import Foundation


class Settings: NSObject {

    struct Settings: Codable {
        // persistant
        var floatRight: Bool = false
        var useAltIcon: Bool = false
        var useFlashBlue: Bool = false
        var useFlash: Bool = false
        var useSystemAlert: Bool = false
        var useBlockingAlert: Bool = false
        var earlyWarning: Int = 1
        var notifyTravelTime: Bool = false
        var useSound: Bool = false
        var useFuzzyTime: Bool = false
        var showSeconds: Bool = false
        var leadingZeros: Bool = false
        var showNumber: Int = 10
        var showTime: Bool = true
        var showTitle: Bool = false
        var useTitleLimit: Bool = false
        var calendarNames: [String] = []
    }

    var settings: Settings = Settings()
    var needsDisplay: Bool = true

    override init() {
        super.init()
        unarchive()
    }

    func unarchive() {
        do {
            let readData = try Data(contentsOf: archivePath())
            self.settings = try JSONDecoder().decode(Settings.self, from: readData)
        } catch {
            reset()
        }
    }

    func archive() {
        let jsonData = try! JSONEncoder().encode(self.settings)
        try! jsonData.write(to: archivePath())
    }

    func archivePath() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return URL(fileURLWithPath: paths[0].path + "/" + (Bundle.main.infoDictionary!["CFBundleName"] as! String) + ".cfg")
    }

    func reset() {
        settings.floatRight = false
        settings.useAltIcon = false
        settings.useFlashBlue = false
        settings.useFlash = true
        settings.useSystemAlert = false
        settings.useBlockingAlert = false
        settings.earlyWarning = 1
        settings.notifyTravelTime = false
        settings.useSound = false
        settings.useFuzzyTime = false
        settings.showSeconds = false
        settings.leadingZeros = false
        settings.showNumber = 10
        settings.showTime = true
        settings.showTitle = false
        settings.useTitleLimit = false
        settings.calendarNames = []
        self.archive()
    }
}

