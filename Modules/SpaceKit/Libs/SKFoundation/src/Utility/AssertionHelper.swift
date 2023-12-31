//
//  AssertionHelper.swift
//  SpaceKit
//
//  Created by bytedance on 2019/2/14.
//

import Foundation

public func spaceAssertionFailure(
    _ message: @autoclosure () -> String = "",
    file: StaticString = #fileID,
    line: UInt = #line) {

    if AssertionConfigForTest.isEnable {
        assertionFailure(message())
    }
    errorLog("Space AssertionFailure", message: message(), file: file, line: line)
}

public func spaceAssert(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #fileID,
    line: UInt = #line) {
        
    if AssertionConfigForTest.isEnable {
        assert(condition(), message())
    }
    if condition() == false {
        errorLog("Space AssertionFailure", message: message(), file: file, line: line)
    }
}

public func spaceAssertMainThread(file: StaticString = #fileID, line: UInt = #line) {
    assert(Thread.isMainThread)
    if !Thread.isMainThread {
        errorLog("Space assertMainThread failure", message: "", file: file, line: line)
    }
}

public func spaceAssertionFailureWithoutLog(
    _ message: @autoclosure () -> String = "",
    file: StaticString = #fileID,
    line: UInt = #line) {

    assertionFailure("\(message()) - \(file):\(line)")
}

private func errorLog(
    _ title: String,
    message: @autoclosure () -> String,
    file: StaticString,
    line: UInt) {
    DocsLogger.error(title, extraInfo: ["file": file, "line": line, "message": message()])
}
