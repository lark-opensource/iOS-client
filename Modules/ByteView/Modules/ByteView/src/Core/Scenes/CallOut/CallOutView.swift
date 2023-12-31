//
//  CallOutView.swift
//  ByteView
//
//  Created by liuning.cn on 2020/9/24.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import SnapKit
import AVKit
import Lottie
import RxCocoa
import RxSwift
import LarkMedia
import ByteViewCommon
import UniverseDesignIcon
import ByteViewUI

enum ColorMode {
    case dark
    case light

    var isDark: Bool {
        return self == .dark
    }

    var speakerColor: UIColor {
        self == .dark ? UIColor.ud.N700 : UIColor.ud.N00.alwaysLight
    }
}

class CallOutView: UIView {
    var cancelButton: UIButton {
        return overlayView.cancelButton
    }

    var floatingButton: UIButton {
        return overlayView.floatingButton
    }

    var audioSwitchButton: AudioSwitchButton {
        return overlayView.audioSwitchButton
    }

    lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.vcTokenMeetingBgVideoCall
        return view
    }()

    private lazy var coverVideoView: UIView = {
        let view = GradientView()
        view.colors = [UIColor.ud.N00.withAlphaComponent(0.24), UIColor.clear]
        view.startPoint = CGPoint.zero
        view.endPoint = CGPoint(x: 0, y: 1)
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

    private lazy var overlayView = CallOutOverlayView(frame: .zero, isVoiceCall: isVoiceCall)

    var mode: ColorMode = .dark {
        didSet {
            overlayView.mode = mode
        }
    }
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

    func updateCamera(isOn: Bool) {
        maskImageView.isHidden = isOn
        visualEffectView.isHidden = isOn
        coverVideoView.isHidden = !isOn
    }

    func updateName(name: String) {
        overlayView.nameLabel.vc.justReplaceText(to: name)
    }

    func updateDescription(description: String) {
        overlayView.descriptionLabelText = description
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
        addSubview(coverVideoView)
        addSubview(maskImageView)
        addSubview(visualEffectView)
        addSubview(overlayView)
    }

    private func autoLayoutSubviews() {
        contentView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        coverVideoView.snp.makeConstraints { (maker) in
            maker.left.top.right.equalToSuperview()
            maker.height.equalTo(245)
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

private class CallOutOverlayView: UIView {

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


    var descriptionLabelText: String = "" {
        didSet {
            descriptionLabel.text = descriptionLabelText
            descriptionLabel.snp.updateConstraints {
                $0.height.equalTo(20 * descriptionLabelText.split(separator: "\n").count)
            }
        }
    }

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.font = .systemFont(ofSize: 14)
        label.text = nil
        label.numberOfLines = 2
        return label
    }()

    lazy var floatingButton: UIButton = {
        let button = UIButton(type: .custom)
        let normalColor = UIColor.ud.iconN1
        let highlightedColor = UIColor.ud.iconN3
        let image = UDIcon.getIconByKey(.leftOutlined, iconColor: normalColor)
        let highlightedImage = UDIcon.getIconByKey(.leftOutlined, iconColor: highlightedColor)
        button.setImage(image, for: .normal)
        button.setImage(highlightedImage, for: .highlighted)
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
        button.accessibilityIdentifier = "CallOutView.cancelButton"
        button.layer.masksToBounds = true
        button.layer.ux.setSmoothCorner(radius: 20, corners: .allCorners, smoothness: .max)
        button.vc.setBackgroundColor(UIColor.ud.functionDangerContentDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.functionDangerContentPressed, for: .highlighted)
        let image = UDIcon.getIconByKey(.callEndFilled, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 34, height: 34))
        button.setImage(image, for: .normal)
        button.setImage(image, for: .highlighted)
        return button
    }()

    lazy var audioSwitchButton = AudioSwitchButton(frame: .zero, isVoiceCall: isVoiceCall)
    var audioSwitchButtonWidth: Constraint?

    lazy var animationView: LOTAnimationView = {
        let view = LOTAnimationView(name: "ripple", bundle: .localResources)
        view.loopAnimation = true
        return view
    }()

    var mode: ColorMode = .dark {
        didSet {
            modifyColorMode()
        }
    }

    private var isVoiceCall: Bool
    init(frame: CGRect, isVoiceCall: Bool) {
        self.isVoiceCall = isVoiceCall
        super.init(frame: frame)

        setupSubviews()
        autoLayoutSubviews()
        modifyColorMode()
        doSubscribe()

        if !isVoiceCall {
            setShadowForSwitchButton()
        }
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
        addSubview(animationView)
        addSubview(avatarImageView)
        addSubview(nameLabel)
        addSubview(descriptionLabel)
        addSubview(floatingButton)
        addSubview(cancelView)
        addSubview(audioSwitchButton)
    }

    // disable-lint: duplicated code
    private func autoLayoutSubviews() {
        avatarImageView.snp.makeConstraints { (maker) in
            maker.size.equalTo(100)
            maker.centerX.equalToSuperview()
            maker.top.equalTo(safeAreaLayoutGuide).offset(160)
        }
        nameLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalTo(avatarImageView)
            maker.top.equalTo(avatarImageView.snp.bottom).offset(32)
            maker.left.equalToSuperview().offset(16)
            maker.right.equalToSuperview().offset(-16)
        }
        descriptionLabel.snp.makeConstraints { (maker) in
            maker.height.equalTo(20)
            maker.centerX.equalTo(nameLabel)
            maker.top.equalTo(nameLabel.snp.bottom).offset(8)
            maker.left.right.equalTo(nameLabel)
        }
        floatingButton.snp.makeConstraints { (maker) in
            maker.left.equalTo(16)
            maker.top.equalTo(safeAreaLayoutGuide).offset(10)
            maker.size.equalTo(24)
        }
        audioSwitchButton.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.height.equalTo(36)
            maker.top.equalTo(descriptionLabel.snp.bottom).offset(24)
            audioSwitchButtonWidth = maker.width.equalTo(109).constraint
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
    // enable-lint: duplicated code

    private func createButtonLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 12)
        label.lineBreakMode = .byTruncatingMiddle
        label.textAlignment = .center
        return label
    }

    private func setShadowForView(_ view: UIView) {
        view.layer.ud.setShadowColor(UIColor.ud.staticBlack.withAlphaComponent(0.5))
        view.layer.shadowOpacity = 1.0
        view.layer.shadowRadius = 0.5
        view.layer.shadowOffset = CGSize(width: 0, height: 0.5)
    }

    private func setShadowForSwitchButton() {
        setShadowForView(audioSwitchButton.lbl)
        if let imageView = audioSwitchButton.audioSwitchButton.imageView {
            setShadowForView(imageView)
        }
        setShadowForView(audioSwitchButton.expandIconView)
        setShadowForView(audioSwitchButton.audioSwitchButton)
    }

    private func modifyColorMode() {
        if Display.pad {
            audioSwitchButton.mode = mode
        }
        var ripple: String
        if mode == .dark {
            nameLabel.textColor = UIColor.ud.textTitle
            descriptionLabel.textColor = UIColor.ud.textCaption
            cancelViewLbl.textColor = UIColor.ud.textTitle
            ripple = "ripple"
            if #available(iOS 12.0, *), traitCollection.userInterfaceStyle == .dark, !isVoiceCall {
                ripple = "rippleWhite"
            }
        } else {
            nameLabel.textColor = UIColor.ud.primaryOnPrimaryFill
            if Display.phone {
                descriptionLabel.textColor = UIColor.ud.primaryOnPrimaryFill
            } else {
                descriptionLabel.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.9)
            }
            cancelViewLbl.textColor = UIColor.ud.primaryOnPrimaryFill
            ripple = "rippleWhite"
        }
        if !isVoiceCall {
            setShadowForView(nameLabel)
            setShadowForView(descriptionLabel)
            setShadowForView(cancelViewLbl)
            setShadowForView(floatingButton)

            let image = UDIcon.getIconByKey(.leftOutlined, iconColor: .ud.primaryOnPrimaryFill)
            floatingButton.setImage(image, for: .normal)
            floatingButton.setImage(image, for: .highlighted)
        }

        animationView.setAnimation(named: ripple, bundle: .localResources)
        animationView.loopAnimation = true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if let previousTraitCollection = previousTraitCollection,
               previousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection),
               mode == .dark {
                var ripple: String = ""
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    if isVoiceCall {
                        ripple = "ripple"
                    } else {
                        ripple = "rippleWhite"
                    }
                case .light:
                    ripple = "ripple"
                default:
                    ()
                }
                animationView.setAnimation(named: ripple, bundle: .localResources)
                animationView.loopAnimation = true
                animationView.play()
            }
        }
    }

    var switchButtonShadowView: UIView?
}

class AudioSwitchButton: UIButton {
    let disposeBag = DisposeBag()

    private var iconColor: UIColor { return (isCallOut && !isVoiceCall) ? UIColor.ud.primaryOnPrimaryFill : UIColor.ud.iconN2 }

    lazy var audioSwitchButton: VisualButton = {
        let button = VisualButton(type: .custom)
        button.space = 0
        button.edgeInsetStyle = .top
        button.isEnabled = !Util.isiOSAppOnMacSystem
        button.isUserInteractionEnabled = false
        return button
    }()

    lazy var lbl: UILabel = createLbl()

    lazy var expandIconView = UIImageView()

    private let widthRelay: BehaviorRelay<CGFloat> = BehaviorRelay(value: 109)
    var widthObservable: Observable<CGFloat> {
        return widthRelay.asObservable()
    }

    var mode: ColorMode = .dark {
        didSet {
            modifyColorMode()
        }
    }

    var route: AudioOutput = .unknown
    private var isVoiceCall: Bool
    private let isCallOut: Bool
    init(frame: CGRect, isVoiceCall: Bool, isCallOut: Bool = true) {
        self.isVoiceCall = isVoiceCall
        self.isCallOut = isCallOut
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                if isVoiceCall {
                    self.backgroundColor = mode == .dark ? UIColor.ud.N900.withAlphaComponent(0.1) : UIColor.ud.N00.withAlphaComponent(0.2)
                } else {
                    self.backgroundColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.2)
                }
            } else {
                self.backgroundColor = UIColor.clear
            }
        }
    }
}

extension AudioSwitchButton: AudioOutputListener {

    var dynamicRoute: AudioOutput {
        self.route
    }

    private func modifyColorMode() {
        if Display.pad {
            if mode == .dark {
                lbl.textColor = UIColor.ud.textTitle
                layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
            } else {
                lbl.textColor = UIColor.ud.primaryOnPrimaryFill
                layer.ud.setBorderColor(UIColor.ud.primaryOnPrimaryFill)
            }
            audioSwitchButton.setImage(dynamicRoute.image(isSolid: false, dimension: 24, color: self.mode.speakerColor), for: .normal)
        } else {
            audioSwitchButton.setImage(dynamicRoute.image(isSolid: true, dimension: 24, color: isVoiceCall ? UIColor.ud.iconN1 : UIColor.ud.primaryOnPrimaryFill), for: .normal)
        }
    }

    func setupView() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 6
        if Display.pad {
            self.layer.borderWidth = 1

            self.addSubview(audioSwitchButton)
            self.addSubview(lbl)
            self.audioSwitchButton.snp.makeConstraints { make in
                make.left.equalTo(16)
                make.centerY.equalToSuperview()
                make.size.equalTo(16)
            }
            self.lbl.snp.makeConstraints { make in
                make.right.equalTo(-16)
                make.centerY.equalToSuperview()
                make.height.equalTo(20)
            }
        } else {
            let expandDownImg = UDIcon.getIconByKey(.expandDownFilled, iconColor: iconColor, size: CGSize(width: 10, height: 10))

            let normalColor: UIColor = (isCallOut && !isVoiceCall) ? UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.3) : UIColor.ud.N900.withAlphaComponent(0.08)
            let highlightColor: UIColor = (isCallOut && !isVoiceCall) ? .ud.primaryOnPrimaryFill.withAlphaComponent(0.4) : .ud.N900.withAlphaComponent(0.15)
            self.vc.setBackgroundColor(normalColor, for: .normal)
            self.vc.setBackgroundColor(highlightColor, for: .highlighted)
            self.lbl.textColor = (isCallOut && !isVoiceCall) ? UIColor.ud.primaryOnPrimaryFill : UIColor.ud.textTitle
            self.expandIconView.image = expandDownImg
            self.addSubview(audioSwitchButton)
            self.addSubview(lbl)
            self.addSubview(expandIconView)
            self.audioSwitchButton.snp.makeConstraints { make in
                make.left.equalTo(12)
                make.centerY.equalToSuperview()
                make.size.equalTo(16)
            }
            self.lbl.snp.makeConstraints { make in
                make.right.equalTo(-24)
                make.centerY.equalToSuperview()
                make.height.equalTo(22)
            }
            self.expandIconView.snp.makeConstraints { make in
                make.right.equalTo(-10)
                make.centerY.equalToSuperview()
                make.size.equalTo(10)
            }
        }
    }

    func bindViewModel(_ vm: CallOutViewModel) {
        guard let output = vm.session.audioDevice?.output else { return }
        changeAudioOutput(output.currentOutput, initial: true)
        output.addListener(self)
    }

    func didChangeAudioOutput(_ output: AudioOutputManager, reason: AudioOutputChangeReason) {
        changeAudioOutput(output.currentOutput, initial: false)
    }

    func changeAudioOutput(_ output: AudioOutput, initial: Bool) {
        self.route = output
        Logger.audio.info("calloutVC didChangeAudioOutput \(output)")
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let route = self.dynamicRoute
            let text = route.i18nText
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.lbl.text = text
                if Display.pad {
                    self.audioSwitchButton.setImage(route.image(isSolid: false, dimension: 24, color: self.mode.speakerColor), for: .normal)
                } else {
                    self.audioSwitchButton.setImage(route.image(isSolid: true, dimension: 24, color: self.isVoiceCall ? UIColor.ud.iconN1 : UIColor.ud.primaryOnPrimaryFill), for: .normal)
                }
                self.widthRelay.accept(self.calculateBtnWidth(with: text))
            }
        }
    }

    func updateButtonUI(_ output: AudioOutput) {
        self.audioSwitchButton.setImage(output.image(isSolid: true, dimension: 24, color: UIColor.ud.iconN1), for: .normal)
        let text = output.i18nText
        self.lbl.text = text
        self.widthRelay.accept(self.calculateBtnWidth(with: text))
    }

    func createLbl() -> UILabel {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 16)
        return lbl
    }

    private func calculateBtnWidth(with text: String) -> CGFloat {
        var result: CGFloat = 55
        result += text.vc.boundingSize(with: CGSize(width: 300, height: 20), attributes: [.font: lbl.font ?? .systemFont(ofSize: 14)]).width
        return result
    }
}
