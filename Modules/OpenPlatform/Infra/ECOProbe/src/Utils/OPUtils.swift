//
//  OPUtils.swift
//  LarkOPInterface
//
//  Created by yinyuan on 2020/9/10.
//

import Foundation

public func OPAssertionFailureWithLog(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
    if AssertionConfigForTest.isEnable() {
        assertionFailure(message, file: file, line: line)
    }
    _OPLog(.fatal, nil, "\(file)".cString(using: .utf8), nil, Int32(line), message)
}
