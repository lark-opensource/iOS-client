//
//  CalendarPromtManager.swift
//  ByteView
//
//  Created by wangpeiran on 2022/10/18.
//

import Foundation
import UserNotifications
import NotificationUserInfo
import ByteViewNetwork
import ByteViewTracker
import ByteViewMeeting
import ByteViewUI
import ByteViewSetting

final class CalendarPromtManager {
    private static let queue = DispatchQueue(label: "byteview.calendarPromt.manager")

    init() {
        MeetingManager.shared.addListener(self)
    }

    deinit {
        clean()
    }

    private var notificationRequestIdentifier: String?
    @RwAtomic
    private var promptDic: [String: (VideoChatPrompt, CalendarPromptView)] = [:]
    private var invalidPromptIDs: Set<String> = []  //保留
    private var lastPushDismissId: String? //保留
    private var lastPushShowId: String?  //保留

    // 对外暴露 进入已显示的提醒的对应会议，直接移除提醒
    func checkCurrentPrompt(meetingId: String) {
        Self.queue.async {
            guard let prompt = self.containPrompt(meetingId: meetingId) else { return }
            switch prompt.type {
            case .calendarStart:
                self.dismissPrompt(promptID: prompt.promptID)
            default:
                break
            }
        }
    }

    // 收到push对外暴露
    func handlePrompt(_ prompt: VideoChatPrompt, dependency: MeetingDependency, fromPush: Bool) {
        Self.queue.async {
            guard prompt.type == .calendarStart else { return }
            let id = prompt.promptID
            Logger.Prompt.info("recievePromptPush promptID: \(prompt.promptID), action: \(prompt.action)")
            switch prompt.action {
            case .show:
                let isInvalidID = self.invalidPromptIDs.contains(id)
                guard !isInvalidID && id != self.lastPushShowId else {
                    if fromPush {
                        DevTracker.post(.warning(.calendar_prompt_not_show_on_push).params([
                            "prompt_id": id,
                            "last_show_id": self.lastPushShowId,
                            "type": prompt.type.rawValue,
                            "is_prompt_id_invalid": isInvalidID,
                            "is_from_push": true
                        ]))
                    }
                    return
                }
                VCTracker.post(name: .vc_meeting_cal_view, params: [.conference_id: prompt.calendarStartPrompt?.meetingID])
                self.lastPushShowId = id
                self.showPrompt(prompt, dependency: dependency)
            case .dismiss:
                // 处理远端提示消失逻辑
                guard id != self.lastPushDismissId else {
                    return
                }
                self.lastPushDismissId = id
                self.dismissPrompt(promptID: id)
            default:
                break
            }
        }
    }

    //对外暴露，registerClientInfo调用
    func resetAllPrompts(_ prompts: [VideoChatPrompt], dependency: MeetingDependency) {
        let realPrompts = prompts.filter { $0.type == .calendarStart }
        Self.queue.async { [weak self] in
            guard let self = self else { return }
            Logger.Prompt.info("resetAllPrompts: \(prompts.count)")
            // 更新最新数据
            let tempDic = self.promptDic
            for (_, value) in tempDic {
                let promptID = value.0.promptID
                let hasPrompt = realPrompts.contains { $0.promptID == promptID }
                if !hasPrompt {
                    self.dismissPrompt(promptID: promptID)
                }
            }
            for prompt in realPrompts where !self.containPrompt(promptID: prompt.promptID) {  // 如果新的里面有未显示的，显示出来
                self.showPrompt(prompt, dependency: dependency)
            }
        }
    }

    func clean() {
//        Self.queue.async {
            self.cleanUserNotification()
            let tempDic = self.promptDic
            for (_, value) in tempDic {
                self.dismissPrompt(promptID: value.0.promptID)
            }
            self.invalidPromptIDs = []
//        }
    }

    private func showPrompt(_ prompt: VideoChatPrompt, dependency: MeetingDependency) {
        guard let calendarStartPrompt = prompt.calendarStartPrompt else { return }
        let promptID = prompt.promptID
        let meetingID = MeetingManager.shared.currentSession?.meetingId
        if calendarStartPrompt.meetingID == meetingID { // 当前已处于该日程会议
            dismissPrompt(promptID: promptID)
        } else {
            let createTime = TimeInterval(calendarStartPrompt.promptCreateTime) / 1000
            let interval = Int(Date().timeIntervalSince1970 - createTime)
            let duration = min(60, max(0, 60 - interval)) // 修正无效值
            if duration > 0 {
                Self.queue.asyncAfter(deadline: .now() + .seconds(duration)) {
                    self.dismissPrompt(promptID: promptID)
                }
                _showPrompt(prompt: prompt, dependency: dependency)
            } else {
                dismissPrompt(promptID: promptID)
            }
        }
    }

    private func _showPrompt(prompt: VideoChatPrompt, dependency: MeetingDependency) {
        guard !containPrompt(promptID: prompt.promptID) else { return }
        Util.runInMainThread {
            let key = Self.vcPromptKey(id: prompt.promptID)
            let promptView = CalendarPromptView(frame: .zero, dependency: dependency, cardKey: key) // 默认基础width: 351, height: 148
            promptView.delegate = self
            self.promptDic[key] = (prompt, promptView)

            self.cleanUserNotification()
            VCTracker.post(name: .vc_meeting_lark_hint, params: [.action_name: "display"])
            self.showUserNotification(for: prompt, dependency: dependency)
            promptView.setCalendarStartPrompt(prompt)
            promptView.playMeetingOnGoing()

            Logger.Prompt.info("show calendarPrompt promptID: \(prompt.promptID), meetingId: \(prompt.calendarStartPrompt?.meetingID)")
            PushCardCenter.shared.postCard(id: key, isHighPriority: false, extraParams: nil, view: promptView, tap: nil)
        }
    }

    func dismissPrompt(promptID: String, changeToStack: Bool = false) {
        if invalidPromptIDs.contains(promptID) {
            Logger.Prompt.info("warning for has dismissPrompted")
        }
        invalidPromptIDs.insert(promptID)
        promptDic.removeValue(forKey: Self.vcPromptKey(id: promptID))
        Util.runInMainThread {
            Logger.Prompt.info("remove calendarPrompt promptID: \(promptID)")
            PushCardCenter.shared.remove(with: Self.vcPromptKey(id: promptID), changeToStack: changeToStack)
        }
    }

    func containPrompt(promptID: String) -> Bool {
        let keyId = Self.vcPromptKey(id: promptID)
        if promptDic[keyId] != nil { return true }
        return false
    }

    func containPrompt(meetingId: String) -> VideoChatPrompt? {
        for (_, value) in promptDic {
            if value.0.calendarStartPrompt?.meetingID == meetingId {
                return value.0
            }
        }
        return nil
    }

    static func vcPromptKey(id: String) -> String {
        return "VC|Prompt|\(id)"
    }
}

extension CalendarPromtManager: MeetingManagerListener, MeetingSessionListener {
    func didCreateMeetingSession(_ session: MeetingSession) {
        if session.isPending {
            session.addListener(self)
        }
    }

    func didLeaveMeetingSession(_ session: MeetingSession, event: MeetingEvent) {
    }

    func didLeavePending(session: MeetingSession) {
        checkCurrentPrompt(meetingId: session.meetingId)
    }
}

extension CalendarPromtManager: CalendarPromptViewDelegate {
    func didConfirmPrompt(_ prompt: VideoChatPrompt, from: UIView, dependency: MeetingDependency) {
        let routeFrom = RouteFrom(from)
        Self.queue.async {
            MeetingTracks.trackReplyPrompt(prompt, action: .confirm)
            if let calendarStartPrompt = prompt.calendarStartPrompt {
                // 同时存在入会提醒（先）和忙线响铃（后）的情况下，点击“加入”，避免显示忙线响铃的UI
                let meetingID = calendarStartPrompt.meetingID
                let title = calendarStartPrompt.displayedTitle
                let params = PreviewEntryParams.meetingId(meetingID, source: .calendarPrompt, topic: title, isE2EeMeeting: false, chatID: nil, messageID: nil, isWebinar: calendarStartPrompt.subtype == .webinar)

                MeetingManager.shared.startMeeting(.preview(params), dependency: dependency, from: routeFrom)
            }

            let promptID = prompt.promptID
            self.dismissPrompt(promptID: promptID, changeToStack: true)
            self.replyPrompt(httpClient: dependency.httpClient, id: promptID, type: prompt.type, action: .confirm) { result in
                if result.isSuccess {
                    VCTracker.post(name: .vc_meeting_cal_click, params: [.click: "join", .target: TrackEventName.vc_meeting_pre_view,
                                                                         .conference_id: prompt.calendarStartPrompt?.meetingID])
                }
            }
        }
    }

    func didCancelPrompt(_ prompt: VideoChatPrompt, from: UIView, dependency: MeetingDependency) {
        Self.queue.async {
            MeetingTracks.trackReplyPrompt(prompt, action: .cancel)
            let promptID = prompt.promptID
            self.dismissPrompt(promptID: promptID, changeToStack: true)
            self.replyPrompt(httpClient: dependency.httpClient, id: promptID, type: prompt.type, action: .cancel) { result in
                if result.isSuccess {
                    VCTracker.post(name: .vc_meeting_cal_click, params: [.click: "dismiss", .conference_id: prompt.calendarStartPrompt?.meetingID])
                }
            }
        }
    }

    private func replyPrompt(httpClient: HttpClient, id: String, type: VideoChatPrompt.TypeEnum, action: ReplyPromptRequest.Action,
                             completion: ((Result<Void, Error>) -> Void)? = nil) {
        let request = ReplyPromptRequest(promptId: id, type: type, action: action)
        httpClient.send(request, completion: completion)
    }
}

// MARK: - User Notification
private extension CalendarPromtManager {
    func showUserNotification(for prompt: VideoChatPrompt, dependency: MeetingDependency) {
        guard UIApplication.shared.applicationState != .active else {
            return
        }

        switch prompt.type {
        case .calendarStart:
            guard let calendarPrompt = prompt.calendarStartPrompt else { return }
            let showsDetail = dependency.setting.shouldShowDetails
            let identifier = calendarPrompt.uniqueID + "_" + calendarPrompt.meetingID
            let url = "//client/videochat/prompt?source=calendar&id=\(calendarPrompt.uniqueID)"
            let content = VideoContent(url: url, extraStr: "")
            let extra = Extra(type: .video, content: content)
            let userInfo = UserInfo(extra: extra).toDict()
            if showsDetail {
                let httpClient = dependency.httpClient
                httpClient.participantService.participantInfo(pid: calendarPrompt.startUser, meetingId: calendarPrompt.meetingID) { [weak self] ap in
                    let body = calendarPrompt.subtype == .webinar ? I18n.View_G_NameStartedWebinarTitle(ap.name, calendarPrompt.displayedTitle) : I18n.View_M_StartedTitleName(ap.name, calendarPrompt.displayedTitle)
                    UNUserNotificationCenter.current().addLocalNotification(withIdentifier: identifier, body: body, userInfo: userInfo)
                    self?.notificationRequestIdentifier = identifier
                }
            } else {
                showDefaultNotification(identifier, userInfo)
            }
        default:
            break
        }
    }

    private func showDefaultNotification(_ identifier: String, _ userInfo: [String: Any]) {
        let body = I18n.View_M_YouReceivedInvite
        UNUserNotificationCenter.current().addLocalNotification(withIdentifier: identifier, body: body, userInfo: userInfo)
        notificationRequestIdentifier = identifier
    }

    func cleanUserNotification() {
        if let identifier = notificationRequestIdentifier {
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
        notificationRequestIdentifier = nil
    }
}

extension VideoChatPrompt.CalendarStartPrompt {
    var displayedTitle: String {
        return eventTitle.isEmpty ? I18n.View_G_ServerNoTitle : eventTitle
    }
}
