//
//  NBTViewController.swift
//  NBTParser
//
//  Created by Kabir Oberai on 11/07/16.
//  Copyright © 2016 Kabir Oberai. All rights reserved.
//

import Cocoa
import NBTParser

struct KVPair {
	var key: String
	var value: Any?
}

class NBTViewController: NSViewController {
	let uuidValues = NSMutableDictionary()
	@IBOutlet weak var outlineView: NSOutlineView!
	
	var dict: NBTDictionary? {
		didSet {
			outlineView.reloadData()
		}
	}
}

extension NBTViewController: NSOutlineViewDataSource {
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		if let item = item as? String  { // If not root
			let pair = uuidValues[item] as? KVPair
			let countable = pair?.value as? Countable
			return countable?.count ?? 0 // Return the item's count if it references an array/dict, else 0
		}
		return dict?.count ?? 0 // Return the root dict's count or zero if no root dict
	}
	
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		let pair = uuidValues[item]
		if let dict = pair?.value as? NBTDictionary { // Item refers to dictionary
			let key = dict.keys[index]
			let value = dict[index]
			return uuidValues.append(key: key, value: value)
		} else if let arr = pair?.value as? [AnyObject] { // Item refers to array
			return uuidValues.append(key: String(index), value: arr[index])
		} else { // No item, root dict
			return uuidValues.append(key: dict![keyAt: index]!, value: dict![index]!)
		}
	}
	
	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		let pair = uuidValues[item as! NSString] as? KVPair
		return pair?.value is NBTDictionary || pair?.value is [AnyObject]
	}
}

extension NBTViewController: NSOutlineViewDelegate {
	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		let pair = uuidValues[item as! NSString] as? KVPair
		let key = pair?.key
		let value = pair?.value
		if tableColumn?.identifier == "KeyColumn" {
			let view = outlineView.make(withIdentifier: "KeyCell", owner: self) as? NSTableCellView
			view?.textField?.stringValue = key ?? ""
			return view
		}
		let view = outlineView.make(withIdentifier: "ValueCell", owner: self) as? NSTableCellView
		if let value = value as? Countable {
			view?.textField?.stringValue = "\(value.count) entr\(value.count == 1 ? "y" : "ies")"
		} else {
			view?.textField?.stringValue = String(describing: value ?? "")
		}
		return view
	}
}

protocol Countable {var count: Int {get}}
extension NBTDictionary: Countable {}
extension Array: Countable {}

extension NSMutableDictionary {
	func append(key: String, value: Any?) -> NSString {
		var randomKey = UUID().uuidString as NSString
		while self[randomKey] != nil {
			randomKey = UUID().uuidString as NSString // Ensures that the key is unique
		}
		let pair = KVPair(key: key, value: value)
		setObject(pair, forKey: randomKey)
		return randomKey
	}
	
	subscript(key: Any?) -> KVPair? {
		guard let key = key as? NSString else {return nil}
		return self[key] as? KVPair
	}
}
