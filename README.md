# swift-filestore
Simple, file-based key-value store with full Swift Concurrency support 

[![MIT License](https://img.shields.io/github/license/juyan/swift-filestore)](https://github.com/juyan/swift-filestore/blob/main/LICENSE)
[![Package Releases](https://img.shields.io/github/v/release/juyan/swift-filestore)](https://github.com/juyan/swift-filestore/releases)
[![Swift Version](https://img.shields.io/badge/swift-5.5-critical)](https://swift.org)
[![Supported Platforms](https://img.shields.io/badge/platform-iOS%2014%20%7C%20macOS%2012-lightgrey)](https://developer.apple.com)


## Why swift-filestore?
There doesn't seem to exist a fast, nimble key-value persistence solution that works well with Swift Concurrency. 

If you are looking for a simple key-value store with change stream, but don't want to bridge any closures, or RxSwift/Combine into Swift Concurrency, then swift-filestore could be a good fit.

## Quick Start
swift-filestore does not require developers to create new struct/classes for your data model. For example, to use JSON serialization, just have your existing model conform to `JSONDataRepresentable`.

```swift

struct MyModel: Codable, JSONDataRepresentable {
    let id: String
    let value: String
}

let objectStore = try FileObjectStore.create()
let model = MyModel()

try await objectStore.write(key: model.id, namespace: "MyModels", object: model)
```

## Object Change Stream
swift-filestore offers an object change subscription API via Swift Concurrency.

```swift
for try await model in await objectStore.observe(key: id, namespace: "MyModels", objectType: MyModel.self) {
    // process the newly emitted model object
}
```

## Custom serialization/deserialization
You may define your custom serialization/deserialization protocol like below:

```swift

protocol BinaryDataRepresentable: DataRepresentable {}

extension BinaryDataRepresentable {

  public func serialize() throws -> Data {
    // your custom serialization goes here...
  }
  
  public static func from(data: Data) throws -> Self {
    // your custom deseriazation goes here...
  }
}

struct MyModel: BinaryDataRepresentable {
    let id: String
    let value: String
}
```