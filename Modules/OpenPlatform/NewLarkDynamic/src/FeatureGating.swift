//
//  FeatureGating.swift
//  NewLarkDynamic
//
//  Created by lilun.ios on 2020/11/8.
//

import Foundation
struct FeatureGating {
    /// 消息卡片染色日志功能打开
    /// 预计时间：预计4.46版本全量
    /// 技术负责人：lilun.ios
    static let messageCardDetailLog = "message.card.log.enable.detail"

    // 是否启用图片的Strectch模式
    // 预计时间：预计5.25版本全量
    // 技术负责人：zhangjie.alonso
    static let messageCardEnableImageStretchMode = "messagecard.image.stretch.enable"

    // 是否启用消息卡片新版标题包含icon与subtitle
    // 预计时间：5.25 全量
    // 技术负责人：zhangjie.alonso
    static let messageCardHeaderUseNew  = "messagecard.header.use.new"
}
