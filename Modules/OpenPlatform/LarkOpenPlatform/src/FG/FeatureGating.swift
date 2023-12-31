//
//  FeatureGating.swift
//  LarkOpenPlatform
//
//  Created by lilun.ios on 2020/9/6.
//

import UIKit

struct FeatureGatingKey {
    // 消息卡片打开染色日志
    // 预计时间：预计4.7.0版本全量
    // 技术负责人：lilun.ios
    static let messageCardDetailLog = "message.card.log.enable.detail"
    // 是否允许本地灰度样式
    // 预计时间：预计4.9.0版本全量
    // 技术负责人：lilun.ios
    static let messageCardEnableGrayStyle = "message_card.gray.enable_setting"
    // 是否允许新版本卡片正常展示
    // 预计时间：
    // 技术负责人：
    static let supportNewCard = "messagecard.new_card.support"

    // 是否启用消息卡片新版标题包含icon与subtitle
    // 预计时间：5.25 全量
    // 技术负责人：zhangjie.alonso
    static let messageCardHeaderUseNew  = "messagecard.header.use.new"
}
