//
//  QuickLaunchBarItemView.swift
//  LarkQuickLaunchBar
//
//  Created by ByteDance on 2023/5/10.
//

import Foundation
import SnapKit
import UniverseDesignIcon
import UniverseDesignFont
import LarkQuickLaunchInterface
import LarkExtensions

public class QuickLaunchBarItemView: UIView {

    lazy var itemBtn: UIButton = UIButton(type: .custom)
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = self.config.titleFont
        label.textColor = self.config.titleColor
        return label
    }()

    private var config: QuickLaunchBarItemViewConfig
    private var item: QuickLaunchBarItem

    public init(config: QuickLaunchBarItemViewConfig = QuickLaunchBarItemViewConfig(), item: QuickLaunchBarItem) {
        self.item = item
        self.config = config
        super.init(frame: .zero)
        itemBtn.imageView?.contentMode = .scaleAspectFill
        itemBtn.imageView?.snp.makeConstraints({ make in
            make.width.equalTo(config.iconSize.width)
            make.height.equalTo(config.iconSize.height)
        })
        if config.enableTitle {
            let container = UIView(frame: .zero)
            addSubview(container)
            container.addSubview(itemBtn)
            container.addSubview(titleLabel)
            itemBtn.snp.makeConstraints { (make) in
                make.top.equalToSuperview()
                make.width.equalTo(config.iconSize.width)
                make.height.equalTo(config.iconSize.height)
                make.centerX.equalToSuperview()
            }
            titleLabel.snp.makeConstraints { make in
                make.top.equalTo(itemBtn.snp.bottom).offset(config.titleTopPadding)
                make.centerX.bottom.equalToSuperview()
            }
            container.snp.makeConstraints { make in
                make.width.centerX.centerY.equalToSuperview()
            }
            titleLabel.text = item.name
            assert(item.name?.isEmpty != true, "EnableTitle is open, please set all items' title!")
        } else {
            addSubview(itemBtn)
            itemBtn.snp.makeConstraints { (make) in
                make.width.equalTo(config.iconSize.width)
                make.height.equalTo(config.iconSize.height)
                make.centerX.centerY.equalToSuperview()
            }
        }
        itemBtn.hitTestEdgeInsets = .init(top: -10, left: -10, bottom: -10, right: -10)
        let image = item.isEnable ? item.nomalImage : item.disableImage
        itemBtn.setImage(image, for: .normal)
        itemBtn.setImage(image, for: .selected)
        itemBtn.setImage(image, for: .highlighted)
        itemBtn.addTarget(self, action: #selector(itemBtnClickEvent), for: .touchUpInside)
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressEvent))
        itemBtn.addGestureRecognizer(gesture)
        
        updateBadge(item.badge)
    }

    public func updateItem(_ item: QuickLaunchBarItem) {
        self.item = item
        titleLabel.text = item.name
        let image = item.isEnable ? item.nomalImage : item.disableImage
        itemBtn.setImage(image, for: .normal)
        
        updateBadge(item.badge)
    }
    
    private func updateBadge(_ badge: Badge?) {
        guard let badge = badge else {
            itemBtn.uiBadge.badgeView?.removeFromSuperview()
            return
        }
        if itemBtn.uiBadge.badgeView == nil {
            itemBtn.uiBadge.addBadge(type: badge.type)
        }
        itemBtn.uiBadge.badgeView?.type = badge.type
        itemBtn.uiBadge.badgeView?.style = badge.style
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func itemBtnClickEvent() {
        if item.isEnable {
            item.action?(item)
        } else {
            item.disableAction?(item)
        }
    }

    @objc
    private func longPressEvent() {
        item.longPressAction?(item)
    }
}
