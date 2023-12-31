//
//  ChatKeyboardMoreItem.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2021/12/27.
//

import UIKit
import Foundation

/// 键盘「+」号菜单类型
/// - 此处顺序会影响整体排序，越小的越靠前
/// - 白名单管控
public enum ChatKeyboardMoreItemType: Int {
    case file /// 文件
    case doc /// 云文档
    case groupSolitaire /// 群接龙
    case vote /// 投票
    case redPacket /// 红包
    case calendarEvent /// 日程
    case location /// 定位
    case userCard /// 个人名片
    case scheduleSend /// 定时发送
    case todo /// 任务
    case meego /// meego
    case realTimeTranslate /// 翻译助手开关
    case openPlatform /// 开放平台小程序
}

/// 键盘「+」号菜单模型
public protocol ChatKeyboardMoreItem {
    var icon: UIImage { get }
    var selectIcon: UIImage? { get }
    var tapped: (() -> Void) { get set }
    var text: String { get }
    var showDotBadge: Bool { get set } // 展示红点 badge
    var type: ChatKeyboardMoreItemType { get } // 用于排序 + 白名单管控
    var badgeText: String? { get }  // 文字 badge
    var customViewBlock: ((UIView) -> Void)? { get }  // 用于完全自定义样式, 参数 view 为一个占满 cell 的不可交互的 view
    var isDynamic: Bool { get } // 是否动态Item，动态Item image会充满
}

public struct ChatKeyboardMoreItemConfig: ChatKeyboardMoreItem {
    public let customViewBlock: ((UIView) -> Void)?
    public let icon: UIImage
    public let selectIcon: UIImage?
    public var tapped: () -> Void
    public let text: String
    public let type: ChatKeyboardMoreItemType
    public let badgeText: String?
    public var showDotBadge: Bool
    public let isDynamic: Bool

    public init(
        text: String,
        icon: UIImage,
        selectIcon: UIImage? = nil,
        type: ChatKeyboardMoreItemType,
        badgeText: String? = nil,
        showDotBadge: Bool = false,
        isDynamic: Bool = false,
        customViewBlock: ((UIView) -> Void)? = nil,
        tapped: @escaping () -> Void) {
        self.text = text
        self.showDotBadge = showDotBadge
        self.isDynamic = isDynamic
        self.selectIcon = selectIcon
        self.icon = icon
        self.type = type
        self.tapped = tapped
        self.badgeText = badgeText
        self.customViewBlock = customViewBlock
    }
}
