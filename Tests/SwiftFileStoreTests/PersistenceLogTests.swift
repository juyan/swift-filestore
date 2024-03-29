// PersistenceLogTests.swift
// Copyright (c) 2024 PacketFly Corporation
//

@testable import SwiftFileStore
import XCTest

final class PersistenceLogTests: XCTestCase {
    var log: PersistenceLogImpl<TestObject>!

    func test_append_flush() async throws {
        log = try! PersistenceLogImpl<TestObject>(name: "test-queue")
        let object1 = TestObject(value: 1)
        let object2 = TestObject(value: 2)
        try await log.append(element: object1)
        try await log.append(element: object2)
        let result = try await log.flush()
        XCTAssertEqual(result, [object1, object2])
    }
}
