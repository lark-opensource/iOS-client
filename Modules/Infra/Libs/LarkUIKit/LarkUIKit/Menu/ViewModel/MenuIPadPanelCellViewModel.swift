//
//  MenuIPadPanelCellViewModel.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/2.
//

import Foundation
import UIKit
import LarkBadge

/// iPad菜单的视图模型
final class MenuIPadPanelCellViewModel: MenuIPadPanelCellViewModelProtocol {

    /// 选项的数据模型
    private let model: MenuItemModelProtocol

    var title: String {
        model.title
    }

    let font: UIFont

    /// 选项的Badge的父亲路径
    private let parentPath: Path

    /// 存储选项视图背景颜色不同状态下的颜色，为了兼容现有代码，采用UInt作为键，后期会改进
    private var backgroundColor: [UInt: UIColor] = [:]

    /// 存储选项视图标题颜色不同状态下的颜色
    private var titleColor: [UInt: UIColor] = [:]

    /// 存储选项视图图片颜色不同状态下的颜色
    private var imageColor: [UInt: UIColor] = [:]

    var isShowBorderLine: Bool

    var badgeType: BadgeType {
        switch self.menuBadgeType.type {
        case .number:
            return .label(.number(Int(self.model.badgeNumber)))
        case .none:
            return .clear
        case .dotLarge:
            if self.model.badgeNumber > 0 {
                return .dot(.lark)
            } else {
                return .clear
            }
        case .dotSmall:
            if self.model.badgeNumber > 0 {
                return .dot(.web)
            } else {
                return .clear
            }
        }
    }

    var isShowBadge: Bool {
        self.badgeType != .clear && self.badgeType != .label(.number(0))
    }

    var menuBadgeType: MenuBadgeType {
        self.model.badgeType
    }

    let badgeStyle: BadgeStyle

    var path: Path {
        self.parentPath.raw(model.itemIdentifier)
    }

    var action: MenuItemModelProtocol.MenuItemAction {
        model.action
    }

    var autoClosePanelWhenClick: Bool {
        model.autoClosePanelWhenClick
    }

    var disable: Bool {
        model.disable
    }

    var identifier: String {
        model.itemIdentifier
    }

    /// 初始化视图模型
    /// - Parameters:
    ///   - model: 数据模型
    ///   - parentPath: Badge的父亲路径
    ///   - badgeStyle: 菜单的Badge风格
    ///   - font: 标题字号
    ///   - isShowBorderLine: 是否应该显示分割线
    ///   - normalBackgroundColor: 正常状态下的背景颜色
    ///   - hoverBackgroundColor: hover状态下的背景颜色
    ///   - pressBackgroundColor: 按压状态下的背景颜色
    ///   - disableBackgroundColor: 禁用状态下的背景颜色
    ///   - normalTitleColor: 正常状态下的标题颜色
    ///   - pressTitleColor: 按压状态下的标题颜色
    ///   - hoverTitleColor: hover状态的标题颜色
    ///   - disableTitleColor: 禁用状态下的标题颜色
    ///   - normalImageColor: 正常状态下的图片颜色
    ///   - pressImageColor: 按压状态下的图片颜色
    ///   - hoverImageColor: hover状态下的图片颜色
    ///   - disableImageColor: 禁用状态下的标题颜色
    init(model: MenuItemModelProtocol,
         parentPath: Path,
         badgeStyle: BadgeStyle,
         font: UIFont,
         isShowBorderLine: Bool = true,
         normalBackgroundColor: UIColor = UIColor.menu.normalBackgroundColorForIPad,
         hoverBackgroundColor: UIColor = UIColor.menu.hoverBackgroundColor,
         pressBackgroundColor: UIColor = UIColor.menu.pressBackgroundColor,
         disableBackgroundColor: UIColor = UIColor.menu.disableBackgroundColor,
         normalTitleColor: UIColor = UIColor.menu.normalTitleColorForIPad,
         pressTitleColor: UIColor = UIColor.menu.pressTitleColorForIPad,
         hoverTitleColor: UIColor = UIColor.menu.hoverTitleColorForIPad,
         disableTitleColor: UIColor = UIColor.menu.disableTitleColor,
         normalImageColor: UIColor = UIColor.menu.normalImageColor,
         pressImageColor: UIColor = UIColor.menu.pressImageColor,
         hoverImageColor: UIColor = UIColor.menu.hoverImageColor,
         disableImageColor: UIColor = UIColor.menu.disableImageColor) {
        self.model = model
        self.parentPath = parentPath
        self.font = font
        self.isShowBorderLine = isShowBorderLine
        self.badgeStyle = badgeStyle

        self.titleColor[UIControl.State.normal.rawValue] = normalTitleColor
        self.titleColor[UIControl.State.disabled.rawValue] = disableTitleColor
        self.titleColor[UIControl.State.selected.rawValue] = pressTitleColor
        self.titleColor[UIControl.State.focused.rawValue] = hoverTitleColor

        self.backgroundColor[UIControl.State.normal.rawValue] = normalBackgroundColor
        self.backgroundColor[UIControl.State.disabled.rawValue] = disableBackgroundColor
        self.backgroundColor[UIControl.State.selected.rawValue] = pressBackgroundColor
        self.backgroundColor[UIControl.State.focused.rawValue] = hoverBackgroundColor

        self.imageColor[UIControl.State.disabled.rawValue] = disableImageColor
        self.imageColor[UIControl.State.normal.rawValue] = normalImageColor
        self.imageColor[UIControl.State.selected.rawValue] = pressImageColor
        self.imageColor[UIControl.State.focused.rawValue] = hoverImageColor
    }

    func image(for status: UIControl.State) -> UIImage {
        model.imageModel.image(for: .iPadPopover, status: status)
    }

    func backgroundColor(for status: UIControl.State) -> UIColor {
        self.backgroundColor[status.rawValue] ?? UIColor.menu.normalBackgroundColor
    }

    func imageColor(for status: UIControl.State) -> UIColor {
        self.imageColor[status.rawValue] ?? UIColor.menu.normalImageColor
    }

    func titleColor(for status: UIControl.State) -> UIColor {
        self.titleColor[status.rawValue] ?? UIColor.menu.normalTitleColor
    }
}
