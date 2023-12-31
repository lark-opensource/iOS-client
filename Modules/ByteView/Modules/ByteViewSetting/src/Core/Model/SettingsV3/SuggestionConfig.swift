//
//  SuggestionConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

/// https://cloud.bytedance.net/appSettings-v2/detail/config/169800/detail/status?review_id=316405
// disable-lint: magic number
public struct SuggestionConfig: Decodable {
    /// 建议列表拉取控频(毫秒
    public let requestInterval: Int
    /// 批量呼叫冷却时间
    public let callLoadingInterval: Int
    /// 批量呼叫最大数
    public let maxCallNumber: Int

    static let `default` = SuggestionConfig(requestInterval: 500, callLoadingInterval: 3000, maxCallNumber: 100)

    enum CodingKeys: String, CodingKey {
        case requestInterval = "suggestRequestInterval"
        case callLoadingInterval = "suggestCallLoadingInterval"
        case maxCallNumber = "suggestMaxCallNumber"
    }
}
