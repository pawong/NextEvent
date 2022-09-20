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
    
    func resizeWindow(){
        let screenSize = NSScreen.main!.frame
        let percent = CGFloat(0.85)
        self.view.window?.setFrame(NSRect(x:0,y:0,width:screenSize.size.width * percent,height:screenSize.size.height * percent), display: true)
         self.view.window?.center()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)))
        self.view.window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.resizeWindow()
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
