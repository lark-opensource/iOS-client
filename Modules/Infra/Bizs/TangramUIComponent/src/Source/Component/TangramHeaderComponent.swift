//
//  TangramHeaderComponent.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2021/4/25.
//

import UIKit
import Foundation
import LarkTag
import TangramComponent
import UniverseDesignColor

public final class TangramHeaderComponentProps: Props {
    public typealias IconProvider = (UIImageView) -> Void
    public typealias MenuButtonTapped = (UIButton) -> Void

    /// 标题内容
    public var title: String = ""
    /// 标题字体颜色
    public var titleColor: UIColor?
    public var titleNumberOfLines: Int = 3
    /// 设置图标的闭包
    public var iconProvider: EquatableWrapper<IconProvider?> = .init(value: nil)
    /// 标题后的 Tag
    public var headerTag: TangramHeaderConfig.HeaderTag?
    /// 亮暗主题，默认为亮色
    public var theme: TangramHeaderConfig.Theme = .light
    public var showMenu: Bool = false
    public var menuTapHandler: EquatableWrapper<MenuButtonTapped?> = .init(value: nil)
    /// 可配置区域，传入前必须已经设置好大小
    public var customView: EquatableWrapper<TangramHeaderConfig.CustomViewProvider?> = .init(value: nil)
    public var customViewSize: CGSize = .zero
    public init() {}

    public func clone() -> TangramHeaderComponentProps {
        let clone = TangramHeaderComponentProps()
        clone.title = title
        clone.titleColor = titleColor
        clone.titleNumberOfLines = titleNumberOfLines
        clone.iconProvider = iconProvider
        clone.headerTag = headerTag
        clone.theme = theme
        clone.showMenu = showMenu
        clone.menuTapHandler = menuTapHandler
        clone.customView = customView
        clone.customViewSize = customViewSize
        return clone
    }

    public func equalTo(_ old: Props) -> Bool {
        guard let old = old as? TangramHeaderComponentProps else { return false }
        return title == old.title &&
            titleColor == old.titleColor &&
            titleNumberOfLines == old.titleNumberOfLines &&
            iconProvider == old.iconProvider &&
            headerTag == old.headerTag &&
            theme == old.theme &&
            showMenu == old.showMenu &&
            menuTapHandler == old.menuTapHandler &&
            customView == old.customView &&
            customViewSize == old.customViewSize
    }

    func transTo() -> TangramHeaderConfig {
        return TangramHeaderConfig(title: title,
                                   titleColor: titleColor,
                                   titleNumberOfLines: titleNumberOfLines,
                                   iconProvider: iconProvider.value,
                                   headerTag: headerTag,
                                   theme: theme,
                                   showMenu: showMenu,
                                   menuTapHandler: menuTapHandler.value,
                                   customView: customView.value,
                                   customViewSize: customViewSize)
    }
}

public final class TangramHeaderComponent<C: Context>: RenderComponent<TangramHeaderComponentProps, TangramHeaderView, C> {
    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return TangramHeaderView.sizeThatFit(config: props.transTo(), size: size)
    }

    public override func update(_ view: TangramHeaderView) {
        super.update(view)
        view.configure(with: props.transTo(), width: view.frame.width)
    }
}
