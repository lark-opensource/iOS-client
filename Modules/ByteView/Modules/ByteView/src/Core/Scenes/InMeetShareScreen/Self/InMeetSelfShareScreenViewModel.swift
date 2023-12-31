//
//  InMeetSelfShareScreenViewModel.swift
//  ByteView
//
//  Created by Prontera on 2021/3/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import Action
import Reachability
import RxCocoa
import ReplayKit
import ByteViewNetwork
import ByteViewTracker
import ByteViewUI
import UniverseDesignColor
import UniverseDesignIcon

final class InMeetSelfShareScreenViewModel: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        switch change {
        case .containerWillAppear:
            if meeting.autoShareScreen {
                meeting.autoShareScreen = false
                showShareScreenAlert()
            }
        default:
            break
        }
    }

    static var isPickerViewAvailable: Bool {
        if #available(iOS 13.1, *) {
            return true
        } else if #available(iOS 13.0, *) {
            return false
        } else if #available(iOS 12.0, *) {
            return true
        } else {
            return false
        }
    }

    private static let logger = Logger.selfShareScreen
    private let disposeBag = DisposeBag()
    /// 应 PM 要求，对齐安卓，状态记录在内存中，新入会、再入会（含异常退会、切换租户及更换设备），都走默认配置
    private(set) lazy var audioSwitchOnRelay = BehaviorRelay<Bool>(value: meeting.setting.shareAudioConfig.isOpenAudioShare)
    let networkExitRelay = BehaviorRelay<Bool>(value: true)
    let meeting: InMeetMeeting
    let context: InMeetViewContext
    var shareScreenID: String?
    var meetingID: String { meeting.meetingId }
    let isShareScreenMeetingRelay: BehaviorRelay<Bool>
    let isBoxSharing: Bool
    let mySharingScreenRelay = BehaviorRelay<Bool>(value: false)
    let broadcastExtensionStateRelay = BehaviorRelay<Bool>(value: false)
    let reportInterval: TimeInterval
    var broadcastExtensionId: String { meeting.setting.broadcastExtensionId }
    private var timer: Timer?
    private lazy var pickerView: UIView? = {
        if InMeetSelfShareScreenViewModel.isPickerViewAvailable, #available(iOS 12.0, *) {
            _ = ReplayKitFixer.fixOnce
            let pickerView = ShareScreenSncWrapper.createRPSystemBroadcastPickerView(for: .shareToRoom)
            if #available(iOS 12.2, *) {
                pickerView?.preferredExtension = self.broadcastExtensionId
            }
            pickerView?.showsMicrophoneButton = false
            return pickerView
        } else {
            return nil
        }
    }()
    private var isMySharingScreen: Bool
    private lazy var logDescription = metadataDescription(of: self)

    // server推送的停止屏幕共享的类型
    enum RemoteShareScreenStatus {
        case othersStartSharing // 其它人开始共享
        case stopByHost // 失去共享权限而被主持人停止共享
        case stopSharing
    }

    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.context = resolver.viewContext
        self.isMySharingScreen = meeting.shareData.isMySharingScreen
        self.isShareScreenMeetingRelay = BehaviorRelay<Bool>(value: meeting.subType == .screenShare)
        self.isBoxSharing = meeting.setting.isBoxSharing
        self.reportInterval = TimeInterval(meeting.setting.sendShareScreenPublishInfoConfig.sendShareScreenIntervalMs / 1000)
        context.addListener(self, for: .containerWillAppear)
        meeting.shareData.addListener(self)
        DispatchQueue.global().async { [weak self] in
            self?.bindViewModel()
        }
        Self.logger.debug("init \(logDescription), isBoxSharing:\(isBoxSharing)")
        NotificationCenter.default.addObserver(self, selector: #selector(shareScreenExtensionDidStartup),
                                               name: Self.shareScreenExtensionStartup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shareScreenExtensionDidQuit),
                                               name: Self.shareScreenExtensionQuit, object: nil)
    }

    deinit {
        stopTimer()
        Self.logger.debug("deinit \(logDescription)")
    }

    lazy var stopSharingAction: CocoaAction = {
        return CocoaAction(workFactory: { [weak self] _ in
            Self.logger.info("stopSharingAction excute")
            guard let self = self else { return .empty() }
            MeetingTracksV2.trackClickStopSharingScreen(isSharingContent: self.isSharingContent,
                                                        isMinimized: false,
                                                        isMore: false)
            if self.isShareScreenMeetingRelay.value == true {
                VCTracker.post(name: .vc_meeting_finish, params: ["finish_reason": "finish_share_screen"])
                self.stopShareScreen(with: .meetingEnd)
                self.meeting.leave()
            } else {
                self.stopShareScreen(with: .shareScreenEnd)
            }
            VCTracker.post(name: .vc_meeting_sharescreen_click,
                                  params: [.click: "stop_sharing"])
            return .empty()
        })
    }()

    lazy var leftButtonAction: CocoaAction = {
        return CocoaAction(workFactory: { [weak self] _ in
            guard let self = self else {
                return .empty()
            }
            if self.isMySharingScreen {
                VCTracker.post(name: .vc_meeting_sharescreen_click,
                                      params: [.click: "minimize"])
                self.meeting.router.setWindowFloating(true)
            } else {
                VCTracker.post(name: .vc_meeting_sharescreen_click,
                                      params: [.click: "close"])
                VCTracker.post(name: .vc_meeting_finish, params: ["finish_reason": "leave_before_start_broadcast"])
                self.meeting.leave()
            }
            return .empty()
        })
    }()

    var shareScreenTitle: Driver<String> {
        return isShareScreenMeetingRelay
            .map { $0 ? I18n.View_M_NowSharingToastMirroring : I18n.View_M_NowSharingToast }
            .asDriver(onErrorJustReturn: I18n.View_M_NowSharingToast)
    }

    var stopSharingScreenTitle: Driver<String> {
        return isShareScreenMeetingRelay
            .map { $0 ? I18n.View_VM_StopSharingMirroring : I18n.View_VM_StopSharing }
            .asDriver(onErrorJustReturn: I18n.View_VM_StopSharing)
    }

    var floatingIcon: Driver<UIImage?> {
        return mySharingScreenRelay
            .asDriver(onErrorJustReturn: false)
            .map {
                UDIcon.getIconByKey(.shareScreenFilled, iconColor: $0 ? .ud.functionSuccessFillDefault : .ud.iconN3,
                                    size: CGSize(width: 32, height: 32))
            }
    }

    var floatingTitle: Driver<String> {
        return mySharingScreenRelay
            .asDriver(onErrorJustReturn: false)
            .map { $0 ? I18n.View_G_ScreenSharingToRoom : I18n.View_MV_SharingNotStarted }
    }

    private func pickerViewDidTouch() {
        VCTracker.post(name: .vc_meeting_sharescreen_click, params: [.click: "picker_view"])
        guard let pickerView = pickerView, ShareScreenSncWrapper.getCheckResult(by: .shareToRoom) else {
            Toast.showOnVCScene(I18n.View_G_FailShareForNow)
            return
        }

        for subview in pickerView.subviews {
            if let button = subview as? UIButton {
                button.sendActions(for: .allEvents)
            }
        }
    }

    private func bindViewModel() {
        bindNetworking()
        audioSwitchOnRelay
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isOn in
                Self.logger.info("audio switch isOn: \(isOn)")
                guard let self = self else { return }
                if isOn {
                    self.meeting.rtc.engine.updateScreenCapture(.videoAndAudio)
                } else {
                    self.meeting.rtc.engine.updateScreenCapture(.videoOnly)
                }
                let params: TrackParams = [.action_name: "share_device_audio", .extend_value: ["action_enabled": isOn ? 1 : 0]]
                VCTracker.post(name: .vc_meeting_page_onthecall, params: params)
            })
            .disposed(by: disposeBag)

        meeting.httpClient.send(ShareScreenRequest(meetingId: meeting.meetingId, breakoutRoomId: meeting.setting.breakoutRoomId, action: .stop))

        var requestingStatus: Bool?
        let retryRelay = BehaviorRelay<Void>(value: ())
        let timeInterval: Int = 700
        Observable.combineLatest(broadcastExtensionStateRelay,
                                 networkExitRelay.distinctUntilChanged(),
                                 mySharingScreenRelay,
                                 retryRelay.debounce(.milliseconds(timeInterval), scheduler: MainScheduler.instance))
            .filter({ (status: Bool, network: Bool, value: Bool, _) -> Bool in
                Self.logger.info("status is \(status), network is \(network), value is \(value)")
                return status != value
            })
            .map { $0.0 }
            .concatMap({ [weak self] status -> Single<(Bool, String)?> in
                guard let self = self else {
                    return .error(VCError.unknown)
                }
                guard requestingStatus != status else {
                    Self.logger.error("is already requesting")
                    return .just(nil)
                }
                // 无权限开始屏幕共享
                if status && !self.canShareContent {
                    self.stopShareScreen(with: .noPermission)
                    return .just(nil)
                }
                // 以下情况可以抢共享：当前无人共享or当前自己在共享or当前其他人在共享且自己可以抢共享
                if status && self.isSharingContent && !self.isSelfSharingContent && !self.canReplaceShareContent {
                    self.stopShareScreen(with: .noPermission)
                    return .just(nil)
                }
                let request: Single<(Bool, String)?>
                let httpClient = self.meeting.httpClient
                if status {
                    self.track(with: .request)
                    let startRequest = ShareScreenRequest(meetingId: self.meeting.meetingId, breakoutRoomId: self.meeting.setting.breakoutRoomId, action: .start)
                    request = RxTransform.single {
                        httpClient.getResponse(startRequest, completion: $0)
                    }
                    .map { (true, $0.shareScreenId) }
                    .catchError({ [weak self] error in
                        Self.logger.error("start with error: \(error)")
                        self?.stopShareScreen(with: .shareScreenEnd)
                        return .just(nil)
                    })
                } else {
                    let stopRequest = ShareScreenRequest(meetingId: self.meeting.meetingId, breakoutRoomId: self.meeting.setting.breakoutRoomId, action: .stop)
                    request = RxTransform.single {
                        httpClient.getResponse(stopRequest, completion: $0)
                    }
                    .map { (false, $0.shareScreenId) }
                    .catchError({ (error) -> Single<(Bool, String)?> in
                        Self.logger.error("stop with error: \(error)")
                        requestingStatus = nil
                        retryRelay.accept(())
                        return .just(nil)
                    })
                }
                requestingStatus = status
                return request.do(onSuccess: { _ in
                    requestingStatus = nil
                })
            })
            .compactMap { $0 }
            .flatMapLatest({ [weak self] info -> Single<Bool> in
                guard let self = self else {
                    return .error(VCError.unknown)
                }
                self.shareScreenID = info.0 ? info.1 : nil
                self.track(with: .response)
                return .just(info.0)
            })
            .subscribe(onNext: { [weak self] isSharing in
                if isSharing != self?.isMySharingScreen {
                    Util.runInMainThread {
                        self?.didChangeMySharing(isSharing)
                    }
                }
            }, onError: { error in
                Self.logger.error("start or stop with error: \(error)")
            })
            .disposed(by: disposeBag)
    }

    func bindNetworking() {
        let reachability = Reachability.shared
        reachability.notificationCenter.rx
            .notification(Notification.Name.reachabilityChanged)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.networkExitRelay.accept(ReachabilityUtil.isConnected)
            })
            .disposed(by: disposeBag)
    }

    private func reportToServerExtensionStatusWithNTP(isPublishScreen: Bool) {
        let currentTime = Int64(Date().timeIntervalSince1970 * 1000)
        self.meeting.httpClient.getResponse(GetNtpTimeRequest()) { [weak self] r in
            switch r {
            case .success(let rsp):
                self?.reportToServerExtensionStatus(isPublishScreen: isPublishScreen, timestamp: currentTime + rsp.ntpOffset)
            case .failure(let error):
                Logger.tracker.info("getNtpTime request failed, error: \(error)")
                self?.reportToServerExtensionStatus(isPublishScreen: isPublishScreen, timestamp: currentTime)
            }
        }
    }

    private func reportToServerExtensionStatus(isPublishScreen: Bool, timestamp: Int64) {
        Self.logger.info("start report extension status to server, isPublishScreen: \(isPublishScreen)")
        let request = EntrustServerTrackRequest(key: "-1", params: [:], trackType: .rtcScreenStreaming, rtcScreenStreamEvent: EntrustServerTrackRequest.RTCScreenStreamingEvent(eventType: isPublishScreen ? .startRTCPublish : .stopRTCPublish, meetingId: self.meeting.meetingId, timestamp: timestamp))
        self.meeting.httpClient.send(request)
    }

    @objc private func shareScreenExtensionDidStartup() {
        Self.logger.info("selfShareScreen shareScreenExtensionStartup")
        meeting.rtc.engine.publishScreen()
        didShareScreenExtensionStateChanged(isOn: true)
        // 向服务端打点，开始publish
        startTimer()
        // 关闭截屏录屏保护
        meeting.service.security.vcScreenCastChange(true)
    }

    @objc private func shareScreenExtensionDidQuit() {
        Self.logger.info("selfShareScreen shareScreenExtensionQuit")
        meeting.rtc.engine.unpublishScreen()
        didShareScreenExtensionStateChanged(isOn: false)
        // 向服务端打点，开始unPublish
        reportToServerExtensionStatusWithNTP(isPublishScreen: false)
        stopTimer()
        // 开启截屏录屏保护
        meeting.service.security.vcScreenCastChange(false)
    }

    private func startTimer() {
        self.stopTimer()
        let timer = Timer(timeInterval: reportInterval, repeats: true) { [weak self] (t) in
            if let self = self {
                self.reportToServerExtensionStatusWithNTP(isPublishScreen: true)
            } else {
                t.invalidate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
        self.timer = timer
    }

    private func stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }

    enum TrackAction {
        case request
        case response
        case shareScreen
    }

    func track(with action: TrackAction) {
        guard isShareScreenMeetingRelay.value else {
            return
        }
        let actionName: String
        switch action {
        case .request:
            actionName = "req_share_screen"
        case .response:
            actionName = "share_screen_result"
        case .shareScreen:
            actionName = "begin_share_screen"
        }
        var params: TrackParams = [.action_name: actionName]
        if let shareScreenID = self.shareScreenID {
            params["share_screen_id"] = shareScreenID
        }
        VCTracker.post(name: .vc_client_signal_info,
                              params: params,
                              platforms: [.plane])
    }
}

extension InMeetSelfShareScreenViewModel {

    var canShareContent: Bool { meeting.setting.canShareContent }
    var canReplaceShareContent: Bool { meeting.setting.canReplaceShareContent }
    var isSharingDocument: Bool { meeting.shareData.isSharingDocument }
    var isSharingContent: Bool { meeting.shareData.isSharingContent }
    var isSelfSharingContent: Bool { meeting.shareData.isSelfSharingContent }

    func didChangeMySharing(_ isSharing: Bool) {
        Self.logger.info("mySharingScreenRelay: \(isSharing)")
        isMySharingScreen = isSharing
        if !isSharing {
            stopShareScreen(with: .shareScreenEnd)
            if isShareScreenMeetingRelay.value {
                meeting.router.setWindowFloating(false)
            }
        }
        mySharingScreenRelay.accept(isSharing)
        meeting.shareData.setSelfSharingScreenShow(isSharing)
    }
}

extension InMeetSelfShareScreenViewModel: InMeetShareDataListener {

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        let isLocalProjection = meeting.shareData.isLocalProjection
        if isLocalProjection != isShareScreenMeetingRelay.value {
            isShareScreenMeetingRelay.accept(isLocalProjection)
        }
        if isMySharingScreen {
            let status: RemoteShareScreenStatus
            if [.othersSharingScreen, .magicShare, .shareScreenToFollow, .whiteboard].contains(newScene.shareSceneType) {
                status = .othersStartSharing
            } else if newScene.isNone && !oldScene.isNone {
                status = self.canShareContent ? .stopSharing : .stopByHost
            } else {
                return
            }
            Self.logger.info("info from push otherSharing: \(status) ")
            switch status {
            case .othersStartSharing:
                stopShareScreen(with: .otherShareScreen)
            case .stopSharing:
                stopShareScreen(with: .shareScreenEnd)
            case .stopByHost:
                stopShareScreen(with: .stoppedByHost)
            }
        }
    }

}

extension InMeetSelfShareScreenViewModel {
    func showShareScreenAlert() {
        guard !isMySharingScreen else {
            Self.logger.error("showShareScreenAlert error with mySharingScreenRelay")
            return
        }
        if Self.isPickerViewAvailable {
            pickerViewDidTouch()
        } else {
            let message = I18n.View_VM_ShareDeviceScreenDescription(Util.appName)
            ByteViewDialog.Builder()
                .title(I18n.View_VM_ShareDeviceScreen)
                .message(message)
                .rightTitle(I18n.View_G_OkButton)
                .show()
        }
    }
}

extension InMeetSelfShareScreenViewModel {
    func didShareScreenExtensionStateChanged(isOn: Bool) {
        broadcastExtensionStateRelay.accept(isOn)
        if isOn {
            self.track(with: .shareScreen)
            let audioEnable = self.audioSwitchOnRelay.value
            if audioEnable {
                meeting.rtc.engine.updateScreenCapture(.videoAndAudio)
            }
            let params: TrackParams = [.action_name: "share_device_audio", .extend_value: ["action_enabled": audioEnable ? 1 : 0]]
            VCTracker.post(name: .vc_meeting_page_onthecall, params: params)
        }
    }

    enum ShareScreenEndReason {
        case meetingEnd
        case noPermission
        case shareScreenEnd
        case otherShareScreen
        case stoppedByHost
    }

    func stopShareScreen(with reason: ShareScreenEndReason) {
        Self.logger.info("stopShareScreen reason:\(reason)")
        let reasonString: String
        switch reason {
        case .meetingEnd:
            reasonString = I18n.View_M_MeetingHasEnded
        case .shareScreenEnd:
            reasonString = I18n.View_M_ScreenSharingStopped
        case .otherShareScreen:
            reasonString = I18n.View_VM_OthersStartedSharing
        case .noPermission:
            reasonString = I18n.View_M_NoPermissionToShare
        case .stoppedByHost:
            reasonString = I18n.View_M_HostStoppedYourSharingSession
        }
        meeting.rtc.engine.sendScreenCaptureExtensionMessage(reasonString)
    }
}

private extension InMeetSelfShareScreenViewModel {
    static let shareScreenExtensionStartup = Notification.Name("kNotificationByteOnExtensionStartup")
    static let shareScreenExtensionQuit = Notification.Name("kNotificationByteOnExtensionQuit")
}
