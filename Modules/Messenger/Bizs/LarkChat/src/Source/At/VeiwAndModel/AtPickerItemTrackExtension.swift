//
//  AtPickerItemTrackExtension.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/8/21.
//

import Foundation

/// @选人打点使用
struct AtPickerItemTrackExtension {
    var location: Int
    var tag: String?
    var isQuery: Bool
    var isWanted: Bool

    /// 打点参数，文档 https://bytedance.feishu.cn/space/doc/doccnoUNiuL7f9IYeCmGxvajnod#
    func toDictionary(_ isOuter: Bool) -> [String: String] {
        return [
            "category": "Chat",
            "notice": "atother",
            "choiceType": isWanted ? "guess" : "normal",
            "memberType": isOuter ? "external" : "internal",
            "is_query": isQuery ? "y" : "n",
            "search_location": "\(location)",
            "guess_type": tag ?? ""
        ]
    }
}
