//
//  CountDownConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

// disable-lint: magic number
/// 倒计时 lark Settings 配置，一期需求有变更，暂时去掉了，留给二期再用
public struct CountDownConfig: Decodable {
    /// minutes
    public let quickSelectionTime: [UInt]
    static let `default` = CountDownConfig(quickSelectionTime: [5, 10, 15, 30])
}
