//
//  MenuIPhonePanelCellViewModel.swift
//  LarkUIKitDemo
//
//  Created by 刘洋 on 2021/1/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkBadge
import LarkSetting
import LarkFeatureGating

/// iPhone选项的视图模型
final class MenuIPhonePanelCellViewModel: MenuIPhonePanelCellViewModelProtocol {

    /// 选项的数据模型
    private let model: MenuItemModelProtocol

    /// 选项的Badge的父亲路径
    private let parentPath: Path

    /// 标题的默认字号
    private let defaultFont: UIFont

    /// 标题的最小字号
    private let minFont: UIFont

    /// 存储选项视图背景颜色不同状态下的颜色，为了兼容现有代码，采用UInt作为键，后期会改进
    private var backgroundColor: [UInt: UIColor] = [:]

    /// 存储选项视图标题颜色不同状态下的颜色
    private var titleColor: [UInt: UIColor] = [:]

    /// 存储选项视图图片颜色不同状态下的颜色
    private var imageColor: [UInt: UIColor] = [:]

    var menuBadgeType: MenuBadgeType {
        self.model.badgeType
    }

    let badgeStyle: BadgeStyle

    /// 初始化视图模型
    /// - Parameters:
    ///   - model: 选项数据模型
    ///   - defaultFont: 默认字号
    ///   - minFont: 最小字号
    ///   - parentPath: Badge路径
    ///   - badgeStyle: 菜单Badge的显示风格
    ///   - normalBackgroundColor: 正常状态下的背景颜色
    ///   - pressBackgroundColor: 按压状态下的背景颜色
    ///   - disableBackgroundColor: 禁用状态下的背景颜色
    ///   - normalTitleColor: 正常状态下的标题颜色
    ///   - pressTitleColor: 按压状态下的标题颜色
    ///   - disableTitleColor: 禁用状态下的标题颜色
    ///   - normalImageColor: 正常状态下的图片颜色
    ///   - pressImageColor: 按压状态下的图片颜色
    ///   - disableImageColor: 禁用状态下的图片颜色
    init(model: MenuItemModelProtocol,
         defaultFont: UIFont,
         minFont: UIFont,
         parentPath: Path,
         badgeStyle: BadgeStyle,
         normalBackgroundColor: UIColor = UIColor.ud.bgFloat,
         pressBackgroundColor: UIColor = UIColor.ud.fillHover,
         disableBackgroundColor: UIColor = UIColor.ud.fillDisabled,
         normalTitleColor: UIColor = UIColor.ud.textCaption,
         pressTitleColor: UIColor = UIColor.ud.textCaption,
         disableTitleColor: UIColor = UIColor.ud.textCaption,
         normalImageColor: UIColor = UIColor.ud.iconN1,
         pressImageColor: UIColor = UIColor.ud.iconN1,
         disableImageColor: UIColor = UIColor.ud.iconN1) {
        self.model = model
        self.parentPath = parentPath
        self.defaultFont = defaultFont
        self.minFont = minFont
        self.badgeStyle = badgeStyle

        self.titleColor[UIControl.State.normal.rawValue] = normalTitleColor
        self.titleColor[UIControl.State.disabled.rawValue] = disableTitleColor

        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems")) {//Global 纯UI相关，成本比较大，先不改
            self.titleColor[UIControl.State.disabled.rawValue] = UIColor.ud.textDisabled
        }
        self.titleColor[UIControl.State.selected.rawValue] = pressTitleColor

        self.backgroundColor[UIControl.State.normal.rawValue] = normalBackgroundColor
        self.backgroundColor[UIControl.State.disabled.rawValue] = disableBackgroundColor
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems")) {//Global 纯UI相关，成本比较大，先不改
            self.backgroundColor[UIControl.State.disabled.rawValue] = normalBackgroundColor
        }
        self.backgroundColor[UIControl.State.selected.rawValue] = pressBackgroundColor

        self.imageColor[UIControl.State.disabled.rawValue] = disableImageColor
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems")) {//Global 纯UI相关，成本比较大，先不改
            self.imageColor[UIControl.State.disabled.rawValue] = UIColor.ud.iconDisabled
        }
        self.imageColor[UIControl.State.normal.rawValue] = normalImageColor
        self.imageColor[UIControl.State.selected.rawValue] = pressImageColor
    }

    var title: String {
        model.title
    }

    func font(for size: CGSize, lineHeight: CGFloat) -> UIFont {
        let displayTitle = self.title
        // 生成一个段落样式，用于精确表示菜单标题的样式
        var paraStyle = NSMutableParagraphStyle()
        paraStyle.maximumLineHeight = lineHeight
        paraStyle.minimumLineHeight = lineHeight
        paraStyle.alignment = .center
        // 需要根据单词换行，而不是使用三个点
        paraStyle.lineBreakMode = .byWordWrapping
        var reallySize = NSString(string: displayTitle)
            .boundingRect(with: CGSize(width: size.width, height: CGFloat(MAXFLOAT)),
                          options: .usesLineFragmentOrigin,
                          attributes: [NSAttributedString.Key.font: self.defaultFont, NSAttributedString.Key.paragraphStyle: paraStyle],
                          context: nil).size
        // 计算出来的大小需要使用`ceilf`函数向上取整
        reallySize.height = CGFloat(ceilf(Float(reallySize.height)))
        // 如果比可用区域大那么就要使用小字号
        guard reallySize.height <= size.height else {
            return self.minFont
        }
        return self.defaultFont
    }

    func image(for status: UIControl.State) -> UIImage {
        model.imageModel.image(for: .iPhonePanel, status: status)
    }

    func backgroundColor(for status: UIControl.State) -> UIColor {
        self.backgroundColor[status.rawValue] ?? UIColor.ud.bgFloat
    }

    func imageColor(for status: UIControl.State) -> UIColor {
        self.imageColor[status.rawValue] ?? UIColor.menu.normalImageColor
    }

    func titleColor(for status: UIControl.State) -> UIColor {
        self.titleColor[status.rawValue] ?? UIColor.menu.normalTitleColor
    }

    var badgeType: BadgeType {
        switch self.model.badgeType.type {
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

}
