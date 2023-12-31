//
//  LarkShareConfig.swift
//  Lark
//
//  Created by 王飞 on 2021/4/11.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import LarkReleaseConfig
import LarkUIKit

enum LarkShareType {
    // 微信
    case wechat
    // 朋友圈
    case moments
}

extension ReleaseConfig {
    static var isHtoneKA: Bool {
        ReleaseConfig.isKA && ReleaseConfig.releaseChannel == "htone"
    }
}

struct LarkShareConfig {

    static let mini_sharecard_chat_send = "mini_sharecard_chat_send"
    static let mini_sharecard_wechat_send = "mini_sharecard_wechat_send"
    static let mini_sharecard_moments_send = "mini_sharecard_moments_send"

    static var enableShareTypes: [LarkShareType] {
        // 华通 KA 支持全部分享，6.9版本下掉分享到朋友圈 @孙泽楠CSM
        if ReleaseConfig.isHtoneKA {
            return [
                .wechat
//                .moments
            ]
        }
        // 仅飞书支持微信分享，
        // https://bytedance.feishu.cn/docs/doccnhX1XaudQXYseX6K2G2PgDd
        //【屏蔽字节飞书的iPad 微信/朋友圈 分享入口】 @刘凡PM
        if !ReleaseConfig.isKA && ReleaseConfig.isFeishu && !Display.pad {
            return [
                .wechat
            ]
        }
        // 非华通 KA 不支持任何分享
        return []
    }

    static func isShareSupport(type: LarkShareType) -> Bool {
        enableShareTypes.contains(type)
    }
}
