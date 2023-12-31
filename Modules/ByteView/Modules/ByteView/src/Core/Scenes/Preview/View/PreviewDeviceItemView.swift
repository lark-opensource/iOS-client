//
//  MediaItemView.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/9/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import UniverseDesignIcon
import LarkMedia
import ByteViewSetting
import ByteViewUI

class PreviewDeviceItemView: UIView {

    var isHorizontalStyle: Bool = false {
        didSet {
            guard isHorizontalStyle != oldValue else { return }
            actionButton.edgeInsetStyle = isHorizontalStyle ? .left : .top
            let space: CGFloat = isHorizontalStyle ? 8 : 3
            let inset: CGFloat = isHorizontalStyle ? 16 : 8
            let fontSize: CGFloat = isHorizontalStyle ? 17 : 12
            let expansionSpace: CGFloat = isHorizontalStyle ? 8 : 0
            actionButton.space = space
            actionButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
            actionButton.contentEdgeInsets = .init(top: 0, left: inset, bottom: 0, right: inset + expansionSpace) // right多加的expansionSpace是为了button在自动撑开时多撑开expansionSpace以显示下title与image之间的间距
            actionButton.setTitleColor(titleColor, for: .normal)
            updateStyle()
        }
    }

    fileprivate var titleColor: UIColor { isHorizontalStyle ? .ud.textTitle : .ud.textCaption }

    fileprivate lazy var actionButton: VisualButton = {
        let btn = VisualButton()
        btn.clipsToBounds = true
        btn.layer.cornerRadius = 8
        btn.edgeInsetStyle = .top
        btn.space = 3 // 设计稿为2，偏差为label内文字偏移
        btn.isNeedExtend = true
        btn.vc.setBackgroundColor(UIColor.ud.N900.withAlphaComponent(0.05), for: .normal)
        btn.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgNeutralPressed.withAlphaComponent(0.2), for: .highlighted)
        btn.vc.setBackgroundColor(UIColor.ud.N900.withAlphaComponent(0.05), for: .disabled)
        btn.addTarget(self, action: #selector(handleClick), for: .touchUpInside)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        btn.titleLabel?.textAlignment = .center
        btn.titleLabel?.lineBreakMode = .byTruncatingTail
        btn.setTitleColor(titleColor, for: .normal)
        btn.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        btn.contentEdgeInsets = .init(top: 0, left: 8, bottom: 0, right: 8)
        return btn
    }()

    fileprivate var iconSize: CGSize { CGSize(width: PreviewDeviceLayout.iconSize, height: PreviewDeviceLayout.iconSize) }
    fileprivate let iconColor: UIColor = PreviewDeviceLayout.iconColor

    fileprivate var onImage: UIImage? { UDIcon.getIconByKey(icon(isOn: true), iconColor: iconColor, size: iconSize) }
    fileprivate var offImage: UIImage? { UDIcon.getIconByKey(icon(isOn: false), iconColor: UIColor.ud.colorfulRed, size: iconSize) }
    fileprivate var disabledImage: UIImage? { UDIcon.getIconByKey(icon(isOn: false), iconColor: UIColor.ud.iconDisabled.withAlphaComponent(0.8), size: iconSize) }
    fileprivate var noConnectImage: UIImage? { UDIcon.getIconByKey(.disconnectAudioFilled, iconColor: iconColor, size: iconSize) }
    fileprivate var disabledNoConnectImage: UIImage? { UDIcon.getIconByKey(.disconnectAudioFilled, iconColor: UIColor.ud.iconDisabled, size: iconSize) }
    fileprivate var roomImage: UIImage? = {
        let size = CGSize(width: PreviewDeviceLayout.iconSize, height: PreviewDeviceLayout.iconSize)
        return UDIcon.getIconByKey(.videoSystemFilled, iconColor: PreviewDeviceLayout.iconColor, size: size)
    }()
    fileprivate var disabledRoomImage: UIImage? = {
        let size = CGSize(width: PreviewDeviceLayout.iconSize, height: PreviewDeviceLayout.iconSize)
        return UDIcon.getIconByKey(.videoSystemFilled, iconColor: .ud.iconDisabled, size: size)
    }()

    private var buttonDisabledImage: UIImage? { UDIcon.getIconByKey(icon(isOn: false), iconColor: UIColor.ud.iconDisabled, size: iconSize) }
    fileprivate let unavailableIcon = UIImageView(image: CommonResources.iconDeviceDisabled)

    var clickHandler: ((UIView) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(actionButton)
        addSubview(unavailableIcon)
        actionButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        updateStyle()
        actionButton.addInteraction(type: .highlight)
    }

    var isOn = false {
        didSet {
            if isOn != oldValue {
                updateStyle()
            }
        }
    }

    var isAuthorized = false {
        didSet {
            if isAuthorized != oldValue {
                updateStyle()
            }
        }
    }


    var isButtonDisabled: Bool = false {
        didSet {
            if isButtonDisabled != oldValue {
                updateStyle()
            }
        }
    }

    func updateStyle() {
        actionButton.setTitle(title, for: .normal)
        if isButtonDisabled {
            actionButton.setImage(buttonDisabledImage, for: .disabled)
            actionButton.isEnabled = false
            unavailableIcon.isHidden = true
        } else if !isAuthorized {
            actionButton.isEnabled = true
            unavailableIcon.isHidden = false
            actionButton.setImage(disabledImage, for: .normal)
            actionButton.setImage(disabledImage, for: .highlighted)
        } else {
            actionButton.isEnabled = true
            unavailableIcon.isHidden = true
            if actionButton.isEnabled {
                actionButton.setImage(isOn ? onImage : offImage, for: .normal)
                actionButton.setImage(isOn ? onImage : offImage, for: .highlighted)
            } else {
                actionButton.setImage(offImage, for: .normal)
            }
        }

        if let imageView = actionButton.imageView {
            unavailableIcon.snp.remakeConstraints { make in
                make.right.equalTo(imageView).offset(Display.pad ? 5.5 : 6.5)
                make.bottom.equalTo(imageView).offset(Display.pad ? 2 : 2.5)
                make.size.equalTo(Display.pad ? 14 : 16)
            }
        }
    }

    // MARK: - Protected
    fileprivate var title: String { "" }

    fileprivate func icon(isOn: Bool) -> UDIconType {
        methodNotImplemented()
    }

    // MARK: - Private

    @objc
    private func handleClick() {
        clickHandler?(self)
    }
}

class PreviewMicrophoneView: PreviewDeviceItemView, MeetingSettingListener {
    var switchAudioClick: (() -> Void)?

    var isArrowDown: Bool = false {
        didSet {
            guard let imageView = switchAudioButton.imageView, !switchAudioButton.isHidden else { return }
            UIView.animate(withDuration: 0.1) {
                imageView.transform = CGAffineTransform(rotationAngle: self.isArrowDown ? 0 : -.pi)
            }
        }
    }

    var isHighlighted: Bool = false {
        didSet {
            if switchAudioButton.isHidden {
                actionButton.isHighlighted = isHighlighted
            } else {
                if actionButton.isHighlighted {
                    actionButton.isHighlighted = false
                }
                switchAudioButton.isHighlighted = isHighlighted
            }
        }
    }

    lazy var switchAudioButton: VisualButton = {
        let btn = VisualButton()
        let size: CGSize = CGSize(width: 16, height: 16)
        btn.vc.setBackgroundColor(UIColor.ud.N900.withAlphaComponent(0.05), for: .normal)
        btn.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgNeutralPressed.withAlphaComponent(0.2), for: .highlighted)
        btn.vc.setBackgroundColor(UIColor.ud.N900.withAlphaComponent(0.05), for: .disabled)
        let image = UDIcon.getIconByKey(.downSmallCcmOutlined, iconColor: .ud.iconN2, size: size)
        btn.setImage(image, for: .normal)
        btn.setImage(image, for: .highlighted)
        btn.setImage(UDIcon.getIconByKey(.downSmallCcmOutlined, iconColor: .ud.iconDisabled, size: size), for: .disabled)
        btn.layer.cornerRadius = 8
        btn.layer.masksToBounds = true
        btn.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        if let imageView = btn.imageView {
            imageView.transform = CGAffineTransform(rotationAngle: -.pi)
        }
        btn.addInteraction(type: .highlight)
        btn.addTarget(self, action: #selector(clickSwitchAudio), for: .touchUpInside)
        return btn
    }()

    private lazy var lineView: UIView = {
        let line = UIView()
        line.backgroundColor = .ud.lineDividerDefault.withAlphaComponent(0.15)
        return line
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(switchAudioButton)
        addSubview(lineView)
        actionButton.setImage(UDIcon.getIconByKey(.micOffFilled, iconColor: UIColor.ud.iconDisabled), for: .disabled)
        actionButton.delegate = self
        switchAudioButton.delegate = self

        updateLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var title: String { I18n.View_G_MicAbbreviated }

    var btnTitle: String { actionButton.titleLabel?.text ?? title }

    override func icon(isOn: Bool) -> UDIconType {
        isOn ? .micFilled : .micOffFilled
    }

    var shouldShowSwitchAudio: Bool = true {
        didSet {
            updateLayout()
        }
    }

    var audioType: PreviewAudioType = .system {
        didSet {
            if audioType != oldValue {
                updateStyle()
                updateLayout()
            }
        }
    }

    var isEnabled: Bool = true {
        didSet {
            guard isEnabled != oldValue else { return }
            actionButton.isEnabled = isEnabled
        }
    }


    func bindMeetingSetting(_ setting: MeetingSettingManager) {
        handlePadMicSpeakerDisabled(setting.isMicSpeakerDisabled)
        setting.addListener(self, for: .isMicSpeakerDisabled)
    }

    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .isMicSpeakerDisabled {
            handlePadMicSpeakerDisabled(isOn)
        }
    }

    func handlePadMicSpeakerDisabled(_ isDisabled: Bool) {
        self.isButtonDisabled = isDisabled
    }

    override func updateStyle() {
        switch audioType {
        case .noConnect:
            actionButton.isEnabled = isEnabled
            unavailableIcon.isHidden = true
            actionButton.setTitle(I18n.View_G_NoAudio_Icon, for: .normal)
            actionButton.setImage(noConnectImage, for: .normal)
            actionButton.setImage(noConnectImage, for: .highlighted)
            actionButton.setImage(disabledNoConnectImage, for: .disabled)
        case .room:
            actionButton.isEnabled = isEnabled
            unavailableIcon.isHidden = true
            actionButton.setTitle(I18n.View_G_RoomAudioIcon, for: .normal)
            actionButton.setImage(roomImage, for: .normal)
            actionButton.setImage(roomImage, for: .highlighted)
            actionButton.setImage(disabledRoomImage, for: .disabled)
        case .pstn:
            super.updateStyle()
            actionButton.setTitle(I18n.View_G_Phone, for: .normal)
        default:
            super.updateStyle()
        }
        actionButton.setTitleColor((audioType == .system || audioType == .pstn) && !isAuthorized ? .ud.textDisabled : titleColor, for: .normal)
    }

    private func updateLayout() {
        let isShowSwitchAudio = shouldShowSwitchAudio && (audioType == .system || audioType == .pstn)
        switchAudioButton.isHidden = !isShowSwitchAudio
        lineView.isHidden = !isShowSwitchAudio
        if isShowSwitchAudio {
            actionButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            actionButton.snp.remakeConstraints { make in
                make.left.top.bottom.equalToSuperview()
                make.right.equalTo(switchAudioButton.snp.left)
            }
            switchAudioButton.snp.remakeConstraints { make in
                make.top.bottom.right.equalToSuperview()
                make.width.equalTo(36)
            }
            lineView.snp.remakeConstraints { make in
                make.left.centerY.equalTo(switchAudioButton)
                make.width.equalTo(1)
                make.height.equalTo(24)
            }
        } else {
            actionButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            actionButton.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    private func resetHighlighted() {
        if actionButton.isHighlighted {
            actionButton.isHighlighted = false
        }
        if switchAudioButton.isHighlighted {
            switchAudioButton.isHighlighted = false
        }
    }

    @objc
    func clickSwitchAudio() {
        switchAudioClick?()
    }
}

extension PreviewMicrophoneView: VisualButtonEventDelegate {
    func didHighlighted() {
        if !switchAudioButton.isHidden {
            lineView.isHidden = true
        }
    }

    func didUnhighlighted() {
        if !switchAudioButton.isHidden {
            lineView.isHidden = false
        }
    }
}

class PreviewCameraView: PreviewDeviceItemView {

    override var title: String { I18n.View_VM_Camera }

    override var iconSize: CGSize { CGSize(width: PreviewDeviceLayout.iconSize, height: PreviewDeviceLayout.iconSize) }

    override func icon(isOn: Bool) -> UDIconType {
        isOn ? .videoFilled : .videoOffFilled
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateStyle() {
        super.updateStyle()
        actionButton.setTitleColor(isAuthorized ? titleColor : .ud.textDisabled, for: .normal)
    }
}

class PreviewScanRoomView: PreviewDeviceItemView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        unavailableIcon.isHidden = true
        actionButton.isEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateStyle() {
        actionButton.setTitle(title, for: .normal)
        let roomImage = roomIcon(iconColor)
        actionButton.setImage(roomImage, for: .normal)
        actionButton.setImage(roomImage, for: .highlighted)
    }

    override var title: String { I18n.View_G_RoomAudioIcon }
    private func roomIcon(_ color: UIColor) -> UIImage { UDIcon.getIconByKey(.videoSystemFilled, iconColor: color, size: iconSize) }
}

final class PreviewSpeakerView: PreviewDeviceItemView, AudioOutputListener {
    private let helper: PreviewSpeakerIconHelper

    var isHighlighted: Bool = false {
        didSet {
            actionButton.isHighlighted = isHighlighted
        }
    }

    override init(frame: CGRect) {
        self.helper = PreviewSpeakerIconHelper()
        super.init(frame: frame)
        unavailableIcon.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindAudioOutput(_ output: AudioOutputManager) {
        updateViews(output)
        output.addListener(self)
    }

    func didChangeAudioOutput(_ output: AudioOutputManager, reason: AudioOutputChangeReason) {
        updateViews(output)
    }

    private func updateViews(_ output: AudioOutputManager) {
        let text = helper.buttonTitle(audioOutput: output)
        actionButton.setTitle(text, for: .normal)
        actionButton.isEnabled = output.isDisabled
        helper.setImage(for: actionButton, audioOutput: output)
    }


    override func updateStyle() { }
}


private struct PreviewDeviceLayout {
    static var iconSize: CGFloat { Display.pad && VCScene.isRegular && VCScene.isLandscape ? 20 : 22 }
    static let iconColor: UIColor = .ud.iconN1.withAlphaComponent(0.8)
}

final class PreviewSpeakerIconHelper {

    struct Image {
        let normal: UIImage
        let disabled: UIImage
    }

    private lazy var imageSize = CGSize(width: PreviewDeviceLayout.iconSize, height: PreviewDeviceLayout.iconSize)
    private lazy var mutedNormal = UDIcon.getIconByKey(.speakerMuteFilled, iconColor: normalColor, size: imageSize)
    private lazy var mutedDisabled = UDIcon.getIconByKey(.speakerMuteFilled, iconColor: UIColor.ud.iconDisabled, size: imageSize)

    private let normalColor: UIColor
    init(normalColor: UIColor = PreviewDeviceLayout.iconColor) {
        self.normalColor = normalColor
    }

    func setImage(for button: UIButton, audioOutput: AudioOutputManager) {
        button.isEnabled = !audioOutput.isPadMicSpeakerDisabled
        let images = image(for: audioOutput)
        button.setImage(images.normal, for: .normal)
        button.setImage(images.normal, for: .highlighted)
        button.setImage(images.disabled, for: .disabled)
    }

    func image(for audioOutput: AudioOutputManager) -> Image {
        let normalImage: UIImage
        let disableImage: UIImage
        if audioOutput.isDisabled {
            normalImage = self.mutedDisabled
            disableImage = self.mutedDisabled
        } else if audioOutput.isMuted {
            normalImage = self.mutedNormal
            disableImage = self.mutedDisabled
        } else {
            let output = audioOutput.currentOutput
            normalImage = output.image(dimension: imageSize.width, color: normalColor)
            disableImage = output.image(dimension: imageSize.width, color: normalColor)
        }
        return .init(normal: normalImage, disabled: disableImage)
    }

    func buttonTitle(audioOutput: AudioOutputManager) -> String {
        if audioOutput.isDisabled || audioOutput.isMuted {
            return I18n.View_MV_AlreadyMutedButton
        } else {
            return audioOutput.currentOutput.i18nText
        }
    }
}
