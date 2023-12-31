//
//  LarkShareItemType+Tea.swift
//  LarkContact
//
//  Created by shizhengyu on 2021/2/10.
//

import Foundation
import LarkSnsShare

extension LarkShareItemType {
    func teaDesc() -> String {
        switch self {
        case .wechat, .timeline:
            return "wechat"
        case .qq:
            return "qq"
        case .weibo:
            return "weibo"
        case .more:
            return "system"
        case .copy:
            return "copy"
        case .save:
            return "save"
        case .custom(let context):
            return "custom_\(context.identifier)"
        case .unknown:
            return "unknown"
        case .shareImage:
            return "shareImage"
        }
    }
}
