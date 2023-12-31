//
//  ToolBarItemView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import UIKit
import ByteViewUI
import UniverseDesignLoading

struct ToolBarItemLayout {
    static let collectionIconSize = CGSize(width: 24, height: 24)
    static let landscapeCollectionIconSize = CGSize(width: 22, height: 22)
    static let padItemHeight: CGFloat = 40
    static let listIconSize = CGSize(width: 20, height: 20)

    static func textWidth(_ text: String, font: UIFont) -> CGFloat {
        text.vc.boundingWidth(height: padItemHeight, font: font)
    }
}

class ToolBarItemView: UIView, ToolBarItemDelegate {
    static let badgeSize: CGFloat = 8

    let item: ToolBarItem
    let button = UIButton()
    let iconView = UIImageView()

    lazy var animationView: UIView = {
        let spinColor: UIColor = Display.phone ? .ud.iconN1 : .ud.iconN2
        let spinIndicatorSize: CGFloat = Display.phone ? 24.0 : 20.0
        let spinIndicatorConfig = UDSpinIndicatorConfig(size: spinIndicatorSize, color: spinColor.withAlphaComponent(0.8))
        let spinConfig = UDSpinConfig(indicatorConfig: spinIndicatorConfig, textLabelConfig: nil)
        let view = UDLoading.spin(config: spinConfig)
        view.isHidden = true
        return view
    }()

    var itemType: ToolBarItemType {
        item.itemType
    }

    lazy var badgeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.colorfulRed
        view.layer.cornerRadius = Self.badgeSize / 2
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    init(item: ToolBarItem) {
        self.item = item
        super.init(frame: .zero)
        setupSubviews()
        item.addListener(self)
        bind(item: item)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        button.addTarget(self, action: #selector(handleButtonClick), for: .touchUpInside)
        addSubview(button)

        button.addSubview(iconView)
        button.addSubview(animationView)
        addSubview(badgeView)
    }

    func bind(item: ToolBarItem) {
        button.isEnabled = item.isEnabled
        button.isSelected = item.isSelected
    }

    func handleClick() {
        item.clickAction()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if button.frame != bounds {
            button.frame = bounds
        }
    }

    func toolbarItemDidChange(_ item: ToolBarItem) {
        bind(item: item)
    }

    @objc private func handleButtonClick() {
        throttledClick(())
    }

    private lazy var throttledClick: Throttle<Void> = {
        throttle(interval: .milliseconds(600)) { [weak self] in
            self?.handleClick()
        }
    }()

    func startAnimation() {
        iconView.isHidden = true
        animationView.isHidden = false
    }

    func stopAnimation() {
        iconView.isHidden = false
        animationView.isHidden = true
    }
}
