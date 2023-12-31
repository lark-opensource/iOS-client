//
//  MenuPanelCellCommonViewModelProtocol.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/3.
//

import Foundation
import UIKit
import LarkBadge

/// 不同样式下菜单中每一个选项的公共视图模型
protocol MenuPanelCellCommonViewModelProtocol {
    /// 选项的标题
    var title: String {get}

    /// 根据选项的视图状态获取对应的图片
    /// - Parameter status: 视图的状态
    func image(for status: UIControl.State) -> UIImage

    /// 根据选项的视图状态获取对应的图片颜色
    /// - Parameter status: 视图的状态
    func imageColor(for status: UIControl.State) -> UIColor

    /// 根据选项的视图状态获取对应的标题
    /// - Parameter status: 视图的状态
    func titleColor(for status: UIControl.State) -> UIColor

    /// 根据选项的视图状态获取对应的背景颜色
    /// - Parameter status: 视图的状态
    func backgroundColor(for status: UIControl.State) -> UIColor

    /// Badge的显示样式
    var badgeType: BadgeType {get}

    /// LarkMenu中的Badge显示样式
    var menuBadgeType: MenuBadgeType {get}

    /// Badge的显示风格
    var badgeStyle: BadgeStyle {get}

    /// Badge的路径，用于监听Badge的数字变化
    var path: Path {get}

    /// 选项的行为
    var action: MenuItemModelProtocol.MenuItemAction {get}

    /// 点击选项是否关闭菜单
    var autoClosePanelWhenClick: Bool {get}

    /// 选项是否允许点击
    var disable: Bool {get}

    /// 选项的ID唯一标识符
    var identifier: String {get}

}
