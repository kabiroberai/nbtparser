//
//  NBTDocument.swift
//  NBTParserDemo
//
//  Created by Kabir Oberai on 18/09/16.
//  Copyright © 2016 Kabir Oberai. All rights reserved.
//

import Cocoa
import NBTParser

class NBTDocument: NSDocument {

	var dict: NBTDictionary?
	
	override func makeWindowControllers() {
		let storyboard = NSStoryboard(name: "Main", bundle: nil)
		let windowController = storyboard.instantiateController(withIdentifier: "Document Window Controller") as! NSWindowController
		addWindowController(windowController)
		let vc = windowController.contentViewController as? NBTViewController
		vc?.dict = dict
	}
	
	override class func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool {
		return typeName == "NBT"
	}
	
	override func read(from data: Data, ofType typeName: String) throws {
		do {
			dict = try NBTDictionary(data: data)
		} catch {
			Swift.print(error)
		}
	}

}

