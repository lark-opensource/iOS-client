//
//  UpgradePremiumViewController.swift
//  ByteView
//
//  Created by fakegourmet on 2021/3/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewCommon
import ByteViewUI
import UniverseDesignEmpty

private class UpgradePremiumView: UIView {

    lazy var upgradePremiumImageView: UDEmpty = {
        let config = UDEmptyConfig(imageSize: 120, spaceBelowImage: 0, type: .platformUpgrading1)
        let initialView = UDEmpty(config: config)
        return initialView
    }()

    lazy var upgradePremiumLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = .init(string: I18n.View_G_UpgradePlanToUseFeature, config: .h3, alignment: .center, textColor: .ud.textTitle)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(upgradePremiumImageView)
        addSubview(upgradePremiumLabel)

        upgradePremiumImageView.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
        }

        upgradePremiumLabel.snp.makeConstraints {
            $0.top.equalTo(upgradePremiumImageView.snp.bottom).offset(16)
            $0.left.right.equalToSuperview()
            $0.bottom.lessThanOrEqualToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class UpgradePremiumViewController: BaseViewController {

    private lazy var upgradePremiumView = UpgradePremiumView(frame: .zero)
    var isPopover = false
    var contentHeight: CGFloat = 0

    private var labelBounds: CGRect {
        upgradePremiumView.upgradePremiumLabel.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(upgradePremiumView)
        upgradePremiumView.snp.makeConstraints {
            if isPopover {
                $0.left.right.equalToSuperview().inset(24)
                $0.top.equalTo(view.safeAreaLayoutGuide).inset(20)
                $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(20)
            } else {
                $0.left.right.equalToSuperview().inset(16)
                $0.top.equalTo(view.safeAreaLayoutGuide).inset(52)
                $0.bottom.lessThanOrEqualToSuperview().inset(48)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateViewLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateViewLayout()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: nil, completion: { [weak self] _ in
            self?.updateViewLayout()
        })
    }

    func updateContentHeight() {
        let labelHeight = upgradePremiumView.upgradePremiumLabel.sizeThatFits(CGSize(width: labelBounds.width, height: .greatestFiniteMagnitude)).height
        let heightOffset = labelHeight - VCFontConfig.h3.lineHeight
        if isPopover {
            contentHeight = 216 + heightOffset
        } else {
            contentHeight = 260 + heightOffset
        }
    }

    private func updateViewLayout() {
        updateContentHeight()
        updateDynamicModalSize(CGSize(width: 375, height: contentHeight))
        panViewController?.updateBelowLayout()
    }
}

extension UpgradePremiumViewController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        isPopover = isRegular
    }
}

extension UpgradePremiumViewController: PanChildViewControllerProtocol {
    var defaultLayout: RoadLayout {
        return .shrink
    }

    func height(_ axis: RoadAxis, layout: RoadLayout) -> PanHeight {
        upgradePremiumView.setNeedsLayout()
        upgradePremiumView.layoutIfNeeded()
        updateContentHeight()
        updateDynamicModalSize(CGSize(width: 375, height: contentHeight))
        return .contentHeight(contentHeight + 13)
    }
}
