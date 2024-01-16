// Observer.swift
// Copyright (c) 2024 PacketFly Corporation
//

import Foundation

final class Observer {
    let key: String
    let namespace: String
    var callbacks: [String: (DataRepresentable?) -> Void]

    init(key: String, namespace: String) {
        self.key = key
        self.namespace = namespace
        callbacks = [:]
    }

    func registerCallback(id: String, callback: @escaping ((DataRepresentable?) -> Void)) {
        callbacks[id] = callback
    }
}
