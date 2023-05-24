//
//  File.swift
//  
//
//  Created by Jun Yan on 5/24/23.
//

import Foundation

/// DataRepresentable that serialize/deserialize with JSON
public protocol JSONDataRepresentable: DataRepresentable {}

extension JSONDataRepresentable where Self: Codable {
  
  public func serialize() throws -> Data {
    try JSONEncoder().encode(self)
  }
  
  public static func from(data: Data) throws -> Self {
    try JSONDecoder().decode(Self.self, from: data)
  }
}
