//
//  PadToolBarTitledView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/9.
//

import UIKit

class PadToolBarTitledView: PadToolBarItemView {
    static let maxTitleWidth: CGFloat = 176
    static let fontSize: CGFloat = 14
    static let fontWeight: UIFont.Weight = .regular

    override var itemWidth: CGFloat {
        showTitle ? 12 + 20 + 6 + 12 + itemTitleWidth : 40
    }

    override func reset() {
        super.reset()
        toggleTitle(show: true)
    }

    func toggleTitle(show: Bool) {
        canShowTitle = show
        setNeedsLayout()
    }

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Self.fontSize, weight: Self.fontWeight)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    override func setupSubviews() {
        super.setupSubviews()
        button.addSubview(titleLabel)
    }

    override func bind(item: ToolBarItem) {
        super.bind(item: item)
        titleLabel.textColor = item.isEnabled ? UIColor.ud.textTitle : UIColor.ud.textDisabled
        if titleLabel.text != item.title || item.showTitle == titleLabel.isHidden {
            titleLabel.text = item.title
            item.notifySizeListeners()
        }
        lastTitleColor = item.titleColor
        updateGradientTitleLabel()
    }

    var lastTitleColor: ToolBarColorType = .none
    var lastBounds: CGRect = .zero

    override func layoutSubviews() {
        super.layoutSubviews()
        if item.title.isEmpty || !showTitle {
            titleLabel.isHidden = true
            iconView.frame = CGRect(origin: CGPoint(x: 10, y: 10), size: Self.iconSize)
        } else {
            let actualTitleWidth = min(Self.maxTitleWidth, itemTitleWidth)
            let titleHeight: CGFloat = 22
            titleLabel.isHidden = false
            iconView.frame = CGRect(origin: CGPoint(x: 12, y: 10), size: Self.iconSize)
            titleLabel.frame = CGRect(x: 38, y: (bounds.height - titleHeight) / 2, width: actualTitleWidth, height: titleHeight)
        }
        if bounds != lastBounds {
            lastBounds = bounds
            updateGradientTitleLabel()
        }
    }

    private func updateGradientTitleLabel() {
        let titleColor = lastTitleColor
        if let validTitleColor = titleColor.toRealColor(titleLabel.bounds) {
            titleLabel.textColor = validTitleColor
        } else {
            titleLabel.textColor = item.isEnabled ? UIColor.ud.textTitle : UIColor.ud.textDisabled
        }
    }

    var itemTitleWidth: CGFloat {
        ToolBarTitleWidthCache.titleWidth(item.title, fontSize: Self.fontSize, fontWeight: Self.fontWeight)
    }
}
