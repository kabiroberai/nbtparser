//
//  NBTDictionary.swift
//  NBTParser
//
//  Created by Kabir Oberai on 18/09/16.
//  Copyright © 2016 Kabir Oberai. All rights reserved.
//

import Foundation
import Gzip

enum NBTTag: UInt8 {
	case end, byte, short, int, long, float, double, byteArray, string, list, compound, intArray
}

public enum NBTError: Error {
	
	/// There was no data available to be parsed.
	case noData
	
	/// The data was in an invalid format.
	case invalid
	
	/// The parser had not finished parsing but reached the end of file.
	case eofReached
}

/// A readonly class that represents an `NBT` file. Similar to Swift's `Dictionary` class.
///
/// - Note: The only way to initialise an `NBTDictionary` besides initialising it from another dictionary is to use `init(url:_)` or `init(data:_)`. These initialisers accept an `NBT` file in `URL` or `Data` form respectively and create an `NBTDictionary` from the file's contents.
///
/// - SeeAlso: `init(data:_)`, `init(url:_)`
public class NBTDictionary {
	
	public private(set) var parent: NBTDictionary?
	
	/// The unordered keys and values contained in the receiver as a `Dictionary` type.
	public private(set) var values: [String: Any] = [:]
	
	/// The keys of the receiver.
	public private(set) var keys: [String] = []
	
	/// The number of items that the receiver contains.
	public var count: Int {return keys.count}
	
	init() {} // Makes the default initialiser internal
	
	/// Initialises an `NBTDictionary` with the same properties as `other`.
	///
	/// - Parameter other: The `NBTDictionary` whose properties to use.
	public convenience init(other: NBTDictionary) {
		self.init()
		self.values = other.values
		self.keys = other.keys
	}
	
	/// Initialises an empty `NBTDictionary`, setting its parent to the `parent` argument.
	///
	/// - Note: This is the only way to set an `NBTDictionary`'s parent, and once this value has been set it cannot be changed.
	///
	/// - Parameter parent: The dictionary to set as the new `NBTDictionary`'s parent.
	public convenience init(parent: NBTDictionary?) {
		self.init()
		self.parent = parent
	}
	
	/// Returns the value in the `NBTDictionary` corresponding to `key`, if any.
	///
	/// Equivalent to `values[key]`.
	///
	/// - Parameter key: The key of the value to be accessed.
	///
	/// - SeeAlso: `subscript(index:_)`, `subscript(keyAt:_)`
	public fileprivate(set) subscript(key: String) -> Any? {
		get {
			return values[key]
		}
		set {
			guard let newValue = newValue else {
				values.removeValue(forKey: key)
				keys = keys.filter {$0 != key}
				return
			}
			let oldValue = values.updateValue(newValue, forKey: key)
			if oldValue == nil {
				keys.append(key)
			}
		}
	}
	
	/// Returns the value in the `NBTDictionary` at the specified `index`, if any.
	///
	/// Essentially the same as `values[keys[index]]` but safer.
	///
	/// - SeeAlso: `subscript(key:_)`
	///
	/// - Parameter index: The index of the value to be accessed.
	///
	/// - Returns: The value as type `Any` if there was a value at the index, or `nil` if the index was out of bounds.
	public subscript(index: Int) -> Any? {
		guard index > -1 && index < keys.count else {return nil}
		let key = keys[index]
		return values[key]
	}
	
	/// Returns the value in the `NBTDictionary` at the specified `index`, if any.
	///
	/// Essentially the same as `keys[index]` but safer.
	///
	/// - SeeAlso: `subscript(key:_)`
	///
	/// - Parameter index: The index of the key to be accessed.
	///
	/// - Returns: The key if there was one at the index, or `nil` if the index was out of bounds.
	public subscript(keyAt index: Int) -> String? {
		guard index > -1 && index < keys.count else {return nil}
		return keys[index]
	}
}

extension NBTDictionary {
	
	/// Parses the supplied path into an `NBTDictionary`, decompressing it if needed.
	///
	/// - Bug: There is currently a bug in which lists of the compound type are reversed. If list order is important, you should reverse the list yourself when fetching it.
	///
	/// - SeeAlso: `init(data:_)`
	///
	/// - Parameter path: The path of the file to be parsed
	///
	/// - Throws:
	///		- An error in the Cocoa domain if the url could not be converted into `Data`.
	///		- `GzipError` if the data was gzipped but could not be decompressed.
	///		- `NBTError` if there was an error parsing the NBT.
	public convenience init(contentsOf path: String) throws {
		let url = URL(fileURLWithPath: path)
		try self.init(contentsOf: url)
	}
	
	/// Parses the supplied URL into an `NBTDictionary`, decompressing it if needed.
	///
	/// - Bug: There is currently a bug in which lists of the compound type are reversed. If list order is important, you should reverse the list yourself when fetching it.
	///
	/// - SeeAlso: `init(data:_)`
	///
	/// - Parameter url: The url of the file to be parsed
	///
	/// - Throws: 
	///		- An error in the Cocoa domain if the url could not be converted into `Data`.
	///		- `GzipError` if the data was gzipped but could not be decompressed.
	///		- `NBTError` if there was an error parsing the NBT.
	public convenience init(contentsOf url: URL) throws {
		let data = try Data(contentsOf: url)
		try self.init(data: data)
	}
	
	/// Parses the supplied NBT `Data` into an `NBTDictionary`.
	///
	/// - Bug: There is currently a bug in which lists of the compound type are reversed. If list order is important, you should reverse the list yourself when fetching it.
	///
	/// - SeeAlso: `init(url:_)`
	///
	/// - Parameter data: The `Data` to parse.
	///
	/// - Throws: 
	///		- `GzipError` if the data was gzipped but could not be decompressed.
	///		- `NBTError` if there was an error parsing the NBT.
	public convenience init(data: Data) throws {
		var data = data.isGzipped ? try data.gunzipped() : data
		guard !data.isEmpty else {throw NBTError.noData}
		self.init()
		try data.withUnsafeMutableBytes {try parse(withBytes: $0, length: data.count)}
	}
	
	func parse(withBytes bytes: UnsafeMutablePointer<UInt8>, length: Int) throws {
		var bytes = bytes
		let finalBytes = bytes + length
		var currDict = self
		while bytes <= finalBytes {
			let tag = try bytes.nextTag()
			if tag == .end {
				// If there's no parent, we're back at the topmost level, so finish initialising
				guard let parent = currDict.parent else {return}
				currDict = parent
			} else if bytes < finalBytes {
				let key = try bytes.nextString()
				currDict[key] = try bytes.next(of: tag, in: &currDict)
			} else {
				throw NBTError.eofReached // The last byte is not a .end tag
			}
		}
		throw NBTError.eofReached
	}
}

extension UnsafeMutablePointer {
	
	/// Fetches the next value of the given type and advances the pointer forwards.
	///
	/// - Note: Values of type `String` and `Array` should be parsed using their respective methods, i.e. `nextString()` and `nextArray(of:_)`.
	///
	/// - SeeAlso: `nextString()`, `nextArray(of:_)`
	///
	/// - Precondition: If the memory being pointed to is not bound to `type`, the return value is undefined.
	///
	/// - Parameter type: The type of the next value in memory. This must be of a fixed size.
	///
	/// - Returns: A value of `type`.
	mutating func next<T: Integer>(_ type: T.Type) -> T {
		let pointee = withMemoryRebound(to: type, capacity: 1) {$0.pointee}
		self += MemoryLayout<T>.stride
		return pointee
	}
	
	mutating func nextTag() throws -> NBTTag {
		let rawTag = next(UInt8.self)
		guard let tag = NBTTag(rawValue: rawTag) else {throw NBTError.invalid}
		return tag
	}
	
	mutating func nextString() throws -> String {
		let length = Int(next(UInt16.self).bigEndian)
		guard let name = String(bytesNoCopy: self, length: length, encoding: .utf8, freeWhenDone: false) else {throw NBTError.invalid}
		self += length
		return name
	}
	
	mutating func nextArray<T>(of type: T.Type) -> [T] {
		let length = Int(next(Int32.self).bigEndian) // This is common to both NBT array formats
		let array = withMemoryRebound(to: type, capacity: 1) {Array(UnsafeBufferPointer(start: $0, count: length))}
		self += MemoryLayout<T>.stride * length
		return array
	}
	
	mutating func next(of tag: NBTTag, in dict: inout NBTDictionary) throws -> Any {
		switch tag {
		case .byte:
			return next(UInt8.self)
			
		case .short:
			return next(Int16.self).bigEndian
			
		case .int:
			return next(Int32.self).bigEndian
			
		case .long:
			return next(Int.self).bigEndian
			
		case .float:
			let pattern = next(UInt32.self).bigEndian
			return Float(bitPattern: pattern)
			
		case .double:
			let pattern = next(UInt64.self).bigEndian
			return Double(bitPattern: pattern)
			
		case .byteArray:
			return nextArray(of: Int8.self)
			
		case .string:
			return try nextString()
			
		case .list: // TODO: Fix a bug in which compound lists are reversed
			let listTag = try nextTag() // A list only has one type of value
			let length = next(Int32.self).bigEndian
			return try (0..<length).map {_ in try next(of: listTag, in: &dict)}
			
		case .compound:
			dict = NBTDictionary(parent: dict)
			return dict
			
		case .intArray:
			return nextArray(of: Int32.self).map {$0.bigEndian}
			
		case .end: // This can only happen if a list is of the .end type, which isn't normal.
			throw NBTError.invalid
		}
	}
}

extension NBTDictionary: CustomStringConvertible {
	
	/// The readable description of the `NBTDictionary`.
	public var description: String {
//		return values.description /* Uncomment this line to return Swift's own Dictionary description
		var result = "{\n"
		for index in keys.indices {
			let key = keys[index]
			let value = "\(self[index] ?? "")\n"
			let indentAmount = 4
			let indentation = String(repeating: " ", count: indentAmount)
			var separated = value.components(separatedBy: .newlines)
			for index in separated.indices where index > 0 && index < separated.count - 1 {
				separated[index] = "\(indentation)\(separated[index])"
			}
			var itemCount = ""
			if let count = (self[index] as? IntCountable)?.count {
				itemCount = " (\(count) entr\(count == 1 ? "y" : "ies"))"
			}
			result += "\(indentation)[\(index)]: \(key)\(itemCount) => \(separated.joined(separator: "\n"))"
		}
		return result + "}" // kthxbye */
	}
}

protocol IntCountable {
	var count: Int {get}
}

extension NBTDictionary: IntCountable {
	
	/// Similar to `values`, however this also converts all child `NBTDictionaries` into Swift `Dictionaries`.
	///
	/// - SeeAlso: `values`
	public var dictValues: [String: Any] {
		var dict: [String: Any] = [:]
		for (key, value) in values {
			if let value = value as? NBTDictionary {
				dict[key] = value.dictValues
			} else if let value = value as? [Any] {
				dict[key] = value.dictValues
			} else {
				dict[key] = value
			}
		}
		return dict
	}
}

extension Array: IntCountable {
	var dictValues: [Any] {
		return map { value in
			if let value = value as? NBTDictionary {
				return value.dictValues
			} else if let value = value as? [Any] {
				return value.dictValues
			}
			return value
		}
	}
}
