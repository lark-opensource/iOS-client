//
//  PrelobbyViewController.swift
//  ByteView
//
//  Created by liujianlong on 2021/1/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import Action
import RxCocoa
import RxSwift
import AVFoundation
import AVKit
import Lottie
import UniverseDesignIcon
import LarkMedia
import UniverseDesignToast
import ByteViewUI
import ByteViewTracker
import UniverseDesignColor
import ByteViewSetting
import LarkKeyCommandKit

final class PrelobbyViewController: VMViewController<LobbyViewModel> {
    struct Layout {
        static let verticalPadding: CGFloat = 40
        static let horizontalPadding: CGFloat = 16
    }

    let disposeBag = DisposeBag()
    private var toastOffset: CGFloat = 0

    private(set) lazy var prelobbyView: PrelobbyView = { PrelobbyView(model: viewModel.prelobbyViewModel) }()

    private var backButton: UIButton { prelobbyView.backButton }
    private var connectRoomBtn: PreviewConnectRoomButton { prelobbyView.connectRoomBtn }

    private var contentView: PreviewContentView { prelobbyView.contentView }
    private var avatarImageView: AvatarView { contentView.avatarImageView }
    private var labButton: UIButton { contentView.labButton }
    private var assistLabel: PaddingLabel { contentView.assistLabel }

    private var footerView: PreviewFooterView { prelobbyView.footerView }
    private var deviceView: PreviewDeviceView { footerView.deviceView }
    private var micView: PreviewMicrophoneView { deviceView.micView }
    private var cameraView: PreviewCameraView { deviceView.cameraView }
    private var speakerView: PreviewSpeakerView { deviceView.speakerView }
    private var leaveBtn: UIButton { footerView.commitBtn }
    private var audioOutput: AudioOutputManager? { viewModel.session.audioDevice?.output }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !viewModel.isCameraMuted {
            viewModel.camera.setMuted(false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        IdleTimerMonitor.start()
        MeetingTracksV2.trackShowPreviewVC(
            isInWaitingRoom: true,
            isCamOn: !viewModel.isCameraMuted,
            isMicOn: !viewModel.isMicrophoneMuted.value
        )
        viewModel.shouldShowAudioToast = false
        prelobbyView.updateToastOffset(in: view)
    }

    override func viewDidFirstAppear(_ animated: Bool) {
        bindExtraVirtualBgToast()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IdleTimerMonitor.stop()
        prelobbyView.resetToastContext()
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.prelobbyView.updateLayout(newContext.layoutType.isRegular)
    }

    override func viewLayoutContextDidChanged() {
        self.prelobbyView.updateToastOffset(in: self.view)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard Display.pad else { return }
        handleAvatar()
    }

    override func setupViews() {
        isNavigationBarHidden = true
        view.backgroundColor = .clear
        view.addSubview(prelobbyView)

        backButton.addTarget(self, action: #selector(didClickBack(_:)), for: .touchUpInside)
        connectRoomBtn.addTarget(self, action: #selector(didClickConnectRoom), for: .touchUpInside)
        leaveBtn.addTarget(self, action: #selector(didClickLeave(_:)), for: .touchUpInside)
        labButton.addTarget(self, action: #selector(didClickLab(_:)), for: .touchUpInside)
        deviceView.isLongMic = viewModel.shouldShowAudioArrow
        footerView.updateLayoutClosure = { [weak self] in
            guard let self = self else { return }
            self.prelobbyView.bottomDeviceMinHeight = self.footerView.deviceMinHeight
        }

        setupLayout()
    }

    override func bindViewModel() {
        viewModel.delegate = self
        viewModel.hostViewController = self
        setFooterViewStyle(by: viewModel.currentAudioType)

        viewModel.isMicrophoneMuted
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isMuted in
                guard let self = self, self.viewModel.joinTogetherRoomRelay.value == nil, self.viewModel.currentAudioType == .pstn || self.viewModel.currentAudioType == .system else { return }
                self.updateMicView(isMuted: isMuted)
            })
            .disposed(by: disposeBag)

        if viewModel.isJoinRoomEnabled {
            connectRoomBtn.isHidden = false
            connectRoomBtn.isEnabled = false
            viewModel.joinTogetherRoomRelay.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] user in
                guard let self = self else { return }
                let hasRoom = user != nil
                let micOff = self.viewModel.isMicrophoneMuted.value
                if hasRoom {
                    self.viewModel.currentAudioType = .room
                }
                self.setFooterViewStyle(by: self.viewModel.currentAudioType)
                self.connectRoomBtn.updateConnectState(hasRoom, roomName: self.viewModel.joinRoomVM.roomNameAbbr)
                self.audioOutput?.setNoConnect(hasRoom)
                if !hasRoom, self.viewModel.currentAudioType != .noConnect {
                    self.updateMicView(isMuted: micOff)
                }
                self.assistLabel.isHidden = !hasRoom
            }).disposed(by: disposeBag)
        }

        Observable.combineLatest(viewModel.isCameraMutedObservable, Privacy.cameraAccess)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isMuted, authorize in
                self?.cameraView.isAuthorized = authorize.isAuthorized
                self?.cameraView.isOn = !isMuted
                self?.contentView.updateCameraOn(!isMuted)
                self?.handleAvatar()
            })
            .disposed(by: disposeBag)

        self.micView.clickHandler = { [weak self] _ in
            guard let self = self else { return }
            if self.viewModel.joinTogetherRoomRelay.value != nil {
                self.didClickConnectRoom(true)
            } else {
                self.viewModel.handleMicrophone()
            }
        }
        self.cameraView.clickHandler = { [weak self] _ in
            self?.viewModel.handleCamera()
        }
        self.speakerView.clickHandler = { [weak self] view in
            guard let self = self else { return }
            if self.viewModel.joinTogetherRoomRelay.value != nil {
                VCTracker.post(name: .vc_toast_status, params: ["toast_name": "ultrasonic_sync_join_success", "connect_type": "preview"])
                Toast.show(I18n.View_G_WowPairedRoomAudio, in: self.view)
                return
            }
            self.viewModel.shouldShowAudioToast = true

            let config = AudioOutputActionSheet.Config(offset: -3, cellWidth: 280, cellMaxWidth: 360, margins: .init(top: 0, left: 0, bottom: 0, right: 12))
            self.audioOutput?.showPicker(scene: .prelobby, from: self, anchorView: view, config: config)

            DispatchQueue.global().async {
                LobbyTracksV2.trackSpeakerStatusOfLobby(isSheet: !LarkAudioSession.shared.isHeadsetConnected, source: .preLobby)
            }
        }

        viewModel.labButtonHidden.drive(onNext: { [weak self] (isHidden: Bool) in
            guard let self = self else { return }
            self.labButton.isHidden = isHidden
            self.labButton.setImage(UDIcon.getIconByKey(self.viewModel.setting.isVirtualBgEnabled ? .virtualBgOutlined : .effectsOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 22, height: 22)), for: .normal)
        }).disposed(by: disposeBag)
    }

    private func bindExtraVirtualBgToast() {
        viewModel.showVirtualBgToastBehavior
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                guard let self = self,
                      self.viewModel.effectManger?.virtualBgService.calendarMeetingVirtual?.hasExtraBg == true,
                      self.viewModel.effectManger?.virtualBgService.calendarMeetingVirtual?.hasShowedExtraBgToast == false else {
                    return
                }
                Logger.ui.info("showVirtualBgToastBehavior \(status)")
                if status == .done, !self.labButton.isHidden {
                    let anchorToastView = AnchorToastView()
                    self.view.addSubview(anchorToastView)
                    anchorToastView.snp.makeConstraints { make in
                        make.edges.equalToSuperview()
                    }
                    anchorToastView.setStyle(I18n.View_G_UniSetYouCanChange, on: .bottom, of: self.labButton, distance: 4, defaultEnoughInset: 8)
                    self.viewModel.effectManger?.virtualBgService.calendarMeetingVirtual?.hasShowedExtraBgToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        anchorToastView.removeFromSuperview()
                    }
                }
            })
            .disposed(by: disposeBag)
    }

    private func setFooterViewStyle(by audioType: PreviewAudioType) {
        guard !viewModel.isWebinarAttendee else {
            footerView.deviceView.style = .webinarAttendee
            return
        }
        switch audioType {
        case .noConnect:
            micView.isEnabled = false
            footerView.deviceView.style = .noConnect
        case .pstn:
            micView.isEnabled = true
            let phoneNumber = viewModel.session.service?.setting.callmePhoneNumber ?? ""
            let callMeTipText = I18n.View_G_CallNumberOnceJoin(phoneNumber)
            footerView.updateCallMeTip(callMeTipText)
            footerView.deviceView.style = .callMe
        case .room:
            micView.isEnabled = false
            footerView.deviceView.style = .room
        default:
            micView.isEnabled = true
            footerView.deviceView.style = .system
        }
        micView.audioType = audioType
    }

    private func updateMicView(isMuted: Bool) {
        let hasPermission = Privacy.audioAuthorized
        self.micView.isAuthorized = hasPermission
        self.micView.isOn = !isMuted
        if !isMuted {
            self.audioOutput?.setMuted(false)
        }
    }

    @objc private func didClickBack(_ sender: Any) {
        PrelobbyTracks.clickBack()
        viewModel.router.setWindowFloating(true)
    }

    @objc private func didClickLeave(_ sender: Any) {
        PrelobbyTracks.clickLeave()
        prelobbyView.resetToastContext()
        viewModel.hangUp()
    }

    @objc private func didClickLab(_ sender: Any) {
        viewModel.clickLab(from: self)
    }

    @objc private func didClickConnectRoom(_ isMicView: Bool = false) {
        if !self.viewModel.setting.isUltrawaveEnabled {
            Toast.show(I18n.View_UltraOnToUseThis_Note)
            return
        }
        let vc = JoinRoomTogetherViewController(viewModel: viewModel.joinRoomVM)
        vc.delegate = self
        let sourceView = isMicView ? micView : connectRoomBtn
        let popoverConfig = DynamicModalPopoverConfig(sourceView: sourceView,
                                                      sourceRect: sourceView.bounds.offsetBy(dx: 0, dy: 4),
                                                      backgroundColor: .ud.bgFloat,
                                                      popoverLayoutMargins: UIEdgeInsets(top: 0, left: 10, bottom: -4, right: 10),
                                                      permittedArrowDirections: isMicView ? .down : .up)
        let regularConfig = DynamicModalConfig(presentationStyle: .popover,
                                               popoverConfig: popoverConfig,
                                               backgroundColor: .clear)
        let compactConfig = DynamicModalConfig(presentationStyle: .pan)
        viewModel.router.presentDynamicModal(vc, regularConfig: regularConfig, compactConfig: compactConfig)
    }

    private func handleAvatar() {
        let size: CGFloat = 200
        if Privacy.videoDenied {
            avatarImageView.setAvatarInfo(.asset(UDIcon.getIconByKey(.videoOffOutlined, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: size, height: size))))
            avatarImageView.updateStyle(.square)
            contentView.updateAvatarImageSize(isDenied: true)
        } else {
            viewModel.avatarInfo.drive(onNext: { [weak self] (avatarInfo) in
                self?.avatarImageView.setAvatarInfo(avatarInfo, size: .large)
            }).disposed(by: disposeBag)
            avatarImageView.updateStyle(.circle)
            contentView.updateAvatarImageSize(isDenied: false)
        }
    }

    private func setupLayout() {
        prelobbyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func disconnectRoom() {
        guard let room = self.viewModel.joinTogetherRoomRelay.value else {
            Logger.ui.warn("prelobby didClickDisconnect ignored, room is nil")
            return
        }
        Logger.ui.info("prelobby didClickDisconnect")
        viewModel.joinRoomVM.disconnectRoom()
        didDisconnectRoom(nil, room: room)
    }

    // MARK: - KeyCommand
    override func keyBindings() -> [KeyBindingWraper] {
        let muteMicOrCamKeyBindings = [
            KeyCommandBaseInfo(
                input: "D",
                modifierFlags: [.command, .shift],
                discoverabilityTitle: I18n.View_G_MuteOrUnmuteCut_Text
            ).binding(
                target: self,
                selector: #selector(switchAudioMuteStatus)
            ).wraper,
            KeyCommandBaseInfo(
                input: "V",
                modifierFlags: [.command, .shift],
                discoverabilityTitle: I18n.View_G_StartOrStopCamCut_Text
            ).binding(
                target: self,
                selector: #selector(switchVideoMuteStatus)
            ).wraper
        ]
        return super.keyBindings() + muteMicOrCamKeyBindings
    }

    @objc private func switchAudioMuteStatus() {
        guard Display.pad, viewModel.joinTogetherRoomRelay.value == nil, !viewModel.isWebinarAttendee, viewModel.audioMode == .internet else { return }
        let isMicMuted = viewModel.isMicrophoneMuted.value
        Logger.ui.info("switch audio mute status to by keyboard shortcut, new isMicMuted = \(!isMicMuted), location: .preLobby")
        viewModel.handleMicrophone()
        KeyboardTrack.trackClickShortcut(with: .muteMicrophone, to: isMicMuted, from: .lobby)
    }

    @objc private func switchVideoMuteStatus() {
        guard Display.pad, !viewModel.isWebinarAttendee else { return }
        let isCamMuted = viewModel.isCameraMuted
        Logger.ui.info("switch video mute status to by keyboard shortcut, new isCamMuted = \(!isCamMuted), location: .preLobby")
        viewModel.handleCamera()
        KeyboardTrack.trackClickShortcut(with: .muteCamera, to: isCamMuted, from: .lobby)
    }
}

extension PrelobbyViewController: JoinRoomTogetherViewControllerDelegate {
    func didConnectRoom(_ controller: UIViewController, room: ByteviewUser) {
        self.viewModel.joinTogetherRoomRelay.accept(room)
    }

    func didDisconnectRoom(_ controller: UIViewController?, room: ByteviewUser) {
        self.viewModel.currentAudioType = .system
        self.viewModel.session.joinMeetingParams?.audioMode = .internet
        self.viewModel.joinTogetherRoomRelay.accept(nil)
        Toast.show(I18n.View_G_UsingSystemAudio_Toast, in: self.view)
        viewModel.session.audioDevice?.output.setPadMicSpeakerDisabled(viewModel.setting.isMicSpeakerDisabled)
    }
}

extension PrelobbyViewController: AudioSelectViewControllerDelegate {
    func didSelectedAudio(at type: PreviewAudioType) {
        if type != .room, viewModel.joinTogetherRoomRelay.value != nil {
            disconnectRoom()
        }
    }
}

extension PrelobbyViewController: LobbyViewModelDelegate {
    func speakerViewWillAppear() {
        speakerView.isHighlighted = VCScene.isRegular
    }

    func speakerViewWillDisappear() {
        speakerView.isHighlighted = false
    }
}
