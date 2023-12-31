//
//  LobbyViewModel.swift
//  ByteView
//
//  Created by Prontera on 2020/6/28.
//

import UIKit
import RxSwift
import RxCocoa
import Action
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import ByteViewMeeting
import AVFAudio
import UniverseDesignIcon
import LarkMedia
import ByteViewSetting
import ByteViewRtcBridge

enum LobbySource {
    case preLobby
    case inLobby
}

protocol LobbyViewModelDelegate: AnyObject {
    func speakerViewWillAppear()
    func speakerViewWillDisappear()
}

class LobbyViewModel: VCManageResultPushObserver, MeetingSettingListener, MeetingBasicServiceProvider {
    static let setCameraNotificationKey = Notification.Name(rawValue: "Byteview.Lobby.MuteMyCamera")
    static let setMicrophoneNotificationKey = Notification.Name(rawValue: "Byteview.Lobby.MuteMyMicrophone")
    static let setNotificationUserInfoKey = "isMuted"
    static let logger = Logger.ui

    var shouldShowAudioToast = false
    var isCameraMuted: Bool {
        get { isCameraMutedRelay.value }
        set {
            guard isCameraMutedRelay.value != newValue else { return }
            camera.setMuted(newValue)
            if isCameraMutedRelay.value != camera.isMuted {
                isCameraMutedRelay.accept(camera.isMuted)
            }
        }
    }

    weak var delegate: LobbyViewModelDelegate?
    var isCameraMutedObservable: Observable<Bool> { isCameraMutedRelay.asObservable() }
    let isCameraMutedRelay: BehaviorRelay<Bool>

    let isMicrophoneMuted: BehaviorRelay<Bool>
    let isPadMicSpeakerDisabled: BehaviorRelay<Bool>
    let startInfo: LobbyInfo
    let caller: Observable<ParticipantUserInfo>
    let defaultMeetSetting: MicCameraSetting
    let disposeBag = DisposeBag()
    let isJoinRoomEnabled: Bool
    let participantSettings: ParticipantSettings?
    private lazy var logDescription = metadataDescription(of: self)
    weak var hostViewController: UIViewController?
    let lobbySource: LobbySource
    let session: MeetingSession
    let joinTogetherRoomRelay = BehaviorRelay<ByteviewUser?>(value: nil)
    let camera: PreviewCameraManager
    private let audioSessionFixer = LarkAudioSession.shared.fixAudioSession([.activeOnAlarmEnd, .activeOnForeground])
    var showVirtualBgToastBehavior: BehaviorRelay<ExtraBgDownLoadStatus> = .init(value: .unStart)

    var isSetupForLab: Bool = false
    let isCamMicHidden: Bool
    var isWebinarAttendee: Bool
    let isCamOriginMuted: Bool
    var currentAudioType: PreviewAudioType
    var audioMode: ParticipantSettings.AudioMode { participantSettings?.audioMode ?? .internet}
    let service: MeetingBasicService
    let effectManger: MeetingEffectManger?
    var shouldShowAudioArrow: Bool { Display.pad || session.isE2EeMeeting || service.setting.isCallMeEnabled  }

    lazy var joinRoomVM: JoinRoomTogetherViewModel = {
        let meetingId = startInfo.meetingId
        let room = joinTogetherRoomRelay.value
        let provider = PrelobbyJoinRoomProvider(room: room, filter: .generic(.meetingId(meetingId, nil)), meetingId: meetingId, httpClient: session.httpClient)
        let vm = JoinRoomTogetherViewModel(service: service, provider: provider)
        return vm
    }()

    var prelobbyViewModel: PrelobbyContainerViewModel {
        .init(session: session, service: service, isCameraOn: !isCameraMuted, camera: camera, isWebinarAttendee: isWebinarAttendee)
    }

    init?(session: MeetingSession, lobbySource: LobbySource) {
        guard let lobbyInfo = session.lobbyInfo, let service = session.service else {
            Self.logger.error("lobbyInfo or meetSetting is nil")
            return nil
        }
        let isWebinarAttendee = {
            switch lobbySource {
            case .preLobby:
                return lobbyInfo.preLobbyParticipant?.participantMeetingRole == .webinarAttendee
            case .inLobby:
                return lobbyInfo.lobbyParticipant?.participantMeetingRole == .webinarAttendee
            }
        }()
        let isWebinar = lobbyInfo.meetingSubType == .webinar
        self.service = service
        self.isWebinarAttendee = isWebinarAttendee
        self.isCamMicHidden = isWebinarAttendee
        // 扫描会议室目前不支持webinar
        self.isJoinRoomEnabled = service.setting.isJoinRoomTogetherEnabled && !isWebinar && !session.isE2EeMeeting
        self.session = session
        self.effectManger = session.effectManger
        self.camera = PreviewCameraManager(scene: lobbySource.toCameraScene(), service: service, effectManger: session.effectManger)
        let meetSetting = session.lobbyMeetSetting(lobbyInfo)
        self.lobbySource = lobbySource
        self.defaultMeetSetting = meetSetting
        let callerSubject = ReplaySubject<ParticipantUserInfo>.create(bufferSize: 1)
        let participantService = service.httpClient.participantService
        participantService.participantInfo(pid: service.account, meetingId: service.meetingId) { ap in
            callerSubject.onNext(ap)
        }
        self.caller = callerSubject.asObservable()
        self.startInfo = lobbyInfo
        let isCameraMuted = !meetSetting.isCameraEnabled || isCamMicHidden
        self.isCamOriginMuted = isCameraMuted
        self.isCameraMutedRelay = BehaviorRelay(value: isCameraMuted)
        self.isMicrophoneMuted = BehaviorRelay(value: !meetSetting.isMicrophoneEnabled || service.setting.isMicSpeakerDisabled || isCamMicHidden)
        self.isPadMicSpeakerDisabled = BehaviorRelay(value: service.setting.isMicSpeakerDisabled)
        switch lobbySource {
        case .preLobby:
            self.joinTogetherRoomRelay.accept(lobbyInfo.preLobbyParticipant?.targetToJoinTogether)
            self.participantSettings = lobbyInfo.preLobbyParticipant?.participantSettings
        case .inLobby:
            self.joinTogetherRoomRelay.accept(lobbyInfo.lobbyParticipant?.targetToJoinTogether)
            self.participantSettings = lobbyInfo.lobbyParticipant?.participantSettings
        }
        self.currentAudioType = participantSettings?.audioMode.audioType ?? .system
        self.camera.delegate = self
        Self.logger.debug("init \(logDescription)")
        bindNotifications()
        service.push.vcManageResult.addObserver(self)
        self.setupForLab()
        labButtonHiddenRelay.accept(!service.setting.showsEffects || self.isCamMicHidden)
        service.setting.addListener(self, for: [.isVirtualBgEnabled, .isAnimojiEnabled, .showsEffects, .isMicSpeakerDisabled])
        session.audioDevice?.output.addListener(self)
        isMicrophoneMuted.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] isMuted in
            if !isMuted {
                self?.session.audioDevice?.output.setMuted(false)
            }
        }).disposed(by: disposeBag)
        joinTogetherRoomRelay.asObservable().subscribe(onNext: { [weak self] in
            self?.session.audioDevice?.output.setNoConnect($0 != nil)
        }).disposed(by: self.disposeBag)
        setupForLab()
    }

    deinit {
        Self.logger.debug("deinit \(logDescription)")
    }

    private func bindNotifications() {
        session.callCoordinator.muteCallMicrophone(muted: self.isMicrophoneMuted.value)
        NotificationCenter
            .default.rx
            .notification(LobbyViewModel.setMicrophoneNotificationKey)
            .subscribe(onNext: { [weak self] (notification: Notification) in
                guard let self = self,
                    let muted = notification.userInfo?[LobbyViewModel.setNotificationUserInfoKey] as? Bool else {
                        return
                }
                if self.isMicrophoneMuted.value != muted {
                    // 处理 CallKit 场景，CallKit 处已经埋了摄像头事件埋点，这里不用重复埋了
                    self.handleMicrophone()
                }
            })
            .disposed(by: disposeBag)

        NotificationCenter
            .default.rx
            .notification(LobbyViewModel.setCameraNotificationKey)
            .subscribe(onNext: { [weak self] (notification: Notification) in
                guard let self = self,
                    let muted = notification.userInfo?[LobbyViewModel.setNotificationUserInfoKey] as? Bool else {
                        return
                }
                if self.isCameraMuted != muted {
                    self.handleCamera()
                }
            })
            .disposed(by: disposeBag)
    }

    func didReceiveManageResult(_ message: VCManageResult) {
        if message.meetingID == session.meetingId, message.type == .meetinglobby || message.type == .meetingprelobby {
            session.log("didReceiveLobbyAction: \(message.action)")
            switch message.action {
            case .hostallowed, .meetingStart:
                Util.runInMainThread { [weak self] in
                    self?.shouldShowAudioToast = false
                    self?.joinMeeting()
                }
            default:
                break
            }
        }
    }

    private let labButtonHiddenRelay = BehaviorRelay<Bool>(value: true)
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if effectManger?.virtualBgService.calendarMeetingVirtual == nil {  // 防止admin数据比associate来的晚
            self.setupForLab()
        }
        if key == .showsEffects {
            labButtonHiddenRelay.accept(!settings.showsEffects || self.isCamMicHidden)
        } else if key == .isMicSpeakerDisabled {
            isPadMicSpeakerDisabled.accept(isOn)
        }
    }

    func muteMicrophone(_ isMuted: Bool) {
        session.callCoordinator.muteCallMicrophone(muted: isMuted)
        var request = UpdateLobbyParticipantRequest(meetingId: session.meetingId)
        request.isMicrophoneMuted = isMuted
        httpClient.send(request)
        isMicrophoneMuted.accept(isMuted)
    }
}

extension LobbyViewModel: EffectVirtualBgCalendarListener, EffectPretendCalendarListener {

    func setupForLab() {
        guard !isSetupForLab, setting.isVirtualBgEnabled || setting.isAnimojiEnabled, let effectManger = effectManger, effectManger.virtualBgService.calendarMeetingVirtual == nil else {
            return
        }
        Self.logger.debug("lobby setupForLab \(session.videoChatInfo?.meetingSource)")
        isSetupForLab = true

        effectManger.getForCalendarSetting(meetingId: session.meetingId, uniqueId: nil, isWebinar: nil, isUnWebinarAttendee: !self.isWebinarAttendee)
        effectManger.virtualBgService.addCalendarListener(self, fireImmediately: true)
        effectManger.pretendService.addCalendarListener(self, fireImmediately: true)
    }

    private func handleVirtualBgAllowInLobby(allowInfo: AllowVirtualBgRelayInfo) {
        Self.logger.debug("lobby setupForLab \(allowInfo.allow) \(!self.isCameraMuted) \(effectManger?.virtualBgService.currentVirtualBgsModel?.bgType != .setNone)")
        if !allowInfo.allow, !self.isCameraMuted, allowInfo.hasUsedBgInAllow == true {  // 不允许+摄像头打开+使用了虚拟背景
            self.handleCamera() // 先mute再去背景，保证隐私
            self.camera.effect.enableBackgroundBlur(false)
            self.camera.effect.setBackgroundImage("")
            Toast.hideAllToasts()
            Toast.show(I18n.View_G_DisallowBackCamAutoOff)
        } // 否则打开的时候再处理
    }

    private func handleVirtualBgAllowPreLobby(allowInfo: AllowVirtualBgRelayInfo) {
        Self.logger.debug("lobby handle bg AllowPreLobby \(allowInfo)")
        if !allowInfo.allow {
            self.camera.effect.enableBackgroundBlur(false)
            self.camera.effect.setBackgroundImage("")
            if let hasUsedBgInAllow = allowInfo.hasUsedBgInAllow, hasUsedBgInAllow {
                Toast.show(I18n.View_G_HostNotAllowBackUse)
                self.effectManger?.virtualBgService.hasShowedNotAllowToast = true
            }
        }
    }

    func didChangeExtrabgDownloadStatus(status: ExtraBgDownLoadStatus) {

        Logger.effectBackGround.info("------------------1 \(status)")

        self.showVirtualBgToastBehavior.accept(status)
    }

    func didChangeVirtualBgAllow(allowInfo: AllowVirtualBgRelayInfo) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            if self.lobbySource == .preLobby {
                self.handleVirtualBgAllowPreLobby(allowInfo: allowInfo)
            } else if self.lobbySource == .inLobby {
                self.handleVirtualBgAllowInLobby(allowInfo: allowInfo)
            }
        }
    }

    func didChangeAnimojAllow(isAllow: Bool) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            Logger.effectPretend.debug("lobby handle animoji AllowPreLobby \(isAllow), \(self.effectManger?.pretendService.isAnimojiOn())")
            if !isAllow, self.effectManger?.pretendService.isAnimojiOn() == true {
                self.effectManger?.pretendService.cancelAnimoji()
            }
        }
    }
}

extension LobbyViewModel {
    var floatVM: FloatingPreMeetVM {
        FloatingPreMeetVM(session: self.session,
                          service: self.service,
                          avatarInfo: avatarInfo,
                          topic: .just(""),
                          meetingStatus: .just(""),
                          overlayStatus: .just(I18n.View_M_WaitingEllipsis),
                          isCameraMutedRelay: isCameraMutedRelay,
                          meetingID: self.startInfo.meetingId)
    }
}


extension LobbyViewModel {
    var labButtonHidden: Driver<Bool> {
        labButtonHiddenRelay.asDriver()
    }

    func clickLab(from: UIViewController) {
        guard let service = session.service, let effect = session.effectManger else { return }
        let name: TrackEventName = self.lobbySource == .preLobby ? .vc_pre_waitingroom : .vc_meeting_page_waiting_rooms
        VCTracker.post(name: name, params: [.action_name: "effect"])
        if self.lobbySource == .preLobby {
            VCTracker.post(name: .vc_meeting_pre_click,
                           params: [.click: "labs_setting",
                                    .is_starting_auth: true])
        }
        let viewModel = InMeetingLabViewModel(service: service, effectManger: effect, fromSource: lobbySource == .preLobby ? .preLobby : .inLobby)
        let viewController = InMeetingLabViewController(viewModel: viewModel)
        viewController.location = lobbySource == .inLobby ? .lobby : .preLobby
        router.presentDynamicModal(viewController,
                                   regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                   compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true),
                                   from: from)
    }
}

extension LobbyViewModel: AudioOutputListener {
    func didChangeAudioOutput(_ output: AudioOutputManager, reason: AudioOutputChangeReason) {
        if output.isDisabled || output.isMuted, !isMicrophoneMuted.value {
            muteMicrophone(true)
        }
        if !UltrawaveManager.shared.isRecvingUltrawave, shouldShowAudioToast {
            output.showToast(in: self.hostViewController?.view)
        }
    }

    func audioOutputPickerWillAppear() {
        delegate?.speakerViewWillAppear()
    }

    func audioOutputPickerWillDisappear() {
        delegate?.speakerViewWillDisappear()
    }

    func audioOutputPickerDidAppear() {
        delegate?.speakerViewWillAppear()
    }

    func audioOutputPickerDidDisappear() {
        delegate?.speakerViewWillDisappear()
    }
}

extension LobbyViewModel: PreviewCameraDelegate {
    func cameraNeedShowToast(_ camera: PreviewCameraManager, content: PreviewCameraManager.ToastContent) {
        Toast.showOnVCScene(content.localizedDescription)
    }

    func cameraWasInterrupted(_ camera: PreviewCameraManager) {
        handleInterruption(isMuted: true)
    }

    func cameraInterruptionEnded(_ camera: PreviewCameraManager) {
        handleInterruption(isMuted: camera.isMuted)
    }

    private func handleInterruption(isMuted: Bool) {
        self.isCameraMutedRelay.accept(isMuted)
        LobbyTracks.trackCameraStatusOfLobby(muted: isMuted)
        var request = UpdateLobbyParticipantRequest(meetingId: session.meetingId)
        request.isCameraMuted = isMuted
        httpClient.send(request)
    }

    func didFailedToStartVideoCapture(error: Error) {
        isCameraMuted = true
    }
}

private extension LobbySource {
    func toCameraScene() -> RtcCameraScene {
        switch self {
        case .preLobby:
            return .prelobby
        case .inLobby:
            return .lobby
        }
    }
}

private extension MeetingSession {
    func lobbyMeetSetting(_ lobbyInfo: LobbyInfo) -> MicCameraSetting {
        var settings = localSetting
        if lobbyInfo.isBeMovedIn {
            settings.isMicrophoneEnabled = lobbyInfo.lobbyParticipant?.isMicrophoneMuted == false
            settings.isCameraEnabled = lobbyInfo.lobbyParticipant?.isCameraMuted == false
        } else if let myself = lobbyInfo.lobbyParticipant {
            // 服务端只记录麦克风和摄像头，并没有记录扬声器
            if let isMicrophoneMuted = myself.isMicrophoneMuted, !isMicrophoneMuted {
                settings.isMicrophoneEnabled = true
            }
            if let isCameraMuted = myself.isCameraMuted, !isCameraMuted {
                settings.isCameraEnabled = true
            }
        }
        return settings
    }
}

//extension BehaviorRelay<ExtraBgDownLoadStatus> {
//    func bindExtraVirtualBgToast(toastContainer: UIView, toastAnchor: UIView, disposeBag: DisposeBag) {
//        self.distinctUntilChanged()
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { status in
//                guard LabVirtualBgService.shared?.calendarMeetingVirtual?.hasExtraBg == true else { return }
//                Logger.ui.info("showVirtualBgToastBehavior \(status)")
//                if status == .done, !toastAnchor.isHidden {
//                    let anchorToastView = AnchorToastView()
//                    toastContainer.addSubview(anchorToastView)
//                    anchorToastView.snp.makeConstraints { make in
//                        make.edges.equalToSuperview()
//                    }
//                    anchorToastView.setStyle(I18n.View_G_UniSetYouCanChange, on: .bottom, of: toastAnchor, distance: 4, defaultEnoughInset: 8)
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                        anchorToastView.removeFromSuperview()
//                    }
//                }
//            })
//            .disposed(by: disposeBag)
//    }
//}
