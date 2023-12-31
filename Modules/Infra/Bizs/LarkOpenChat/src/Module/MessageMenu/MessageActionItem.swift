//
//  MessageActionItem.swift
//  LarkOpenChat
//
//  Created by Zigeng on 2023/1/25.
//

import Foundation
import UIKit

public struct MessageActionItem {

    public typealias MessageAction = (() -> Void)

    public var subItems: [MessageActionItem] {
        return _subItems
    }
    /// 会根据全局配置自动加上 上层业务不感知
    var _subItems: [MessageActionItem] = []
    /// 描述文字
    public var subText: String?

    public enum DisableActionType {
        case showToast(String)
        case action(()->Void)
    }

    /// 常规按钮初始化
    public init(
        text: String,
        icon: UIImage,
        showDot: Bool = false,
        enable: Bool = true,
        disableActionType: DisableActionType? = nil,
        trackExtraParams: [AnyHashable: Any],
        subItems: [MessageActionItem] = [],
        tapAction: @escaping MessageAction) {
            self.text = text
            self.icon = icon
            self.showDot = showDot
            self.isGrey = !enable
            self.tapAction = tapAction
            self.disableActionType = disableActionType
            self.trackExtraParams = trackExtraParams
            self._subItems = subItems
        }

    /// 禁用后点击事件
    public private(set) var disableActionType: DisableActionType?
    /// 点击事件
    public private(set) var tapAction: MessageAction
    /// 是否显示置灰
    public private(set) var isGrey: Bool
    /// 按钮业务提供方提供的按钮名称
    public private(set) var text: String
    /// 按钮业务提供方提供的按钮图标
    public private(set) var icon: UIImage
    /// 按钮业务方声明是否需要红点
    public private(set) var showDot: Bool
    /// 业务方在菜单按钮点击时,期望在上报IM_MSG_MENU_CLICK添加的额外埋点信息
    /// 加入的参数会统一在点击按钮上报事件时加入. 必须上报的参数有click和target
    public private(set) var trackExtraParams: [AnyHashable: Any]
}
