//
//  PerfDegradeView.swift
//  ByteView
//
//  Created by liujianlong on 2021/8/5.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import SnapKit
import ByteViewUI

class PerfDegradeWarningView: UIView {
    enum Style {
        case staticDegrade
        case dynamicDegrade
    }

    private(set) var titleLabel: UILabel = .init()
    private(set) var warningIcon: UIImageView = .init(image: nil)
    private(set) var actionButton: UIButton!
    private(set) var muteButton: UIButton!
    private(set) var closeButton: FixedTouchSizeButton!

    private let effectManger: MeetingEffectManger?
    let style: Style

    init(style: Style, effectManger: MeetingEffectManger?) {
        self.style = style
        self.effectManger = effectManger
        super.init(frame: .zero)
        self.setup()

        if style == .staticDegrade {
            // 当前机型配置较低，开启下列功能可能会影响性能
            self.titleLabel.text = I18n.View_MV_MightAffectFunction
            self.actionButton.setTitle(I18n.View_G_IGotItDuh, for: .normal)
        } else {
            let isVirtualBgOrBlurOn = (effectManger?.virtualBgService.currentVirtualBgsModel?.bgType ?? .setNone) != .setNone
            let i18ns = [
                (I18n.View_VM_VirtualBackground, isVirtualBgOrBlurOn),
                (I18n.View_VM_Avatar, effectManger?.pretendService.isAnimojiOn() ?? false),
                (I18n.View_VM_TouchUpShort, effectManger?.pretendService.isBeautyOn() ?? false),
                (I18n.View_G_Filters, effectManger?.pretendService.isFilterOn() ?? false)
            ]
            let onFeatures = i18ns.filter(\.1).map(\.0).joined(separator: ", ")
            // 当前设备性能消耗过高，建议关闭 {{虚拟头像、虚拟背景、美颜和滤镜}} 功能保证会议流畅
            self.titleLabel.text = I18n.View_MV_EffectsSmoothMeet(onFeatures)
            self.actionButton.setTitle(I18n.View_MV_TurnOffEffects, for: .normal)
            self.muteButton.setTitle(I18n.View_G_LowerVideoQuality_ToastButton, for: .normal)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        self.alpha = 0.94
        self.backgroundColor = UIColor.ud.functionWarningFillSolid02
        self.clipsToBounds = true
        let image = UDIcon.getIconByKey(.warningColorful, size: CGSize(width: 16, height: 16))

        self.warningIcon = UIImageView(image: image)

        self.titleLabel = UILabel()
        self.titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.numberOfLines = 0

        self.actionButton = UIButton(type: .custom)
        self.actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
        self.actionButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)

        self.muteButton = UIButton(type: .custom)
        self.muteButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
        self.muteButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)

        self.closeButton = FixedTouchSizeButton(type: .custom)
        self.closeButton.touchSize = CGSize(width: 44.0, height: 44.0)
        let closeImage = UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN2, size: CGSize(width: 16, height: 16))
        self.closeButton.setImage(closeImage, for: .normal)

        self.addSubview(self.warningIcon)
        self.addSubview(self.titleLabel)
        if self.style == .dynamicDegrade {
            self.addSubview(self.closeButton)
            self.addSubview(self.muteButton)
        }
        self.addSubview(self.actionButton)

        self.titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        self.titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        self.actionButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        self.actionButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        self.actionButton.setContentHuggingPriority(.defaultHigh, for: .vertical)

        self.muteButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        self.muteButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        self.muteButton.setContentHuggingPriority(.defaultHigh, for: .vertical)

        if Display.pad && VCScene.isRegular {
            setupPadLayout()
        } else {
            setupPhoneLayout()
        }
    }

    let leftSpacer = UILayoutGuide()
    let rightSpacer = UILayoutGuide()

    func remakeLayout(isRegular: Bool) {
        if isRegular {
            setupPadLayout()
        } else {
            setupPhoneLayout()
        }
    }

    func updatePhoneLayout() {
        setupPhoneLayout()
    }

    // disable-lint: duplicated code
    private func setupPhoneLayout() {
        let horizontalPadding: CGFloat = 16.0
        self.cleanupSpacer()

        if isPhoneLandscape {
            self.addLayoutGuide(leftSpacer)
            self.addLayoutGuide(rightSpacer)
            leftSpacer.snp.makeConstraints { make in
                make.left.equalToSuperview()
            }
            rightSpacer.snp.makeConstraints { make in
                make.right.equalToSuperview()
                make.width.equalTo(leftSpacer)
            }
            self.warningIcon.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(14.0)
                make.left.equalTo(self.leftSpacer.snp.right)
                make.size.equalTo(CGSize(width: 16.0, height: 16.0))
            }
            self.titleLabel.snp.remakeConstraints { make in
                make.left.equalTo(self.warningIcon.snp.right).offset(8.0)
                make.top.equalToSuperview().offset(12.0)
                make.right.equalTo(self.rightSpacer.snp.left)
            }
        } else {
            self.warningIcon.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(14.0)
                make.left.equalTo(self.safeAreaLayoutGuide).offset(horizontalPadding)
                make.size.equalTo(CGSize(width: 16.0, height: 16.0))
            }
            self.titleLabel.snp.remakeConstraints { make in
                make.left.equalTo(self.warningIcon.snp.right).offset(8.0)
                make.top.equalToSuperview().offset(12.0)
                if self.style == .staticDegrade {
                    make.right.equalTo(self.safeAreaLayoutGuide).offset(-horizontalPadding)
                } else {
                    make.right.equalTo(self.closeButton.snp.left).offset(-16.0)
                }
            }
        }
        self.actionButton.snp.remakeConstraints { make in
            make.left.equalTo(self.titleLabel)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(4.0)
            make.bottom.equalToSuperview().offset(-12.0)
            make.height.equalTo(20)
        }
        if self.style == .dynamicDegrade {
            self.backgroundColor = UIColor.ud.functionWarningFillSolid02
            self.layer.cornerRadius = 0.0
            self.layer.borderWidth = 0.0
            self.layer.ud.setBorderColor(UIColor.ud.functionWarningContentDefault)
            self.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
            self.layer.shadowRadius = 0.0
            self.layer.ud.setShadowColor(UIColor.ud.shadowDefaultMd)

            self.muteButton.snp.remakeConstraints { make in
                make.left.equalTo(self.actionButton.snp.right).offset(16.0)
                make.centerY.equalTo(self.actionButton)
                make.height.equalTo(20)
            }

            self.closeButton.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(14.0)
                make.right.equalTo(self.safeAreaLayoutGuide).offset(-horizontalPadding)
                make.size.equalTo(CGSize(width: 16.0, height: 16.0))
            }
        }
    }

    private func setupPadLayout() {
        self.cleanupSpacer()
        if style == .staticDegrade {
            self.warningIcon.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(16.0).priority(.high)
                make.left.equalTo(self.safeAreaLayoutGuide.snp.left).priority(.medium)
                make.left.greaterThanOrEqualTo(self.safeAreaLayoutGuide.snp.left)
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize(width: 16.0, height: 16.0))
            }
            self.titleLabel.snp.remakeConstraints { make in
                make.left.equalTo(self.warningIcon.snp.right).offset(8.0)
                make.top.equalToSuperview().offset(12.0)
                make.bottom.equalToSuperview().offset(-12.0)
            }
            self.actionButton.snp.remakeConstraints { make in
                make.right.equalToSuperview().offset(-16.0)
                make.centerY.equalToSuperview()
                make.left.greaterThanOrEqualTo(self.titleLabel.snp.right).offset(8.0)
                make.height.equalTo(20)
            }
        } else {
            self.backgroundColor = UIColor.ud.functionWarningFillSolid01
            self.layer.cornerRadius = 6.0
            self.layer.borderWidth = 1.0
            self.layer.ud.setBorderColor(UIColor.ud.functionWarningContentDefault)
            self.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
            self.layer.shadowRadius = 8.0
            self.layer.ud.setShadowColor(UIColor.ud.shadowDefaultMd)

            self.warningIcon.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(19.0)
                make.left.equalToSuperview().offset(20.0)
                make.size.equalTo(CGSize(width: 16.0, height: 16.0))
            }
            self.titleLabel.snp.remakeConstraints { make in
                make.left.equalTo(self.warningIcon.snp.right).offset(8.0)
                make.top.equalToSuperview().offset(16.0)
                make.right.equalTo(self.closeButton.snp.left).offset(-32.0)
            }
            self.actionButton.snp.remakeConstraints { make in
                make.left.equalTo(self.titleLabel)
                make.top.equalTo(self.titleLabel.snp.bottom).offset(4.0)
                make.bottom.equalToSuperview().offset(-22.0)
                make.height.equalTo(20)
            }
            self.muteButton.snp.remakeConstraints { make in
                make.left.equalTo(self.actionButton.snp.right).offset(16.0)
                make.centerY.equalTo(self.actionButton)
            }
            self.closeButton.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(19.0)
                make.right.equalToSuperview().offset(-20.0).priority(.high)
                make.right.equalTo(self.safeAreaLayoutGuide.snp.right).priority(.medium)
                make.right.lessThanOrEqualTo(self.safeAreaLayoutGuide.snp.right)
                make.size.equalTo(CGSize(width: 16.0, height: 16.0))
            }
        }
    }
    // enable-lint: duplicated code

    private func cleanupSpacer() {
        leftSpacer.owningView?.removeLayoutGuide(leftSpacer)
        rightSpacer.owningView?.removeLayoutGuide(rightSpacer)
    }
}
