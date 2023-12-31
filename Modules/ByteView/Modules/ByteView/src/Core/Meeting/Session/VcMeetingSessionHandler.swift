//
//  VcMeetingSessionHandler.swift
//  ByteView
//
//  Created by kiri on 2022/7/29.
//

import Foundation
import ByteViewTracker
import ByteViewMeeting
import ByteViewNetwork
import LarkMedia
import ByteViewUI
import LarkShortcut

extension MeetingSession {
    // 这里的3个属性比较重要，在进入下一个状态前更新
    var videoChatInfo: VideoChatInfo? { attr(.videoChatInfo) }
    var lobbyInfo: LobbyInfo? { attr(.lobbyInfo) }
    var endReason: MeetEndReason? { attr(.endReason) }
}

/// 本类处理vc类型MeetingSession的大部分自动任务
/// - 处理后台任务的开启和关闭
/// - 处理状态变化时VideoChatInfo、LobbyInfo和MeetEndReason的更新
/// - 处理会议升级时VideoChatInfo的更新
/// - 处理被推送自动关闭的情况
/// - 处理离开忙线时的行为
final class VcMeetingSessionHandler: MeetingComponent {
    private let session: MeetingSession
    private let sessionId: String

    @RwAtomic private var onTheCallCallbacks: [(Result<Any, Error>) -> Void] = []

    init?(session: MeetingSession, event: MeetingEvent, fromState: MeetingState) {
        guard let service = session.service else { return nil }
        self.session = session
        self.sessionId = session.sessionId
        session.addListener(self)
        TrackContext.shared.updateContext(for: session.sessionId) { $0.account = service.account }
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        if #available(iOS 13, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(didFailToActiveVcScene(_:)),
                                                   name: FloatingWindow.didFailToActiveVcSceneNotification, object: nil)
        }

        service.shortcut?.registerHandler(self, for: .vc.leaveMeeting, isWeakReference: true)
        service.shortcut?.registerHandler(self, for: .vc.waitingOnTheCall, isWeakReference: true)
    }

    func willReleaseComponent(session: MeetingSession, event: MeetingEvent, toState: MeetingState) { }

    deinit {
        endBackgroundTask()
        NotificationCenter.default.removeObserver(self)
        session.log("deinit VcMeetingSessionHandler")
    }

    @objc private func didFailToActiveVcScene(_ notification: Notification) {
        /// 这里不知道是因为app被杀掉了还是外界屏幕被断掉了，因此不向服务器发送请求，避免影响app杀死后重新入会的逻辑。后续需要调研区分的方法
        session.leave(.failedToActiveVcScene.handleMeetingEndManually())
    }

    // MARK: - background task
    private var vcBackgroundTaskId: UIBackgroundTaskIdentifier?
    @objc private func didEnterBackground() {
        VCTracker.post(name: .vc_mobile_ground_status_dev, params: [.action_name: "did_enter_background", "in_background": 1])
        if session.isPending || vcBackgroundTaskId != nil {
            return
        }
        session.log("begin byteview background task")
        vcBackgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "video_chat_task") { [weak self] in
            self?.endBackgroundTask()
            DevTracker.post(.warning(.background_task_expire).category(.meeting))
        }
    }

    @objc private func willEnterForeground() {
        VCTracker.post(name: .vc_mobile_ground_status_dev, params: [.action_name: "will_enter_foreground", "in_background": 0])
        endBackgroundTask()
    }

    private func endBackgroundTask() {
        if let vcBackgroundTaskId = self.vcBackgroundTaskId {
            session.log("end byteview background task, \(vcBackgroundTaskId)")
            self.vcBackgroundTaskId = nil
            UIApplication.shared.endBackgroundTask(vcBackgroundTaskId)
        }
    }

    private var pendingInfo: VideoChatAttachedInfo?
}

extension VcMeetingSessionHandler: MeetingSessionListener {
    func willEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession) {
        session.updateContextOnStateChange(state: state, event: event, from: from)
        if from == .preparing, state != .end {
            Util.runInMainThread {
                let background = UIApplication.shared.applicationState == .background ? 1 : 0
                VCTracker.post(name: .vc_mobile_ground_status_dev, params: [.action_name: "start_meeting", "in_background": background])
            }
        }
        #if DEBUG
        if from == .start {
            assert(state == .preparing, "shouldnot transition state from start to \(state)")
        }
        switch state {
        case .calling, .ringing, .prelobby, .lobby, .onTheCall:
            assert(!session.meetingId.isEmpty, "session.meetingId is empty!!!")
        default:
            break
        }
        #endif
    }

    func didEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession) {
        switch state {
        case .onTheCall:
            session.push?.combinedInfo.addObserver(self)
            let callbacks = self.onTheCallCallbacks
            self.onTheCallCallbacks = []
            callbacks.forEach { $0(.success(Void())) }
        case .end:
            if !event.isHandleMeetingEndManually {
                session.handleMeetingEnd(from: from, event: event, completion: nil)
            }
            let callbacks = self.onTheCallCallbacks
            self.onTheCallCallbacks = []
            callbacks.forEach { $0(.failure(MeetingError.meetingIsEnded)) }
        default:
            break
        }
        session.service?.postMeetingChanges({
            $0.state = state
            $0.type = session.meetType
            if session.isInLobby, let info = session.lobbyInfo {
                $0.meetingId = info.meetingId
            } else if let info = session.videoChatInfo {
                $0.meetingId = info.id
                $0.meetingSource = info.meetingSource
                $0.subtype = info.settings.subType
                $0.isBoxSharing = info.settings.isBoxSharing
            }
        })
    }

    /// 状态机状态切换失败
    func didFailToExecuteEvent(_ event: MeetingEvent, session: MeetingSession, error: Error) {
        if case MeetingStateError.pendingNotSupported = error {
            if let info = event.videoChatInfo {
                self.pendingInfo = .info(info)
            } else if let lobbyInfo = event.lobbyInfo {
                self.pendingInfo = .lobbyInfo(lobbyInfo)
            }
        }
        let routeAlarm = "\(session.state)_\(event.name)"
        VCTracker.post(name: .vcex_statemachine_switch_fail, params: ["route_alarm": routeAlarm], platforms: [.tea, .slardar])

        if event.name == .startPreparing, case .preview = event.meetingEntry, let error = error as? MeetingStateError {
            self.handlePreviewMeetingStateError(error)
        }
    }

    func didLeavePending(session: MeetingSession) {
        TrackContext.shared.updateCurrent(envId: sessionId)
        if let info = self.session.videoChatInfo {
            session.fireNonPendingVideoChatInfoEvents(info)
        }
        // delay到和leavePending一起的操作之后
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            self.session.executeInQueue(source: "VcMeeting.didLeavePending") {
                if let info = self.pendingInfo {
                    self.session.sendToMachine(attachedInfo: info)
                } else if let ringing = self.session.component(for: RingingState.self) {
                    // 暂时只在Ringing状态下, 实现忙线转换
                    if !session.isAcceptRinging, let myself = self.session.myself, myself.status == .ringing {
                        // 用户主动接受引起的pending态退出，无需进入 Ringing 态
                        ringing.leavePending(session: session)
                    }
                }
                self.pendingInfo = nil
            }
        }
        session.service?.postMeetingChanges({ $0.isPending = false })
    }

    private func handlePreviewMeetingStateError(_ error: MeetingStateError) {
        switch error {
        case .invalidInfo, .missingContext:
            // 入会流程受阻塞，表现为不会弹出 preview 弹框
            session.loge("Start preview failed with MeetingStateError: \(error)")
            Toast.show(I18n.View_M_FailedToJoinMeeting)
        case .pendingNotSupported, .unexpectedEvent, .unexpectedStatus:
            session.loge("Start preview failed with MeetingStateError: \(error)")
        case .ignore:
            // 忽略 ignore
            break
        }
    }
}

extension VcMeetingSessionHandler: VideoChatCombinedInfoPushObserver {

    func didReceiveCombinedInfo(inMeetingInfo: VideoChatInMeetingInfo, calendarInfo: CalendarInfo?) {
        guard session.state == .onTheCall, var info = session.videoChatInfo else { return }
        if inMeetingInfo.id == info.id, info.type == .call, inMeetingInfo.vcType == .meet {
            session.log("1v1 did upgrade meet")
            info.type = .meet
            session.updateVideoChatInfo(info)
            if !session.isPending {
                session.setting?.lastOnTheCallMeetingId = info.id
            }
            session.service?.postMeetingChanges({ $0.type = .meet })
        }
    }
}

private extension MeetingSession {

    /// update before enter state
    func updateContextOnStateChange(state: MeetingState, event: MeetingEvent, from: MeetingState) {
        TrackContext.shared.updateContext(for: sessionId, block: { $0.update(isCallKit: isCallKit) })
        switch state {
        case .lobby, .prelobby:
            if let info = event.lobbyInfo {
                self.setAttr(info, for: .lobbyInfo)
            }
        case .calling, .ringing, .onTheCall:
            if let info = event.videoChatInfo {
                self.updateVideoChatInfo(info)
                self.updateMyself(info: info, fireListeners: true)
                if !self.isPending {
                    fireNonPendingVideoChatInfoEvents(info)
                }
                if state == .onTheCall {
                    self.removeAttr(.lobbyInfo)
                }
            }
        case .end:
            if let reason = event.endReason(account: account, fromState: from) {
                log("endReason is \(reason)")
                self.setAttr(reason, for: .endReason)
            }
            if let info = event.videoChatInfo {
                self.updateVideoChatInfo(info)
                self.updateMyself(info: info, fireListeners: false)
            }
        default:
            break
        }
    }

    func updateVideoChatInfo(_ source: VideoChatInfo) {
        log("videoChatInfoDidChange")
        let oldValue = self.videoChatInfo
        let info = mergeInfo(oldInfo: oldValue, newInfo: source)
        setAttr(info, for: .videoChatInfo)
        self.isE2EeMeeting = info.settings.isE2EeMeeting
        TrackContext.shared.updateContext(for: sessionId, block: { $0.update(info: info) })
        if oldValue == nil {
            DevTracker.post(.criticalPath(.receive_first_videochatinfo).category(.meeting).params([.env_id: sessionId, .conference_id: info.id]))
        }
    }

    func fireNonPendingVideoChatInfoEvents(_ info: VideoChatInfo) {
        SlardarLog.updateConferenceId(info.id)
        if let msg = info.msg, msg.isShow, msg.type != .tips {
            NoticeService.shared.handleMsgInfo(msg, httpClient: httpClient)
        }
    }

    private func updateMyself(info: VideoChatInfo, fireListeners: Bool) {
        if let myself = info.participant(byUser: account), let notifier = component(for: MyselfNotifier.self) {
            notifier.update(myself, fireListeners: fireListeners)
        }
    }

    private func mergeInfo(oldInfo: VideoChatInfo?, newInfo: VideoChatInfo) -> VideoChatInfo {
        guard let oldInfo = oldInfo else { return newInfo }
        var info = newInfo
        if let oldConfig = oldInfo.settings.featureConfig, newInfo.settings.featureConfig == nil {
            // 有些VideoChatInfo不带featureConfig
            info.settings.featureConfig = oldConfig
        }
        if oldInfo.meetingSource != .unknown, newInfo.meetingSource == .unknown {
            info.meetingSource = oldInfo.meetingSource
        }
        return info
    }
}

extension VcMeetingSessionHandler: ShortcutHandler {
    func canHandleShortcutAction(context: ShortcutActionContext) -> Bool {
        switch context.action.id {
        case .vc.waitingOnTheCall, .vc.leaveMeeting:
            return context.string("sessionId") == self.sessionId
        default:
            return false
        }
    }

    func handleShortcutAction(context: ShortcutActionContext, completion: @escaping (Result<Any, Error>) -> Void) {
        switch context.action.id {
        case .vc.waitingOnTheCall:
            switch self.session.state {
            case .onTheCall:
                completion(.success(Void()))
            case .end:
                completion(.failure(MeetingError.meetingIsEnded))
            default:
                self.onTheCallCallbacks.append(completion)
            }
        case .vc.leaveMeeting:
            let event: MeetingEvent
            let shouldWaitServerResponse = context.bool("shouldWaitServerResponse")
            let reason = context.string("reason")
            if session.state == .onTheCall, reason == "securityInterruption" {
                event = .leaveBecauseUnsafe
            } else {
                event = .userLeave
            }
            session.log("leave meeting from shortcut: \(reason), shouldWaitServerResponse = \(shouldWaitServerResponse)")
            if shouldWaitServerResponse {
                session.leaveAndWaitServerResponse(event) {  completion($0.map({ _ in Void() })) }
            } else {
                session.leave(event) {  completion($0.map({ _ in Void() })) }
            }
        default:
            fatalError("unsupported shortcut action \(context.action.id)")
        }
    }


    private enum MeetingError: String, Error, CustomStringConvertible {
        case meetingIsEnded

        var description: String { "VcMeetingSessionHandler.MeetingError.\(rawValue)" }
    }
}

private extension MeetingAttributeKey {
    static let videoChatInfo: MeetingAttributeKey = "vc.videoChatInfo"
    static let lobbyInfo: MeetingAttributeKey = "vc.lobbyInfo"
    static let endReason: MeetingAttributeKey = "vc.endReason"
}
