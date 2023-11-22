import Combine
import XCTest
@testable import SwiftFileStore

final class FileObjectStoreTests: XCTestCase {
  
  var store: FileObjectStore!
  
  override func setUp() {
    super.setUp()
    store = try! FileObjectStore.create()
  }
  
  override func tearDown() {
    super.tearDown()
    try! FileManager.default.removeItem(at: store.rootDir)
  }
  
  func test_readWrite() async throws {
    let object = TestObject(value: 2)
    try await store.write(key: "test", namespace: "test", object: object)
    let readResult = try await store.read(key: "test", namespace: "test", objectType: TestObject.self)
    XCTAssertEqual(readResult, object)
  }
  
  func test_deletetNamespace() async throws {
    let object = TestObject(value: 1)
    let object2 = TestObject(value: 2)
    try await store.write(key: "test", namespace: "test", object: object)
    try await store.write(key: "test2", namespace: "test", object: object2)
    try await store.removeAll(namespace: "test")
    
    let readResult = try await store.read(key: "test", namespace: "test", objectType: TestObject.self)
    let readResult2 = try await store.read(key: "test2", namespace: "test", objectType: TestObject.self)
    XCTAssertNil(readResult)
    XCTAssertNil(readResult2)
  }
  
  func test_deleteObject() async throws {
    let object = TestObject(value: 1)
    try await store.write(key: "test", namespace: "test", object: object)
    let readResult = try await store.read(key: "test", namespace: "test", objectType: TestObject.self)
    XCTAssertNotNil(readResult)
    try await store.remove(key: "test", namespace: "test")
    let readResult2 = try await store.read(key: "test", namespace: "test", objectType: TestObject.self)
    XCTAssertNil(readResult2)
  }
  
  func test_observer() async throws {
    let object = TestObject(value: 1)
    let object2 = TestObject(value: 2)
    let expectation = XCTestExpectation(description: "stream subscription")
    let expectation2 = XCTestExpectation(description: "stream breaks")
    Task {
      var values: [TestObject?] = []
      let stream = await store.observe(key: "test", namespace: "test", objectType: TestObject.self)
      expectation.fulfill()
      for try await value in stream {
        values.append(value)
        if values.count == 3 {
          break
        }
      }
      XCTAssertEqual(values, [nil, object, object2])
      expectation2.fulfill()
    }
    await fulfillment(of: [expectation], timeout: 1)
    try await store.write(key: "test", namespace: "test", object: object)
    try await store.write(key: "test", namespace: "test", object: object2)
    await fulfillment(of: [expectation2], timeout: 1)
  }
}


#if os(Linux)
import XCTest

extension XCTestCase {
    /// Wait on an array of expectations for up to the specified timeout, and optionally specify whether they
    /// must be fulfilled in the given order. May return early based on fulfillment of the waited on expectations.
    ///
    /// - Parameter expectations: The expectations to wait on.
    /// - Parameter timeout: The maximum total time duration to wait on all expectations.
    /// - Parameter enforceOrder: Specifies whether the expectations must be fulfilled in the order
    ///   they are specified in the `expectations` Array. Default is false.
    /// - Parameter file: The file name to use in the error message if
    ///   expectations are not fulfilled before the given timeout. Default is the file
    ///   containing the call to this method. It is rare to provide this
    ///   parameter when calling this method.
    /// - Parameter line: The line number to use in the error message if the
    ///   expectations are not fulfilled before the given timeout. Default is the line
    ///   number of the call to this method in the calling file. It is rare to
    ///   provide this parameter when calling this method.
    ///
    /// - SeeAlso: XCTWaiter
    func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval, enforceOrder: Bool = false) async {
        return await withCheckedContinuation { continuation in
            // This function operates by blocking a background thread instead of one owned by libdispatch or by the
            // Swift runtime (as used by Swift concurrency.) To ensure we use a thread owned by neither subsystem, use
            // Foundation's Thread.detachNewThread(_:).
            Thread.detachNewThread { [self] in
                wait(for: expectations, timeout: timeout, enforceOrder: enforceOrder)
                continuation.resume()
            }
        }
    }
}
#endif
