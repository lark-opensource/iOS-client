//
//  LobbyViewController.swift
//  ByteView
//
//  Created by Prontera on 2020/6/28.
//

import UIKit
import RxSwift
import RxCocoa
import ByteViewCommon
import ByteViewTracker
import AVFAudio
import UniverseDesignIcon
import LarkMedia
import UniverseDesignToast
import ByteViewUI
import LarkKeyCommandKit
import ByteViewRtcBridge

class LobbyViewController: VMViewController<LobbyViewModel> {
    let disposeBag = DisposeBag()

    lazy var waitingLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .ud.textTitle
        return label
    }()

    private lazy var videoView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [waitingLabel, videoView])
        stackView.spacing = 32
        stackView.axis = .vertical
        stackView.alignment = .center
        return stackView
    }()

    private lazy var containerView: UIView = UIView()

    lazy var topBar = LobbyNavigationBar(viewModel: self.viewModel, delegate: self)
    lazy var bottomBar = LobbyToolBar(isCamMicHidden: viewModel.isCamMicHidden, output: viewModel.session.audioDevice?.output)

    private lazy var overlayView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.backgroundColor = UIColor.ud.vcTokenMeetingBgVideoOff
        view.clipsToBounds = true
        return view
    }()

    private lazy var labButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.vc.setBackgroundColor(UIColor.ud.N00.withAlphaComponent(0.8), for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.N00, for: .highlighted)
        let isVirtualBgEnabled = viewModel.setting.isVirtualBgEnabled
        button.setImage(UDIcon.getIconByKey(isVirtualBgEnabled ? .virtualBgOutlined : .virtualBgOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 22, height: 22)), for: .normal)
        button.layer.borderWidth = 1 / view.vc.displayScale
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        button.addInteraction(type: .lift)
        return button
    }()

    lazy var avatarImageView: AvatarView = {
        let imageView = AvatarView()
        imageView.isHidden = true
        imageView.removeMaskView()
        return imageView
    }()

    private let cameraHaveNoAccessImageView: UIImageView = {
        let dimension = Display.pad ? 300.0 : 88.0
        let image = UDIcon.getIconByKey(.videoOffFilled, iconColor: .ud.iconDisabled, size: CGSize(width: dimension, height: dimension))
        let imageView = UIImageView(image: image)
        imageView.isHidden = true
        return imageView
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !viewModel.isCameraMuted {
            viewModel.camera.setMuted(false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        IdleTimerMonitor.start()
        VCTracker.post(name: .vc_meeting_waiting_view)
        viewModel.session.slaTracker.resetOnthecall()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IdleTimerMonitor.stop()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.shouldShowAudioToast = false
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if Display.pad {
            self.updatePadLayout()
            self.bottomBar.updatePadLayout()
        }
        self.topBar.updateLayout()
    }

    override func setupViews() {
        view.backgroundColor = UIColor.ud.bgBody
        navigationController?.view.backgroundColor = UIColor.clear

        view.addSubview(topBar)
        view.addSubview(containerView)
        containerView.addSubview(contentStackView)
        view.addSubview(overlayView)
        view.addSubview(avatarImageView)
        view.addSubview(cameraHaveNoAccessImageView)

        updateTopBarConstraints()
        updateSwitchButton()
        setUpToolbar()

        if Display.phone {
            containerView.snp.makeConstraints { make in
                make.top.equalTo(topBar.snp.bottom)
                make.bottom.equalTo(bottomBar.snp.top).offset(-24)
                make.left.right.equalToSuperview()
            }
            contentStackView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
            }
            videoView.snp.makeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalTo(videoView.snp.width)
            }
        } else {
            updatePadLayout()
        }

        avatarImageView.snp.remakeConstraints { (make) in
            make.height.equalTo(videoView.snp.height).multipliedBy(0.5)
            make.width.equalTo(avatarImageView.snp.height)
            make.center.equalTo(videoView)
        }
        cameraHaveNoAccessImageView.snp.remakeConstraints { make in
            make.height.equalTo(videoView.snp.height).multipliedBy(0.4)
            make.width.equalTo(cameraHaveNoAccessImageView.snp.height)
            make.center.equalTo(videoView)
        }
        overlayView.snp.makeConstraints {
            $0.edges.equalTo(videoView)
        }

        setUpCamera()

        view.addSubview(labButton)
        labButton.snp.makeConstraints { (maker) in
            maker.top.right.equalTo(videoView).inset(12)
            maker.size.equalTo(36)
        }
    }

    private func updatePadLayout() {
        guard Display.pad else { return }
        if !VCScene.isLandscape {
            containerView.snp.remakeConstraints { make in
                make.top.equalTo(topBar.snp.bottom).offset(8)
                make.bottom.equalTo(bottomBar.snp.top)
                make.left.right.equalToSuperview()
            }
            contentStackView.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.right.equalToSuperview().inset(20)
            }
            videoView.snp.remakeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalTo(videoView.snp.width)
            }
        } else {
            containerView.snp.remakeConstraints { make in
                make.top.equalTo(topBar.snp.bottom).offset(8)
                make.bottom.equalTo(bottomBar.snp.top)
                make.left.right.equalToSuperview()
            }
            contentStackView.snp.remakeConstraints { make in
                make.top.greaterThanOrEqualToSuperview()
                make.bottom.lessThanOrEqualToSuperview()
                make.left.right.equalToSuperview().inset(20)
                make.centerY.equalToSuperview()
            }
            videoView.snp.remakeConstraints { make in
                make.width.equalToSuperview().priority(.low)
                make.width.lessThanOrEqualToSuperview()
                make.height.equalTo(videoView.snp.width).multipliedBy(9.0 / 16.0)
            }
        }
    }

    private func setUpCamera() {
        let streamRenderView = StreamRenderView()
        if Display.pad {
            streamRenderView.renderMode = .renderModeFit
        } else {
            streamRenderView.renderMode = .renderModeHidden
        }
        streamRenderView.bindMeetingSetting(viewModel.setting)
        streamRenderView.setStreamKey(.local)
        videoView.addSubview(streamRenderView)
        streamRenderView.frame = videoView.bounds
        streamRenderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    private func updateTopBarConstraints() {
        topBar.alpha = 1
        topBar.snp.remakeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
        }
        topBar.barContentGuide.snp.remakeConstraints { make in
            make.left.right.bottom.equalTo(topBar)
            make.height.equalTo(InMeetNavigationBar.contentHeight)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
    }

    override func bindViewModel() {
        viewModel.session.audioDevice?.output.addListener(self)

        viewModel.hostViewController = self
        viewModel.joinTogetherRoomRelay.asDriver().drive(onNext: { [weak self] in
            guard let self = self else { return }
            let text = $0 == nil ?
            (self.viewModel.startInfo.isBeMovedIn ? I18n.View_G_HostMoveYouLobbyJoin : I18n.View_M_WaitForHostToLetYouIn) :
            I18n.View_G_WaitHostAllowYouRoom
            self.waitingLabel.attributedText = NSAttributedString(string: text, config: .h2, alignment: .center)
        }).disposed(by: rx.disposeBag)

        Observable.combineLatest(viewModel.isCameraMutedObservable,
                                 Privacy.cameraAccess)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isMuted, authorize in
                guard let self = self else { return }
                self.avatarImageView.isHidden = !isMuted || !authorize.isAuthorized
                self.cameraHaveNoAccessImageView.isHidden = authorize.isAuthorized
            })
            .disposed(by: rx.disposeBag)

        viewModel.isCameraMutedObservable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] isMuted in
            guard let self = self else { return }
            self.overlayView.backgroundColor = isMuted ? UIColor.ud.vcTokenMeetingBgVideoOff : .clear
        }).disposed(by: rx.disposeBag)

        viewModel.avatarInfo
            .drive(onNext: { [weak self] (avatarInfo: AvatarInfo) in
                self?.avatarImageView.setAvatarInfo(avatarInfo, size: Display.pad ? .large : .medium)
            })
            .disposed(by: rx.disposeBag)

        labButton.addTarget(self, action: #selector(didClickLab(_:)), for: .touchUpInside)
        viewModel.labButtonHidden.drive(onNext: { [weak self] (isHidden: Bool) in
            guard let self = self else { return }
            let isVirtualBgEnabled = self.viewModel.setting.isVirtualBgEnabled
            self.labButton.isHidden = isHidden
            self.labButton.setImage(UDIcon.getIconByKey(isVirtualBgEnabled ? .virtualBgOutlined : .effectsOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 22, height: 22)), for: .normal)
        }).disposed(by: rx.disposeBag)

        bindExtraVirtualBgToast()

        LobbyTracks.trackDisplayOfLobby(interactiveID: viewModel.startInfo.lobbyParticipant?.interactiveId ?? "")
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

    private func updateSwitchButton() {
        guard let audioOutput = viewModel.session.audioDevice?.output else { return }
        bottomBar.updateAudioOutput(audioOutput)
    }

    @objc private func didClickLab(_ sender: Any) {
        viewModel.clickLab(from: self)
    }

    func didClickSpeaker() {
        if viewModel.joinTogetherRoomRelay.value != nil {
            VCTracker.post(name: .vc_toast_status, params: ["toast_name": "ultrasonic_sync_join_success", "connect_type": "preview"])
            Toast.show(I18n.View_G_WowPairedRoomAudio, in: self.view)
            return
        }
        viewModel.shouldShowAudioToast = true
        viewModel.session.audioDevice?.output.showPicker(scene: .lobby, from: self, anchorView: bottomBar.speakerItemView, config: .init(offset: -4))
        DispatchQueue.global().async {
            LobbyTracksV2.trackSpeakerStatusOfLobby(isSheet: !LarkAudioSession.shared.isHeadsetConnected, source: .inLobby)
        }
    }

    @objc func clickCameraBtn(sender: UIControl) {
        let newIsCameraMuted = !viewModel.isCameraMuted
        LobbyTracks.trackCameraStatusOfLobby(muted: newIsCameraMuted, source: .inLobby)
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
        guard Display.pad, !viewModel.isWebinarAttendee else { return }
        let isMicMuted = viewModel.isMicrophoneMuted.value
        Logger.ui.info("switch audio mute status to by keyboard shortcut, new isMicMuted = \(!isMicMuted), location: .lobby")
        viewModel.handleMicrophone()
        KeyboardTrack.trackClickShortcut(with: .muteMicrophone, to: isMicMuted, from: .lobby)
    }

    @objc private func switchVideoMuteStatus() {
        guard Display.pad, !viewModel.isWebinarAttendee else { return }
        let isCamMuted = viewModel.isCameraMuted
        Logger.ui.info("switch video mute status to by keyboard shortcut, new isCamMuted = \(!isCamMuted), location: .lobby")
        viewModel.handleCamera()
        KeyboardTrack.trackClickShortcut(with: .muteCamera, to: isCamMuted, from: .lobby)
    }
}

extension LobbyViewController: AudioOutputListener {
    func didChangeAudioOutput(_ output: AudioOutputManager, reason: AudioOutputChangeReason) {
        updateSwitchButton()
    }
}

// MARK: - navigation bar
extension LobbyViewController: LobbyNavigationBarDelegate {
    func topBarDidClickHangup(_ sender: UIButton) {
        viewModel.hangUp()
    }
}
