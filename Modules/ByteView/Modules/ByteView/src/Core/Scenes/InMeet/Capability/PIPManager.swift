//
//  PIPManager.swift
//  ByteView
//
//  Created by fakegourmet on 2022/9/22.
//

import Foundation
import UIKit
import AVKit
import ByteViewTracker
import ByteViewMeeting
import ByteViewCommon
import ByteViewSetting
import ByteViewRtcBridge
import ByteViewNetwork
import ByteViewUI
import ByteViewRTCRenderer

protocol PIPObserver: AnyObject {
    func pictureInPictureWillStart()
    func pictureInPictureDidStart()
    func pictureInPictureWillStop()
    func pictureInPictureDidStop()
    func pictureInPictureWillStartFailed(error: Error)
    func pictureInPictureRestoreUserInterface(completionHandler: @escaping (Bool) -> Void)
}

extension PIPObserver {
    func pictureInPictureWillStart() {}
    func pictureInPictureDidStart() {}
    func pictureInPictureWillStop() {}
    func pictureInPictureDidStop() {}
    func pictureInPictureWillStartFailed(error: Error) {}
    func pictureInPictureRestoreUserInterface(completionHandler: @escaping (Bool) -> Void) {}
}

/// VC 画中画
/// https://bytedance.feishu.cn/wiki/wikcnxubsS3NlcuOyc3sucPG0N9
final class PIPManager: NSObject {

    static let didChangePiPStatusNotification = Notification.Name(rawValue: "vc.pip.didChangePiPStatus")
    static let pipStatusKey = "PIPManager.pipStatusKey"
    static let pipSessionIDKey = "PIPManager.pipSessionIDKey"

    var isEnabled: Bool {
        session.setting?.isPiPEnabled ?? false
    }

    var isSampleBufferRenderEnabled: Bool {
        session.setting?.isPiPSampleBufferRenderEnabled ?? false
    }

    var isActive: Bool {
        controller?.isPictureInPictureActive ?? false
    }

    // ByteViewSampleBufferLayerView初始化可能引发卡死，因此PIP模式尽可能缓存复用
    private(set) lazy var sampleBufferRenderView: ByteViewRenderView = {
        Logger.pip.info("init sampleBufferRenderView")
        let view = ByteViewRenderViewFactory(renderType: .sampleBufferLayer).create(with: nil, fpsHint: 0)
        Logger.pip.info("init sampleBufferRenderView complete")
        return view
    }()

    /// 画中画渲染 View
    /// 会议维度生命周期
    private(set) lazy var participantView: FloatingParticipantView = {
        let participantView = FloatingParticipantView()
        if isSampleBufferRenderEnabled {
            participantView.streamRenderView.rendererType = .sampleBufferLayer
            participantView.streamRenderView.sampleBufferRenderView = sampleBufferRenderView
        } else {
            participantView.streamRenderView.rendererType = .metalLayer
        }
        participantView.streamRenderView.shouldIgnoreAppState = true
        return participantView
    }()

    private let rtc: InMeetRtcEngine
    private let session: MeetingSession
    @RwAtomic
    private var audioMode: ParticipantSettings.AudioMode
    private weak var microphone: InMeetMicrophoneManager?

    init(session: MeetingSession, myself: Participant, microphone: InMeetMicrophoneManager, rtc: InMeetRtcEngine) {
        self.session = session
        self.audioMode = myself.settings.audioMode
        self.microphone = microphone
        self.rtc = rtc
        super.init()
        session.addMyselfListener(self)
        session.setting?.addListener(self, for: .isPiPEnabled)
        if #available(iOS 13.0, *), VCScene.supportsMultipleScenes {
            NotificationCenter.default.addObserver(self, selector: #selector(sceneDidActivate(_:)), name: UIScene.didActivateNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(sceneWillDeactivate(_:)), name: UIScene.willDeactivateNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(didReceiveDidBecomeActiveNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(adjustContentSizeIfNeeded), name: UIApplication.willResignActiveNotification, object: nil)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(adjustContentSizeIfNeeded), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)

        Util.runInMainThread {
            // 初始化 RenderView
            _ = self.participantView
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private var defaultContentSize: CGSize {
        if Display.phone {
            return CGSize(width: 3, height: 4)
        } else {
            return VCScene.isLandscape ? CGSize(width: 16, height: 9) : CGSize(width: 1, height: 1)
        }
    }

    private var controller: AVPictureInPictureController?
    private var pipVideoCallViewController: UIViewController?

    /// 用于激活画中画的 view
    private(set) weak var activeView: UIView?

    /// 初始化画中画 Controller
    /// - Parameter view: 用于激活画中画的 view
    ///
    /// 激活画中画条件：
    /// 1. 需要该 view 在 window 上
    /// 2. view 的 size 不能为 zero
    /// 3. view 不能 hidden 或者 alpha 小于 0.1
    ///
    /// 画中画结束时会有过场动画收束至该 view
    func setup(with view: UIView) {
        pipVideoCallViewController = nil
        controller = nil
        if #available(iOS 15.0, *) {
            let vc = AVPictureInPictureVideoCallViewController()
            vc.preferredContentSize = defaultContentSize
            pipVideoCallViewController = vc
            let contentSource = AVPictureInPictureController.ContentSource.init(activeVideoCallSourceView: view, contentViewController: vc)
            controller = AVPictureInPictureController(contentSource: contentSource)
            controller?.canStartPictureInPictureAutomaticallyFromInline = isEnabled
            controller?.requiresLinearPlayback = true
            controller?.delegate = self
            activeView = view
        } else {
            // Fallback on earlier versions
        }
    }

    func attach(vc: UIViewController) {
        Util.runInMainThread { [weak self] in
            self?.pipVideoCallViewController?.addChild(vc)
            self?.pipVideoCallViewController?.view.addSubview(vc.view)
            vc.view.snp.remakeConstraints {
                $0.edges.equalToSuperview()
            }
        }
    }

    func detach() {
        Util.runInMainThread { [weak self] in
            self?.pipVideoCallViewController?.children.forEach {
                $0.vc.removeFromParent()
            }
        }
    }

    func reset() {
        Util.runInMainThread { [weak self] in
            self?.pipVideoCallViewController?.vc.removeFromParent()
            self?.pipVideoCallViewController = nil
            self?.activeView?.removeFromSuperview()
            self?.controller = nil
        }
    }

    private let observers = Listeners<PIPObserver>()
    func addObserver(_ observer: PIPObserver) {
        observers.addListener(observer)
    }

    func removeObserver(_ observer: PIPObserver) {
        observers.removeListener(observer)
    }

    @objc
    private func didReceiveDidBecomeActiveNotification() {
        adjustContentSizeIfNeeded()
        stopPIPIfNeeded()
    }

    private func stopPIPIfNeeded(tryCount: Int = 3) {
        guard clientState == .active else { return }
        if tryCount > 0, let controller = controller {
            Logger.pip.info("stop picture in picture when become active")
            controller.stopPictureInPicture()
            // 点击 app 回前台瞬间可能会关闭失败
            // 此处兜底
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: { [weak self] in
                self?.stopPIPIfNeeded(tryCount: tryCount - 1)
            })
        } else {
            Logger.pip.error("stop picture in picture when become active failed")
        }
    }

    @objc
    private func adjustContentSizeIfNeeded() {
        guard clientState != .background else { return }
        updateContentSize(size: defaultContentSize)
    }

    func updateContentSize(size: CGSize) {
        guard isEnabled else { return }
        Logger.pip.info("\(#function) w: \(size.width) h: \(size.height)")
        Util.runInMainThread { [weak self] in
            self?.pipVideoCallViewController?.preferredContentSize = size
        }
    }

    private func preparePIPStart() {
        rtc.enablePIPMode(true)
        guard !isSampleBufferRenderEnabled else {
            return
        }
        // PIP 视频渲染需要开启音频采集
        if audioMode == .noConnect {
            microphone?.startAudioCapture(scene: .noaudioEnterPip)
        }
        // callkit 下，不主动关闭硬件静音
        if !session.isCallKit {
            microphone?.setAudioUnitMuted(false)
        }
    }

    private func preparePIPStop() {
        rtc.enablePIPMode(false)
        guard !isSampleBufferRenderEnabled else {
            return
        }
        if audioMode == .noConnect {
            microphone?.stopAudioCapture()
        }
        if !session.isCallKit {
            microphone?.setAudioUnitMuted(microphone?.isMuted ?? false)
        }
    }

    // 防止未知vc展示到画中画上
    private func detectAndDismissOtherVCIfNeeded() {
        if let vc = pipVideoCallViewController?.view.window?.rootViewController?.presentedViewController {
            Logger.pip.warn("detect and dismiss: \(vc)")
            vc.dismiss(animated: false)
        }
    }
}

extension PIPManager {

    enum ClientState {
        case unknown
        case active
        case background
    }

    private var clientState: ClientState {
        if #available(iOS 13.0, *), VCScene.supportsMultipleScenes {
            switch activeView?.window?.windowScene?.activationState {
            case .foregroundActive: return .active
            case .background: return .background
            default: return .unknown
            }
        } else {
            switch AppInfo.shared.applicationState {
            case .active: return .active
            case .background: return .background
            default: return.unknown
            }
        }
    }

    @available(iOS 13.0, *)
    private var pipScene: UIWindowScene? { activeView?.window?.windowScene }

    private func isPIPScene(_ notification: Notification) -> Bool {
        if #available(iOS 13.0, *) {
            if let scene = notification.object as? UIWindowScene, scene == pipScene {
                return true
            }
        }
        return false
    }

    @objc private func sceneWillDeactivate(_ notification: Notification) {
        if isPIPScene(notification) {
            adjustContentSizeIfNeeded()
        }
    }

    @objc private func sceneDidActivate(_ notification: Notification) {
        if isPIPScene(notification) {
            adjustContentSizeIfNeeded()
            stopPIPIfNeeded()
        }
    }
}

extension PIPManager: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Logger.pip.info("\(#function)")
        preparePIPStart()
        observers.forEach {
            $0.pictureInPictureWillStart()
        }
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Logger.pip.info("\(#function)")
        detectAndDismissOtherVCIfNeeded()
        observers.forEach {
            $0.pictureInPictureDidStart()
        }
        if !session.isEnd {
            NotificationCenter.default.post(name: Self.didChangePiPStatusNotification,
                                            object: self,
                                            userInfo: [
                                                Self.pipStatusKey: true,
                                                Self.pipSessionIDKey: session.sessionId
                                            ])
        }
    }

    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Logger.pip.info("\(#function)")
        preparePIPStop()
        observers.forEach {
            $0.pictureInPictureWillStop()
        }
        if !session.isEnd {
            NotificationCenter.default.post(name: Self.didChangePiPStatusNotification,
                                            object: self,
                                            userInfo: [
                                                Self.pipStatusKey: false,
                                                Self.pipSessionIDKey: session.sessionId
                                            ])
        }
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Logger.pip.info("\(#function)")
        observers.forEach {
            $0.pictureInPictureDidStop()
        }
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        Logger.pip.info("\(#function) \(error)")
        observers.forEach {
            $0.pictureInPictureWillStartFailed(error: error)
        }
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        Logger.pip.info("\(#function)")
        observers.forEach {
            $0.pictureInPictureRestoreUserInterface(completionHandler: completionHandler)
        }
    }
}

extension PIPManager: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        self.audioMode = myself.settings.audioMode
    }
}

extension PIPManager: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .isPiPEnabled, #available(iOS 14.2, *) {
            controller?.canStartPictureInPictureAutomaticallyFromInline = isEnabled
        }
    }
}
