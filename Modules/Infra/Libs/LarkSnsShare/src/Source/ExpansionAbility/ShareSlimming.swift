//
//  ShareSlimming.swift
//  LarkSnsShare
//
//  Created by shizhengyu on 2020/11/16.
//

import Foundation
import LarkReleaseConfig

/// 因应用瘦身需要，国内版和海外版所引入的三方应用SDK不同
/// 因此分享渠道会分别维护一份白名单，不在白名单内的项会被过滤
public enum ShareSlimming {
    /// 国内白名单
    public static func whitelistForInternal() -> [LarkShareItemType] {
        return [
            .wechat,
            .timeline,
            .qq,
            .weibo,
            .more(.default),
            .save,
            .copy,
            .shareImage,
            .custom(CustomShareContext.default())
        ]
    }
    /// 海外白名单
    public static func whitelistForOversea() -> [LarkShareItemType] {
        return [
            .more(.default),
            .save,
            .copy,
            .shareImage,
            .custom(CustomShareContext.default())
        ]
    }

    public static func currentWhitelist() -> [LarkShareItemType] {
        if ReleaseConfig.isFeishu {
            return whitelistForInternal()
        }
        if ReleaseConfig.isLark {
            return whitelistForOversea()
        }
        return []
    }
}
