//
//  File.swift
//
//
//  Created by Jun Yan on 5/18/23.
//

import Foundation


/// A simple, efficient and Swift concurrency ready key-value object storage.
/// Keys are namespaced to avoid conflicts. Object needs to conform to ``DataRepresentable``
public protocol ObjectStore {
  
  /// Read an object from storage.
  /// ```
  /// let cat = try await read("100", "Cats", Cat.self)
  /// ```
  /// - Parameters:
  ///   - key: key of the object, such as "100"
  ///   - namespace: namespace of the object, such as "Cats"
  ///   - objectType: The type of the object
  /// - Returns: The object or nil if not present
  func read<T>(key: String, namespace: String, objectType: T.Type) async throws -> T? where T: DataRepresentable

  
  /// Write an object to storage.
  /// ```
  /// try await write("100", "Cats", cat)
  /// ```
  /// - Parameters:
  ///   - key: key of the object, such as "100"
  ///   - namespace: namespace of the object, such as "Cats"
  ///   - object: The object to write
  func write<T>(key: String, namespace: String, object: T) async throws where T: DataRepresentable
  
  /// Remove an object from storage
  /// - Parameters:
  ///   - key: key of the object
  ///   - namespace: namespace of the object
  func remove(key: String, namespace: String) async throws

  
  /// Remove all objects under a certain namespace
  /// ```
  /// try await removeAll(namespace: "Cats") // remove all cat objects
  /// ```
  /// - Parameter namespace: namespace of the object
  func removeAll(namespace: String) async throws
    
  /// Get all objects keys under a certain namespace
  /// ```
  /// try await readAllKeys(namespace: "Cats") // read all cat objects keys
  /// ```
  /// - Parameter namespace: namespace of the object
  func readAllKeys(namespace: String) async throws -> [String]
  
  /// Observe the change of a certain object identified by key and namespace. This will immediately emit the object's current value.
  /// - Parameters:
  ///   - key: key to the object
  ///   - namespace: namespace of the object
  ///   - objectType: type of the object
  /// - Returns: An `AsyncThrowingStream` that caller can consume the changes continously under async context.
  func observe<T>(key: String, namespace: String, objectType: T.Type) async -> AsyncThrowingStream<T?, Error> where T: DataRepresentable
}

/// A piece of data that can be serialize and deserialized
/// See ``ObjectStore``
public protocol DataRepresentable {
  func serialize() throws -> Data

  static func from(data: Data) throws -> Self
}
