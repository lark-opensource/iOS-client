//
//  LarkFeature.swift
//  LarkSetting
//
//  Created by 王元洵 on 2022/7/26.
//

import Foundation
struct LarkFeature: SettingDecodable, Encodable {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "lark_features")

    private let online: [String]
    private let values: [String: String]

    var stringSet: Set<String> { Set(online) }
}
