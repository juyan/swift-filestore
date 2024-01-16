// FileObjectStoreTests.swift
// Copyright (c) 2024 PacketFly Corporation
//

@testable import SwiftFileStore
import XCTest

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

    func test_readAllKeys() async throws {
        let object = TestObject(value: 1)
        let object2 = TestObject(value: 2)
        try await store.write(key: "test1", namespace: "test", object: object)
        try await store.write(key: "test2", namespace: "test", object: object2)
        let keys = try await store.readAllKeys(namespace: "test")
        XCTAssertEqual(Set(keys), Set(["test1", "test2"]))
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
