//
//  File.swift
//
//
//  Created by Jun Yan on 5/18/23.
//

import Foundation

public protocol ObjectStore {
  func read<T>(key: String, namespace: String, objectType: T.Type) async throws -> T? where T: DataRepresentable

  func write<T>(key: String, namespace: String, object: T) async throws where T: DataRepresentable

  func remove(key: String, namespace: String) async throws

  func removeAll(namespace: String) async throws
  
  func observe<T>(key: String, namespace: String, objectType: T.Type) async -> AsyncThrowingStream<T?, Error> where T: DataRepresentable
}

public protocol DataRepresentable {
  func serialize() throws -> Data

  static func from(data: Data) throws -> Self
}
