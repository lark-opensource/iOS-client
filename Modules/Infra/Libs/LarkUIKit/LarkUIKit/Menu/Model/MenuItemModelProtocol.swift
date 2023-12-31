//
//  MenuItemModelProtocol.swift
//  LarkUIKitDemo
//
//  Created by 刘洋 on 2021/1/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 菜单页面显示出来每一个Item的数据模型
@objc
public protocol MenuItemModelProtocol {

    /**
     用于表示Item触发的行为的别名

     - Parameters:
        - identifier: Item的唯一标识符
     */
    typealias MenuItemAction = (_ identifier: String) -> Void

    /**
     Item的标题
     */
    var title: String {get set}

    /**
     Item的图片模型
     */
    var imageModel: MenuItemImageModelProtocol {get set}

    /**
     Item的bage数量

     当为0的时候表示这个Item不附带Badge，否则表示附带的Badge数量
     */
    var badgeNumber: UInt {get set}

    /// Item的bage风格
    var badgeType: MenuBadgeType {get set}

    /**
     点击Item的触发的行为
     */
    var action: MenuItemAction {get set}

    /**
     点击Item后是否关闭菜单面板
     */
    var autoClosePanelWhenClick: Bool {get set}

    /**
     Item是否可以被点击
     */
    var disable: Bool {get set}

    /**
     Item的唯一标识符

     必须保持唯一，这个涉及到内部红点更新的逻辑
     */
    var itemIdentifier: String {get}

    /**
     Item的优先级

     优先级越高的菜单项会排列在前面
     */
    var itemPriority: Float {get}
}
