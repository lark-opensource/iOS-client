//
//  NaviParams.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/11.
//

import Foundation
import SuiteCodable

public enum OpenType: String, Codable, HasDefault {
    public static func `default`() -> OpenType {
        return .none
    }

    case push, present, showDetail, none
}

public struct NaviParams: Codable {
    public var openType: OpenType = .none
    public var popTo: URL?
    public var switchTab: URL?
    public var forcePush: Bool = false
    public var animated: Bool = true

    public init() {}

    static func parse(from dict: [String: Any], with decoder: DictionaryDecoder) -> Self {
        var dict = dict
        // NOTE： ** `animated` 处理说明 **
        // 背景：
        //   如果 dict 里没有 "animated" 字段，则会被 `DictionaryDecoder` 解析为
        //   `Bool.default()` 值（即 `false`），不符合预期；此处填充默认值绕过
        if dict[Self.CodingKeys.animated.stringValue] == nil {
            dict[Self.CodingKeys.animated.stringValue] = true
        }
        return (try? decoder.decode(Self.self, from: dict)) ?? Self()
    }
}
