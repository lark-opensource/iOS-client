//
//  Violations.swift
//  
//
//  Created by Sergej Jaskiewicz on 13.12.2019.
//

import Foundation
import OpenCombine

extension Subscribers.Demand {
    internal func assertNonZero(file: StaticString = #fileID,
                                line: UInt = #line) {
        if self == .none {
            fatalError("API Violation: demand must not be zero", file: file, line: line)
        }
    }
}
