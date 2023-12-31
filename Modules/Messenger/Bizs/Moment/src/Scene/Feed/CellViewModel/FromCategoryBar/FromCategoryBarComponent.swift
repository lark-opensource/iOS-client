//
//  FromCategoryBarComponent.swift
//  Moment
//
//  Created by bytedance on 2021/8/10.
//

import Foundation
import UIKit
import AsyncComponent
import UniverseDesignColor

final class FromCategoryBarComponent<C: AsyncComponent.Context>: ASComponent<FromCategoryBarComponent.Props, EmptyState, FromCategoryBar, C> {
    final class Props: ASComponentProps {
        var backgroundColorNormal: UIColor
        var backgroundColorPress: UIColor
        var iconKey: String
        var iconSize: CGFloat
        var title: String
        var titleFont: UIFont
        var onTapped: (() -> Void)?
        var enable: Bool
        var hitTestEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: -4, left: 0, bottom: -4, right: 0)
        init(iconKey: String = "", iconSize: CGFloat = 24, title: String = "",
             titleFont: UIFont = UIFont.systemFont(ofSize: 12, weight: .medium),
             enable: Bool = true,
             backgroundColorNormal: UIColor = UDColor.N50 & UDColor.N300,
             backgroundColorPress: UIColor = UDColor.N200 & UDColor.N400) {
            self.iconKey = iconKey
            self.title = title
            self.titleFont = titleFont
            self.iconSize = iconSize
            self.enable = enable
            self.backgroundColorNormal = backgroundColorNormal
            self.backgroundColorPress = backgroundColorPress
        }
    }

    override var isSelfSizing: Bool {
        return true
    }

    override var isComplex: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        return FromCategoryBar.sizeToFit(iconWidth: props.iconSize, title: props.title, titleFont: props.titleFont, iconKey: props.iconKey, enable: props.enable)
    }

    public override func create(_ rect: CGRect) -> FromCategoryBar {
        return FromCategoryBar(frame: rect,
                               iconWidth: props.iconSize,
                               backgroundColorNormal: props.backgroundColorNormal,
                               backgroundColorPress: props.backgroundColorPress)
    }

    override func update(view: FromCategoryBar) {
        super.update(view: view)
        view.update(title: props.title, iconKey: props.iconKey, titleFont: props.titleFont, enable: props.enable)
        view.onTapped = props.onTapped
        view.hitTestEdgeInsets = props.hitTestEdgeInsets
    }
}
