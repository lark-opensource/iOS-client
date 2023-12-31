//
//  CallInView.swift
//  ByteView
//
//  Created by liuning.cn on 2020/9/25.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import Lottie
import ByteViewCommon
import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewMeeting
import SnapKit
import ByteViewUI

private struct Layout {
    static let avatarSideLength: CGFloat = 100.0
    static let rippleSpreadDiff: CGFloat = 28.0
    static let nameLabelHeight: CGFloat = 28.0
    static let descriptionLabelHeight: CGFloat = 20.0
    static let floatingButtonDistanceToEdge: CGFloat = 16
    static let floatingButtonDistanceToTopEdge: CGFloat = 10
    static let floatingButtonSideLength: CGFloat = 24.0
    static let buttonAndLabelDistance: CGFloat = 8.0
    static let commonLabelHeight: CGFloat = 18.0
    static let bottomEdgeDistance: CGFloat = 40.0
    static let buttonSideLength: CGFloat = 68.0
    static let buttonImageSize: CGSize = CGSize(width: 34, height: 34)

    static let bannerCommonLongMargin: CGFloat = 16.0
    static let bannerCommonShortMargin: CGFloat = 8.0
    static let ipPhoneFullButtonSize: CGFloat = Display.iPhoneMaxSeries ? 82 : 72
}

class CallInView: UIView {
    var audioSwitchButton: AudioSwitchButton {
        return overlayView.audioSwitchButton
    }

    private lazy var contentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.clear
        return view
    }()

    private lazy var backgroundImageView = AvatarView(style: .square)

    private lazy var visualEffectView: UIVisualEffectView = {
        let veView = UIVisualEffectView()
        veView.effect = UIBlurEffect(style: .regular)
        return veView
    }()

    private lazy var maskedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloatPush
        return view
    }()

    lazy var overlayView = CallInOverlayView(viewModel: self.viewModel)
    var acceptButton: UIButton {
        return overlayView.acceptButton
    }
    var declineButton: UIButton {
        return overlayView.declineButton
    }
    var voiceOnlyButton: UIButton {
        return overlayView.voiceOnlyButton
    }
    var floatingButton: UIButton {
        return overlayView.floatingButton
    }

    private let viewModel: CallInViewModel
    private var isVoiceCall: Bool { viewModel.isVoiceCall }
    private var callInType: CallInType { viewModel.callInType }

    // MARK: - Init
    init(viewModel: CallInViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI elements update
    func updateAvatar(avatarInfo: AvatarInfo) {
        overlayView.avatarImageView.setAvatarInfo(avatarInfo)
        backgroundImageView.setAvatarInfo(avatarInfo, size: .large)
    }

    func updateName(name: String) {
        overlayView.nameLabel.vc.justReplaceText(to: name)
    }

    func updateAcceptEnabled(enabled: Bool, isClickVoiceOnly: Bool) {
        // 在点击接听后，为防止重复点击，acceptButton会被置为disable状态，但为了防止变成disable的颜色变化有点突兀，UX要求使用normal的颜色
        overlayView.updateAcceptEnabled(enabled: enabled, isClickVoiceOnly: isClickVoiceOnly)
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
        overlayView.rippleView.play()
    }

    func stopRipple() {
        overlayView.rippleView.stop()
    }

    // MARK: - Layouts
    private func setupSubviews() {
        clipsToBounds = true

        addSubview(contentView)
        contentView.addSubview(backgroundImageView)
        contentView.addSubview(visualEffectView)
        contentView.addSubview(maskedView)
        contentView.addSubview(overlayView)

        backgroundImageView.isHidden = (callInType.isPhoneCall && Display.phone)

        // update voice-only button and label
        overlayView.voiceOnlyButton.isHidden = isVoiceCall
        overlayView.voiceOnlyLabel.isHidden = isVoiceCall

        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        backgroundImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        visualEffectView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        maskedView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        overlayView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

class CallInOverlayView: UIView {
    let rippleView: LOTAnimationView = {
        let view = LOTAnimationView(name: "ripple", bundle: .localResources)
        view.loopAnimation = true
        return view
    }()

    let avatarImageView = AvatarView()

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: isPhoneCallStyle ? 32 : 20, weight: .medium)
        label.textAlignment = callInType == .ipPhoneBindLark && Display.phone ? .left : .center
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = callInType == .ipPhoneBindLark && Display.phone ? .left : .center
        return label
    }()

    lazy var audioSwitchButton = AudioSwitchButton(frame: .zero, isVoiceCall: isVoiceCall, isCallOut: false)
    var audioSwitchButtonWidth: Constraint?

    lazy var floatingButton: UIButton = {
        let button = UIButton()
        let normalColor = UIColor.ud.iconN1
        let highlightedColor = UIColor.ud.iconN3
        let image = UDIcon.getIconByKey(.leftOutlined, iconColor: normalColor)
        let highlightedImage = UDIcon.getIconByKey(.leftOutlined, iconColor: highlightedColor)
        button.setImage(image, for: .normal)
        button.setImage(highlightedImage, for: .highlighted)
        return button
    }()

    lazy var declineButton: UIButton = {
        let button = UIButton()
        button.vc.setBackgroundColor(UIColor.ud.functionDangerFillDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.functionDangerFillPressed, for: .highlighted)
        button.vc.setBackgroundColor(UIColor.ud.functionDangerFillDefault, for: .disabled)
        button.layer.masksToBounds = true
        return button
    }()

    lazy var acceptButton: UIButton = {
        let button = UIButton()
        button.vc.setBackgroundColor(UIColor.ud.functionSuccessFillDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.functionSuccessFillPressed, for: .highlighted)
        button.vc.setBackgroundColor(UIColor.ud.functionSuccessFillLoading, for: .disabled)
        button.layer.masksToBounds = true
        return button
    }()

    lazy var acceptLoadingView: LoadingView = {
        let view = LoadingView(style: .white)
        view.isHidden = true
        return view
    }()

    private lazy var buttonView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.addSubview(declineButton)
        view.addSubview(acceptButton)
        acceptButton.addSubview(acceptLoadingView)
        return view
    }()

    let declineLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_G_DeclineButton
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    let acceptLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_G_AcceptButton
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var voiceOnlyButton: UIButton = {
        let button = UIButton()
        button.vc.setBackgroundColor(UIColor.ud.N900.withAlphaComponent(0.08), for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.N900.withAlphaComponent(0.15), for: .highlighted)
        let image = UDIcon.getIconByKey(.callFilled, iconColor: .ud.functionSuccessFillDefault, size: Layout.buttonImageSize)
        let hiImage = UDIcon.getIconByKey(.callFilled, iconColor: .ud.functionSuccessFillPressed, size: Layout.buttonImageSize)
        button.setImage(image, for: .normal)
        button.setImage(hiImage, for: .highlighted)
        button.layer.ux.setSmoothCorner(radius: 20, corners: .allCorners, smoothness: .max)
        button.layer.masksToBounds = true
        return button
    }()

    lazy var voiceOnlyLoadingView: LoadingView = {
        let view = LoadingView(style: .grey)
        view.isHidden = true
        return view
    }()

    let voiceOnlyLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_MV_SwitchToVoice_CallButton
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var warningView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.O100

        view.layer.masksToBounds = true
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        let containerView = UIView()
        containerView.addSubview(warningIcon)
        containerView.addSubview(attentionLabel)
        view.addSubview(containerView)

        warningIcon.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(attentionLabel)
            maker.size.equalTo(16)
            maker.left.greaterThanOrEqualToSuperview()
        }
        attentionLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(warningIcon.snp.right).offset(8)
            maker.right.lessThanOrEqualToSuperview()
            maker.top.equalToSuperview().offset(12)
            maker.bottom.equalToSuperview().offset(-12)
        }
        containerView.snp.makeConstraints { (maker) in
            maker.left.greaterThanOrEqualToSuperview().offset(16)
            maker.right.lessThanOrEqualToSuperview().offset(-16)
            maker.centerX.top.bottom.equalToSuperview()
        }
        return view
    }()

    private lazy var attentionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0 // 文案可能需要显示多行，根据UX规范，此提示内容需要全部展示
        var title = I18n.View_G_IfAcceptCurrentCallEnds // 原有的
        if let setting = MeetingManager.shared.currentSession?.setting {
            if setting.meetingSubType == .screenShare {
                title = I18n.View_MV_IfAcceptEndScreenShare
            } else if setting.meetingType == .call {
                title = I18n.View_MV_IfAcceptCurrentCallEnds
            } else if setting.meetingType == .meet {
                title = I18n.View_MV_NewCallLeaveMeetingNow
            }
        }
        label.attributedText = NSAttributedString(string: title, config: .bodyAssist)
        return label
    }()

    private lazy var warningIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.warningColorful, size: CGSize(width: 16, height: 16))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    var isPhoneCallStyle: Bool { return callInType.isPhoneCall && Display.phone }

    private var acceptButtonImage: UIImage?
    private var voiceDisableButtonImage: UIImage?

    private let viewModel: CallInViewModel

    private var isVoiceCall: Bool { viewModel.isVoiceCall }
    private var callInType: CallInType { viewModel.callInType }
    private var isBusy: Bool { viewModel.isBusyRinging }
    private var isCallKit: Bool { viewModel.isCallKitEnabled }
    private var isFromFloating: Bool { viewModel.hasShownFloating }

    init(viewModel: CallInViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupSubviews()
        doSubscribe()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func doSubscribe() {
        audioSwitchButton.widthObservable.subscribe(onNext: { [weak self] (width) in
            self?.audioSwitchButtonWidth?.update(offset: width)
        }).disposed(by: rx.disposeBag)
    }

    private func setupSubviews() {
        if !(isPhoneCallStyle) {
            addSubview(rippleView)
            addSubview(voiceOnlyButton)
            addSubview(voiceOnlyLabel)
            voiceOnlyButton.addSubview(voiceOnlyLoadingView)
        }
        addSubview(avatarImageView)
        addSubview(nameLabel)
        addSubview(descriptionLabel)
        addSubview(floatingButton)
        addSubview(declineLabel)
        addSubview(acceptLabel)
        addSubview(buttonView)
        addSubview(warningView)
        addSubview(audioSwitchButton)
        if Display.pad {
            audioSwitchButton.isHidden = true
        }

        backgroundColor = isPhoneCallStyle ? UIColor.ud.N00.withAlphaComponent(0.9) : UIColor.clear

        rippleView.isHidden = isPhoneCallStyle
        avatarImageView.isHidden = Display.phone && callInType.isPhoneCallWithoutBinding

        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textAlignment = callInType == .ipPhoneBindLark && Display.phone ? .left : .center

        if isPhoneCallStyle {
            declineButton.layer.cornerRadius = Layout.ipPhoneFullButtonSize / 2
            acceptButton.layer.cornerRadius = Layout.ipPhoneFullButtonSize / 2
        } else {
            declineButton.layer.ux.setSmoothCorner(radius: 20, corners: .allCorners, smoothness: .max)
            acceptButton.layer.ux.setSmoothCorner(radius: 20, corners: .allCorners, smoothness: .max)
        }

        let icon: UDIconType = isVoiceCall ? .callFilled : .videoFilled
        let acceptImage = UDIcon.getIconByKey(icon, iconColor: .ud.primaryOnPrimaryFill, size: Layout.buttonImageSize)
        acceptButtonImage = acceptImage
        acceptButton.setImage(acceptImage, for: .normal)
        acceptButton.setImage(acceptImage, for: .highlighted)
        acceptButton.setImage(acceptImage, for: .disabled)

        let declineImage = UDIcon.getIconByKey(.callEndFilled, iconColor: .ud.primaryOnPrimaryFill, size: Layout.buttonImageSize)
        declineButton.setImage(declineImage, for: .normal)
        declineButton.setImage(declineImage, for: .highlighted)
        declineButton.setImage(declineImage, for: .disabled)

        let voiceDisableImage = UDIcon.getIconByKey(.callFilled, iconColor: .ud.iconDisabled, size: Layout.buttonImageSize)
        voiceDisableButtonImage = voiceDisableImage
        voiceOnlyButton.setImage(voiceDisableImage, for: .disabled)

        layoutViewsFullScreen()
    }

    private func layoutViewsFullScreen() {
        if isPhoneCallStyle {
            setupIpPhoneFullView()
        } else {
            setupGeneralFullView()
        }
    }

    private func setupGeneralFullView() {
        floatingButton.snp.remakeConstraints { (make) in
            make.left.equalToSuperview().offset(Layout.floatingButtonDistanceToEdge)
            make.top.equalTo(safeAreaLayoutGuide).offset(Layout.floatingButtonDistanceToTopEdge)
            make.height.width.equalTo(Layout.floatingButtonSideLength)
        }
        rippleView.snp.remakeConstraints { make in
            make.center.equalTo(self.avatarImageView.snp.center)
            make.width.equalTo(self.avatarImageView.snp.width).offset(Layout.rippleSpreadDiff)
            make.height.equalTo(self.avatarImageView.snp.height).offset(Layout.rippleSpreadDiff)
        }
        avatarImageView.snp.remakeConstraints { (make) in
            make.top.equalTo(safeAreaLayoutGuide).offset(160)
            make.centerX.equalToSuperview()
            make.size.equalTo(Layout.avatarSideLength)
        }
        nameLabel.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(Layout.bannerCommonLongMargin)
            make.top.equalTo(avatarImageView.snp.bottom).offset(32)
            make.height.equalTo(Layout.nameLabelHeight)
        }
        descriptionLabel.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(Layout.bannerCommonLongMargin)
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.height.equalTo(Layout.descriptionLabelHeight)
        }
        audioSwitchButton.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.height.equalTo(36)
            maker.top.equalTo(descriptionLabel.snp.bottom).offset(24)
            audioSwitchButtonWidth = maker.width.equalTo(109).constraint
        }
        voiceOnlyButton.snp.remakeConstraints { (make) in
            make.centerX.equalTo(acceptButton)
            make.size.equalTo(Layout.buttonSideLength)
        }
        voiceOnlyLoadingView.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(34)
        }
        acceptButton.snp.remakeConstraints { (make) in
            make.size.equalTo(Layout.buttonSideLength)
        }
        acceptLoadingView.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(34)
        }
        declineButton.snp.remakeConstraints { (make) in
            make.size.equalTo(Layout.buttonSideLength)
            make.right.equalTo(acceptButton.snp.left).offset(-135)
        }
        buttonView.snp.remakeConstraints { (make) in
            make.top.bottom.right.equalTo(acceptButton)
            make.left.equalTo(declineButton)
            make.centerX.equalToSuperview()
        }

        declineLabel.snp.remakeConstraints { (make) in
            make.centerX.equalTo(declineButton)
            make.top.equalTo(declineButton.snp.bottom).offset(Layout.buttonAndLabelDistance)
            make.height.equalTo(Layout.commonLabelHeight)
            make.bottom.equalTo(warningView.snp.top).offset(-Layout.bottomEdgeDistance)
        }
        acceptLabel.snp.remakeConstraints { (make) in
            make.centerX.equalTo(acceptButton)
            make.top.equalTo(acceptButton.snp.bottom).offset(Layout.buttonAndLabelDistance)
            make.height.equalTo(Layout.commonLabelHeight)
            make.bottom.equalTo(declineLabel)
        }
        voiceOnlyLabel.snp.remakeConstraints { (make) in
            make.centerX.equalTo(voiceOnlyButton)
            make.top.equalTo(voiceOnlyButton.snp.bottom).offset(Layout.buttonAndLabelDistance)
            make.height.equalTo(Layout.commonLabelHeight)
            make.bottom.equalTo(acceptButton.snp.top).offset(-28)
        }

        layoutWarningView()
    }

    private func setupIpPhoneFullView() {
        floatingButton.snp.remakeConstraints { (make) in
            make.left.equalToSuperview().offset(Layout.floatingButtonDistanceToEdge)
            make.top.equalTo(safeAreaLayoutGuide).offset(Layout.floatingButtonDistanceToTopEdge)
            make.height.width.equalTo(Layout.floatingButtonSideLength)
        }
        if callInType == .ipPhoneBindLark {
            avatarImageView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(48)
                make.top.equalTo(safeAreaLayoutGuide).offset(75)
                make.size.equalTo(61.0)
            }
            nameLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(avatarImageView)
                make.left.equalTo(avatarImageView.snp.right).offset(10)
                make.right.equalToSuperview().inset(48)
                make.height.equalTo(34)
            }
            descriptionLabel.snp.remakeConstraints { (make) in
                make.left.right.equalTo(nameLabel)
                make.top.equalTo(nameLabel.snp.bottom).offset(Layout.bannerCommonShortMargin)
                make.height.equalTo(20)
            }
        } else {
            nameLabel.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.left.right.equalToSuperview().inset(Layout.bannerCommonLongMargin)
                make.top.equalTo(safeAreaLayoutGuide).offset(Display.iPhoneMaxSeries ? 76 : 56)
                make.height.equalTo(44)
            }
            descriptionLabel.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.left.right.equalToSuperview().inset(Layout.bannerCommonLongMargin)
                make.top.equalTo(nameLabel.snp.bottom).offset(3)
                make.height.equalTo(Layout.descriptionLabelHeight)
            }
        }

        acceptButton.snp.remakeConstraints { (make) in
            make.size.equalTo(Layout.ipPhoneFullButtonSize)
        }
        acceptLoadingView.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(34)
        }
        declineButton.snp.remakeConstraints { (make) in
            make.size.equalTo(Layout.ipPhoneFullButtonSize)
            make.right.equalTo(acceptButton.snp.left).offset(Display.iPhoneMaxSeries ? -138 : -127)
        }
        buttonView.snp.remakeConstraints { (make) in
            make.top.bottom.right.equalTo(acceptButton)
            make.left.equalTo(declineButton)
            make.centerX.equalToSuperview()
        }
        declineLabel.snp.remakeConstraints { (make) in
            make.centerX.equalTo(declineButton)
            make.top.equalTo(declineButton.snp.bottom).offset(Layout.buttonAndLabelDistance)
            make.height.equalTo(Layout.commonLabelHeight)
            make.bottom.equalTo(warningView.snp.top).offset(-Layout.bottomEdgeDistance)
        }
        acceptLabel.snp.remakeConstraints { (make) in
            make.centerX.equalTo(acceptButton)
            make.top.equalTo(acceptButton.snp.bottom).offset(Layout.buttonAndLabelDistance)
            make.height.equalTo(Layout.commonLabelHeight)
            make.bottom.equalTo(declineLabel)
        }

        layoutWarningView()
    }

    func layoutWarningView() {
        if isBusy {
            warningView.snp.remakeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.bottom.equalTo(safeAreaLayoutGuide)
                make.height.greaterThanOrEqualTo(44)
            }
        } else {
            warningView.snp.remakeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.bottom.equalTo(safeAreaLayoutGuide)
                make.height.equalTo(0)
            }
        }
    }

    func updateAcceptEnabled(enabled: Bool, isClickVoiceOnly: Bool) {
        acceptButton.isEnabled = enabled
        voiceOnlyButton.isEnabled = enabled
        voiceOnlyLoadingView.isHidden = enabled || !isClickVoiceOnly
        acceptLoadingView.isHidden = enabled || isClickVoiceOnly
        acceptLabel.textColor = enabled ? UIColor.ud.textTitle : UIColor.ud.textDisabled
        voiceOnlyLabel.textColor = enabled ? UIColor.ud.textTitle : UIColor.ud.textDisabled
        let voiceOnlyImage = (!enabled && isClickVoiceOnly)
        if !enabled {
            if isClickVoiceOnly {
                voiceOnlyLoadingView.play()
                voiceOnlyButton.setImage(UIImage(), for: .disabled)
                acceptLoadingView.stop()
                acceptButton.setImage(acceptButtonImage, for: .disabled)
            } else {
                acceptLoadingView.play()
                acceptButton.setImage(UIImage(), for: .disabled)
                voiceOnlyLoadingView.stop()
                voiceOnlyButton.setImage(voiceDisableButtonImage, for: .disabled)
            }
        } else {
            acceptLoadingView.stop()
            voiceOnlyLoadingView.stop()
            acceptButton.setImage(acceptButtonImage, for: .disabled)
            voiceOnlyButton.setImage(voiceDisableButtonImage, for: .disabled)
        }

    }
}
