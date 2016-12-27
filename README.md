# NBTParser
A Swift NBT Parser

## Installation

1. Build your target platform's framework (NBTParser macOS / iOS)
* Drag the framework into your project, making sure that **Copy items if needed** is checked
* Add `NBTParser.framework` to **Embed Frameworks** in your target's **Build Phases** if it isn't already there

## Usage

### Path
```swift
NBTDictionary(contentsOf: path)
```

### URL
```swift
NBTDictionary(contentsOf: url)
```

### Data
```swift
NBTDictionary(data: data)
```
