//
//  NavigationBarItemView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/13.
//

import UIKit

class NavigationBarItemView: ToolBarItemView {
    static let iconSize = CGSize(width: 24, height: 24)
    private static let buttonSize: CGFloat = 28

    override func setupSubviews() {
        super.setupSubviews()

        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.vc.setBackgroundColor(.clear, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgNeutralPressed, for: .highlighted)
        button.vc.setBackgroundColor(.clear, for: .selected)
    }

    override func bind(item: ToolBarItem) {
        super.bind(item: item)
        iconView.image = ToolBarImageCache.image(for: item, location: .navbar)
        badgeView.isHidden = item.badgeType != .dot
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let newButtonFrame = CGRect(x: (frame.width - Self.buttonSize) / 2,
                              y: (frame.height - Self.buttonSize) / 2,
                              width: Self.buttonSize,
                              height: Self.buttonSize)
        if button.frame != newButtonFrame {
            button.frame = newButtonFrame
        }
        let newIconViewFrame = CGRect(origin: CGPoint(x: 2, y: 2), size: Self.iconSize)
        if iconView.frame != newIconViewFrame {
            iconView.frame = newIconViewFrame
        }
        animationView.frame = iconView.frame
        let newBadgeViewFrame = CGRect(x: button.frame.maxX - Self.badgeSize + 1,
                                       y: button.frame.minY - 1,
                                       width: Self.badgeSize,
                                       height: Self.badgeSize)
        if badgeView.frame != newBadgeViewFrame {
            badgeView.frame = newBadgeViewFrame
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if bounds.contains(point) {
            return button
        } else {
            return super.hitTest(point, with: event)
        }
    }
}
