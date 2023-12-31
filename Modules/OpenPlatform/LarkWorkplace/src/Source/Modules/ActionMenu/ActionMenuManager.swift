//
//  ActionMenuManager.swift
//  LarkWorkplace
//
//  Created by Shengxy on 2023/7/11.
//

import Foundation
import LarkUIKit

/// 应用操作菜单展示 Manager，存储操作菜单状态
/// 两种菜单类型：「ICON 形态应用操作菜单」「Block 操作菜单」
/// 两种菜单唤起方式：「ICON 形态或 Block 长按」「Block 点击标题栏右上角操作按钮」
final class ActionMenuManager {
    /// 当前UI是否是更新中（禁止长按操作）
    var isUILocalChanging: Bool = false
    /// 屏幕变化时是否需要刷新长按菜单气泡
    var isNeedRefreshMenuView: Bool = false
    /// 菜单气泡的 popOver 容器（长按菜单和操作菜单通用）（iPad场景）
    weak var showMenuPopOver: BaseUIViewController?
    /// 长按菜单内容 UIView（老版本，用stackView实现）（ICON 形态应用操作菜单）
    var longPressMenuView: WorkPlaceLongPressMenuView?
    /// Block操作菜单内容 UIView（新版本，用collectionView实现）（Block 操作菜单）
    var actionMenuView: WPActionMenuView?
    /// 菜单指向应用在 UICollectionView 中的位置索引
    var targetPath: IndexPath?
    /// 指向应用的 itemId
    var targetItemId: String?
}
