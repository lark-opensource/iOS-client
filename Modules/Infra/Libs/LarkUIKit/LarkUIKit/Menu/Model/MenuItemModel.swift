//
//  MenuItemModel.swift
//  LarkUIKitDemo
//
//  Created by 刘洋 on 2021/1/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

/// 菜单页面显示出来每一个Item的数据模型
public final class MenuItemModel: NSObject, MenuItemModelProtocol {

    public var title: String

    public var imageModel: MenuItemImageModelProtocol

    public var badgeNumber: UInt

    public var badgeType: MenuBadgeType

    public var action: MenuItemAction

    public var autoClosePanelWhenClick: Bool

    public var disable: Bool

    public let itemIdentifier: String

    public var itemPriority: Float

    /// 根据数据模型中的每一项数据初始化数据模型
    /// - Parameters:
    ///   - title: Item的标题
    ///   - imageModel: Item的图片数据模型
    ///   - action: Item的行为
    ///   - itemIdentifier: Item的唯一标识符
    ///   - badgeNumber: Item的Badge数字信息
    ///   - autoClosePanelWhenClick: Item是否点击后直接关闭菜单面板
    ///   - disable: Item是否被禁用
    ///   - badgeType: Item的Badge风格
    @objc
    public init(title: String,
         imageModel: MenuItemImageModelProtocol,
         itemIdentifier: String,
         badgeNumber: UInt = 0,
         autoClosePanelWhenClick: Bool = true,
         disable: Bool = false,
         itemPriority: Float = 0,
         badgeType: MenuBadgeType = .initWithDotSmallStyle(),
         action: @escaping MenuItemAction) {
        self.title = title
        self.imageModel = imageModel
        self.action = action
        self.badgeNumber = badgeNumber
        self.autoClosePanelWhenClick = autoClosePanelWhenClick
        self.disable = disable
        self.itemIdentifier = itemIdentifier
        self.itemPriority = itemPriority
        self.badgeType = badgeType
        super.init()
    }
}
