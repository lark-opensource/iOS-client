//
//  MenuComponent.swift
//  Action
//
//  Created by 赵冬 on 2019/7/20.
//

import UIKit
import Foundation
import AsyncComponent

final class MenuComponent<C: AsyncComponent.Context>: ASComponent<MenuComponent.Props, EmptyState, MenuButton, C> {
    final class Props: ASComponentProps {
        var icon: UIImage
        var onTapped: MenuButton.TapCallback?

        init(icon: UIImage) {
            self.icon = icon
        }
    }

    override var isSelfSizing: Bool {
        return true
    }

    override var isComplex: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        return MenuButton.getSize(size)
    }

    override func update(view: MenuButton) {
        super.update(view: view)
        view.layer.cornerRadius = 6
        view.update(icon: props.icon)
        view.onTapped = props.onTapped
        view.onTapped = { [weak self] menuButton in
            self?.props.onTapped?(menuButton)
        }
    }
}
