// PersistenceLog.swift
// Copyright (c) 2024 PacketFly Corporation
//

import Foundation

/// A persistent log which supports append and flush operation.
/// This can be used as a persistent logging queue as an alternative to in-memory queue to prevent data losses if app is killed.
public protocol PersistenceLog {
    associatedtype Element: DataRepresentable

    func append(element: Element) async throws

    func flush() async throws -> [Element]
}

public actor PersistenceLogImpl<ElementType>: PersistenceLog where ElementType: DataRepresentable {
    public typealias Element = ElementType

    let fileURL: URL

    private let name: String
    private let dirURL: URL
    private let fileHandle: FileHandle

    public init(name: String) throws {
        let applicationSupportDir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let rootDir = applicationSupportDir.appendingPathComponent("persistence-log", isDirectory: true)
        try FileManager.default.createDirIfNotExist(url: rootDir)
        try self.init(name: name, rootDir: rootDir)
    }

    init(name: String, rootDir: URL) throws {
        self.name = name
        dirURL = rootDir
        let fileURL = rootDir.appendingPathComponent(name, isDirectory: false)
        let success = FileManager.default.createFileIfNotExist(url: fileURL)
        if !success {
            throw "failed to create file at \(fileURL.absoluteString)"
        }
        fileHandle = try FileHandle(forUpdating: fileURL)
        self.fileURL = fileURL
    }

    public func append(element: ElementType) async throws {
        try fileHandle.seekToEnd()
        let data = try element.serialize()
        let dataSize = UInt32(data.count)
        let bytes: Data = withUnsafeBytes(of: dataSize) { Data($0) } + data
        try fileHandle.write(contentsOf: bytes)
    }

    public func flush() async throws -> [ElementType] {
        try fileHandle.seek(toOffset: 0)
        let fileData = try fileHandle.readToEnd()
        try fileHandle.truncate(atOffset: 0)
        return try fileData?.deserializeToArray() ?? []
    }
}

extension Data {
    func deserializeToArray<ElementType>() throws -> [ElementType] where ElementType: DataRepresentable {
        var result: [ElementType] = []
        var idx = 0
        let uint32Size = MemoryLayout<UInt32>.size
        while idx < count {
            let sizeData = subdata(in: idx ..< idx + uint32Size)
            let size = sizeData.withUnsafeBytes { (rawPtr: UnsafeRawBufferPointer) in
                rawPtr.load(as: UInt32.self)
            }
            idx += uint32Size
            let elementData = subdata(in: idx ..< idx + Int(size))
            idx += Int(size)
            let element = try ElementType.from(data: elementData)
            result.append(element)
        }
        return result
    }
}
