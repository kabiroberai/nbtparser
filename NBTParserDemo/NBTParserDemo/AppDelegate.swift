//
//  AppDelegate.swift
//  NBTParserDemo
//
//  Created by Kabir Oberai on 18/09/16.
//  Copyright © 2016 Kabir Oberai. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	@IBAction func openHelp(_ sender: Any?) {
		NSWorkspace.shared().open(URL(string: "https://google.com")!)
	}

}

