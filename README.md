# swift-filestore
Simple, file-based key-value store with full Swift Concurrency support 

![MIT License](https://img.shields.io/github/license/juyan/swift-filestore)
![Package Releases](https://img.shields.io/github/v/release/juyan/swift-filestore)
![Build Results](https://img.shields.io/github/actions/workflow/status/juyan/swift-filestore/.github/workflows/swift.yml?branch=main)
![Swift Version](https://img.shields.io/badge/swift-5.5-critical)
![Supported Platforms](https://img.shields.io/badge/platform-iOS%2014%20%7C%20macOS%2012-lightgrey)


## Why swift-filestore? 

If your app is built fully under Swift Concurrency, and is in need for a simple key-value storage solution, `swift-filestore` should be a good fit.

It provides basic CRUD operation and a change stream API, all under the paradigm of Swift Concurrency(`async/await`, `AsyncSequence`).
Under the hood it simply serialize each object into a separate file, no databases or caches are involved.

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
