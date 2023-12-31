//
//  CallOutViewController.swift
//  ByteView
//
//  Created by 李凌峰 on 2018/6/14.
//

import UIKit
import RxSwift
import AVFoundation
import AVKit
import ByteViewCommon
import ByteViewTracker
import UniverseDesignIcon
import LarkMedia
import ByteViewNetwork
import ByteViewRtcBridge

class CallOutViewController: VMViewController<CallOutViewModel> {
    private lazy var callOutView = CallOutView(frame: .zero, isVoiceCall: viewModel.isVoiceCall)

    private var isTracked = false
    private var dialingTimeoutDisposeBag = DisposeBag()

    private lazy var camera = PreviewCameraManager(scene: .callOut, service: viewModel.service, effectManger: viewModel.session.effectManger)
    private var iconColor: UIColor { return viewModel.isVoiceCall ? UIColor.ud.iconN2 : UIColor.ud.primaryOnPrimaryFill}

    // MARK: - Lifecycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        doPageTrack()
        startProximity()
        callOutView.playRipple()
        IdleTimerMonitor.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopProximity()
        IdleTimerMonitor.stop()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        callOutView.stopRipple()
        viewModel.shouldShowAudioToast = false
    }

    // MARK: - proximity
    private func startProximity() {
        if !viewModel.isCallKitEnabled {
            ProximityMonitor.updateAudioOutput(route: LarkAudioSession.shared.currentOutput, isMuted: false)
            ProximityMonitor.start(isPortrait: !view.isLandscape)
        }
    }

    private func stopProximity() {
        if !viewModel.isCallKitEnabled {
            ProximityMonitor.stop()
        }
    }

    // MARK: - Layout views
    override func setupViews() {
        view.addSubview(callOutView)
        callOutView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        // 因为悬浮窗先切换VC再触发Size动画，因此切全屏时默认隐藏控件
        // 预期等到动画结束再显示控件
        if viewModel.service.router.isFloatTransitioning {
            callOutView.updateOverlayAlpha(alpha: 0)
        }
    }

    // MARK: - UI bindings
    override func bindViewModel() {
        bindAudioOutput()
        bindAvatar()
        bindCamera()
        bindRenderView()
        bindName()
        bindDescription()
        bindDailingTimeout()
        bindDialingNoResponseToast()
        bindUIAction()
    }

    private func bindAudioOutput() {
        viewModel.session.audioDevice?.output.addListener(self)
        callOutView.audioSwitchButton.bindViewModel(viewModel)
    }

    private func bindUIAction() {
        callOutView.audioSwitchButton.addTarget(self, action: #selector(switchAudioOutput), for: .touchUpInside)
        callOutView.cancelButton.addTarget(self, action: #selector(cancelDialing), for: .touchUpInside)
        callOutView.floatingButton.addTarget(self, action: #selector(floatWindow), for: .touchUpInside)
    }

    private func bindAvatar() {
        viewModel.avatarInfo
            .drive(onNext: { [weak self] avatarInfo in
                guard let self = self else { return }
                self.callOutView.updateAvatar(avatarInfo: avatarInfo)
            }).disposed(by: rx.disposeBag)
    }

    private func bindCamera() {
        self.callOutView.updateCamera(isOn: viewModel.isCameraOn)
        self.callOutView.mode = viewModel.isCameraOn ? .light : .dark
        camera.delegate = viewModel
    }

    private func bindRenderView() {
        if viewModel.isCameraOn {
            let streamRenderView = StreamRenderView()
            streamRenderView.cropLocalPortraitTo1x1 = false
            streamRenderView.renderMode = .renderModeHidden
            streamRenderView.setStreamKey(.local)
            self.callOutView.contentView.addSubview(streamRenderView)
            streamRenderView.frame = self.callOutView.contentView.bounds
            streamRenderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            streamRenderView.bindMeetingSetting(viewModel.service.setting)
            let maskView = UIView(frame: streamRenderView.frame)
            if Display.pad {
                maskView.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.3)
            } else {
                maskView.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.4)
            }
            maskView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.callOutView.contentView.addSubview(maskView)

            camera.setMuted(false)
        }
    }

    private func bindName() {
        viewModel.name.drive(onNext: { [weak self] name in
            guard let self = self else { return }
            self.callOutView.updateName(name: name)
        }).disposed(by: rx.disposeBag)
    }

    private func bindDescription() {
        viewModel.description.drive(onNext: { [weak self] description in
            guard let self = self else { return }
            self.callOutView.updateDescription(description: description)
        }).disposed(by: rx.disposeBag)
    }

    private func bindDailingTimeout() {
        viewModel.timeoutOfDialing.drive(onNext: { [weak self] in
            guard let self = self else { return }
            self.notityDialingTimeout()
        }).disposed(by: dialingTimeoutDisposeBag)
    }

    private func unbindDialingTimeout() {
        dialingTimeoutDisposeBag = DisposeBag()
    }

    private func bindDialingNoResponseToast() {
        viewModel.noResponseOfDialing.drive(onNext: { [weak self] in
            guard let self = self else { return }
            self.showNoResponseOfDialing()
        }).disposed(by: rx.disposeBag)
    }

    private func showNoResponseOfDialing() {
        if !viewModel.service.router.isFloating {
            Toast.show(I18n.View_VM_NoResponseTryAgain, duration: 10)
        }
    }

    // MARK: - UI actions
    @objc private func switchAudioOutput() {
        viewModel.session.audioDevice?.output.showPicker(scene: .callOut, from: self, anchorView: callOutView.audioSwitchButton)
        VCTracker.post(name: .vc_call_page_calling, params: [.action_name: viewModel.session.audioDevice?.output.currentOutput.trackText])
    }

    @objc private func cancelDialing() {
        viewModel.onCancelDialing()
        unbindDialingTimeout()
        viewModel.cancelCalling()
        VCTracker.post(name: .vc_meeting_calling_click, params: [.click: "cancel"])
    }

    @objc private func floatWindow() {
        notifyFloatWindow()
    }

    // MARK: - Page routings, window floatings etc.
    private func notityDialingTimeout() {
        viewModel.callingTimeout()
    }

    private func notifyFloatWindow() {
        viewModel.service.router.setWindowFloating(true)
    }

    // MARK: - Page tracks
    private func doPageTrack() {
        if !isTracked {
            CallingReciableTracker.endEnterCalling()
            var params: TrackParams = [
                "is_bluetooth_on": LarkAudioSession.shared.isBluetoothActive
            ]
            if self.viewModel.session.meetType == .call {
                params.updateParams(["call_source": self.viewModel.isVoiceCall ? "voice_call" : "video_call"])
            }
            VCTracker.post(name: .vc_meeting_calling_view, params: params)

            VCTracker.post(name: .vc_call_page_calling, params: [.action_name: "display"])
            isTracked = true
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return viewModel.isVoiceCall ? .default : .lightContent
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

// MARK: - FloatingWindowTransitioning
extension CallOutViewController: FloatingWindowTransitioning {
    func floatingWindowWillTransition(to frame: CGRect, isFloating: Bool) {
        self.callOutView.updateOverlayAlpha(alpha: 0)
    }

    func floatingWindowDidTransition(to frame: CGRect, isFloating: Bool) {
        self.callOutView.updateOverlayAlpha(alpha: 1, duration: 0.25)
    }
}

// MARK: - Delegate
extension CallOutViewController: AudioOutputListener {
    func didChangeAudioOutput(_ output: AudioOutputManager, reason: AudioOutputChangeReason) {
        if !viewModel.service.router.isFloating {
            self.showToast(output)
        }
        let route = output.currentOutput
        ProximityMonitor.updateAudioOutput(route: route, isMuted: false)
        var params: TrackParams = [ .click: route.i18nText, .location: "calling_page", "is_bluetooth_on": route == .bluetooth,
                                    "call_source": self.viewModel.isVoiceCall ? "voice_call" : "video_call"]
        VCTracker.post(name: .vc_meeting_calling_click, params: params)
    }

    private func showToast(_ output: AudioOutputManager) {
        if Display.phone {
            let content: String
            switch output.currentOutput {
            case .speaker:
                content = I18n.View_MV_UseSpeakerConnected
            case .receiver:
                content = I18n.View_MV_UseEarConnected
            default:
                content = I18n.View_MV_UseDeviceConnected(output.fullOutputsName)
            }
            Toast.showOnVCScene(content, in: nil)
        } else {
            output.showToast()
        }
    }

    func audioOutputPickerWillAppear() {
        expandDetail(true)
    }

    func audioOutputPickerWillDisappear() {
        expandDetail(false)
    }

    private func expandDetail(_ expanded: Bool) {
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.2, animations: {
            self.callOutView.audioSwitchButton.expandIconView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        }, completion: { _ in
            if expanded {
                self.callOutView.audioSwitchButton.expandIconView.image = UDIcon.getIconByKey(.expandUpFilled, iconColor: self.iconColor, size: CGSize(width: 10, height: 10))
            } else {
                self.callOutView.audioSwitchButton.expandIconView.image = UDIcon.getIconByKey(.expandDownFilled, iconColor: self.iconColor, size: CGSize(width: 10, height: 10))
            }
            self.callOutView.audioSwitchButton.expandIconView.transform = .identity
        })
    }
}
