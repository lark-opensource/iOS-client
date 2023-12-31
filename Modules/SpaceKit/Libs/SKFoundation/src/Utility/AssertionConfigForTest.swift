//
//  AssertionConfigForTest.swift
//  SKFoundation
//
//  Created by bupozhuang on 2022/3/8.
//

import Foundation

/// 在单测环境下使用，需要在tearDown reset, 避免其他用例被影响
/// 解决mock网络请求时中assert
public final class AssertionConfigForTest {
    private static var _enable: Bool = true
    public static var isEnable: Bool {
        return _enable
    }
    public static func reset() {
        _enable = true
    }
    
    public static func disableAssertWhenTesting() {
        guard isBeingTest else {
            assert(false, "can not disable assert not being test")
            return
        }
        _enable = false
    }
    static var isBeingTest: Bool = {
    #if DEBUG
        return ProcessInfo.processInfo.environment["IS_TESTING_DOCS_SDK"] == "1"
    #else
        return false
    #endif
    }()
}
