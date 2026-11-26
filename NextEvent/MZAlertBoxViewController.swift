//
//  MZAlertBoxViewController.swift
//  NextEvent
//
//  Created by Paul Wong on 10/6/19.
//  Copyright © 2019 Paul Wong. All rights reserved.
//

import Cocoa


class MZAlertBoxWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        //self.window?.toggleFullScreen(nil)
    }
}


class MZAlertBoxViewController: NSViewController {
    
    var eventTitleString: String = ""
    var eventDate: Date? = nil
    var playSound: Bool = false
    var timer: Timer!
    
    @IBOutlet weak var eventTitleTextField: NSTextField!
    @IBOutlet weak var eventDateTextField: NSTextField!
    @IBOutlet weak var eventLocationButton: NSButton!
    @IBOutlet weak var calendarColorTextField: NSTextField!

    @IBOutlet weak var okayButton: NSButton!
    
    @IBAction func okayPress(_ sender: Any?) {
        /*
        let presOptions: NSApplication.PresentationOptions = []
        let optionsDictionary = [NSView.FullScreenModeOptionKey.fullScreenModeApplicationPresentationOptions: presOptions]
        view.exitFullScreenMode(options: optionsDictionary)
        */
        self.view.window?.close()
    }

    @IBAction func eventLocationButtonPress(_ sender: Any?) {
        if let url = URL(string: eventLocationButton.title) {
            NSWorkspace.shared.open(url)
            self.view.window?.close()
        //} else {
        //    let urlstring = "http://www.google.com/search?q=\( eventLocationButton.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        //    if let url = URL(string: urlstring) {
        //        NSWorkspace.shared.open(url)
        //        self.view.window?.close()
        //    }
        }
    }
    
    /// Makes the alert cover the whole screen below the menu bar (and notch), so
    /// nothing at the top is hidden. Before the window is shown, use the screen the
    /// user is working on; afterwards, whichever screen the window is on.
    func resizeWindow(to screen: NSScreen? = nil) {
        guard let window = self.view.window,
              let screen = screen ?? window.screen ?? NSScreen.main else { return }
        var frame = screen.frame
        // visibleFrame's top edge sits just below the menu bar; the Dock is
        // still covered because the other edges come from the full frame
        frame.size.height = screen.visibleFrame.maxY - frame.minY
        window.setFrame(frame, display: true)
    }

    @objc func screenChanged(_ notification: Notification) {
        self.resizeWindow()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)))
        self.view.window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.resizeWindow(to: NSScreen.main)

        // refit when the window moves to another display, or displays are
        // added, removed, or change resolution
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenChanged(_:)),
            name: NSWindow.didChangeScreenNotification,
            object: self.view.window
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenChanged(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear() {
        let now: Date = Date()
        eventTitleTextField.stringValue = eventTitleString
        if playSound {
            NSSound.beep()
        }
        if eventDate != nil && ceil(now.timeIntervalSinceReferenceDate) < ceil(eventDate!.timeIntervalSinceReferenceDate) {
            timer = Timer.scheduledTimer(
                timeInterval: 1,
                target: self,
                selector: #selector(fireTimer(_:)),
                userInfo: nil,
                repeats: true
            )
            RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
        }
    }
    
    @objc func fireTimer(_ sender: Any?) {
        self.updateTitle()
    }
    
    func updateTitle() {
        let now: Date = Date()
        if ceil(now.timeIntervalSinceReferenceDate) < ceil(eventDate!.timeIntervalSinceReferenceDate) {
            let timeString = TimeStringTools().getFullTimeString(
                startDate: now,
                endDate: eventDate!,
                showSeconds: true,
                leadingZeros: false
            )
            eventTitleTextField.stringValue = "\(timeString)until \(eventTitleString)"
        } else {
            eventTitleTextField.stringValue = eventTitleString
            if playSound {
                NSSound.beep()
            }
            timer.invalidate()
        }
    }
}

extension MZAlertBoxViewController {
    static func freshController() -> MZAlertBoxViewController {
        let storyboard = NSStoryboard(name: "MZAlertBox", bundle: nil)
        let identifier = "MZ Alert Controller"

        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? MZAlertBoxViewController else {
            fatalError("Why cant i find MZ MZAlertBox Controller? - Check MZAlertBox.storyboard")
        }
        return viewcontroller
    }
}
