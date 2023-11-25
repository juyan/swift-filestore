# swift-filestore
Lightweight key-value store with Structured Concurrency API. 

![MIT License](https://img.shields.io/github/license/juyan/swift-filestore)
![Package Releases](https://img.shields.io/github/v/release/juyan/swift-filestore)
![Build Results](https://img.shields.io/github/actions/workflow/status/juyan/swift-filestore/.github/workflows/swift.yml?branch=main)
![Swift Version](https://img.shields.io/badge/swift-5.5-critical)
![Supported Platforms](https://img.shields.io/badge/platform-iOS%2014%20%7C%20macOS%2012-lightgrey)


## Why swift-filestore? 

If your app is built with Swift Concurrency and is in need for a lightweight key-value storage solution, `swift-filestore` should be a good fit.

It is a key-value persistence solution which provides CRUD operation and change stream APIs under Swift's Structured Concurrency(`async/await`, `AsyncSequence`).
Under the hood it simply serializes each object into a separate file, no databases or caches solutions are involved. This keeps your app lean and stable.

## Quick Start

Obtain an instance by calling `FileObjectStore.create()`. The method simply create a root directory under app's `Application Support` directory.
In rare cases where it fails to create the directory, you can choose to fallback to a in-memory implementation of `ObjectStore`, or can handle it in your own way.

```swift
func createWithFallback() -> ObjectStore {
  do {
    return try FileObjectStore.create()
  } catch {
    return MemoryObjectStore()
  }
}
```

swift-filestore does not require developers to create new struct/classes for your data model. For example, to use JSON serialization, just have your existing model conform to `JSONDataRepresentable`.

```swift

struct MyModel: Codable, JSONDataRepresentable {
    let id: String
    let value: String
}

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
If you are looking for non-json serializations, you may define your custom serialization/deserialization protocol as below:

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
