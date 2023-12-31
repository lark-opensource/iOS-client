//
//  UDBadge+Update.swift
//  UniverseDesignBadge
//
//  Created by Meng on 2020/10/28.
//

import Foundation
import UIKit
import UniverseDesignIcon
import SnapKit

extension UDBadge {
    /// force update badge UI and layout
    public func forceUpdate() {
        update()
    }

    func didUpdateConfig() {
        guard lastRefreshId != config.refreshId else { return }
        lastRefreshId = config.refreshId
        runOnMain { [weak self] in
            self?.update()
        }
    }

    func update() {
        updateStyle()
        switch config.type {
        case .dot:
            updateDot()
        case .text:
            updateText()
        case .number:
            updateNumber()
        case .icon:
            updateIcon()
        }

        let badgeSize = currentSize
        if let superView = superview, config.hasAnchor {
            self.snp.updateConstraints { (make) in
                let center = config.centerPoint(for: superView.bounds, with: badgeSize)
                make.centerX.equalTo(superView.snp.leading).offset(center.x)
                make.centerY.equalTo(superView.snp.top).offset(center.y)
            }
        }
        invalidateIntrinsicContentSize()
    }

    private func updateStyle() {
        layer.borderWidth = config.border.width
        layer.borderColor = config.borderStyle.color.cgColor
        layer.cornerRadius = config.cornerRadius
        contentView.backgroundColor = config.style.color
        contentView.layer.cornerRadius = config.cornerRadius
        contentView.layer.borderColor = UIColor.clear.cgColor
        icon.tintColor = config.contentStyle.color
        label.textColor = config.contentStyle.color
    }

    private func updateDot() {
        label.isHidden = true
        icon.isHidden = true
    }

    private func updateText() {
        isHidden = config.text.isEmpty && !config.showEmpty
        label.isHidden = config.text.isEmpty && !config.showEmpty
        label.text = config.text
        icon.isHidden = true
    }

    private func updateNumber() {
        if config.number > config.maxNumber {
            switch config.maxType {
            case .ellipsis:
                isHidden = false
                label.isHidden = true
                icon.isHidden = false
                icon.image = UDIcon.getIconByKey(
                    .moreOutlined,
                    iconColor: UDBadgeColorStyle.dotCharacterLimitIcon.color,
                    size: UDBadgeType.icon.defaultSize
                )
            case .plus:
                isHidden = (config.number <= 0) && !config.showZero
                icon.isHidden = true
                label.isHidden = (config.number <= 0) && !config.showZero
                label.text = "\(config.maxNumber)+"
            }
        } else {
            isHidden = (config.number <= 0) && !config.showZero
            icon.isHidden = true
            label.isHidden = (config.number <= 0) && !config.showZero
            label.text = "\(config.number)"
        }
    }

    private func updateIcon() {
        label.isHidden = true
        icon.isHidden = false
        if let image = config.icon?.image {
            icon.image = image
        } else {
            icon.image = config.icon?.placeHolderImage
            config.icon?.fetchImage(onCompletion: { [weak self](result) in
                switch result {
                case let .success(image):
                    self?.runOnMain { self?.icon.image = image }
                case let .failure(error):
                    print("UDBadge fetch icon image failed \(error)")
                }
            })
        }
    }

    private func runOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async { block() }
        }
    }
}

// MARK: - Layout
extension UDBadge {
    internal var currentSize: CGSize {
        var contentSize: CGSize
        switch config.type {
        case .dot:
            contentSize = config.dotSize.size
        case .text:
            contentSize = textSize(more: false)
        case .number:
            contentSize = textSize(more: config.number > config.maxNumber)
        case .icon:
            contentSize = UDBadgeType.icon.defaultSize
        }
        contentSize.width += config.border.padding
        contentSize.height += config.border.padding
        return contentSize
    }

    private func textSize(more: Bool) -> CGSize {
        let padding: CGFloat = 2.0 * Layout.labelPadding
        if more && config.maxType == .ellipsis {
            return CGSize(width: padding + UDBadgeType.icon.defaultSize.width,
                          height: UDBadgeType.icon.defaultSize.height)
        } else {
            let textFitSize = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                     height: config.type.defaultSize.height))
            var width = textFitSize.width + padding + 2 * config.border.width
            width = max(width, config.type.defaultSize.width)
            return CGSize(width: width, height: config.type.defaultSize.width)
        }
    }
}
