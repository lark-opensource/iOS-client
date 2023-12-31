//
//  Violations.swift
//  
//
//  Created by Sergej Jaskiewicz on 16/09/2019.
//

import Foundation
internal func APIViolationValueBeforeSubscription(file: StaticString = #fileID,
                                                  line: UInt = #line) -> Never {
    fatalError("""
               API Violation: received an unexpected value before receiving a Subscription
               """,
               file: file,
               line: line)
}

internal func APIViolationUnexpectedCompletion(file: StaticString = #fileID,
                                               line: UInt = #line) -> Never {
    fatalError("API Violation: received an unexpected completion", file: file, line: line)
}

internal func abstractMethod(file: StaticString = #fileID, line: UInt = #line) -> Never {
    fatalError("Abstract method call", file: file, line: line)
}

extension Subscribers.Demand {
    internal func assertNonZero(file: StaticString = #fileID,
                                line: UInt = #line) {
        if self == .none {
            fatalError("API Violation: demand must not be zero", file: file, line: line)
        }
    }
}
