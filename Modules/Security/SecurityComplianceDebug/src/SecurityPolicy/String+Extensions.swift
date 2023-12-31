//
//  String+Extensions.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/12/4.
//

import Foundation

extension String.StringInterpolation {
    mutating func appendInterpolation<T>(_ value: T?, defaultValue: String) {
        if let value = value {
            appendInterpolation(value)
        } else {
            appendLiteral(defaultValue)
        }
    }
}
