//
//  AutoHideToolbarConfig.swift
//  ByteView
//
//  Created by ByteDance on 2022/10/14.
//

import Foundation
// disable-lint: magic number
public struct AutoHideToolbarConfig: Decodable {
    public let firstAutoHideDuration: Int // 入会首次自动隐藏时长，单位ms
    public let continueAutoHideDuration: Int // 后续自动隐藏时长，单位ms
    public let doubleTapTimeout: Int // 双击事件的超时时长，单位ms

    public static let `default` = AutoHideToolbarConfig(firstAutoHideDuration: 10000, continueAutoHideDuration: 5000, doubleTapTimeout: 300)
}
