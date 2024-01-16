// FileObjectStore.swift
// Copyright (c) 2024 PacketFly Corporation
//

import Foundation

/// Implementation of `ObjectStore` using flat files.
/// Each namespace has a directory, and each object is serialized into a flat file under the directory.
public final class FileObjectStore: ObjectStore {
    private static let rootDirName = "file-object-store"

    let rootDir: URL

    private let observerManager = ObserverManager()

    public static func create() throws -> FileObjectStore {
        let applicationSupportDir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let rootDir = applicationSupportDir.appendingPathComponent(Self.rootDirName, isDirectory: true)
        try FileManager.default.createDirIfNotExist(url: rootDir)
        return FileObjectStore(rootDir: rootDir)
    }

    init(rootDir: URL) {
        self.rootDir = rootDir
    }

    public func read<T>(key: String, namespace: String, objectType _: T.Type) async throws -> T? where T: DataRepresentable {
        let fileURL = rootDir.appendingPathComponent(namespace).appendingPathComponent(key)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return try T.from(data: Data(contentsOf: fileURL))
        } else {
            return nil
        }
    }

    public func write<T>(key: String, namespace: String, object: T) async throws where T: DataRepresentable {
        let dirURL = rootDir.appendingPathComponent(namespace)
        let fileURL = dirURL.appendingPathComponent(key)
        try FileManager.default.createDirIfNotExist(url: dirURL)
        try object.serialize().write(to: fileURL)
        Task {
            await observerManager.publishValue(key: key, namespace: namespace, value: object)
        }
    }

    public func remove(key: String, namespace: String) async throws {
        let dirURL = rootDir.appendingPathComponent(namespace)
        let fileURL = dirURL.appendingPathComponent(key)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        Task {
            await observerManager.publishRemoval(namespace: namespace, key: key)
        }
    }

    public func removeAll(namespace: String) async throws {
        let dirURL = rootDir.appendingPathComponent(namespace)
        try FileManager.default.removeItem(at: dirURL)
        Task {
            await observerManager.publishRemoval(namespace: namespace)
        }
    }

    public func readAllKeys(namespace: String) async throws -> [String] {
        let dirURL = rootDir.appendingPathComponent(namespace)
        return try FileManager.default.contentsOfDirectory(atPath: dirURL.path)
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

extension FileManager {
    func createDirIfNotExist(url: URL) throws {
        if !fileExists(atPath: url.path) {
            try createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func createFileIfNotExist(url: URL) -> Bool {
        if !fileExists(atPath: url.path) {
            return createFile(atPath: url.path, contents: nil, attributes: nil)
        } else {
            return true
        }
    }
}

extension String: Error {}
