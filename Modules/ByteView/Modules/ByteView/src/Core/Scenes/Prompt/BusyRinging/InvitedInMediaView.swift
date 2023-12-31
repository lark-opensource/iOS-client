//
//  InvitedInMediaView.swift
//  ByteView
//
//  Created by wangpeiran on 2021/11/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon
import RxSwift
import Action
import RxCocoa
import AVFoundation
import ByteViewTracker
import ByteViewSetting
import ByteViewNetwork

class InvitedInMediaView: UIView {

    fileprivate var actionButton: UIButton!

    private var onImage: UIImage? { UDIcon.getIconByKey(icon(isOn: true), iconColor: UIColor.ud.N650, size: CGSize(width: 18, height: 18)) }
    private var offImage: UIImage? { UDIcon.getIconByKey(icon(isOn: false), iconColor: UIColor.ud.colorfulRed, size: CGSize(width: 18, height: 18)) }
    private var disabledImage: UIImage? { UDIcon.getIconByKey(icon(isOn: false), iconColor: UIColor.ud.textDisabled, size: CGSize(width: 18, height: 18)) }

    private let unavailableIcon = UIImageView(image: CommonResources.iconDeviceDisabled)

    var clickHandler: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    var isOn = false {
        didSet {
            let normalImage = isOn ? onImage : offImage
            if isAuthorized {
                if isEnabled {
                    actionButton.setImage(normalImage, for: .normal)
                } else {
                    actionButton.setImage(offImage, for: .normal)
                }
                actionButton.setImage(normalImage, for: .highlighted)
            } else {
                actionButton.setImage(disabledImage, for: .normal)
                actionButton.setImage(disabledImage, for: .highlighted)
            }
            actionButton.setImage(disabledImage, for: .disabled)
        }
    }

    var isAuthorized = false {
        didSet {
            unavailableIcon.isHidden = isAuthorized || isMicSpeakerDisabled
        }
    }

    var isMicSpeakerDisabled: Bool = false

    var isEnabled = true

    // MARK: - Protected

    fileprivate func setupSubviews() {
        actionButton = EnlargeTouchButton(padding: 32)
        actionButton.setImage(onImage, for: .normal)
        actionButton.setImage(onImage, for: .highlighted)
        actionButton.setImage(offImage, for: .selected)
        actionButton.vc.setBackgroundColor(.ud.N900.withAlphaComponent(0.08), for: .normal)
        actionButton.vc.setBackgroundColor(.ud.N900.withAlphaComponent(0.15), for: .highlighted)
        actionButton.layer.masksToBounds = true
        actionButton.addTarget(self, action: #selector(handleClick), for: .touchUpInside)

        unavailableIcon.isHidden = true

        addSubview(actionButton)
        addSubview(unavailableIcon)

        actionButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        unavailableIcon.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(17)
            make.top.equalToSuperview().offset(15)
            make.size.equalTo(14)
        }
    }

    fileprivate var title: String { "" }

    fileprivate func icon(isOn: Bool) -> UDIconType {
        methodNotImplemented()
    }

    // MARK: - Private

    @objc
    private func handleClick() {
        clickHandler?()
    }
}

class InvitedInMicrophoneView: InvitedInMediaView {

    override func icon(isOn: Bool) -> UDIconType {
        isOn ? .micFilled : .micOffFilled
    }

    func bindMeetingSetting(_ setting: MeetingSettingManager) {
        self.isMicSpeakerDisabled = setting.isMicSpeakerDisabled
        self.actionButton.isEnabled = !self.isMicSpeakerDisabled
        setting.addListener(self, for: .isMicSpeakerDisabled)
    }
}

class InvitedInCameraView: InvitedInMediaView {

    override func icon(isOn: Bool) -> UDIconType {
        isOn ? .videoFilled : .videoOffFilled
    }
}


class InvitedInMediaVM {
    let disposeBag = DisposeBag()

    var isCameraOn: Bool {
        get { isCameraOnRelay.value }
        set {
            guard isCameraOn != newValue else { return }
            isCameraOnRelay.accept(newValue)
        }
    }
    var isCameraOnObservable: Observable<Bool> { isCameraOnRelay.asObservable() }
    private let isCameraOnRelay: BehaviorRelay<Bool>

    let isMicOn: BehaviorRelay<Bool>

    let userId: String
    let isMuteOnEntry: Bool

    let isWebinarAttentee: Bool

    var meetSetting: MicCameraSetting {
        MicCameraSetting(isMicrophoneEnabled: isMicOn.value, isCameraEnabled: isCameraOn)
    }

    let setting: MeetingSettingManager

    init(userId: String, setting: MeetingSettingManager, isMuteOnEntry: Bool, isWebinarAttentee: Bool) {
        self.userId = userId
        self.isMuteOnEntry = isMuteOnEntry
        self.isWebinarAttentee = isWebinarAttentee
        self.setting = setting

        let lastSetting = setting.micCameraSetting
        Logger.ring.info("busy ring: \(!Privacy.audioDenied) \(lastSetting.isMicrophoneEnabled) \(!isMuteOnEntry)")

        self.isMicOn = BehaviorRelay(value: Privacy.audioAuthorized && lastSetting.isMicrophoneEnabled && !isMuteOnEntry && !setting.isMicSpeakerDisabled)
        self.isCameraOnRelay = BehaviorRelay(value: Privacy.videoAuthorized && lastSetting.isCameraEnabled)
        setting.addListener(self, for: .isMicSpeakerDisabled)
    }

    func muteMic(type: MeetingType) {
        Privacy.requestMicrophoneAccessAlert(cancelHandler: { _ in
            VCTracker.post(name: .vc_meeting_callee_view, params: [.click: "cancel_no_auth",
                                                            "is_in_duration": true,
                                                            "call_type": self.getCallType(type: type),
                                                            .location: "mic"] )
        }, sureHandler: { _ in
            VCTracker.post(name: .vc_meeting_callee_view, params: [.click: "open_system_setting",
                                                            "is_in_duration": true,
                                                            "call_type": self.getCallType(type: type),
                                                            .location: "mic"] )
        }, completion: { [weak self] result in
            Util.runInMainThread {
                guard let self = self, case .success = result else { return }
                let micOn = self.isMicOn.value
                self.isMicOn.accept(!micOn)
            }
        })
    }

    func muteCamera(type: MeetingType) {
        Privacy.requestCameraAccessAlert(cancelHandler: { _ in
            VCTracker.post(name: .vc_meeting_callee_view, params: [.click: "cancel_no_auth",
                                                                  "is_in_duration": true,
                                                                  .location: "camera"] )
        }, sureHandler: { _ in
            VCTracker.post(name: .vc_meeting_callee_view, params: [.click: "open_system_setting",
                                                                  "is_in_duration": true,
                                                                  .location: "camera"] )
        }, completion: { [weak self] in
            guard let self = self, $0.isSuccess else { return }
            self.isCameraOn = !self.isCameraOn
        })
    }

    func getCallType(type: MeetingType) -> String {
        var callType: String = "unknown"
        switch type {
        case .call:
            callType = "call"
        case .meet:
            callType = "meeting"
        default:
            callType = "unknown"
        }
        return callType
    }
}

extension InvitedInMicrophoneView: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .isMicSpeakerDisabled {
            self.actionButton.isEnabled = !isOn
            isAuthorized = Privacy.audioAuthorized
        }
    }
}

extension InvitedInMediaVM: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .isMicSpeakerDisabled {
            handlePadMicSpeakerDisabled(isOn)
        }
    }

    func handlePadMicSpeakerDisabled(_ isDisabled: Bool) {
        if isDisabled {
            self.isMicOn.accept(false)
        }
    }
}
