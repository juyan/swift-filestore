//
//  File.swift
//  
//
//  Created by Jun Yan on 1/15/24.
//

import Foundation
import XCTest

extension XCTestCase {
    
    
    func fulfillmentCompat(expectations: [XCTestExpectation], timeout: TimeInterval) async {
    #if swift(>=5.8)
        await fulfillment(of: expectations, timeout: timeout)
    #else
        wait(for: expectations, timeout: timeout)
    #endif
    }
}
