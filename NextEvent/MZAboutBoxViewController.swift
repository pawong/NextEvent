//
//  MZAboutBoxViewController.swift
//  NextEvent
//
//  Created by Paul Wong on 2/10/18.
//  Copyright © 2018 Paul Wong. All rights reserved.
//

import Cocoa


class MZAboutBoxViewController: NSViewController {

    @IBOutlet weak var appTitle: NSTextField!
    @IBOutlet weak var appVersion: NSTextField!
    @IBOutlet var appAcknowledgments: NSTextView!
    @IBOutlet weak var appCopyright: NSTextField!
    @IBOutlet weak var appIcon: NSImageView!

    @IBOutlet weak var helpView: NSView!
    @IBOutlet weak var aboutView: NSView!

    @IBOutlet var helpBox: NSTextView!
    @IBOutlet weak var helpButton: NSButton!

    var isHelpVisible: Bool!
    var macId: String?
    var text: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        isHelpVisible = false
        self.forceHelp(force: true)

        let infoDict = Bundle.main.infoDictionary
        appTitle.stringValue = (infoDict!["CFBundleExecutable"] as? String)!
        appVersion.stringValue = "Version \((infoDict!["CFBundleShortVersionString"] as? String)!) (Build \((infoDict!["CFBundleVersion"] as? String)!))"
        appCopyright.stringValue = (infoDict!["NSHumanReadableCopyright"] as? String)!
        appIcon.image = NSApp.applicationIconImage

        // Set help
        if let helpURL = Bundle.main.url(forResource: "help", withExtension: "rtfd") {
            helpBox.textStorage?.append(
                try! NSAttributedString(
                    url: helpURL,
                    options: [.documentType: NSAttributedString.DocumentType.rtfd],
                    documentAttributes: nil
                )
            )
        }

        // Set acknowledgements
        if let ackURL = Bundle.main.path(forResource: "acknowledgments", ofType: "txt") {
            try! appAcknowledgments.string = String(contentsOfFile: ackURL, encoding: String.Encoding.utf8)
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.center()
        self.view.window?.level = .floating
    }
    
    func resizeWindow(size:(CGFloat,CGFloat)){
        self.view.window?.setFrame(NSRect(x:0,y:0,width:size.0,height:size.1), display: true)
    }
    
    @IBAction func toggleHelp(_ sender: Any?) {
        if self.isHelpVisible == true {
        // show about
            self.resizeWindow(size: (612, 312))
            self.isHelpVisible = false
            self.helpView.isHidden = true
            self.aboutView.isHidden = false
            self.helpButton.title = "Help"
        } else {
            // show help
            let screenSize = NSScreen.main!.frame
            let percent = CGFloat(0.80)
            self.resizeWindow(size: (612, screenSize.size.height * percent))
            self.view.window?.center()

            self.isHelpVisible = true
            self.helpView.isHidden = false
            self.aboutView.isHidden = true
            self.helpButton.title = "About"
        }
        self.view.window?.center()
    }

    @IBAction func reviewApp(_ sender: Any?) {
        let url = NSURL(string: "macappstore://itunes.apple.com/app/\(self.macId ?? "mazookie")?mt=12")! as URL
        NSWorkspace.shared.open(url)
    }

    @IBAction func visitWebsite(_ sender: Any?) {
        NSWorkspace.shared.open(NSURL(string: "http://github/pawong/NextEvent")! as URL)
    }

    func forceHelp(force: Bool) {
        if force == true {
            self.isHelpVisible = false
        } else {
            self.isHelpVisible = true
        }

        self.toggleHelp(nil)
    }

    func setMacId(newMacId: String) {
        macId = newMacId
    }

}

extension MZAboutBoxViewController {
    static func freshController() -> MZAboutBoxViewController {
        let storyboard = NSStoryboard(name: "MZAboutBox", bundle: nil)
        let identifier = "MZ AboutBox Controller"

        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier)
            as? MZAboutBoxViewController else {
            fatalError("Why cant i find MZ AboutBox Controller? - Check MZAboutBox.storyboard")
        }
        return viewcontroller
    }
}
