//
//  CallInViewController.swift
//  ByteView
//
//  Created by 李凌峰 on 2018/6/15.
//

import UIKit
import RxSwift
import AVFoundation
import ByteViewCommon
import UniverseDesignShadow
import ByteViewTracker
import UniverseDesignIcon
import LarkMedia

class CallInViewController: VMViewController<CallInViewModel> {
    lazy var callInView: CallInView = {
        let callInView = CallInView(viewModel: viewModel)
        callInView.layer.ud.setShadowColor(UDShadowColorTheme.s5DownColor.withAlphaComponent(0.16))
        callInView.layer.shadowOpacity = 1
        callInView.layer.shadowOffset = CGSize(width: 0, height: 8)
        callInView.layer.shadowRadius = 36
        callInView.layer.masksToBounds = false
        return callInView
    }()

    private var isClickVoiceOnly = false

    private var disposeBag = DisposeBag()

    deinit {
        RingPlayer.shared.stop()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #unavailable(iOS 16.0) {
            UIDevice.updateDeviceOrientationForViewScene(nil, to: .portrait, animated: true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        callInView.playRipple()
        IdleTimerMonitor.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IdleTimerMonitor.stop()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !(viewModel.callInType.isPhoneCall && Display.phone) {
            callInView.stopRipple()
        }
    }

    // MARK: - Layout views
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = .clear
        view.addSubview(callInView)

        callInView.snp.remakeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        if !viewModel.isBusyRinging {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                let meeting = self.viewModel.meeting
                let pushRingtone = meeting.videoChatInfo?.ringtone
                let ringtone: String?
                if let pushRingtone, !pushRingtone.isEmpty {
                    ringtone = pushRingtone
                } else {
                    ringtone = meeting.setting?.customRingtone
                }
                RingPlayer.shared.play(.ringing(ringtone))
            }
        }

        // 因为悬浮窗先切换VC再触发Size动画，因此切全屏时默认隐藏控件
        // 预期等到动画结束再显示控件
        if viewModel.router.isFloatTransitioning {
            callInView.updateOverlayAlpha(alpha: 0)
        }
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if self.viewModel.isBusyRinging && !newContext.layoutType.isRegular && newContext.layoutChangeReason.isOrientationChanged && view.isLandscape {
            self.dismissForCard()
        }
    }

    // MARK: - UI bindings
    override func bindViewModel() {
        bindAudioOutput()
        bindAvatar()
        bindName()
        bindDescription()
        bindAcceptEnabled()
        bindUIAction()
        doPageTrack()
    }

    private func bindAudioOutput() {
        if Display.phone, viewModel.is1v1, viewModel.callInType == .vc, let output = viewModel.meeting.audioDevice?.output {
            output.addListener(self)
            callInView.audioSwitchButton.addTarget(self, action: #selector(switchAudioOutput), for: .touchUpInside)
            let route = output.currentOutput
            callInView.audioSwitchButton.updateButtonUI(route)
            viewModel.trackRouteChange(route)
        }
    }

    private func bindUIAction() {
        callInView.declineButton.addTarget(self, action: #selector(decline), for: .touchUpInside)
        callInView.acceptButton.addTarget(self, action: #selector(accept), for: .touchUpInside)
        callInView.voiceOnlyButton.addTarget(self, action: #selector(acceptVoiceOnly), for: .touchUpInside)
        callInView.floatingButton.addTarget(self, action: #selector(notifyFloatWindow), for: .touchUpInside)
    }

    private func bindAvatar() {
        let handleAvatar: (AvatarInfo) -> Void = { [weak self] avatarInfo in
            guard let self = self else { return }
            self.callInView.updateAvatar(avatarInfo: avatarInfo)
        }

        viewModel.avatarInfo.drive(onNext: handleAvatar).disposed(by: rx.disposeBag)

        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .withLatestFrom(viewModel.avatarInfo)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: handleAvatar)
            .disposed(by: rx.disposeBag)
    }

    private func bindName() {
        viewModel.name.drive(onNext: { [weak self] name in
            guard let self = self else { return }
            self.callInView.updateName(name: name)
        }).disposed(by: rx.disposeBag)
    }

    private func bindDescription() {
        viewModel.callInDescription.drive(onNext: { [weak self] description in
            guard let self = self else { return }
            self.callInView.updateDescription(description: description)
        }).disposed(by: rx.disposeBag)
    }

    private func bindAcceptEnabled() {
        viewModel.isButtonEnabled
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (enable) in
                guard let self = self else { return }
                self.callInView.updateAcceptEnabled(enabled: enable, isClickVoiceOnly: self.isClickVoiceOnly)
            }).disposed(by: rx.disposeBag)
    }

    // MARK: - UI actions
    @objc
    func decline() {
        viewModel.decline()
    }

    @objc func accept() {
        isClickVoiceOnly = false
        viewModel.accept()
    }

    @objc func acceptVoiceOnly() {
        isClickVoiceOnly = true
        viewModel.acceptVoiceOnly()
    }

    @objc private func notifyFloatWindow() {
        if viewModel.isBusyRinging { // 忙线1v1返回卡片，非忙线进入小窗
            dismissForCard()
        } else {
            viewModel.router.setWindowFloating(true)
        }
    }

    @objc private func switchAudioOutput() {
        guard let output = viewModel.meeting.audioDevice?.output else {
            return
        }
        output.showPicker(scene: .callIn, from: self, anchorView: callInView.audioSwitchButton)
        VCTracker.post(name: .vc_call_page_calling, params: [.action_name: output.currentOutput.trackText])
    }

    private func dismissForCard() {
        PromptWindowControllerV2.shared.dismissVC()
        RingingCardManager.shared.post(meetingId: viewModel.meeting.meetingId, type: .callInBusyRing)
    }

    // MARK: - Page Track
    private func doPageTrack() {
        var params: TrackParams = [
            "is_mic_open": false,
            "is_in_duration": false,
            "is_cam_open": false,
            "is_voip": self.viewModel.meeting.isCallKitFromVoIP ? 1 : 0,
            "is_ios_new_feat": 0, // 新特性上线后有效
            "is_bluetooth_on": LarkAudioSession.shared.isBluetoothActive,
            "is_full_card": true,
            "is_callkit": false
        ]
        if self.viewModel.meeting.meetType == .call {
            params.updateParams(self.viewModel.getCallParamsTrack())
        }
        VCTracker.post(name: .vc_meeting_callee_view, params: params)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Display.pad ? .all : .portrait
    }
}

// MARK: - Delegate
extension CallInViewController {
    private func expandDetail(_ expanded: Bool) {
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.2, animations: {
            self.callInView.audioSwitchButton.expandIconView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        }, completion: { _ in
            if expanded {
                self.callInView.audioSwitchButton.expandIconView.image = UDIcon.getIconByKey(.expandUpFilled, iconColor: UIColor.ud.iconN2, size: CGSize(width: 10, height: 10))
            } else {
                self.callInView.audioSwitchButton.expandIconView.image = UDIcon.getIconByKey(.expandDownFilled, iconColor: UIColor.ud.iconN2, size: CGSize(width: 10, height: 10))
            }
            self.callInView.audioSwitchButton.expandIconView.transform = .identity
        })
    }
}

// MARK: - FloatingWindowTransitioning
extension CallInViewController: FloatingWindowTransitioning {
    func floatingWindowWillTransition(to frame: CGRect, isFloating: Bool) {
        self.callInView.updateOverlayAlpha(alpha: 0)
    }

    func floatingWindowDidTransition(to frame: CGRect, isFloating: Bool) {
        self.callInView.updateOverlayAlpha(alpha: 1, duration: 0.25)
    }
}

extension CallInViewController: AudioOutputListener {
    func didChangeAudioOutput(_ output: AudioOutputManager, reason: AudioOutputChangeReason) {
        let route = output.currentOutput
        callInView.audioSwitchButton.updateButtonUI(route)
        let content: String
        switch route {
        case .speaker:
            content = I18n.View_MV_UseSpeakerConnected
        case .receiver:
            content = I18n.View_MV_UseEarConnected
        default:
            content = I18n.View_MV_UseDeviceConnected(output.fullOutputsName)
        }
        Toast.showOnVCScene(content, in: callInView)
        viewModel.trackRouteChange(route)
    }

    func audioOutputPickerWillAppear() {
        expandDetail(true)
    }

    func audioOutputPickerWillDisappear() {
        expandDetail(false)
    }
}
