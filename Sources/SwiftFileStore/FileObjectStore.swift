//
//  File.swift
//
//
//  Created by Jun Yan on 5/18/23.
//

import Foundation

public final class FileObjectStore: ObjectStore {
  private static let rootDirName = "file-object-store"

  let rootDir: URL
  
  private let lock = ReadWriteLock()
  private var observers = [String: [String: Observer]]()

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
    let readTask = Task { () -> T? in
      let fileURL = rootDir.appendingPathComponent(namespace).appendingPathComponent(key)
      if FileManager.default.fileExists(atPath: fileURL.path) {
        return try T.from(data: Data(contentsOf: fileURL))
      } else {
        return nil
      }
    }
    return try await readTask.value
  }

  public func write<T>(key: String, namespace: String, object: T) async throws where T: DataRepresentable {
    let writeTask = Task { () in
      let dirURL = rootDir.appendingPathComponent(namespace)
      let fileURL = dirURL.appendingPathComponent(key)
      try FileManager.default.createDirIfNotExist(url: dirURL)
      try object.serialize().write(to: fileURL)
      if let observer = observers[namespace]?[key] {
        observer.callbacks.values.forEach { callback in
          callback(object)
        }
      }
    }
    return try await writeTask.value
  }

  public func remove(key: String, namespace: String) async throws {
    let removeTask = Task {
      let dirURL = rootDir.appendingPathComponent(namespace)
      let fileURL = dirURL.appendingPathComponent(key)
      if FileManager.default.fileExists(atPath: fileURL.path) {
        try FileManager.default.removeItem(at: fileURL)
      }
      if let observer = observers[namespace]?[key] {
        observer.callbacks.values.forEach { callback in
          callback(nil)
        }
      }
    }
    return try await removeTask.value
  }

  public func removeAll(namespace: String) async throws {
    let removeAllTask = Task {
      let dirURL = rootDir.appendingPathComponent(namespace)
      try FileManager.default.removeItem(at: dirURL)
      if let namespaceObservers = observers[namespace]?.values {
        namespaceObservers.forEach { observer in
          observer.callbacks.values.forEach { callback in
            callback(nil)
          }
        }
      }
    }
    return try await removeAllTask.value
  }
  
  public func observe<T>(key: String, namespace: String, objectType: T.Type) -> AsyncThrowingStream<T?, Error> where T: DataRepresentable {
    lock.write {
      if observers[namespace] == nil {
        observers[namespace] = [:]
      }
      if observers[namespace]?[key] == nil {
        observers[namespace]?[key] = Observer(key: key, namespace: namespace)
      }
    }
    return AsyncThrowingStream { continuation in
      guard let observer = lock.read(closure: { observers[namespace]?[key] }) else {
        continuation.finish(throwing: "unexpected error")
        return
      }
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
      continuation.onTermination = { @Sendable [weak self] _ in
        guard let observer = self?.lock.read(closure: { self?.observers[namespace]?[key] }) else {
          return
        }
        observer.callbacks[callbackID] = nil
        if observer.callbacks.isEmpty {
          self?.lock.write {
            self?.observers[namespace]?[key] = nil
          }
        }
      }
    }
  }
  
  final class Observer {
    let key: String
    let namespace: String
    var callbacks: [String: ((DataRepresentable?) -> ())]
    
    init(key: String, namespace: String) {
      self.key = key
      self.namespace = namespace
      self.callbacks = [:]
    }
    
    func registerCallback(id: String, callback: @escaping ((DataRepresentable?) -> ())) {
      callbacks[id] = callback
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
