//
//  IconButtonComponent.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/2/17.
//

import UIKit
import Foundation
import AsyncComponent

final class IconButtonComponent<C: AsyncComponent.Context>: ASComponent<IconButtonComponent.Props, EmptyState, IconButton, C> {
    final class Props: ASComponentProps {
        var icon: UIImage?
        var iconSize: CGFloat
        var title: String
        var titleFont: UIFont
        var onTapped: IconButton.TapCallback?
        var hitTestEdgeInsets: UIEdgeInsets = .zero
        let iconBlock: (() -> UIImage)?
        init(icon: UIImage, iconSize: CGFloat = 16, title: String = "", titleFont: UIFont = UIFont.systemFont(ofSize: 14)) {
            self.iconBlock = nil
            self.icon = icon
            self.title = title
            self.titleFont = titleFont
            self.iconSize = iconSize
        }
        init(iconBlock: @escaping (() -> UIImage), iconSize: CGFloat = 16, title: String = "", titleFont: UIFont = UIFont.systemFont(ofSize: 14)) {
                    self.iconBlock = iconBlock
                    self.icon = nil
                    self.title = title
                    self.titleFont = titleFont
                    self.iconSize = iconSize
                }
    }

    override var isSelfSizing: Bool {
        return true
    }

    override var isComplex: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        return IconButton.sizeToFit(size, iconSize: props.iconSize, title: props.title, titleFont: props.titleFont)
    }

    public override func create(_ rect: CGRect) -> IconButton {
        return IconButton(frame: rect, iconSize: self.props.iconSize)
    }

    override func update(view: IconButton) {
        super.update(view: view)
        if let iconBlock = self.props.iconBlock {
            view.update(title: props.title, icon: iconBlock(), titleFont: props.titleFont)
        } else {
            view.update(title: props.title, icon: props.icon, titleFont: props.titleFont)
        }
        view.onTapped = props.onTapped
        view.hitTestEdgeInsets = props.hitTestEdgeInsets
    }
}
