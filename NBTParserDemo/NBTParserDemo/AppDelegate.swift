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
	@IBAction func openHelp(_ sender: Any?) {
		NSWorkspace.shared().open(URL(string: "https://github.com/kabiroberai/nbtparser/")!)
	}
}
