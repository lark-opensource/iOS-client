//
//  PhoneToolBarItemView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/9.
//

import UIKit
import UniverseDesignIcon

class PhoneToolBarItemView: ToolBarItemView {
    static let iconSize = CGSize(width: 22, height: 22)
    static let fontSize: CGFloat = 10
    static let fontWeight = UIFont.Weight.regular

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Self.fontSize, weight: Self.fontWeight)
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    override func setupSubviews() {
        super.setupSubviews()
        addSubview(titleLabel)
    }

    override func bind(item: ToolBarItem) {
        super.bind(item: item)
        iconView.image = ToolBarImageCache.image(for: item, location: .phonebar)
        if case .dot = item.badgeType {
            badgeView.isHidden = false
        } else {
            badgeView.isHidden = true
        }
        titleLabel.text = item.title
        titleLabel.textColor = item.isEnabled ? UIColor.ud.textCaption : UIColor.ud.textDisabled
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        iconView.frame = CGRect(origin: CGPoint(x: (frame.width - Self.iconSize.width) / 2, y: 3.5),
                                size: Self.iconSize)
        badgeView.frame = CGRect(x: iconView.frame.maxX - Self.badgeSize / 2,
                                 y: iconView.frame.minY - Self.badgeSize / 2,
                                 width: Self.badgeSize,
                                 height: Self.badgeSize)
        let titleWidth = itemTitleWidth
        titleLabel.frame = CGRect(x: max(4, (frame.width - titleWidth) / 2),
                                  y: iconView.frame.maxY + 2,
                                  width: titleWidth,
                                  height: 13)
    }

    private var itemTitleWidth: CGFloat {
        ToolBarTitleWidthCache.titleWidth(item.title, fontSize: Self.fontSize, fontWeight: Self.fontWeight)
    }
}
