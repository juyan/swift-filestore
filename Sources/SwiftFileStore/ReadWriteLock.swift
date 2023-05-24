//
//  File.swift
//  
//
//  Created by Jun Yan on 5/24/23.
//

import Foundation

public class ReadWriteLock {
  var lock: pthread_rwlock_t

  public init() {
    lock = pthread_rwlock_t()
    pthread_rwlock_init(&lock, nil)
  }

  public func read<T>(closure: () -> T) -> T {
    pthread_rwlock_rdlock(&lock)
    defer { pthread_rwlock_unlock(&lock) }
    return closure()
  }

  public func write(closure: () -> Void) {
    pthread_rwlock_wrlock(&lock)
    closure()
    pthread_rwlock_unlock(&lock)
  }

  deinit {
    pthread_rwlock_destroy(&lock)
  }
}
