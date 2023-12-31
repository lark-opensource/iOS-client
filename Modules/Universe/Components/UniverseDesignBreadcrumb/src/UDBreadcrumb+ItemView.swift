//
//  UDBreadcrumbItemView.swift
//  EEAtomic
//
//  Created by 强淑婷 on 2020/8/19.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon

class UDBreadcrumbItemView: UIView {
    let config: UDBreadcrumbUIConfig

    var title: String = ""

    let itemButton: UIButton = {
        let itemButton = UIButton()
        itemButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 4, bottom: 6, right: 4)
        itemButton.titleLabel?.lineBreakMode = .byTruncatingTail
        return itemButton
    }()
    private static let itemButtonMaxWidth: CGFloat = 320

    let nextIcon = UIImageView()

    var tapItem: ((Int) -> Void)?

    private var index: Int = 0

    private var observation: NSKeyValueObservation?

    init(config: UDBreadcrumbUIConfig) {
        self.config = config

        super.init(frame: .zero)

        self.addSubview(itemButton)
        self.itemButton.snp.makeConstraints { (make) in
            make.leading.top.bottom.equalToSuperview()
            make.width.lessThanOrEqualTo(Self.itemButtonMaxWidth)
        }
        self.itemButton.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)

        self.observation = self.itemButton.observe(\.isHighlighted, options: [.new, .old]) { [weak self] (_, _) in
            guard let `self` = self else { return }

            if self.itemButton.state == .highlighted {
                self.itemButton.backgroundColor = self.config.itemHightedBackgroundColor
            } else {
                self.itemButton.backgroundColor = self.config.itemBackgroundColor
            }
        }

        self.nextIcon.image = UDIcon.rightBoldOutlined.ud.withTintColor(config.iconColor)

        self.itemButton.titleLabel?.font = config.textFont
        self.itemButton.layer.cornerRadius = config.itemCornerRadius

        self.addSubview(nextIcon)
        nextIcon.snp.makeConstraints { (make) in
            make.leading.equalTo(itemButton.snp.trailing)
            make.centerY.right.equalToSuperview()
            make.width.equalTo(12)
            make.height.equalTo(12)
        }
    }

    deinit {
        self.observation?.invalidate()
    }

    func setItem(title: String, hasNext: Bool, index: Int) {
        self.title = title
        itemButton.setTitle(title, for: .normal)
        setState(hasNext: hasNext)
        self.index = index
    }

    func setState(hasNext: Bool) {
        nextIcon.isHidden = !hasNext
        if hasNext {
            itemButton.setTitleColor(config.currentTextColor, for: .normal)
            nextIcon.snp.remakeConstraints { (make) in
                make.leading.equalTo(itemButton.snp.trailing)
                make.centerY.right.equalToSuperview()
                make.width.equalTo(16)
                make.height.equalTo(16)
            }
        } else {
            itemButton.setTitleColor(config.navigationTextColor, for: .normal)
            nextIcon.snp.removeConstraints()
        }
        self.itemButton.snp.remakeConstraints { (make) in
            make.width.lessThanOrEqualTo(Self.itemButtonMaxWidth)
            make.leading.top.bottom.equalToSuperview()
            if !hasNext {
                make.trailing.equalToSuperview()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func buttonClick() {
        self.tapItem?(index)
    }
}
