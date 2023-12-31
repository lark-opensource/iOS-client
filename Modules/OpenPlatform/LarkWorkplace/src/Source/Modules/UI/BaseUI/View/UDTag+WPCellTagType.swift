//
//  WorkPlaceCellCommon.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/6/22.
//

import Foundation
import UniverseDesignTag
import UniverseDesignColor
import UIKit

/// 排序页Cell的Tag类型枚举
enum WPCellTagType: String {
    case recommandBlock // 推荐 block
    case recommandIcon // 推荐 icon
    case recommand
    case block
    case bookMark
    case bot
    case shared // 关联组织应用，管理员推荐 > 共享应用 > 机器人/小组件
    case none
    /// 获取相应的类型文案
    func getText() -> String {
        switch self {
        case .recommandBlock, .recommandIcon:
            return BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_RecTag
        case .recommand:
            return BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AdminRecTitle
        case .block:
            return BundleI18n.LarkWorkplace.OpenPlatform_BaseBlc_Block
        case .bookMark:
            return BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_BkmrkBadge
        case .bot:
            return BundleI18n.LarkWorkplace.AppDetail_Card_Bot
        case .shared:
            return BundleI18n.LarkWorkplace.OpenPlatform_AppShare_AppTag
        case .none:
            return ""
        }
    }
}

extension UDTag {
    // 方法过长，待业务优化
    func wp_updateType(_ type: WPCellTagType) {
        text = type.getText()
        isHidden = false
        let config: UDTagConfig.TextConfig
        switch type {
        case .recommandBlock:
            config = UDTagConfig.TextConfig(
                cornerRadius: 4.0,
                textColor: UIColor.ud.O400,
                backgroundColor: UIColor.ud.O100
            )
        case .recommandIcon:
            // 字体使用 UD token 初始化
            // swiftlint:disable init_font_with_token
            config = UDTagConfig.TextConfig(
                padding: UIEdgeInsets(top: 0, left: 11, bottom: 0, right: 11),
                font: UIFont.systemFont(ofSize: 10),
                cornerRadius: 8.0,
                textColor: UDColor.rgb(0xde7802),
                backgroundColor: UDColor.rgb(0xfeead2),
                height: 16
            )
            // swiftlint:enable init_font_with_token
        case .recommand:
            config = UDTagConfig.TextConfig(
                cornerRadius: 4.0,
                textColor: UIColor.ud.udtokenTagTextSOrange,
                backgroundColor: UIColor.ud.udtokenTagBgOrange
            )
        case .block:
            config = UDTagConfig.TextConfig(
                cornerRadius: 4.0,
                textColor: UIColor.ud.udtokenTagTextSBlue,
                backgroundColor: UIColor.ud.udtokenTagBgBlue
            )
        case .bookMark:
            config = UDTagConfig.TextConfig(
                cornerRadius: 4.0,
                textColor: UIColor.ud.udtokenTagTextSGreen,
                backgroundColor: UIColor.ud.udtokenTagBgGreen
            )
        case .bot:
            config = UDTagConfig.TextConfig(
                cornerRadius: 4.0,
                textColor: UIColor.ud.udtokenTagTextSYellow,
                backgroundColor: UIColor.ud.udtokenTagBgYellow
            )
        case .shared:
            config = UDTagConfig.TextConfig(
                cornerRadius: 4.0,
                textColor: UIColor.ud.udtokenTagTextSBlue,
                backgroundColor: UIColor.ud.udtokenTagBgBlue
            )
        case .none:
            config = UDTagConfig.TextConfig()
            isHidden = true
        }
        updateUI(textConfig: config)
    }
}
