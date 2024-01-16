// ObserverManager.swift
// Copyright (c) 2024 PacketFly Corporation
//

import Foundation

actor ObserverManager {
    private var observers: [String: [String: Observer]]

    init() {
        observers = [:]
    }

    func deleteObserver(key: String, namespace: String) {
        observers[namespace]?[key] = nil
    }

    func getObserver(key: String, namespace: String) -> Observer {
        if let dict = observers[namespace] {
            if let observer = dict[key] {
                return observer
            } else {
                let observer = Observer(key: key, namespace: namespace)
                observers[namespace]?[key] = observer
                return observer
            }
        } else {
            let observer = Observer(key: key, namespace: namespace)
            observers[namespace] = [key: observer]
            return observer
        }
    }

    func publishValue<T>(key: String, namespace: String, value: T) where T: DataRepresentable {
        if let observer = observers[namespace]?[key] {
            for callback in observer.callbacks.values {
                callback(value)
            }
        }
    }

    func publishRemoval(namespace: String, key: String) {
        if let observer = observers[namespace]?[key] {
            for callback in observer.callbacks.values {
                callback(nil)
            }
        }
    }

    func publishRemoval(namespace: String) {
        if let namespaceObservers = observers[namespace]?.values {
            for observer in namespaceObservers {
                for callback in observer.callbacks.values {
                    callback(nil)
                }
            }
        }
    }
}
