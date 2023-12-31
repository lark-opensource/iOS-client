//
// Created by liujianlong on 2022/9/27.
//

import Foundation
import RxSwift
import ByteViewNetwork
import RxRelay
import ByteViewMeeting
import ByteViewTracker
import ByteViewCommon
import ByteViewUI
import ByteViewSetting
import UniverseDesignToast

protocol WebinarRoleListener: AnyObject {
    func webinarDidChangeRole(isAttendee: Bool, oldValue: Bool?)
    func webinarDidChangeRehearsal(isRehearsing: Bool, oldValue: Bool?)
    func webinarDidChangeStageInfo(stageInfo: WebinarStageInfo?, oldValue: WebinarStageInfo?)
    func webinarDidChangeTransitionState(isTransitioning: Bool)
}

extension WebinarRoleListener {
    func webinarDidChangeRole(isAttendee: Bool, oldValue: Bool?) {}
    func webinarDidChangeRehearsal(isRehearsing: Bool, oldValue: Bool?) {}
    func webinarDidChangeStageInfo(stageInfo: WebinarStageInfo?, oldValue: WebinarStageInfo?) {}
    func webinarDidChangeTransitionState(isTransitioning: Bool) {}
}

extension Logger {
    static let webinarRehearsal = getLogger("WebinarRehearsal")
    static let webinarRole = getLogger("WebinarRole")
    static let webinarPanel = getLogger("WebinarPanel")
    static let webinarStage = getLogger("WebinarStage")
}

extension InMeetMeeting {
    var isWebinarAttendee: Bool {
        self.webinarManager?.isWebinarAttendee ?? false
    }
    var isWebinarRehearsing: Bool {
        self.webinarManager?.isRehearsing ?? false
    }
}

enum WebinarState {
    case isWebinarAttendee(AttendeeState)
    case isWebinarPanellist(PanelListState)
    case transitioningToWebinarAttendee(PanelListState)
    case transitioningToWebinarPanellist(AttendeeState)

    struct AttendeeState {
        var isAskingUnmute = false
        var isAskingBecomeParticipant = false
    }

    struct PanelListState {
    }

    struct TransitioningToWebinarAttendeeState {
    }

    struct TransitioningToWebinarPanelListState {
    }
}

final class InMeetWebinarManager: MeetingBasicServiceProvider {
    let meetingID: String
    let session: MeetingSession
    weak var meeting: InMeetMeeting?
    let disposeBag = DisposeBag()

    @RwAtomic
    private var transitionStartTime: Date?

    private let listeners = Listeners<WebinarRoleListener>()

    private let testQueueKey = DispatchSpecificKey<Void>()
    private lazy var queue: DispatchQueue = {
        let queue = DispatchQueue(label: "lark.byteview.webinar")
        queue.setSpecific(key: self.testQueueKey, value: ())
        return queue
    }()
    private func assertOnQueue() {
        assert(DispatchQueue.getSpecific(key: self.testQueueKey) != nil)
    }

    private var state: WebinarState

    @RwAtomic
    private(set) var isRehearsing: Bool {
        didSet {
            guard self.isRehearsing != oldValue else {
                return
            }
            Logger.webinarRehearsal.info("isRehearsingChanged \(oldValue) -> \(self.isRehearsing)")
            self.listeners.forEach { listener in
                listener.webinarDidChangeRehearsal(isRehearsing: self.isRehearsing, oldValue: oldValue)
            }
            if !isRehearsing {
                // 请求返回前，rust 推送的彩排状态信息不准确，此时校准会议时长会有问题
                self.meeting?.updateStartTime()
            }
        }
    }

    @RwAtomic
    private(set) var stageInfo: WebinarStageInfo? {
        didSet {
            guard self.stageInfo != oldValue else {
                return
            }
            self.listeners.forEach { listener in
                listener.webinarDidChangeStageInfo(stageInfo: self.stageInfo, oldValue: oldValue)
            }
        }
    }

    @RwAtomic
    private(set) var isWebinarAttendee: Bool {
        didSet {
            guard self.isWebinarAttendee != oldValue else {
                return
            }
            Logger.webinarRole.info("role changed isWebinarAttendee: \(oldValue) -> \(self.isWebinarAttendee)")
            self.listeners.forEach { listener in
                listener.webinarDidChangeRole(isAttendee: isWebinarAttendee, oldValue: oldValue)
            }
        }
    }

    // 是否正在转场: WebinarRoleTransitionBody弹出后为true，InMeetBody弹出后为false
    @RwAtomic
    private(set) var isTransitioning: Bool = false {
        didSet {
            guard self.isTransitioning != oldValue else {
                return
            }
            Logger.webinarRole.info("Webinar is transitioning: \(self.isTransitioning)")
            self.listeners.forEach { listener in
                listener.webinarDidChangeTransitionState(isTransitioning: self.isTransitioning)
            }
        }
    }

    let service: MeetingBasicService

    init?(session: MeetingSession) {
        guard let myself = session.myself, session.videoChatInfo != nil, let service = session.service else {
            return nil
        }
        self.service = service
        self.meetingID = session.meetingId
        self.session = session
        self.isRehearsing = service.setting.isWebinarRehearsing
        if myself.meetingRole == .webinarAttendee {
            self.isWebinarAttendee = true
            self.state = .isWebinarAttendee(WebinarState.AttendeeState())
            showWebinarAttendeeOnbarding()
        } else {
            self.isWebinarAttendee = false
            self.state = .isWebinarPanellist(WebinarState.PanelListState())
        }
        Logger.webinarRole.info("webinar join meeting role: \(myself.meetingRole)")
    }

    func setup(meeting: InMeetMeeting,
               data: InMeetDataManager) {
        self.meeting = meeting
        data.addListener(self)
        meeting.push.notifyVideoChat.addObserver(self)
        self.session.addMyselfListener(self)
    }

    func addListener(_ listener: WebinarRoleListener, fireImmediately: Bool = true) {
        self.listeners.addListener(listener)
        if fireImmediately {
            listener.webinarDidChangeRole(isAttendee: self.isWebinarAttendee, oldValue: nil)
            listener.webinarDidChangeRehearsal(isRehearsing: isRehearsing, oldValue: nil)
            listener.webinarDidChangeStageInfo(stageInfo: self.stageInfo, oldValue: nil)
        }
    }

    private func handleBecomeAttendeeVideoChatInfo(_ info: VideoChatInfo) {
        assertOnQueue()
        guard case .isWebinarPanellist(let inner) = self.state else {
            switch self.state {
            case .isWebinarAttendee, .transitioningToWebinarAttendee:
                break
            case .transitioningToWebinarPanellist:
                Logger.webinarRole.error("receive become attendee push while transitioning to panellist")
            case .isWebinarPanellist:
                assertionFailure()
            }
            return
        }
        self.state = .transitioningToWebinarAttendee(inner)
        Logger.webinarRole.info("notify become webinarAttendee")
        let body = WebinarRoleTransitionBody(meetingId: self.meetingID, isWebinarAttendee: true, webinarManager: self)
        self.session.service?.router.startRoot(body) { [weak self] _, _  in
            // 麦克风、摄像头相关的弹窗都需要消失
            let dismissIDs: Set<ByteViewUI.ByteViewDialogIdentifier> = [
                .hostRequestMicrophone, .hostRequestCamera,
                .micHandsUp, .micHandsDown,
                .cameraHandsUp, .cameraHandsDown,
                .unmuteAlert, .muteMicrophoneForAll
            ]
            ByteViewDialogManager.shared.dismiss(ids: dismissIDs)
            self?.transitionStartTime = Date()
            self?.isTransitioning = true
        }
        // 等待 mute 接口返回再调用 join 接口，避免后端 join 请求竞争锁失败
        self.muteSelfBeforeTransition { [weak self] in
            self?.join(isWebinarAttendee: true)
        }
    }

    private func handleJoinSucceed(_ videoChatInfo: VideoChatInfo, isWebinarAttendee: Bool) {
        assertOnQueue()
        guard let meeting = self.meeting else {
            return
        }

        guard let newMySelf = videoChatInfo.participants.first(withUser: meeting.account),
              isWebinarAttendee == (newMySelf.meetingRole == .webinarAttendee) else {
            Logger.webinarRole.error("Webinar change role failed: expected isWebinarAttendee = \(isWebinarAttendee), get \(videoChatInfo.participants.first(withUser: meeting.account)?.meetingRole)")
            return
        }

        if videoChatInfo.id != meeting.meetingId {
            Logger.webinarRole.error("webinar meetingID changed \(meeting.meetingId) --> \(videoChatInfo.id)")
        }

        Logger.webinarRole.info("after join, webinar role \(newMySelf.meetingRole), rtcMode: \(newMySelf.settings.rtcMode), attendeeSettings: \(newMySelf.settings.attendeeSettings)")

        if isWebinarAttendee {
            switch self.state {
            case .transitioningToWebinarAttendee:
                self.state = .isWebinarAttendee(WebinarState.AttendeeState())
                self.isWebinarAttendee = isWebinarAttendee
                if let mySelfNotifier = session.component(for: MyselfNotifier.self) {
                    mySelfNotifier.update(newMySelf, fireListeners: true)
                }
                httpClient.send(TrigPushFullMeetingInfoRequest(), options: .retry(3, owner: self))
                let body = InMeetBody(meeting: meeting)
                meeting.router.startRoot(body, completion: { [weak self] _, _ in
                    self?.showWebinarAttendeeOnbarding()
                    self?.isTransitioning = false
                })
            case .isWebinarAttendee, .isWebinarPanellist, .transitioningToWebinarPanellist:
                Logger.webinarRole.error("inconsistent state transition")
            }
        } else {
            switch self.state {
            case .transitioningToWebinarPanellist(let inner):
                DispatchQueue.main.async {
                    if inner.isAskingBecomeParticipant {
                        ByteViewDialogManager.shared.dismiss(ids: [.webinarAttendeeBecomeParticipant])
                    }
                    if inner.isAskingUnmute {
                        ByteViewDialogManager.shared.dismiss(ids: [.webinarAttendeeAskedUnmute])
                    }
                }
                self.state = .isWebinarPanellist(WebinarState.PanelListState())
                self.isWebinarAttendee = isWebinarAttendee
                if let mySelfNotifier = session.component(for: MyselfNotifier.self) {
                    mySelfNotifier.update(newMySelf, fireListeners: true)
                }
                httpClient.send(TrigPushFullMeetingInfoRequest(), options: .retry(3, owner: self))
                let body = InMeetBody(meeting: meeting)
                meeting.router.startRoot(body) { [weak self] _, _ in
                    self?.isTransitioning = false
                }
            case .isWebinarAttendee, .isWebinarPanellist, .transitioningToWebinarAttendee:
                Logger.webinarRole.error("inconsistent state transition")
            }
        }
    }

    private func handleAcceptUnmute(accept: Bool) {
        assertOnQueue()
        guard case .isWebinarAttendee(var inner) = self.state,
              inner.isAskingUnmute else {
            return
        }
        Logger.webinarRole.info("acceptUnmute \(accept)")
        inner.isAskingUnmute = false
        self.state = .isWebinarAttendee(inner)

        InMeetWebinarTracks.PopupClick.acceptHostRequestUnmute(accept: accept)
        if !accept {
            var request = ParticipantChangeSettingsRequest(meetingId: self.meetingID, breakoutRoomId: nil, role: .webinarAttendee)
            request.participantSettings.attendeeSettings = WebinarAttendeeSettings(unmuteOffer: false)
            httpClient.send(request)
        } else {
            DispatchQueue.main.async {
                if let setting = self.session.setting, setting.isMicSpeakerDisabled {
                    setting.updateSettings({ $0.isMicSpeakerDisabled = false })
                }
                self.meeting?.microphone.muteMyself(false, source: .webinar_attendee_unmute, requestByHost: true, completion: nil)
            }
        }
    }


    private func handleHostRequestUnmute() {
        assertOnQueue()
        guard case .isWebinarAttendee(var inner) = self.state,
              !inner.isAskingUnmute else {
            return
        }
        Logger.webinarRole.info("requestUnmute")
        inner.isAskingUnmute = true
        self.state = .isWebinarAttendee(inner)

        Util.runInMainThread {
            let isHandsUp = self.session.myself?.settings.conditionEmojiInfo?.isHandsUp == true
            let title = isHandsUp ? I18n.View_G_HostAllowMicRequest : I18n.View_M_HostMicRequestTitle
            InMeetWebinarTracks.PopupView.hostRequestUnmute()
            ByteViewDialog.Builder()
                    .id(.webinarAttendeeAskedUnmute)
                    .needAutoDismiss(true)
                    .title(title)
                    .message(I18n.View_G_AllowMicRequestWillHear)
                    .leftTitle(I18n.View_M_StayMuted)
                    .leftHandler({ [weak self] _ in
                        guard let self = self else {
                            return
                        }
                        self.queue.async {
                            self.handleAcceptUnmute(accept: false)
                        }
                    })
                    .rightTitle(I18n.View_G_Unmute_CallComes)
                    .rightHandler({ [weak self] _ in
                        guard let self = self else {
                            return
                        }
                        self.queue.async {
                            self.handleAcceptUnmute(accept: true)
                        }
                    })
                    .show()
        }
    }

    private func handleAcceptBecomeParticipant(accept: Bool) {
        assertOnQueue()
        guard case .isWebinarAttendee(var inner) = self.state,
              inner.isAskingBecomeParticipant else {
            return
        }
        inner.isAskingBecomeParticipant = false
        self.state = .isWebinarAttendee(inner)

        InMeetWebinarTracks.PopupClick.acceptHostRequestBecomeParticipant(accept: accept)
        if accept {
            if inner.isAskingUnmute {
                inner.isAskingUnmute = false
                DispatchQueue.main.async {
                    ByteViewDialogManager.shared.dismiss(ids: [.webinarAttendeeAskedUnmute])
                }
            }
            self.state = .transitioningToWebinarPanellist(inner)
            let body = WebinarRoleTransitionBody(meetingId: self.meetingID, isWebinarAttendee: false, webinarManager: self)
            self.session.service?.router.startRoot(body) { [weak self] _, _  in
                self?.transitionStartTime = Date()
                self?.isTransitioning = true
            }
            // 等待 mute 接口返回再调用 join 接口，避免后端 join 请求竞争锁失败
            self.muteSelfBeforeTransition { [weak self] in
                self?.join(isWebinarAttendee: false)
            }
        } else {
            var request = ParticipantChangeSettingsRequest(meetingId: self.meetingID, breakoutRoomId: nil, role: .webinarAttendee)
            request.participantSettings.attendeeSettings = WebinarAttendeeSettings(becomeParticipantOffer: false)
            httpClient.send(request)
        }
    }

    private func handleHostRequestBecomeParticipant() {
        assertOnQueue()
        guard case .isWebinarAttendee(var inner) = self.state,
              !inner.isAskingBecomeParticipant else {
            return
        }
        inner.isAskingBecomeParticipant = true
        self.state = .isWebinarAttendee(inner)
        Logger.webinarRole.info("requestBecomeParticipant")
        Util.runInMainThread {
            InMeetWebinarTracks.PopupView.webinarInviteToBePanelist()
            ByteViewDialog.Builder()
                    .id(.webinarAttendeeBecomeParticipant)
                    .needAutoDismiss(true)
                    .title(I18n.View_G_HostInviteYouPanelist)
                    .message(I18n.View_G_PanelistCanDo)
                    .leftTitle(I18n.View_G_ContinueAsAttendee)
                    .leftHandler({ [weak self] _ in
                        guard let self = self else {
                            return
                        }
                        Logger.webinarRole.info("reject become participant")
                        self.queue.async {
                            self.handleAcceptBecomeParticipant(accept: false)
                        }
                    })
                    .rightTitle(I18n.View_G_ChangeToPanelist)
                    .rightHandler({ [weak self] _ in
                        guard let self = self, self.isWebinarAttendee else {
                            return
                        }
                        Logger.webinarRole.info("accept become participant")
                        self.queue.async {
                            self.handleAcceptBecomeParticipant(accept: true)
                        }
                    })
                    .show()
        }
    }
    private func join(isWebinarAttendee: Bool) {
        Logger.webinarRole.info("join meeting with isWebinarAttendee \(isWebinarAttendee)")
        var params = JoinMeetingParams(joinType: .meetingId(self.meetingID, nil),
                                       meetSetting: MicCameraSetting(isMicrophoneEnabled: false, isCameraEnabled: false))
        if !isWebinarAttendee {
            params.webinarAttendeeBecomeParticipant = true
        }
        httpClient.meeting.joinMeeting(params: params) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let (attachInfo, error)):
                if let videoChatInfo = attachInfo?.videoChatInfo {
                    // 目前 嘉宾 <-> 观众 身份切换时的转场时间较短，说明文案来不及看完，将转场时间加长，调整为 2s；
                    //（至少为 2s，若转场在 2s 内没完成，则按实际时间来转场）
                    let miniTransitionInterval = 2.0
                    var afterInterval = 0.0
                    if let startTime = self.transitionStartTime {
                        let transitionDuration = Date().timeIntervalSince1970 - startTime.timeIntervalSince1970
                        afterInterval = transitionDuration >= miniTransitionInterval ? 0.0 : miniTransitionInterval - transitionDuration
                        self.transitionStartTime = nil
                    }
                    self.queue.asyncAfter(deadline: .now() + .milliseconds(Int(afterInterval * 1000))) {
                        self.handleJoinSucceed(videoChatInfo, isWebinarAttendee: isWebinarAttendee)
                    }
                } else if attachInfo?.lobbyInfo != nil, let videoChatInfo = self.session.videoChatInfo {
                    Logger.webinarRole.error("webinar change role join failed, receive lobby \(error)")
                    let dep = self.session.service?.currentMeetingDependency()
                    self.session.leave(.forceExit) { _ in
                        if let dep = dep {
                            MeetingManager.shared.startMeeting(.rejoin(RejoinParams(info: videoChatInfo, type: .registerClientInfo)), dependency: dep, from: nil)
                        }
                    }
                } else {
                    Logger.webinarRole.error("webinar change role join failed \(error)")
                    self.session.leave(.forceExit)
                }
            case .failure(let error):
                Logger.webinarRole.error("webinar change role join failed \(error)")
                self.session.leave(.forceExit)
            }
        }
    }

    func rejoin(isWebinarAttendee: Bool) {
        let videoChatInfo = self.session.videoChatInfo
        let dep = self.session.service?.currentMeetingDependency()
        self.session.leave(.forceExit) { _ in
            if let info = videoChatInfo, let dep = dep {
                MeetingManager.shared.startMeeting(.rejoin(RejoinParams(info: info, type: .registerClientInfo)), dependency: dep, from: nil)
            }
        }
    }


    /// 结束彩排模式，并开启正式会议
    func startWebinarFromRehearsal() {
        Logger.webinarRehearsal.info("startWebinarFromRehearsal")

        /// 结束彩排模式，并开启正式会议
        var request = HostManageRequest(action: .webinarSettingChange, meetingId: self.meetingID)
        request.webinarSettings = WebinarSettings(attendeePermission: nil,
                                                  maxAttendeeNum: nil,
                                                  rehearsalStatus: .end)
        self.httpClient.send(request) { r in
            switch r {
            case .failure(let err):
                Logger.webinarRehearsal.error("endRehearsal failed: \(err)")
            default:
                break
            }
        }
    }

    private func muteSelfBeforeTransition(completion: @escaping () -> Void) {
        if let meeting = self.meeting,
           meeting.shareData.isMySharingScreen {
            meeting.shareData.setSelfSharingScreenShow(false)
            meeting.rtc.engine.sendScreenCaptureExtensionMessage(I18n.View_M_NoPermissionToShare)
        }
        DispatchQueue.main.async {
            guard let meeting = self.meeting else {
                completion()
                return
            }
            meeting.camera.muteMyself(true, source: .webinar_change_role, showToastOnSuccess: !meeting.camera.isMuted, completion: nil)
            Logger.webinarRole.info("mute self before transition")
            meeting.microphone.muteMyself(true, source: .webinar_change_role, showToastOnSuccess: !meeting.microphone.isMuted) { _ in
                Logger.webinarRole.info("mute self completed")
                completion()
            }
        }
    }

    private func showWebinarAttendeeOnbarding() {
        guard service.shouldShowGuide(.webinarAttendee) else { return }
        let guide = GuideDescriptor(type: .webinarAttendee,
                                    title: nil,
                                    desc: I18n.View_G_RaiseHandOnboardWebinar)
        guide.style = .plain
        guide.sureAction = { [weak self] in
            self?.service.didShowGuide(.webinarAttendee)
        }
        GuideManager.shared.request(guide: guide)
        VCTracker.post(name: .vc_meeting_popup_view, params: ["content": "webinar_audience_onboarding"])
    }
}

extension InMeetWebinarManager: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        guard let attendeeSettings = myself.settings.attendeeSettings else {
            return
        }
        if attendeeSettings.becomeParticipantOffer == true {
            self.queue.async {
                self.handleHostRequestBecomeParticipant()
            }
        }
        if attendeeSettings.unmuteOffer == true {
            self.queue.async {
                self.handleHostRequestUnmute()
            }
        }

    }
}

extension InMeetWebinarManager: InMeetDataListener {
    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        self.queue.async {
            self.isRehearsing = inMeetingInfo.meetingSettings.webinarSettings?.rehearsalStatus == .on
            if let stageInfo = inMeetingInfo.stageInfo {
                // 开启过舞台模式后， stageInfo 一定不为空
                // 嘉宾<-->观众角色切换时，RustSDK 拉到的 InMeetingInfo 不全，可能没有 stageInfo，需要忽略这次推送
                self.updateWebinarStageInfo(newStageInfo: stageInfo)
            }
        }
    }
}

extension InMeetWebinarManager: NotifyVideoChatPushObserver {
    func didNotifyVideoChat(_ info: VideoChatInfo) {
        guard let selfParticipant = info.participant(byUser: session.account),
              selfParticipant.status == .onTheCall,
              selfParticipant.meetingRole == .webinarAttendee else {
            return
        }
        self.queue.async {
            self.handleBecomeAttendeeVideoChatInfo(info)
        }
    }
}


extension InMeetWebinarManager {

    func loadStageBackground(webinarStageInfo: WebinarStageInfo, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = webinarStageInfo.backgroundURL else {
            completion(.failure(VCError.unknown))
            return
        }
        var req = GetVirtualBackgroundRequest(sets: [.init(name: "", url: url)], fromLocal: false)
        req.bizType = .bizWebinarStage
        let startTime = CFAbsoluteTimeGetCurrent()
        httpClient.getResponse(req) { r in
            if case .failure(let e) = r {
                Logger.webinarStage.error("failed downloading stage background \(webinarStageInfo.version): \(e)")
            }
            completion(r.flatMap { rsp in
                guard let path = rsp.infos.first?.path,
                      !path.isEmpty else {
                    return .failure(VCError.unknown)
                }
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                Logger.webinarStage.info("download stage bg cost \(duration)")
                return .success(path)
            })
        }

    }

    private func updateWebinarStageInfo(newStageInfo: WebinarStageInfo) {
        guard self.stageInfo != newStageInfo else {
            return
        }
        let oldStageInfo = self.stageInfo
        Logger.webinarStage.info("stageInfoChanged: \(oldStageInfo) --> \(newStageInfo)")

        showStageToastIfNeeded(newStageInfo: newStageInfo, oldValue: oldStageInfo)
        if Self.stageIsSync(stageInfo: newStageInfo) {
            self.stageInfo = newStageInfo
        } else {
            self.stageInfo = nil
        }
    }

    private static func stageIsSync(stageInfo: WebinarStageInfo?) -> Bool {
        if let info = stageInfo,
           info.actionV2 == .sync {
            return true
        } else {
            return false
        }
    }

    private func dismissToastWhenOrientationChanged(toast: UDToast) {
        InMeetOrientationToolComponent.isLandscapeOrientationRelay
            .filter({ $0 })
            .take(1)
            .subscribe(onNext: { [weak toast] _ in
                toast?.remove()
            })
            .disposed(by: self.disposeBag)
    }

    private func showStageToastIfNeeded(newStageInfo: WebinarStageInfo?, oldValue: WebinarStageInfo?) {
        if Self.stageIsSync(stageInfo: newStageInfo) && !Self.stageIsSync(stageInfo: oldValue),
           let newStageInfo = newStageInfo {
            self.meeting?.disableAudioToastFor(interval: .seconds(2))
            // 开启舞台模式
            if newStageInfo.guests.contains(self.session.account),
               let syncUser = newStageInfo.syncUser {
                // {{name}}正在同步舞台，并将你移上舞台
                self.meeting?.httpClient.participantService.participantInfo(pid: syncUser,
                                                                            meetingId: meetingID,
                                                                            completion: { pInfo in
                    Toast.show(I18n.View_G_SyncMoveYou(pInfo.name))
                })
            } else if !self.isWebinarAttendee,
                      let syncUser = newStageInfo.syncUser {
                // {{name}}正在同步舞台
                self.meeting?.httpClient.participantService.participantInfo(pid: syncUser,
                                                                            meetingId: meetingID,
                                                                            completion: { [weak self] pInfo in
                    Util.runInMainThread {
                        if Display.phone && !VCScene.isLandscape, let self = self,
                           let view = self.session.service?.router.window,
                            !(self.meeting?.shareData.isSelfSharingScreen ?? false),
                           let setting = self.session.setting, setting.canOrientationManually {
                            let toast = UDToast.showTips(with: I18n.View_G_NameSyncRecGoHorizontal(pInfo.name),
                                                                operationText: I18n.View_G_Switch,
                                                                on: view,
                                                                delay: 6.0) { _ in
                                UIDevice.updateDeviceOrientationForViewScene(to: .landscapeRight)
                            }
                            self.dismissToastWhenOrientationChanged(toast: toast)
                        } else {
                            Toast.show(I18n.View_G_NameSyncStage(pInfo.name))
                        }
                    }
                })
            } else {
                // 主持人正在同步舞台
                Util.runInMainThread { [weak self] in
                    if Display.phone && !VCScene.isLandscape,
                       let self = self,
                       let view = self.session.service?.router.window,
                       !(self.meeting?.shareData.isSelfSharingScreen ?? false),
                       let setting = self.session.setting, setting.canOrientationManually {
                        let toast = UDToast.showTips(with: I18n.View_G_HostSyncRecGoHorizontal,
                                                            operationText: I18n.View_G_Switch,
                                                            on: view,
                                                            delay: 6.0) { _ in
                            UIDevice.updateDeviceOrientationForViewScene(to: .landscapeRight)
                        }
                        self.dismissToastWhenOrientationChanged(toast: toast)
                    } else {
                        Toast.show(I18n.View_G_HostSyncStage)
                    }
                }
            }
        } else if Self.stageIsSync(stageInfo: oldValue) && Self.stageIsSync(stageInfo: newStageInfo),
                  let oldValue = oldValue,
                  let newStageInfo = newStageInfo {
            // 舞台模式信息更新
            if !oldValue.guests.contains(self.session.account) && newStageInfo.guests.contains(self.session.account),
               let syncUser = newStageInfo.syncUser {
                self.meeting?.httpClient.participantService.participantInfo(pid: syncUser,
                                                                            meetingId: meetingID,
                                                                            completion: { pInfo in
                    // {{name}}已将你移上舞台
                    Toast.show(I18n.View_G_HostMoveYouStage(pInfo.name))
                })
            }
            if oldValue.allowGuestsChangeView
                && !newStageInfo.allowGuestsChangeView
                && !self.isWebinarAttendee
                && !(self.meeting?.setting.hasCohostAuthority ?? false) {
                Toast.show(I18n.View_G_HostSetOnlyStage)

            }

        } else if Self.stageIsSync(stageInfo: oldValue) && !Self.stageIsSync(stageInfo: newStageInfo) {
            // 停止舞台模式
            if let newStageInfo = newStageInfo, newStageInfo.guests.isEmpty {
                Toast.show(I18n.View_G_StageStop)
            } else {
                Toast.show(I18n.View_G_HostStopSyncStage)
            }

        }
    }
}
