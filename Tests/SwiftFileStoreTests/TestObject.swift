//
//  File.swift
//  
//
//  Created by Jun Yan on 11/21/23.
//

import Foundation
@testable import SwiftFileStore

struct TestObject: Codable, JSONDataRepresentable, Equatable {
    let value: Int
}
