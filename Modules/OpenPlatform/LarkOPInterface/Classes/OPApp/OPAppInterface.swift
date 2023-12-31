//
//  OPAppInterface.swift
//  LarkOPInterface
//
//  Created by Meng on 2020/11/26.
//

import Foundation
import EENavigator

/// 使用appId打开「分享应用」的能力
/// 如果指定ability，则会尝试按照指定的ability打开应用
/// 如果未指定ability，则会尝试按照优先级打开
/// 优先级逻辑(服务端下发):
///    1. 开发者后台指定打开能力
///    2. 默认的优先级 gadget > h5 > bot
/// 打开逻辑(后续迁移时应当注意):
///    gadget: redirect 到 MicroAppBody
///    h5: 使用H5App逻辑打开
///    bot: 查询bot应用机制，并打开
///
public struct OPOpenShareAppBody: PlainBody {
    public enum Ability: String {
        case gadget
        case h5
        case bot
    }

    public static let pattern: String = "//client/open_platform/app_share/open"

    public let appId: String
    public let ability: Ability?
    public let path: String?
    public let appLinkTraceId: String?

    public init(appId: String, ability: Ability? = nil, path: String? = nil, appLinkTraceId: String? = nil) {
        self.appId = appId
        self.ability = ability
        self.path = path
        self.appLinkTraceId = appLinkTraceId
    }
}
