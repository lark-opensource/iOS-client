//
//  RingingMeetCardView.swift
//  ByteView
//
//  Created by wangpeiran on 2022/10/2.
//

import Foundation
import ByteViewUI
import RxSwift
import Action
import RxCocoa
import AVFoundation
import RichLabel
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignShadow
import ByteViewTracker
import ByteViewMeeting
import UIKit
import ByteViewCommon

class RingingMeetCardView: UIView {
    enum Layout {
        static let buttonTextSpacing: CGFloat = 6.0
        static let buttonTextHeight: CGFloat = 16.0
        static let voiceOnlyButtonHeight: CGFloat = 22.0 + 4.0 + 18.0
        static let declineToAcceptForPad: CGFloat = 220.0
        static let declineToAcceptPortraitRatioForPhone: CGFloat = 145.0 / 351.0
        static let declineToAcceptLandscapeRatioForPhone: CGFloat = 220.0 / 511.0

        static let commonLongMargin: CGFloat = 16.0
        static let commonShortMargin: CGFloat = 8.0

        static let buttonLeftMargin: CGFloat = 12.0
        static let buttonWidth: CGFloat = 76.0
        static let buttonContentInsets: CGFloat = 16
    }

    private lazy var avatarImageView = AvatarView()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        label.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        return label
    }()

    private lazy var topicLabel: LKLabel = {
        let label = LKLabel()
        label.backgroundColor = .clear
        label.numberOfLines = 2
        label.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        return label
    }()

    private var attributedMeetingTopic: AttributedMeetingTopic? {
        didSet {
            topicLabel.attributedText = attributedMeetingTopic?.attributedText
            topicLabel.outOfRangeText = attributedMeetingTopic?.outOfRangeText
        }
    }

    private lazy var declineButton: UIButton = {
        let button = UIButton()
        button.vc.setBackgroundColor(UIColor.ud.functionDangerFillDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.functionDangerFillPressed, for: .highlighted)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 6
        button.setTitle(I18n.View_MV_Decline_CallComes, for: .normal)
        button.setTitleColor(.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: Layout.buttonContentInsets, bottom: 0, right: Layout.buttonContentInsets)
        button.accessibilityIdentifier = "InvitedInBanner.declineButton.accessibilityIdentifier"
        button.addTarget(self, action: #selector(clickDecline(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var acceptButton: UIButton = {
        let button = UIButton()
        button.accessibilityIdentifier = "InvitedInBanner.acceptButton.accessibilityIdentifier"
        button.vc.setBackgroundColor(UIColor.ud.functionSuccessFillDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.functionSuccessFillPressed, for: .highlighted)
        button.vc.setBackgroundColor(UIColor.ud.functionSuccessFillLoading, for: .disabled)
        button.setTitle(I18n.View_MV_Join_CallComes, for: .normal)
        button.setTitle("", for: .disabled)
        button.setTitleColor(.ud.primaryOnPrimaryFill, for: .normal)
        button.setTitleColor(.ud.primaryOnPrimaryFill, for: .disabled)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 6
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: Layout.buttonContentInsets, bottom: 0, right: Layout.buttonContentInsets)
        button.addTarget(self, action: #selector(clickAccept(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var loadingView: LoadingView = {
        let view = LoadingView(style: .white)
        view.isHidden = true
        return view
    }()

    private lazy var warningView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.O100

        let containerView = UIView()
        containerView.addSubview(warningIcon)
        containerView.addSubview(attentionLabel)
        view.addSubview(containerView)

        warningIcon.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(14)
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
        label.numberOfLines = 2
        return label
    }()

    private lazy var warningIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.warningColorful, size: CGSize(width: 16, height: 16))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var containerView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 12
        return view
    }()

    var invitedInMediaVM: InvitedInMediaVM?
    private let micView = InvitedInMicrophoneView()
    private let cameraView = InvitedInCameraView()

    private let disposeBag = DisposeBag()

    let viewModel: MeetInViewModel

    init(viewModel: MeetInViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        if let info = viewModel.meeting.videoChatInfo, let setting = viewModel.meeting.setting {
            let isWebinarAttendee = viewModel.meeting.myself?.meetingRole == .webinarAttendee
            self.invitedInMediaVM = InvitedInMediaVM(userId: viewModel.meeting.userId, setting: setting, isMuteOnEntry: info.settings.isMuteOnEntry, isWebinarAttentee: isWebinarAttendee)
        }
        Logger.ring.info("RingingMeetCardView init")
        initialize()
        bindViewModel()
        resetAttentionLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        Logger.ring.info("RingingMeetCardView deinit")
    }

    func bindViewModel() {
        bindAvatar()
        bindName()
        bindTopic()
        bindAcceptEnabled()
        setMicViewClickHandler()
        setCamViewClickHandler()

        invitedInMediaVM?.isMicOn.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] micOn in
                guard let self = self else { return }
                let hasPermission = Privacy.audioAuthorized
                self.micView.isAuthorized = hasPermission
                self.micView.isOn = micOn
            })
            .disposed(by: disposeBag)

        Privacy.requestCameraAccess()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] status in
                guard let self = self, let invitedInMediaVM = self.invitedInMediaVM else {
                    return
                }
                switch status {
                case .denied, .deniedOfAsk:
                    invitedInMediaVM.isCameraOn = false
                default:
                    break
                }
            })
            .disposed(by: disposeBag)

        if let invitedInMediaVM = self.invitedInMediaVM {
            Observable.combineLatest(invitedInMediaVM.isCameraOnObservable,
                                     Privacy.cameraAccess)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] cameraOn, authorize in
                    self?.cameraView.isAuthorized = authorize.isAuthorized
                    self?.cameraView.isOn = cameraOn
                })
                .disposed(by: disposeBag)
        }

        if let setting = self.viewModel.meeting.setting {
            self.micView.bindMeetingSetting(setting)
        }
    }

    private func initialize() {
        backgroundColor = .clear
        layer.ud.setShadow(type: .s5Down)

        micView.layer.cornerRadius = 8
        micView.layer.masksToBounds = true
        cameraView.layer.cornerRadius = 8
        cameraView.layer.masksToBounds = true

        warningView.isHidden = !viewModel.isBusyRinging

        addSubview(containerView)
        containerView.addSubview(avatarImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(topicLabel)
        if !(self.invitedInMediaVM?.isWebinarAttentee ?? false) {
            containerView.addSubview(micView)
            containerView.addSubview(cameraView)
        }
        containerView.addSubview(declineButton)
        containerView.addSubview(acceptButton)
        containerView.addSubview(warningView)

        acceptButton.addSubview(loadingView)

        createConstranits()
    }

    // disable-lint: duplicated code
    private func createConstranits() {
        containerView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        avatarImageView.snp.makeConstraints { (maker) in
            maker.size.equalTo(24.0)
            maker.top.left.equalTo(Layout.commonLongMargin)
        }

        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(Layout.commonShortMargin)
            make.right.equalToSuperview().offset(-Layout.commonLongMargin)
            make.centerY.equalTo(avatarImageView)
            make.height.equalTo(18)
        }

        topicLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(Layout.commonLongMargin)
            make.left.right.equalToSuperview().inset(Layout.commonLongMargin)
        }

        if self.invitedInMediaVM?.isWebinarAttentee ?? false {
            declineButton.snp.makeConstraints { make in
                make.right.equalTo(acceptButton.snp.left).offset(-Layout.buttonLeftMargin)
                make.height.equalTo(36)
                make.width.greaterThanOrEqualTo(Layout.buttonWidth)
                make.top.equalTo(acceptButton)
                make.left.greaterThanOrEqualTo(containerView.snp.left).offset(Layout.buttonLeftMargin)
            }
        } else {
            declineButton.snp.makeConstraints { make in
                make.right.equalTo(acceptButton.snp.left).offset(-Layout.buttonLeftMargin)
                make.height.equalTo(36)
                make.width.greaterThanOrEqualTo(Layout.buttonWidth)
                make.top.equalTo(acceptButton)
                make.left.greaterThanOrEqualTo(cameraView.snp.right).offset(Layout.buttonLeftMargin)
            }
        }

        acceptButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Layout.commonLongMargin)
            make.top.equalTo(topicLabel.snp.bottom).offset(Layout.commonLongMargin)
            make.height.equalTo(36)
            make.width.greaterThanOrEqualTo(Layout.buttonWidth)
        }

        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(16)
        }

        warningView.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(declineButton.snp.bottom).offset(Layout.commonLongMargin)
            if viewModel.isBusyRinging {
                make.height.greaterThanOrEqualTo(44)
            } else {
                make.height.equalTo(0)
            }
        }

        if !(self.invitedInMediaVM?.isWebinarAttentee ?? false) {
            micView.snp.makeConstraints { (make) in
                make.top.equalTo(topicLabel.snp.bottom).offset(Layout.commonLongMargin)
                make.left.equalTo(topicLabel)
                make.size.equalTo(36)
            }

            cameraView.snp.makeConstraints { (make) in
                make.left.equalTo(micView.snp.right).offset(12)
                make.top.equalTo(micView)
                make.size.equalTo(36)
            }
        }
    }
    // enable-lint: duplicated code

    private var lastWidth: CGFloat = 0

    override func layoutSubviews() {
        super.layoutSubviews()
        if lastWidth != self.frame.size.width {
            /// 重新布局attentionLabel，让一行、两行可以及时变化
            lastWidth = self.frame.size.width
            let string = attentionLabel.attributedText
            attentionLabel.attributedText = nil
            attentionLabel.attributedText = string
        }

        let topicHeight = self.attributedMeetingTopic?.height(width: self.bounds.size.width - 2 * Layout.commonLongMargin) ?? 0
        topicLabel.snp.remakeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(Layout.commonLongMargin)
            make.left.right.equalToSuperview().inset(Layout.commonLongMargin)
            make.height.equalTo(topicHeight)
        }
    }

    private func bindAvatar() {
        let handleAvatar: (AvatarInfo) -> Void = { [weak self] avatarInfo in
            guard let self = self else { return }
            self.avatarImageView.setAvatarInfo(avatarInfo)
        }
        viewModel.avatarInfo.drive(onNext: handleAvatar).disposed(by: rx.disposeBag)
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .withLatestFrom(viewModel.avatarInfo)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: handleAvatar)
            .disposed(by: rx.disposeBag)
    }

    private func bindTopic() {
        viewModel.meetInTopic.drive(onNext: { [weak self] name in
            guard let self = self else { return }
            self.attributedMeetingTopic = AttributedMeetingTopic(topic: name, meetingTagType: self.viewModel.meetingTagType)
        }).disposed(by: rx.disposeBag)
    }

    private func bindName() {
        viewModel.meetInDescription.drive(onNext: { [weak self] description in
            guard let self = self else { return }
            self.nameLabel.text = description
        }).disposed(by: rx.disposeBag)
    }

    private func bindAcceptEnabled() {
        viewModel.isButtonEnabled
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (enable) in
                guard let self = self else { return }
                self.acceptButton.isEnabled = enable //在点击接听后，为防止重复点击，acceptButton会被置为disable状态
                self.showLoading(!enable)
            }).disposed(by: rx.disposeBag)
    }

    // disable-lint: duplicated code
    private func setMicViewClickHandler() {
        micView.clickHandler = { [weak self] in
            guard let self = self, let invitedInMediaVM = self.invitedInMediaVM else {
                return
            }
            if invitedInMediaVM.isMuteOnEntry {
                Toast.show(I18n.View_M_MutedOnEntryPreview)
                return
            }
            invitedInMediaVM.muteMic(type: self.viewModel.meeting.meetType)
            if  self.micView.isAuthorized {
                let params: TrackParams = [
                    "click": "mic",
                    "is_in_duration": true,
                    "call_type": self.viewModel.getCallType(),
                    "option": self.invitedInMediaVM?.isMicOn.value == true ? "open" : "close",
                    "is_voip": self.viewModel.meeting.isCallKitFromVoIP ? 1 : 0,
                    "is_ios_new_feat": 0,
                    "is_callkit": false
                ]
                VCTracker.post(name: .vc_meeting_callee_click, params: params)
            } else {
                let params: TrackParams = [
                    .click: "no_auth",
                    "call_type": self.viewModel.getCallType(),
                    "is_in_duration": true,
                    .location: "mic",
                    "is_voip": self.viewModel.meeting.isCallKitFromVoIP ? 1 : 0,
                    "is_ios_new_feat": 0,
                    "is_callkit": false
                ]
                VCTracker.post(name: .vc_meeting_callee_click, params: params)
            }
        }
    }
    // enable-lint: duplicated code

    private func setCamViewClickHandler() {
        cameraView.clickHandler = { [weak self] in
            guard let self = self, let invitedInMediaVM = self.invitedInMediaVM else { return }
            invitedInMediaVM.muteCamera(type: self.viewModel.meeting.meetType)

            if self.cameraView.isAuthorized {
                let params: TrackParams = [
                    "click": "camera",
                    "call_type": self.viewModel.getCallType(),
                    "is_in_duration": true,
                    "option": self.invitedInMediaVM?.isCameraOn ?? false ? "open" : "close",
                    "is_voip": self.viewModel.meeting.isCallKitFromVoIP ? 1 : 0,
                    "is_ios_new_feat": 0,
                    "is_callkit": false
                ]
                VCTracker.post(name: .vc_meeting_callee_click, params: params)
            } else {
                let params: TrackParams = [
                    .click: "no_auth",
                    "call_type": self.viewModel.getCallType(),
                    "is_in_duration": true,
                    .location: "camera",
                    "is_voip": self.viewModel.meeting.isCallKitFromVoIP ? 1 : 0,
                    "is_ios_new_feat": 0,
                    "is_callkit": false
                ]
                VCTracker.post(name: .vc_meeting_callee_click, params: params)
            }
        }
    }

    func resetAttentionLabel() {
        var title = I18n.View_G_IfAcceptCurrentCallEnds // 原有的
        if let setting = MeetingManager.shared.currentSession?.setting {
            if setting.meetingSubType == .screenShare {
                title = I18n.View_MV_JoinNowEndScreenShare
            } else if setting.meetingType == .call {
                title = I18n.View_MV_JoinLeaveCallNow
            } else if setting.meetingType == .meet {
                title = I18n.View_MV_IfAcceptCurrentMeetingEnds
            }
        }
        attentionLabel.attributedText = NSAttributedString(string: title, config: .bodyAssist)
    }
}

extension RingingMeetCardView {
    @objc func clickDecline(_ sender: UIButton) {
        viewModel.decline()
    }

    @objc func clickAccept(_ sender: UIButton) {
        viewModel.accept(isCameraOn: invitedInMediaVM?.isCameraOn, isMicOn: invitedInMediaVM?.isMicOn.value)
        if #unavailable(iOS 16.0) {
            UIDevice.updateDeviceOrientationForViewScene(self, to: .portrait, animated: true)
        }
    }

    private func showLoading(_ loading: Bool) {
        if loading {
            loadingView.play()
            loadingView.isHidden = false
        } else {
            loadingView.stop()
            loadingView.isHidden = true
        }
    }
}
