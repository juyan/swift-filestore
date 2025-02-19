// MemoryObjectStore.swift
// Copyright (c) 2024 PacketFly Corporation
//

import Foundation

/// A fallback `ObjectStore` in case file operation fails. Can also be used for unit tests.
public actor MemoryObjectStore: ObjectStore {
    private var objects: [String: [String: Data]] = [:]
    private let observerManager = ObserverManager()

    public init() {}
  
    public func read(key: String, namespace: String) async throws -> Data? {
        objects[namespace]?[key]
    }

    public func read<T>(key: String, namespace: String, objectType _: T.Type) async throws -> T? where T: DataRepresentable {
        objects[namespace]?[key].flatMap { try? T.from(data: $0) }
    }

    public func write<T>(key: String, namespace: String, object: T) async throws where T: DataRepresentable {
        let data = try object.serialize()
        objects[namespace, default: [:]][key] = data
        await observerManager.publishValue(key: key, namespace: namespace, value: object)
    }

    public func readAllKeys(namespace: String) async throws -> [String] {
        objects[namespace].map { Array($0.keys) } ?? []
    }

    public func remove(key: String, namespace: String) async throws {
        objects[namespace, default: [:]][key] = nil
        await observerManager.publishRemoval(namespace: namespace, key: key)
    }

    public func removeAll(namespace: String) async throws {
        objects[namespace] = nil
        await observerManager.publishRemoval(namespace: namespace)
    }

    public func observe<T>(key: String, namespace: String, objectType: T.Type) async -> AsyncThrowingStream<T?, Error> where T: DataRepresentable {
        let observer = await observerManager.getObserver(key: key, namespace: namespace)
        do {
            let existingValue = try await read(key: key, namespace: namespace, objectType: objectType)
            return AsyncThrowingStream { continuation in
                continuation.yield(existingValue)
                let callbackID = UUID().uuidString
                observer.registerCallback(id: callbackID) { data in
                    if let d = data, let typed = d as? T {
                        continuation.yield(typed)
                    } else if data == nil {
                        continuation.yield(nil)
                    } else {
                        continuation.finish(throwing: "invalid data type")
                    }
                }
                continuation.onTermination = { @Sendable _ in
                    observer.callbacks.removeValue(forKey: callbackID)
                }
            }
        } catch {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: error)
            }
        }
    }
}
