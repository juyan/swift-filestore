//
//  File.swift
//  
//
//  Created by Jun Yan on 5/24/23.
//

import Foundation

actor ObserverManager {
  
  private var observers: [String: [String: Observer]]
  
  init() {
    self.observers = [:]
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
      observers[namespace] = [key : observer]
      return observer
    }
  }
  
  func publishValue<T>(key: String, namespace: String, value: T) where T: DataRepresentable {
    if let observer = self.observers[namespace]?[key] {
      observer.callbacks.values.forEach { callback in
        callback(value)
      }
    }
  }
  
  func publishRemoval(namespace: String, key: String) {
    if let observer = self.observers[namespace]?[key] {
      observer.callbacks.values.forEach { callback in
        callback(nil)
      }
    }
  }
  
  func publishRemoval(namespace: String) {
    if let namespaceObservers = self.observers[namespace]?.values {
      namespaceObservers.forEach { observer in
        observer.callbacks.values.forEach { callback in
          callback(nil)
        }
      }
    }
  }
}
