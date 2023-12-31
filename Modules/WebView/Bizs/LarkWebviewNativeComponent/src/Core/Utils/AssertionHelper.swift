//
//  AssertionHelper.swift
//  LarkWebviewNativeComponent
//
//  Created by tefeng liu on 2020/10/31.
//

import Foundation

func lkAssertionFailure(
    _ message: String,
    error: Error? = nil,
    file: StaticString = #fileID,
    line: UInt = #line) {
    assertionFailure()
    // TODO: 增加日志log
}

