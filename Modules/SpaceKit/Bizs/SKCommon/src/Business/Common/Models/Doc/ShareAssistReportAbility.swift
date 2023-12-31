//
//  ShareAssistReportAbility.swift
//  SKCommon
//
//  Created by lijuyou on 2020/7/13.
//  


import Foundation


//From ShareAssistPanel.swift

/// 分享面板的统计能力
public protocol ShareAssistReportAbility: AnyObject {
    func reportShowSharePage()
    func reportDidShare(to: ShareAssistType, params: [String: String])
}

/// 文档分享辅助类型

/// - feishu: 通过飞书会话发出
/// - byteDanceMoments: 发链接到头条
/// - fileLink: 复制文档链接
/// - snapshot: 文档导出成图片
/// - slideExport: slide 导出pdf png
public enum ShareAssistType {
    case qrcode
    case feishu
    case fileLink
    case passwordLink
    case snapshot
    case more
    case wechat
    case wechatMoment
    case weibo
    case qq
    //长图保存
    case saveImage
    // sheet 卡片模式拷贝全文
    case copyAllTexts
}
