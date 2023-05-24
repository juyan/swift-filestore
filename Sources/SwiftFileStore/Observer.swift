//
//  File.swift
//  
//
//  Created by Jun Yan on 5/24/23.
//

import Foundation

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
