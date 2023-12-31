//
//  MessageCardContextDefine.swift
//  LarkOpenPlatform
//
//  Created by lilun.ios on 2021/2/8.
//

import Foundation
import LKCommonsLogging
import LarkModel
import LarkMessageBase
import LarkMessengerInterface
import LarkSetting

private let logger = Logger.log(DynamicContentViewModelContext.self, category: "MessageCard.ChatContext")
/// 宽版卡片的最窄和最宽设置
let wideCardMinLimitWidth: CGFloat = 378
let wideCardMaxLimitWidth: CGFloat = 600
/// 紧凑宽版卡片的最窄和最宽设置 https://bytedance.feishu.cn/docs/doccnvZWfgViAcbwJfAhIAdmXef#
let wideCardCompactMaxLimitWidth: CGFloat = 400
/// 窄版卡片的最宽设置
let narrowCardMaxLimitWidth: CGFloat = 300
/// 是否应该展示宽版卡片
func shouldDisplayWideCard(_ message: Message, cellMaxWidth: CGFloat?, contentPreferWidth: CGFloat)-> Bool {
    guard UI_USER_INTERFACE_IDIOM() == .pad else {
        logger.info("shouldDisplayWideCard current device is not pad")
        return false
    }
    guard let content = message.content as? CardContent else {
        logger.info("shouldDisplayWideCard current message is not card")
        return false
    }

    @FeatureGatingValue(key: "messagecard.v1carddisablewide.enable")
    var disableV1CardWideMode: Bool

    //content.version = 1 时为v1卡片，这里强制改为窄版展示
    if disableV1CardWideMode && content.version == 1 {
        return false
    }
    /// 检查卡片配置中是否支持宽版本
    return contentPreferWidth > wideCardMinLimitWidth
}

extension Message {
    public func cardMaxLimitWidth() -> CGFloat {
        if let content = message?.content as? CardContent, content.compactWidth {
            return wideCardCompactMaxLimitWidth
        }
        return wideCardMaxLimitWidth
    }
}
