//
//  File.swift
//  
//
//  Created by Jun Yan on 11/25/23.
//

import XCTest
@testable import SwiftFileStore

final class PersistenceLogTests: XCTestCase {
  
  var log: (any TestObjectLog)!
  
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

protocol TestObjectLog: PersistenceLog where Element == TestObject {}

extension PersistenceLogImpl<TestObject>: TestObjectLog {}
