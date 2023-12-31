//
//  EnterpriseCallOutView.swift
//  ByteView
//
//  Created by bytedance on 2021/8/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import SnapKit
import Lottie
import ByteViewCommon
import UniverseDesignIcon
import ByteViewUI

// 公司拨号页面视图
class EnterpriseCallOutView: UIView {

    var cancelButton: UIButton {
        return overlayView.cancelButton
    }

    var floatingButton: UIButton {
        return overlayView.floatingButton
    }

    lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    private lazy var maskImageView = AvatarView(style: .square)

    private lazy var visualEffectView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView()
        visualEffectView.effect = UIBlurEffect(style: .regular)

        let maskView = UIView()
        maskView.alpha = 0.8
        maskView.backgroundColor = UIColor.ud.bgBody

        visualEffectView.contentView.addSubview(maskView)
        maskView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        return visualEffectView
    }()

    private lazy var overlayView = EnterpriseCallOutOverlayView(frame: .zero, isVoiceCall: isVoiceCall)

    // MARK: - Init
    private var isVoiceCall: Bool
    init(frame: CGRect, isVoiceCall: Bool) {
        self.isVoiceCall = isVoiceCall
        super.init(frame: frame)
        setup()
        setupSubviews()
        autoLayoutSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI elements update
    func updateAvatar(avatarInfo: AvatarInfo) {
        overlayView.avatarImageView.setAvatarInfo(avatarInfo)
        maskImageView.setAvatarInfo(avatarInfo, size: .large)
    }

    func updateName(name: String) {
        overlayView.nameLabel.text = name
    }

    func updateDescription(description: String) {
        overlayView.descriptionLabel.text = description
    }

    func updateOverlayAlpha(alpha: CGFloat, duration: TimeInterval = 0) {
        UIView.animate(withDuration: duration) {
            self.overlayView.alpha = alpha
        }
    }

    func playRipple() {
        overlayView.animationView.play()
    }

    func stopRipple() {
        overlayView.animationView.stop()
    }


    // MARK: - Layouts
    private func setup() {
        backgroundColor = .clear
        clipsToBounds = true
    }

    private func setupSubviews() {
        addSubview(contentView)
        addSubview(maskImageView)
        addSubview(visualEffectView)
        addSubview(overlayView)
    }

    private func autoLayoutSubviews() {
        contentView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        maskImageView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        visualEffectView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        overlayView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.safeAreaLayoutGuide)
        }
    }
}

// 公司拨号页面布局
private class EnterpriseCallOutOverlayView: UIView {

    lazy var avatarImageView = AvatarView()

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.attributedText = NSAttributedString(string: " ", config: .h2, alignment: .center)
        label.numberOfLines = 2
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.sizeToFit()
        return label
    }()

    lazy var sloganView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 8.0
        [I18n.View_MV_EnterprisePayment_Highlight, "·", I18n.View_MV_PrivacyProtection_Highlight].forEach { [weak stackView] in
            let label = UILabel()
            label.attributedText = .init(string: $0, config: .boldBodyAssist, textColor: .ud.textCaption)
            stackView?.addArrangedSubview(label)
        }
        return stackView
    }()

    lazy var floatingButton: UIButton = {
        let button = UIButton(type: .custom)
        let normalColor = UIColor.ud.iconN1
        let highlightedColor = UIColor.ud.iconN3
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: normalColor, size: CGSize(width: 24, height: 24)), for: .normal)
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: highlightedColor, size: CGSize(width: 24, height: 24)), for: .highlighted)
        return button
    }()

    lazy var cancelView: UIView = {
        let view = UIView()
        view.addSubview(cancelButton)
        view.addSubview(cancelViewLbl)

        cancelButton.snp.makeConstraints { (maker) in
            maker.size.equalTo(68)
            maker.top.left.right.equalToSuperview()
        }
        cancelViewLbl.snp.makeConstraints { (maker) in
            maker.height.equalTo(18)
            maker.bottom.left.right.equalToSuperview()
            maker.top.equalTo(cancelButton.snp.bottom).offset(8)
        }
        return view
    }()

    lazy var cancelViewLbl: UILabel = createButtonLabel(I18n.View_G_CancelButton)

    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.accessibilityIdentifier = "EnterpriseCallOutView.cancelButton"
        button.layer.masksToBounds = true
        button.layer.ux.setSmoothCorner(radius: 20, corners: .allCorners, smoothness: .max)
        button.vc.setBackgroundColor(UIColor.ud.functionDangerContentDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.functionDangerContentPressed, for: .highlighted)
        let image = UDIcon.getIconByKey(.callEndFilled, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 34, height: 34))
        button.setImage(image, for: .normal)
        button.setImage(image, for: .highlighted)
        return button
    }()

    lazy var animationView: LOTAnimationView = {
        let view = LOTAnimationView(name: "ripple", bundle: .localResources)
        view.loopAnimation = true
        return view
    }()

    private var isVoiceCall: Bool
    init(frame: CGRect, isVoiceCall: Bool) {
        self.isVoiceCall = isVoiceCall
        super.init(frame: frame)
        setupSubviews()
        autoLayoutSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    private func setupSubviews() {
        addSubview(animationView)
        addSubview(avatarImageView)
        addSubview(nameLabel)
        addSubview(descriptionLabel)
        addSubview(sloganView)
        addSubview(cancelView)
    }

    private func autoLayoutSubviews() {
        avatarImageView.snp.makeConstraints { (maker) in
            maker.top.equalTo(safeAreaLayoutGuide).offset(160)
            maker.centerX.equalToSuperview()
            maker.size.equalTo(100)
        }
        nameLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalTo(avatarImageView)
            maker.top.equalTo(avatarImageView.snp.bottom).offset(31)
            maker.left.equalToSuperview().offset(16)
            maker.right.equalToSuperview().offset(-16)
        }
        descriptionLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalTo(nameLabel)
            maker.top.equalTo(nameLabel.snp.bottom).offset(10)
            maker.left.right.equalTo(nameLabel)
        }
        sloganView.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(14.0)
            $0.centerX.equalToSuperview()
        }
        cancelView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(self.safeAreaLayoutGuide).offset(-40)
        }
        animationView.snp.makeConstraints { make in
            make.center.equalTo(self.avatarImageView.snp.center)
            make.width.equalTo(self.avatarImageView.snp.width).offset(28.0)
            make.height.equalTo(self.avatarImageView.snp.height).offset(28.0)
        }
    }

    private func createButtonLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 12)
        label.lineBreakMode = .byTruncatingMiddle
        label.textAlignment = .center
        return label
    }

}
