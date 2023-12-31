//
//  MeetingNotifyService.swift
//  ByteView
//
//  Created by kiri on 2020/10/13.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import Reachability
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import ByteViewMeeting
import ByteViewUI
import NotificationUserInfo

public final class MeetingNotifyService {
    private let logger = Logger.meeting
    private let factory: () throws -> MeetingDependency
    @RwAtomic private var lastRegisterTime: CFTimeInterval = 0
    private lazy var calendarPromtManager = CalendarPromtManager()
    public init(factory: @escaping () throws -> MeetingDependency) {
        self.factory = factory
        logger.info("init MeetingNotifyService")
    }

    deinit {
        logger.info("deinit MeetingNotifyService")
    }

    public func handlePushVideoChat(_ info: VideoChatInfo) {
        logger.info("handlePushVideoChat \(info.id)")
        JoinMeetingQueue.shared.send(JoinMeetingMessage(info: info, type: .push, dependency: factory))
    }

    public func handleWebSocketPush(_ response: GetWebSocketStatusResponse) {
        logger.info("handleWebSocketPush: \(response.status) when network status is \(Reachability.shared.currentReachabilityString)")
        if response.status == .success {
            self.registerClientInfo()
        }
    }

    public func handlePromptPush(_ prompt: VideoChatPrompt) throws {
        logger.info("handlePromptPush: \(prompt.promptID)")
        let dependency = try factory()
        try ByteViewApp.shared.preload(account: dependency.account, reason: "pushVideoChatPrompt")
        calendarPromtManager.handlePrompt(prompt, dependency: dependency, fromPush: true)
    }

    @objc private func didReceiveRemoteNotification(_ notification: Notification) {
        guard let dict = notification.userInfo?[VCNotification.userInfoKey] as? [String: Any],
              let userInfo = UserInfo(dict: dict), let extra = userInfo.extra, extra.type == .video,
              extra.pushAction != .removeThenNotice, extra.content is VideoContent else {
            return
        }

        logger.info("didReceiveRemoteNotification: pushTime = \(userInfo.pushTime), start registerClientInfo")
        self.registerClientInfo()
    }

    @objc private func didReceiveContinueUserActivityNotification(_ notification: Notification) {
        if let activity = notification.userInfo?[VCNotification.userActivityKey] as? NSUserActivity,
           activity.activityType == InMeetHandoffViewModel.Key.HANDOFF_ACTIVITY_TYPE {
            handleHandoffActivity(activity)
        }
    }
}

/// for lazy loading
public protocol MeetingNotifyServiceStartParams {
    var lastMeetingId: String? { get }
    var httpClient: HttpClient? { get }
    var isForegroundUser: Bool { get }
    var latestTerminationType: TerminationType { get }
    func cleanLastMeetingId()
}

extension MeetingNotifyService {
    public func start(_ params: MeetingNotifyServiceStartParams) {
        DispatchQueue.main.async { [weak self] in
            self?._start(params)
        }
    }

    private func _start(_ params: MeetingNotifyServiceStartParams) {
        self.registerClientInfoForStartup(params)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveRemoteNotification(_:)), name: VCNotification.didReceiveRemoteNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveContinueUserActivityNotification(_:)), name: VCNotification.didReceiveContinueUserActivityNotification, object: nil)
    }

    private func registerClientInfoForStartup(_ params: MeetingNotifyServiceStartParams) {
        // PushKit 后台启动拉活时不使用短链拉会议信息
        let appState = UIApplication.shared.applicationState
        guard appState != .background else {
            self.logger.info("registerClientInfoForStartup ignored, appState = background")
            return
        }
        lastRegisterTime = CACurrentMediaTime()
        let sourceType: RegisterClientInfoRequest.SourceType
        if let id = params.lastMeetingId {
            self.logger.info("first launch uncompleted meeting id \(id) and not in background")
            sourceType = params.latestTerminationType.registerClientInfoType
        } else {
            sourceType = .longConnectionLoss
        }
        self.logger.info("registerClientInfoForStartup, appState = \(appState.rawValue), sourceType = \(sourceType)")
        let request = RegisterClientInfoRequest(sourceType: sourceType, status: .idle, meetingIds: [])
        params.httpClient?.getResponse(request) { [weak self] result in
            Queue.push.async {
                guard let self = self, case .success(var response) = result else { return }
                self.logger.info("registerClientInfoForStartup success: \(response)")
                let shouldRejoin = sourceType != .longConnectionLoss
                if shouldRejoin, response.status == .meetingEnd || response.status == .otherDevActive {
                    // killedStartup || crashedStartup, meetingEnd || otherDevActive
                    response.info = nil
                    response.infos = []
                    params.cleanLastMeetingId()
                }
                if response.info == nil, response.infos.isEmpty, response.prompts.isEmpty {
                    self.logger.info("handleInitialPull ignored: infos & prompts isEmpty")
                    return
                }
                guard params.isForegroundUser else {
                    self.logger.info("handleInitialPull ignored: isForegroundUser = false")
                    return
                }
                self.handleInitialPull(response, shouldRejoin: shouldRejoin)
            }
        }
    }

    private func handleInitialPull(_ response: RegisterClientInfoResponse, shouldRejoin: Bool) {
        do {
            logger.info("handleInitialPull, shouldRejoin = \(shouldRejoin)")
            let dependency = try factory()
            try ByteViewApp.shared.preload(account: dependency.account, reason: "registerClientInfo")
            let prompts = response.prompts
            if !prompts.isEmpty {
                // 同步Prompt数据
                calendarPromtManager.resetAllPrompts(prompts, dependency: dependency)
            }
            let infos = response.infoAndMyselfs(account: dependency.account.user)
            if !infos.isEmpty {
                if shouldRejoin {
                    rejoin(infos: infos, dependency: dependency)
                } else {
                    handlePulledInfos(infos, isFromIdle: true, dependency: dependency)
                }
            }
        } catch {
            logger.error("handleInitialPull failed: \(error)")
        }
    }

    private func rejoin(infos: [(VideoChatInfo, Participant)], dependency: MeetingDependency) {
        logger.info("rejoinPulledInfos: count = \(infos.count)")
        guard !MeetingManager.shared.hasActiveMeeting else {
            logger.info("rejoinPulledInfos: active meeting exists, do not show the rejoin alert.")
            return
        }
        for (info, myself) in infos {
            let logger = self.logger.withTag("[\(info.id)]")
            if info.type == .meet, myself.status == .onTheCall || myself.status == .idle {
                logger.info("rejoinPulledInfo: showAlert, status = \(myself.status)")
                let topic = info.settings.topic.isEmpty ? I18n.View_G_ServerNoTitle : info.settings.topic
                let title = I18n.View_M_RejoinMeetingTopicBraces(topic)
                ByteViewDialog.Builder()
                    .id(.rejoinMeeting)
                    .title(title)
                    .message(nil)
                    .leftTitle(I18n.View_G_NoThanksButton)
                    .leftHandler({ _ in
                        logger.info("rejoinPulledInfo: kill")
                        dependency.kill(info, myself: myself)
                    })
                    .rightTitle(I18n.View_G_RejoinButton)
                    .rightHandler({ _ in
                        logger.info("rejoinPulledInfo: startMeeting")
                        MeetingManager.shared.startMeeting(.rejoin(RejoinParams(info: info, type: .registerClientInfo)), dependency: dependency, from: nil)
                    })
                    .show()
            } else {
                logger.info("rejoinPulledInfo: send to JoinMeetingQueue")
                JoinMeetingQueue.shared.send(JoinMeetingMessage(info: info, type: .registerClientInfo, dependency: { dependency }))
            }
        }
    }
}

extension MeetingNotifyService {
    /// 接口逻辑文档 https://bytedance.feishu.cn/space/doc/doccnluc9PJkSKsy8KpJef#aYiNyN
    public func registerClientInfo() {
        let now = CACurrentMediaTime()
        guard now - self.lastRegisterTime > 1, let dependency = try? self.factory() else { return }
        self.lastRegisterTime = now
        var status: Participant.Status = .idle
        if let meeting = MeetingManager.shared.currentSession {
            if meeting.state == .dialing {
                // 当前处于beforeCalling状态，必须返回calling，否则会直接结束会议
                status = .calling
            } else if let s = meeting.myself?.status {
                status = s
            }
        }
        logger.info("registerClientInfo, status = \(status)")
        let request = RegisterClientInfoRequest(sourceType: .longConnectionLoss, status: status, meetingIds: [])
        dependency.httpClient.getResponse(request) { [weak self] result in
            Queue.push.async {
                guard let self = self, case let .success(response) = result, dependency.account.isForegroundUser else { return }
                self.logger.info("registerClientInfo success: \(response)")
                self.handleTriggeredPull(response, isFromIdle: status == .idle, dependency: dependency)
            }
        }
    }

    private func handleTriggeredPull(_ response: RegisterClientInfoResponse, isFromIdle: Bool, dependency: MeetingDependency) {
        logger.info("handleTriggeredPull, isFromIdle = \(isFromIdle)")
        let prompts = response.prompts
        // 同步Prompt数据
        calendarPromtManager.resetAllPrompts(prompts, dependency: dependency)
        let infos = response.infoAndMyselfs(account: dependency.account.user)
        handlePulledInfos(infos, isFromIdle: isFromIdle, dependency: dependency)
    }

    private func handlePulledInfos(_ infos: [(VideoChatInfo, Participant)], isFromIdle: Bool, dependency: MeetingDependency) {
        logger.info("handlePulledInfo: count = \(infos.count)")
        for (info, myself) in infos {
            let logger = self.logger.withTag("[\(info.id)]")
            logger.info("handlePulledInfo start")
            if isFromIdle {
                if info.type == .call, (myself.status == .calling || myself.status == .onTheCall),
                   MeetingManager.shared.findSession(meetingId: info.id, sessionType: .vc) == nil {
                    // to kill
                    logger.info("handlePulledInfo finished: kill video chat info, status = \(myself.status)")
                    dependency.kill(info, myself: myself)
                    continue
                } else if info.type == .meet, myself.status == .onTheCall {
                    // 忽略
                    logger.info("handlePulledInfo finished: ignore onTheCall meeting")
                    continue
                }
            }
            logger.info("handlePulledInfo finished: send to JoinMeetingQueue")
            JoinMeetingQueue.shared.send(JoinMeetingMessage(info: info, type: .registerClientInfo, dependency: { dependency }))
        }
    }
}

extension MeetingNotifyService {
    func handleHandoffActivity(_ activity: NSUserActivity) {
        logger.info("handleHandoffActivity, params: \(activity.userInfo)")
        guard let userInfo = activity.userInfo,
              let meetingId = userInfo[InMeetHandoffViewModel.Key.MEETING_ID] as? String,
              let userId = userInfo[InMeetHandoffViewModel.Key.USER_ID] as? String,
              let topic = userInfo[InMeetHandoffViewModel.Key.TOPIC] as? String,
              let isWebinar = userInfo[InMeetHandoffViewModel.Key.IS_WEBINAR] as? Bool,
              let isSecret = userInfo[InMeetHandoffViewModel.Key.IS_SECRET] as? Bool,
              let isInterview = userInfo[InMeetHandoffViewModel.Key.IS_INTERVIEW] as? Bool else {
            logger.error("handoff params error")
            return
        }
        if let dependency = try? factory(), userId == dependency.account.userId {
            let params = StartMeetingParams(meetingId: meetingId, source: .handoff, topic: topic, isE2EeMeeting: isSecret, chatID: nil, messageID: nil, isWebinar: isWebinar, isInterview: isInterview)
            MeetingManager.shared.startMeeting(params.entry, dependency: dependency, from: nil)
        }
    }
}

extension TerminationType {
    var registerClientInfoType: RegisterClientInfoRequest.SourceType {
        let sourceType: RegisterClientInfoRequest.SourceType
        switch self {
        case .unknown:
            sourceType = .longConnectionLoss
        case .appCrashed, .systemRecycled:
            // 为了解决crash之后不能Alert弹框重新入会，registerClientInfoType强制改为killedStartup
            sourceType = .killedStartup
        case .userKilled:
            sourceType = .killedStartup
        }
        return sourceType
    }
}

private extension MeetingDependency {
    func kill(_ info: VideoChatInfo, myself: Participant) {
        guard self.account.isForegroundUser else { return }
        MeetingTerminationCache.shared.terminate(meetingId: info.id, interactiveId: myself.interactiveId)
        httpClient.meeting.updateVideoChat(meetingId: info.id, action: .terminate, interactiveId: myself.interactiveId, role: myself.meetingRole, completion: { result in
            if let info = result.value??.videoChatInfo {
                JoinMeetingQueue.shared.send(JoinMeetingMessage(info: info, type: .registerClientInfo, dependency: { self }))
            }
        })
        if info.type == .meet, setting.lastOnTheCallMeetingId == info.id {
            setting.lastOnTheCallMeetingId = nil
        }
    }
}

private extension RegisterClientInfoResponse {
    func infoAndMyselfs(account: ByteviewUser) -> [(VideoChatInfo, Participant)] {
        let result = infos.compactMap {
            if let myself = $0.participant(byUser: account) {
                return ($0, myself)
            } else {
                return nil
            }
        }
        if result.isEmpty, let info = self.info, let myself = info.participant(byUser: account) {
            return [(info, myself)]
        } else {
            return result
        }
    }
}
