//
//  CallKitMeetingComponent.swift
//  ByteView
//
//  Created by kiri on 2023/6/12.
//

import Foundation
import ByteViewCommon
import ByteViewMeeting
import ByteViewNetwork
import ByteViewTracker
import CallKit
import LarkMedia
import ByteViewUI
import LarkLocalizations
import ByteViewSetting
import Intents

extension MeetingSession {
    func createCallKitComponent() {
        if let component = CallKitMeetingComponent(session: self) {
            self.setAttr(component, for: "vc.component.CallKitMeetingComponent")
        }
    }

    var callKit: CallKitMeetingComponent? {
        self.attr("vc.component.CallKitMeetingComponent", type: CallKitMeetingComponent.self)
    }
}

final class CallKitMeetingComponent {
    private let session: MeetingSession
    private let service: MeetingBasicService
    @RwAtomic private var call: CallKitCall?
    private let logger: Logger
    private var userId: String { service.userId }
    private var meetingId: String { session.meetingId }
    private var httpClient: HttpClient { service.httpClient }
    @RwAtomic private var meeting: InMeetMeeting?

    @RwAtomic private(set) var isEnabled = true

    init?(session: MeetingSession) {
        guard let service = session.service, session.canCreateCallKitComponent() else { return nil }
        CallKitManager.shared.setupIfNeeded(dependency: service.currentMeetingDependency())
        self.session = session
        self.service = service
        self.logger = Logger.callKit.withContext(session.sessionId).withTag("[CallKitComponent(\(session.sessionId))]")
        session.log("init CallKitMeetingComponent")
    }

    deinit {
        livePrecheckAlert?.dismiss()
        session.log("deinit CallKitMeetingComponent")
    }

    private func execute(file: String = #fileID, function: String = #function, line: Int = #line,
                         action: @escaping (CallKitManager) -> Void) {
        CallKitQueue.queue.async {
            self.logger.info("executeInCallKitQueue \(function)", file: file, function: function, line: line)
            action(.shared)
        }
    }

    private func executeWithCall(delay: DispatchTimeInterval? = nil, file: String = #fileID, function: String = #function, line: Int = #line,
                                 action: @escaping (CallKitManager, CallKitCall) -> Void) {
        let block: () -> Void = {
            guard let call = self.call else {
                self.logger.error("executeWithCallKitCall \(function), can't find call", file: file, function: function, line: line)
                return
            }
            self.logger.info("executeWithCallKitCall \(function)", file: file, function: function, line: line)
            action(.shared, call)
        }
        if let delay = delay {
            CallKitQueue.queue.asyncAfter(deadline: .now() + delay, execute: block)
        } else {
            CallKitQueue.queue.async(execute: block)
        }
    }

    private weak var livePrecheckAlert: ByteViewDialog?

    @objc private func didReceiveContinueUserActivity(_ notification: Notification) {
        guard session.state == .onTheCall, let activity = notification.userInfo?[VCNotification.userActivityKey] as? NSUserActivity else {
            return
        }
        let activityType = activity.activityType
        Logger.meeting.info("didReceiveContinueUserActivity: \(activityType)")
        if activityType == "INStartCallIntent" || activityType == "INStartVideoCallIntent" {
            var handle: INPersonHandle?
            if #available(iOS 13.0, *) {
                guard let intent = activity.interaction?.intent as? INStartCallIntent else { return }
                handle = intent.contacts?.first?.personHandle
            } else {
                guard let intent = activity.interaction?.intent as? INStartVideoCallIntent else { return }
                handle = intent.contacts?.first?.personHandle
            }

            guard let meetingId = CallKitLauncher.processPersonHandle(handle, currentUserId: userId, shuldShowAlert: false),
                  meetingId == session.meetingId else {
                return
            }

            self.unmuteCallCamera()
        }
    }
}

extension CallKitMeetingComponent: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        let muted = myself.settings.isMicrophoneMutedOrUnavailable
        if muted != oldValue?.settings.isMicrophoneMutedOrUnavailable {
            self.muteCallMicrophone(muted: muted)
        }
    }
}

extension CallKitMeetingComponent: MeetingSessionListener {
    func didEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession) {
        logger.info("didEnterState: \(state), fromState: \(from)")
        self.handleStateChanged(state, from: from, event: event)
    }

    private func handleStateChanged(_ state: MeetingState, from: MeetingState, event: MeetingEvent?) {
        switch state {
        case .calling:
            self.enterCallingFromDialing()
        case .lobby, .prelobby:
            switch from {
            case .start, .preparing:
                self.reportJoinCallConnected()
            case .ringing:
                self.reportAnsweringCallConnected()
            default:
                break
            }
        case .onTheCall:
            session.addMyselfListener(self)
            livePrecheckAlert?.dismiss()
            livePrecheckAlert = nil
            switch from {
            case .start, .preparing:
                self.reportJoinCallConnected()
            case .calling:
                self.reportCallingCallConnected()
            case .ringing:
                self.reportAnsweringCallConnected()
            default:
                break
            }
        case .end:
            livePrecheckAlert?.dismiss()
            livePrecheckAlert = nil
            var endReason: CallEndedReason = .default
            if let event, event.name == .noticeTerminated,
               let info = event.videoChatInfo,
               let myself = info.participant(byUser: service.account) {
                if myself.offlineReasonDetails.contains(.acceptElsewhere) {
                    endReason = .answeredElsewhere
                } else if myself.offlineReasonDetails.contains(.refuseElsewhere) {
                    endReason = .declinedElsewhere
                }
            }
            self.reportCallEnded(reason: endReason)
        default:
            break
        }

        if state != .onTheCall {
            self.meeting = nil
        }

        if let info = session.videoChatInfo {
            self.updateCallWith(videoChatInfo: info)
        } else if let lobbyInfo = session.lobbyInfo {
            self.updateCallWith(lobbyInfo: lobbyInfo)
        }
    }

    private func reportAnsweringCallConnected() {
        executeWithCall {
            $1.reportAnswerSucceed()
        }
    }

    private func enterCallingFromDialing() {
        executeWithCall {
            $1.reportStartCallSucceed()
        }
    }

    private func reportCallingCallConnected() {
        executeWithCall(delay: getAsyncDelay()) {
            self.logger.info("reportCallingCallConnected")
            $0.reportOutgoingCall($1)
            $1.reportOutGoingConnected()
        }
    }

    private func reportJoinCallConnected() {
        executeWithCall(delay: getAsyncDelay()) {
            self.logger.info("reportJoinCallConnected")
            if case .dialing = $1.status {
                $1.reportStartCallSucceed()
            }
            $0.reportOutgoingCall($1)
            $1.reportOutGoingConnected()
        }
    }

    private func updateCallWith(videoChatInfo: VideoChatInfo) {
        self.fetchTopic(info: videoChatInfo) { [weak self] topic in
            self?.executeWithCall {
                $0.updateCall($1, info: videoChatInfo, topic: topic)
            }
        }
    }

    private func updateCallWith(lobbyInfo: LobbyInfo) {
        executeWithCall {
            $0.updateCall($1, lobbyInfo: lobbyInfo)
        }
    }

    private func fetchTopic(info: VideoChatInfo, completion: @escaping (String) -> Void) {
        if info.type == .call {
            let currentUserId = self.userId
            if let user = info.participants.first(where: { $0.user.id != currentUserId }) {
                httpClient.participantService.participantInfo(pid: user, meetingId: info.id, completion: { ap in
                    completion(ap.name)
                })
            } else {
                completion(info.settings.topic)
            }
        } else if info.meetingSource == .vcFromInterview {
            completion(I18n.View_M_VideoInterviewNameBraces(info.settings.topic))
        } else {
            completion(info.settings.topic)
        }
    }
}

extension CallKitMeetingComponent: CallKitCallDelegate {
    func didStartCall(_ call: CallKitCall) {
        if self.call != nil {
            assertionFailure("didStartCall again!")
            return
        }
        logger.info("didStartCall \(call)")
        self.call = call
        session.addListener(self)
        let currentState = session.state
        if currentState != .start && currentState != .preparing {
            self.handleStateChanged(currentState, from: .start, event: nil)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveContinueUserActivity(_:)), name: VCNotification.didReceiveContinueUserActivityNotification, object: nil)
    }

    func didRemoveCall(_ call: CallKitCall) {
        if self.call == nil {
            assertionFailure("didRemoveCall on nothing!")
            return
        }
        logger.info("didRemoveCall \(call)")
        NotificationCenter.default.removeObserver(self, name: VCNotification.didReceiveContinueUserActivityNotification, object: nil)
        session.removeListener(self)
        session.removeMyselfListener(self)
        self.isEnabled = false
        self.call = nil
    }

    func didMuteMicrophone(_ call: CallKitCall, isMuted: Bool) {
        // 在Lark app中的逻辑是mute直接设置成功，unmute是个短连，等成功后才会真正打开（避免去真正打开RTC，导致漏音）
        // 但是CallKit的MutedAction回调是系统决定的（有时候会出现连续回调两次的情况），所以针对CallKit开麦也预设成功
        // 失败后再手动关闭，而且这样也不存在漏音的问题，体验也更好，不用开麦先默认失败等接口返回
        // 通过CallKit操作的开关麦逻辑需要同步到App
        let meetType = self.session.meetType
        if session.isInLobby {
            NotificationCenter.default.post(name: LobbyViewModel.setMicrophoneNotificationKey, object: nil,
                                            userInfo: [LobbyViewModel.setNotificationUserInfoKey: isMuted])
            CallKitTracks.trackSetMute(isMuted, meetType: meetType)
            logger.info("SetMutedAction succeed")
        } else if let meeting = self.meeting {
            // 直接无脑同步，不用检查状态
            meeting.microphone.muteMyself(isMuted, source: .callkit, showToastOnSuccess: false) { [weak self] result in
                switch result {
                case .success:
                    CallKitTracks.trackSetMute(isMuted, meetType: meetType)
                    self?.logger.info("SetMutedAction succeed")
                case .failure(let error):
                    self?.logger.info("SetMutedAction failed with error:\(error)")
                    self?.forceSyncMicrphoneFromApp()
                }
            }
        } else {
            CallKitTracks.trackSetMute(isMuted, meetType: meetType)
            logger.info("SetMutedAction succeed")
        }
    }

    func canHoldCall(_ call: CallKitCall, isOnHold: Bool) -> Bool {
        if self.session.isEnd {
            self.logger.info("session is end, cannot holdCall \(call.uuid)")
            return false
        }
        // 通话保持的逻辑统一到系统电话状态 InMeetPhoneCallViewModel
        self.session.isHeldByCallkit = isOnHold
        return true
    }

    func didAcceptRinging(_ call: CallKitCall, error: Error?) {
        if let error = error {
            session.reportAcceptRingingFailed(error)
            return
        }

        // 如果主端页面出来后来了响铃，接听走挂断逻辑或者VC在处理安全事件时，忙线响铃接听需要挂断
        if service.security.didSecurityViewAppear() || ByteViewDialogManager.shared.isShowing(.securityCompliance) {
            self.endCallKitCall(deferRequest: false, isAcceptOther: false)
            return
        }

        OnthecallReciableTracker.startEnterOnthecall()
        self.session.slaTracker.startEnterOnthecall()
        // 与 PM 沟通后，CallKit 接听默认不开启摄像头
        var meetingSettings: MicCameraSetting = call.incomingCallParams?.meetingType == .call ? .onlyAudio : self.service.setting.micCameraSetting
        meetingSettings.isCameraEnabled = false
        // 4.11 新增无麦克风权限可以入会，针对无麦克风权限的用户更新会议设置
        if call.incomingCallParams?.meetingRole == .webinarAttendee || !Privacy.audioAuthorized {
            meetingSettings.isMicrophoneEnabled = false
        }
        let meetingId = self.meetingId
        self.livePreCheck { [weak self] granted in
            if granted {
                self?.acceptCallKitRinging(meetSetting: meetingSettings)
            } else {
                self?.endCallKitCall(deferRequest: false, isAcceptOther: false)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if UIApplication.shared.applicationState != .active && AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
                let body = I18n.View_G_NeedsMicAppNameBraces(LanguageManager.bundleDisplayName)
                UNUserNotificationCenter.current().addLocalNotification(withIdentifier: meetingId, body: body)
            }
        }
    }

    func performEndCall(_ call: CallKitCall, deferRequest: Bool, isAcceptOther: Bool) -> Bool {
        self.meeting?.microphone.stopAudioCapture()
        return endCallKitCall(deferRequest: deferRequest, isAcceptOther: isAcceptOther)
    }

    private func forceSyncMicrphoneFromApp() {
        logger.info("force sync micrphone from app")
        if let isMuted = self.meeting?.myself.settings.isMicrophoneMutedOrUnavailable {
            // 针对App内的麦克风状态进行无脑同步，保证状态统一
            // 历史针对相同状态不会进行同步，但是存在一些特殊情况导致出现问题，比如iOS 16 AudioSession 拉起比较慢，用户早于 AudioSession 激活点击 unmute
            // 另外CallKit的Action执行是在自己的队列里面，用call.isMuted状态来决定当前CallKit的mute状态也不可靠
            logger.info("app sync microphone muted: \(isMuted) to callkit")
            muteCallMicrophone(muted: isMuted)
        }
    }

    private func livePreCheck(completion: @escaping (Bool) -> Void) {
        self.livePrecheckAlert?.dismiss()
        self.livePrecheckAlert = nil

        guard self.session.meetType == .meet, self.service.setting.isLiveLegalEnabled else {
            completion(true)
            return
        }
        let meetingId = self.meetingId
        let placeholderId = self.session.sessionId
        let policyUrl = self.service.setting.policyURL
        httpClient.meeting.livePreCheck(meetingId: meetingId) { [weak self] showsPolicy in
            if !showsPolicy {
                completion(true)
                return
            }
            // nolint-next-line: magic number
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                if let self = self, !self.session.isEnd, UIApplication.shared.applicationState != .active {
                    UNUserNotificationCenter.current().addLocalNotification(withIdentifier: meetingId,
                                                                            body: I18n.View_G_OpenAppToAcceptCall)
                }
            }
            Policy.showJoinLivestreamedMeetingAlert(placeholderId: placeholderId, policyUrl: policyUrl, handler: completion, completion: { alert in
                self?.livePrecheckAlert = alert
            })
        }
    }

    private func acceptCallKitRinging(meetSetting: MicCameraSetting) {
        logger.info("acceptCallKitRinging: setting = \(meetSetting)")
        let state = session.state
        if state == .onTheCall || state == .lobby || state == .prelobby {
            // 兜底逻辑：未执行接听操作，就进入了 OnTheCall 状态
            logger.warn("accept onthecall meeting: \(session)")
            self.reportAnsweringCallConnected()
        } else {
            session.acceptRinging(setting: meetSetting)
        }
    }

    @discardableResult
    private func endCallKitCall(deferRequest: Bool, isAcceptOther: Bool) -> Bool {
        if session.isEnd {
            logger.warn("\(#function) session is end.")
            return false
        } else {
            logger.info("endCallKitCall: deferRequest = \(deferRequest), isAcceptOther = \(isAcceptOther), current = \(session)")
            let duration = DateUtil.formatDuration(Date().timeIntervalSince(meeting?.startTime ?? Date()))
            /// 会中音频被第三方抢占时，会议持续的时间
            VCTracker.post(name: .vc_bluetooth_status, params: ["status": "answer_the_phone_during_meeting",
                                                                "meeting_current_duration": duration])
            var isHoldPstn: Bool = false
            if let meeting = self.meeting {
                isHoldPstn = meeting.audioModeManager.isInCallMe || meeting.audioModeManager.isPstnCalling
            }
            if meeting?.mediaServiceManager.isMediaServiceLost == true {
                session.leave(.mediaServiceLost(isHoldPstn: isHoldPstn, shouldDeferRemote: deferRequest))
            } else {
                session.leave(.userLeave(isHoldPstn: isHoldPstn, shouldDeferRemote: deferRequest))
            }
            return true
        }
    }
}

extension CallKitMeetingComponent: CallCoordinatorProtocol {
    func reportNewIncomingCall(pushInfo: VoIPPushInfo) {
        logger.info("reportNewIncomingCall(pushInfo: \(pushInfo))")
        guard self.call == nil else {
            self.logger.warn("call exists, reportNewIncomingCall(pushInfo) ignored, \(pushInfo.uuid)")
            session.leave(.userLeave)
            return
        }

        CallKitQueue.assertCallKitQueue()
        let callkit = CallKitManager.shared
        let meetingId = pushInfo.conferenceID
        let interactiveId = pushInfo.interactiveID
        if let reason = self.shouldIgnore(meetingId: meetingId, interactiveId: interactiveId) {
            logger.info("reportNewIncomingCall(pushInfo: \(pushInfo.uuid)) ignored, reason = \(reason.rawValue)")
            callkit.ignoreVoipPush(pushInfo, reason: reason)
            session.leave(.filteredByCallKit)
            return
        }
        let call = CallKitCall(session: self.session, incomingParams: .init(pushInfo: pushInfo))
        call.delegate = self
        let ntpChecker = NtpChecker(pushInfo: pushInfo, logger: logger, httpClient: httpClient) { [weak self] in
            self?.onNtpExpired()
        } onNtpCheck: { [weak self] ntpOffset in
            let ntpRecord = DeviceNtpTimeRecord(ntpOffset: ntpOffset)
            self?.service.setting.updateDeviceNtpTimeRecord(ntpRecord)
        }
        ntpChecker.startChecking()
        JoinMeetingQueue.shared.suspend()
        callkit.reportNewIncomingCall(call) { [weak self] r in
            self?.logger.info("reportNewIncomingCall(pushInfo: \(pushInfo.uuid)) finished, result = \(r)")
            if case .failure = r {
                self?.session.leave(.filteredByCallKit)
            }
            JoinMeetingQueue.shared.resume()
        }
        self.logger.info("create call from reportNewIncomingCall(pushInfo: \(pushInfo.uuid))")
    }

    func reportNewIncomingCall(info: VideoChatInfo, myself: Participant, completion: @escaping (Result<CallkitConsumeResult, Error>) -> Void) {
        logger.info("reportNewIncomingCall(info: \(info), myself: \(myself))")
        if info.type == .call {
            httpClient.participantService.participantInfo(pid: info.host, meetingId: info.id) { [weak self] ap in
                guard let self = self else {
                    completion(.failure(VCError.unknown))
                    return
                }
                self._reportNewIncomingCall(info: info, myself: myself, topic: ap.name, completion: completion)
            }
        } else {
            self._reportNewIncomingCall(info: info, myself: myself, topic: info.settings.topic, completion: completion)
        }
    }

    private func _reportNewIncomingCall(info: VideoChatInfo, myself: Participant, topic: String,
                                        completion: @escaping (Result<CallkitConsumeResult, Error>) -> Void) {
        guard self.call == nil else {
            self.logger.warn("call exists, reportNewIncomingCall(info) ignored, \(info.id)")
            completion(.failure(VCError.unknown))
            return
        }
        // joinTime+70s 兜底，防止 push 过来的 ringing info 其实已经过期了，
        // 但是端上使用 .distantFuture 伪造过期时间，导致结束很长的会议还会响铃
        var expirationDate: Date = .distantFuture
        if myself.joinTime > 0 {
            // nolint-next-line: magic number
            let expirationSecs = TimeInterval(myself.joinTime + 70)
            expirationDate = Date(timeIntervalSince1970: expirationSecs)
        }
        let meetingId = info.id
        let interactiveId = myself.interactiveId
        self.execute { callkit in
            if let reason = self.shouldIgnore(meetingId: meetingId, interactiveId: interactiveId) {
                self.logger.info("reportNewIncomingCall(info: \(info.id), interactiveId: \(interactiveId)) ignored, reason = \(reason.rawValue)")
                completion(.success(.ignored(reason)))
                return
            }
            let providerConfig = CallKitManager.ProviderConfig(ringtone: info.ringtone, forceIgnoreRecents: self.session.isE2EeMeeting)
            callkit.updateConfiguration(service: self.service, providerConfig: providerConfig)
            let call = CallKitCall(session: self.session, incomingParams: .init(info: info, myself: myself, topic: topic))
            call.delegate = self
            let ntpChecker = NtpChecker(meetingId: meetingId, apnsExpiration: expirationDate, logger: self.logger, httpClient: self.httpClient) { [weak self] in
                self?.onNtpExpired()
            } onNtpCheck: { [weak self] ntpOffset in
                let ntpRecord = DeviceNtpTimeRecord(ntpOffset: ntpOffset)
                self?.service.setting.updateDeviceNtpTimeRecord(ntpRecord)
            }
            ntpChecker.startChecking()
            callkit.reportNewIncomingCall(call) { r in
                switch r {
                case .success:
                    completion(.success(.succeed))
                case .failure(let error as CXErrorCodeIncomingCallError):
                    if error.code == .filteredByDoNotDisturb {
                        Util.runInMainThread {
                            if UIApplication.shared.applicationState == .active {
                                completion(.success(.downgradeToAppRinging))
                            } else {
                                completion(.success(.error(error.errorCode)))
                            }
                        }
                    } else {
                        completion(.success(.error(error.errorCode)))
                    }
                default:
                    completion(.success(.error(-1)))
                }
            }
            self.logger.info("create call from reportNewIncomingCall(info: \(info.id), interactiveId: \(interactiveId))")
        }
    }

    private func shouldIgnore(meetingId: String, interactiveId: String) -> CallkitIgnoredReason? {
        if MeetingTerminationCache.shared.isTerminated(meetingId: meetingId, interactiveId: interactiveId) {
            logger.warn("Receive terminated conferenceID: \(meetingId), ignore!")
            // VoIP推送延迟，接收到已结束的会议，直接忽略
            return .terminated
        }

        if CallKitManager.shared.isFilteredIncomingCall(meetingId: meetingId, interactiveId: interactiveId) {
            // 对应的 call 已经通报过, 直接忽略
            logger.warn("Receive reported conferenceID: \(meetingId), ignore!")
            return .existed
        }

        return nil
    }

    private static let checkExpireStates: Set<MeetingState> = [.start, .preparing, .ringing]
    private func onNtpExpired() {
        logger.warn("[NTP] onNtpExpired, meetingId: \(self.meetingId), state:\(session.state)")
        // 已经入会了，就不判断是否过期了
        if Self.checkExpireStates.contains(session.state) {
            session.leave(.filteredByCallKit) { result in
                if case let .failure(error) = result {
                    self.logger.error("[NTP] leave meeting err:\(error), force end call")
                    self._reportCallEnded(reason: .remoteEnded)
                }
            }
        }
    }

    private func _reportCallEnded(reason: CallEndedReason, file: String = #fileID, function: String = #function, line: Int = #line) {
        executeWithCall(file: file, function: function, line: line) {
            $0.reportCallEnded($1, reason: reason)
        }
    }

    func requestStartCall<T>(action: @escaping CallKitStartCallAction<T>, completion: @escaping (Result<T, Error>) -> Void) {
        self.execute { callkit in
            guard self.call == nil else {
                self.logger.warn("call exists, requestStartCall ignored")
                completion(.failure(VCError.unknown))
                return
            }
            let providerConfig = CallKitManager.ProviderConfig(forceIgnoreRecents: self.session.isE2EeMeeting)
            callkit.updateConfiguration(service: self.service, providerConfig: providerConfig)
            let call = CallKitCall(session: self.session, startAction: action) { [weak self] r in
                if case .failure = r {
                    self?.logger.error("requestStartCall failed: force end callkit call")
                    self?.reportCallEnded(reason: .failed)
                }
                completion(r)
            }
            call.delegate = self
            callkit.requestStartCall(call, completion: completion)
            self.logger.info("create call from requestStartCall")
        }
    }

    func reportCallEnded(reason: CallEndedReason) {
        self._reportCallEnded(reason: reason)
    }

    func muteCallMicrophone(muted: Bool) {
        executeWithCall {
            $0.muteCallMicrophone($1, muted: muted)
        }
    }

    func unmuteCallCamera() {
        executeWithCall { _, _ in
            self.logger.info("unmuteCallCamera, muted: false")
            CallKitTracks.trackVideo(meetType: self.session.meetType)
            if self.session.isInLobby {
                NotificationCenter.default.post(name: LobbyViewModel.setCameraNotificationKey, object: nil,
                                                userInfo: [LobbyViewModel.setNotificationUserInfoKey: false])
            } else {
                Util.runInMainThread {
                    if self.meeting?.router.isFloating == true {
                        self.meeting?.router.setWindowFloating(false)
                    }
                    self.meeting?.camera.muteMyself(false, source: .callkit, showToastOnSuccess: false, completion: nil)
                    // callkit点击摄像头时，如过是听筒播放，设置为output为speaker
                    self.session.audioDevice?.output.enableSpeakerIfNeeded(true)
                }
            }
        }
    }

    func reportEnteringOnTheCall(meeting: InMeetMeeting) {
        self.meeting = meeting
    }

    func isByteViewCall(uuid: UUID, completion: @escaping (Bool) -> Void) {
        execute {
            completion($0.lookupCall(uuid: uuid) != nil)
        }
    }

    func waitAudioSessionActivated(completion: @escaping (Result<Void, Error>) -> Void) {
        execute {
            $0.waitAudioSessionActivated(completion: completion)
        }
    }

    func releaseHold() {
        executeWithCall {
            $0.releaseHold($1)
        }
    }

    func checkPendingTransactions(callback: @escaping (Bool) -> Void) {
        execute {
            callback($0.checkPendingTransactions())
        }
    }

    private func getAsyncDelay() -> DispatchTimeInterval {
        // 华为能接打电话的手环，快速的 startCall 和 reportConnect 会导致被挂断，需要延迟 1s
        let hasHuawei = AVAudioSession.sharedInstance().availableInputs?
            .contains(where: { $0.portName.uppercased().contains("HUAWEI") }) ?? false
        return hasHuawei ? .seconds(1) : .seconds(0)
    }
}

final class CallKitReceivedTracker {
    let pushInfo: VoIPPushInfo?
    let logger: Logger
    let clientNtpTime = Int64(Date().timeIntervalSince1970 * 1000)
    @RwAtomic private var isTracked = false

    init(pushInfo: VoIPPushInfo?, logger: Logger) {
        self.pushInfo = pushInfo
        self.logger = logger
    }

    /// ntp 时间收到或者超时后，校准收到的时间，再埋点
    func trackReceivedPushViaNTP(ntpDate: Date?) -> Bool {
        guard let pushInfo = self.pushInfo, !isTracked else { return false }
        // ntp 超时判断完成，重置 seqId
        self.isTracked = true
        var callType = ""
        switch pushInfo.meetingType {
        case .call:
            callType = "call"
        case .meet:
            callType = "meeting"
        default:
            callType = "none"
        }
        var params: TrackParams = [
            "action_name": "receive_call_push",
            "sid": String(describing: pushInfo.sid),
            "is_voip": 1,
            "is_new_feat": 0,
            "client_receive_time": clientNtpTime,
            "call_type": callType,
            "interactive_id": String(describing: pushInfo.interactiveID),
            "conference_id": String(describing: pushInfo.conferenceID),
            "inviter_id": String(describing: pushInfo.inviterID),
            "is_callkit": 1
        ]
        if let ntpDate = ntpDate {
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            let ntpMills = Int64(ntpDate.timeIntervalSince1970 * 1000)
            let interval = now - clientNtpTime
            let ntpTime = ntpMills - interval
            params["client_receive_time"] = ntpTime
            logger.info("receive time: ntp=\(ntpTime), local=\(clientNtpTime)")
        }
        VCTracker.post(name: .vc_meeting_callee_status, params: params)
        return true
    }
}

private extension CallKitMeetingComponent {
    final class NtpChecker {
        let meetingId: String
        let apnsExpiration: Date
        let logger: Logger
        let httpClient: HttpClient
        let onExpired: () -> Void
        let onNtpCheck: ((Int64) -> Void)?
        @RwAtomic private var ntpSeqId: Int = 0
        let receivedTracker: CallKitReceivedTracker

        init(meetingId: String, apnsExpiration: Date, logger: Logger, httpClient: HttpClient, onExpired: @escaping () -> Void, onNtpCheck: ((Int64) -> Void)? = nil) {
            self.meetingId = meetingId
            self.apnsExpiration = apnsExpiration
            self.logger = logger
            self.httpClient = httpClient
            self.onExpired = onExpired
            self.onNtpCheck = onNtpCheck
            self.receivedTracker = CallKitReceivedTracker(pushInfo: nil, logger: logger)
        }

        init(pushInfo: VoIPPushInfo, logger: Logger, httpClient: HttpClient, onExpired: @escaping () -> Void, onNtpCheck: ((Int64) -> Void)? = nil) {
            self.meetingId = pushInfo.conferenceID
            self.apnsExpiration = pushInfo.apnsExpiration
            self.logger = logger
            self.httpClient = httpClient
            self.onExpired = onExpired
            self.onNtpCheck = onNtpCheck
            self.receivedTracker = CallKitReceivedTracker(pushInfo: pushInfo, logger: logger)
        }

        func startChecking() {
            DispatchQueue.global().asyncAfter(deadline: .now()) {
                self.checkExpiredDateViaNTP(retryCnt: 1)
            }
        }

        /// 使用 NTP 时间校验 callkit 推送过期时间
        /// - Parameters:
        ///   - params: callkit params
        ///   - call: ByteViewCall
        ///   - retryCnt: 重试次数
        private func checkExpiredDateViaNTP(retryCnt: Int = 0) {
            if retryCnt < 0 {
                self.reportExpiredCallEndViaNTP()
                return
            }
            let sendTime = Date().timeIntervalSince1970
            // 使用毫秒数作为 ntp 请求的 id
            let ntpSeqID = Int(sendTime * 1000)
            self.ntpSeqId = ntpSeqID
            logger.info("[NTP] meetingID:\(self.meetingId), start request with seqID:\(ntpSeqID)")
            httpClient.getResponse(GetNtpTimeRequest(blockUntilUpdate: true)) { result in
                let now = Date().timeIntervalSince1970
                let sendInterval = now - sendTime
                defer {
                    self.logger.info("[NTP] meetingID:\(self.meetingId) get ntp takes \(sendInterval)s, seqID:\(ntpSeqID)")
                }
                // 请求已经超时了，不进行 ntp 过期判断
                if self.ntpSeqId != ntpSeqID {
                    return
                }
                switch result {
                case .success(let ntpTime):
                    guard ntpTime.hasUpdated else {
                        self.checkExpiredDateViaNTP(retryCnt: retryCnt - 1)
                        return
                    }
                    self.onNtpCheck?(ntpTime.ntpOffset)
                    let expiredDate = self.apnsExpiration
                    let ntpDate = Date(timeIntervalSince1970: now + TimeInterval(ntpTime.ntpOffset / 1000))
                    self.logger.info("[NTP] meetingID:\(self.meetingId), ntp:\(ntpDate), expired:\(expiredDate), retryCnt:\(retryCnt), seqID:\(ntpSeqID)")
                    if ntpDate > expiredDate {
                        if retryCnt - 1 >= 0 {
                            self.checkExpiredDateViaNTP(retryCnt: retryCnt - 1)
                        } else {
                            self.reportExpiredCallEndViaNTP()
                        }
                    } else {
                        if self.receivedTracker.trackReceivedPushViaNTP(ntpDate: ntpDate) {
                            self.ntpSeqId = 0
                        }
                    }
                default:
                    self.checkExpiredDateViaNTP(retryCnt: retryCnt - 1)
                }
            }
            // 限定 ntp 请求 3s 超时，超时后补发一次请求
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(3)) {
                // 超时后 seqID 如果不存在或者不等于捕获的，则表明超时时间内已经执行完
                if self.ntpSeqId != ntpSeqID { return }
                self.logger.info("[NTP] meetingID:\(self.meetingId) get ntp timeout, seqID:\(ntpSeqID)")
                self.checkExpiredDateViaNTP(retryCnt: retryCnt - 1)
            }
        }

        func reportExpiredCallEndViaNTP() {
            // 最后本地时间兜底判断过期
            if self.receivedTracker.trackReceivedPushViaNTP(ntpDate: nil) {
                self.ntpSeqId = 0
            }
            if self.apnsExpiration < Date() {
                logger.warn("[NTP] ignore meetingId: \(self.meetingId), expired:\(self.apnsExpiration)")
                self.onExpired()
            }
        }
    }
}

private extension MeetingSession {
    func canCreateCallKitComponent() -> Bool {
        if case .voipPush = self.meetingEntry {
            return true
        }
        if let setting = self.service?.setting {
            if setting.isCallKitOutgoingDisable {
                if case .push = self.meetingEntry {
                    return setting.isCallKitEnabled
                } else {
                    return false
                }
            } else {
                return setting.isCallKitEnabled
            }
        }
        return false
    }
}
