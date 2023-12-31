//
//  ActionButtonComponent.swift
//  Moments
//
//  Created by liluobin on 2020/1/10.
//

import UIKit
import Foundation
import AsyncComponent

final class ActionButtonComponent<C: AsyncComponent.Context>: ASComponent<ActionButtonComponent.Props, EmptyState, ActionButton, C> {
    final class Props: ASComponentProps {
        var icon: UIImage
        var iconSize: CGFloat
        var title: String
        var titleFont: UIFont
        var titleColor: UIColor
        var iconColor: UIColor
        var onTapped: ActionButton.TapCallback?
        var hitTestEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: -9, left: -9, bottom: -9, right: -9)
        var isEnabled = true
        var isRotate: Bool
        init(icon: UIImage,
             iconSize: CGFloat = 16,
             title: String = "",
             titleFont: UIFont = UIFont.systemFont(ofSize: 14),
             titleColor: UIColor = .ud.iconN3,
             iconColor: UIColor = .ud.N500,
             isRotate: Bool = false) {
            self.icon = icon
            self.title = title
            self.titleFont = titleFont
            self.iconSize = iconSize
            self.titleColor = titleColor
            self.iconColor = iconColor
            self.isRotate = isRotate
        }
    }

    override var isSelfSizing: Bool {
        return true
    }

    override var isComplex: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        return ActionButton.sizeToFit(size, iconSize: props.iconSize, title: props.title, titleFont: props.titleFont)
    }

    public override func create(_ rect: CGRect) -> ActionButton {
        return ActionButton(frame: rect, iconSize: self.props.iconSize, iconColor: props.iconColor, titleColor: props.titleColor)
    }

    override func update(view: ActionButton) {
        super.update(view: view)
        view.update(title: props.title, icon: props.icon, titleFont: props.titleFont)
        view.onTapped = props.onTapped
        view.hitTestEdgeInsets = props.hitTestEdgeInsets
        view.isEnabled = props.isEnabled
        view.isRotate = props.isRotate
    }
}
