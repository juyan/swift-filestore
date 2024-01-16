// TestObject.swift
// Copyright (c) 2024 PacketFly Corporation
//

import Foundation
@testable import SwiftFileStore

struct TestObject: Codable, JSONDataRepresentable, Equatable {
    let value: Int
}
