//
//  ExtensionsUtils.swift
//  SKPermission-Unit-Tests
//
//  Created by Weston Wu on 2023/4/24.
//

import Foundation
@testable import SKPermission
import SpaceInterface
import XCTest

extension PermissionValidatorResponse {
    func assertAllow(file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(allow, file: file, line: line)
    }

    func assertEqual(denyType expectDenyType: PermissionResponse.DenyType,
                     preferUIStyle expectUIStyle: PermissionResponse.PreferUIStyle? = nil,
                     file: StaticString = #file, line: UInt = #line) {
        switch self {
        case let .forbidden(denyType, preferUIStyle, _):
            let expectUIStyle = expectUIStyle ?? expectDenyType.preferUIStyle
            XCTAssertEqual(denyType, expectDenyType, file: file, line: line)
            XCTAssertEqual(preferUIStyle, expectUIStyle, file: file, line: line)
        case .allow:
            XCTFail("validator response allow not match expect deny type: \(expectDenyType)", file: file, line: line)
        }
    }

    func assertEqual(behaviorType expectBehaviorType: PermissionDefaultUIBehaviorType, file: StaticString = #file, line: UInt = #line) {
        guard case let .forbidden(_, _, behaviorType) = self else {
            XCTFail("validator response allow not match expect behavior type: \(expectBehaviorType)", file: file, line: line)
            return
        }
        behaviorType.assertEqualTo(expect: expectBehaviorType, file: file, line: line)
    }
}

extension PermissionDefaultUIBehaviorType {
    func assertEqualTo(expect: PermissionDefaultUIBehaviorType, file: StaticString = #file, line: UInt = #line) {
        switch (expect, self) {
            // 最后的回调闭包不检查了
        case let (.toast(expectConfig, expectAllow, expectCompletion, _),
                  .toast(config, allow, completion, _)):
            // 闭包没法判断是否相等，只看是否都为 nil 或不是 nil
            XCTAssertEqual(expectCompletion == nil, completion == nil, file: file, line: line)
            XCTAssertEqual(expectConfig, config, file: file, line: line)
            XCTAssertEqual(expectAllow, allow, file: file, line: line)
        case let (.present(expectProvider), .present(provider)):
            // 简单判断下构造出来的 controller 是不是同一个类型的
            let expectControllerType = type(of: expectProvider()).description()
            let controllerType = type(of: provider()).description()
            XCTAssertEqual(expectControllerType, controllerType, file: file, line: line)
        case (.custom, .custom):
            // 两个闭包的场景没有版本在进行细致的比较
            break
        default:
            XCTFail("case expect behavior type: \(expect) not equal to case behavior type: \(self)", file: file, line: line)
        }
    }
}

extension PermissionResponse {
    func assertAllow(file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(allow, file: file, line: line)
    }

    func assertEqual(denyType expectDenyType: PermissionResponse.DenyType,
                     preferUIStyle expectUIStyle: PermissionResponse.PreferUIStyle? = nil,
                     file: StaticString = #file, line: UInt = #line) {
        switch result {
        case let .forbidden(denyType, preferUIStyle):
            let expectUIStyle = expectUIStyle ?? expectDenyType.preferUIStyle
            XCTAssertEqual(denyType, expectDenyType, file: file, line: line)
            XCTAssertEqual(preferUIStyle, expectUIStyle, file: file, line: line)
        case .allow:
            XCTFail("validator response allow not match expect deny type: \(expectDenyType)", file: file, line: line)
        }
    }
}
