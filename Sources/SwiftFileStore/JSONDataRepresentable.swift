// JSONDataRepresentable.swift
// Copyright (c) 2024 PacketFly Corporation
//

import Foundation

/// DataRepresentable that serialize/deserialize using JSON
/// - Note: For large data please consider other forms of serialization, as JSON is not the most performant option.
public protocol JSONDataRepresentable: DataRepresentable {}

public extension JSONDataRepresentable where Self: Codable {
    func serialize() throws -> Data {
        try JSONEncoder().encode(self)
    }

    static func from(data: Data) throws -> Self {
        try JSONDecoder().decode(Self.self, from: data)
    }
}
