//
//  Assert.swift
//  LarkAssertConfig
//
//  Created by ByteDance on 2023/2/16.
//

import Foundation

// 文档请见：https://bytedance.feishu.cn/wiki/wikcn5ZmvLm18TTTrwpIzNggwtf
public func assertIfNeeded(file: StaticString, message: String, line: UInt) {
    switch assertResult(file: file) {
    case .notConfig:
        print("Assert!! 如果希望忽略，请在Podfile中调用assert_dir方法，传入需要忽略的assert路径，详情请见上方文档")
        Swift.assertionFailure(message, file: file, line: line)
    case .shouldAssert(true):
        print("Assert!! 根据Podfile中assert_dir配置，将assert转为断点，详情请见上方文档")
    case .shouldAssert(false):
        print("Assert!! 根据Podfile中assert_dir配置，忽略assert，详情请见上方文档")
        break
    }
}
