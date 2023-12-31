//
//  EndState.swift
//  ByteView
//
//  Created by kiri on 2021/2/25.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import Reachability
import UIKit
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import ByteViewMeeting
import AVFoundation
import LarkMedia
import ByteViewUI
import ByteViewSetting
import ByteViewRtcBridge
import UniverseDesignIcon

final class EndState: MeetingComponent {
    let session: MeetingSession
    init?(session: MeetingSession, event: MeetingEvent, fromState: MeetingState) {
        self.session = session
        self.entry(event: event, from: fromState, session: session)
    }

    func willReleaseComponent(session: MeetingSession, event: MeetingEvent, toState: MeetingState) {
        let sessionId = session.sessionId
        //延时是为了统计会议结束后的内存销毁情况
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
            let usage = ByteViewMemoryUsage.getCurrentMemoryUsage()
            CommonReciableTracker.trackMetricMeeting(event: .vc_metric_after_meeting,
                                                     appMemory: usage.appUsageBytes,
                                                     systemMemory: usage.systemUsageBytes,
                                                     availableMemory: usage.availableUsageBytes)
            //移除埋点context
            TrackContext.shared.removeContext(for: sessionId)
        }
        #if DEBUG
        if !session.isPending {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                if MeetingManager.shared.currentSession == nil {
                    Util.dumpExistObjects("leaking object")
                }
            }
        }
        #endif
    }

    private func entry(event: MeetingEvent, from: MeetingState, session: MeetingSession) {
        ParticipantService.setStrategy(strategy: nil, for: ParticipantStrategyKey(userId: session.account.id, meetingId: session.meetingId))
        TrackContext.shared.updateContext(for: session.sessionId, block: { $0.isIdle = true })
        trackEnd(from: from)
        MeetingTerminationCache.shared.terminate(session: session)
        ParticipantRelationTagService.clearAllCache()
        Util.runInMainThread {
            let background = UIApplication.shared.applicationState == .background ? 1 : 0
            VCTracker.post(name: .vc_mobile_ground_status_dev,
                           params: [.action_name: "end_meeting", "in_background": background])
        }

        cleanRtc()
        //非pending会议执行逻辑
        if !session.isPending {
            currentEntry(from: from, event: event, session: session)
        }
    }

    private func currentEntry(from: MeetingState, event: MeetingEvent, session: MeetingSession) {
        Reachability.shared.whenReachable = nil
        MeetingLocalNotificationCenter.shared.removeLocalNotification(session.meetingId)
        updateUI(from: from, event: event, session: session)
        SlardarLog.updateConferenceId(nil)
        MeetingEffectManger.ignoreStaticPerfDegrade = false
        InMeetWhiteboardViewController.hasShowToast = false
        NoticeService.shared.handleMeetingEnd()
    }

    private func updateUI(from: MeetingState, event: MeetingEvent, session: MeetingSession) {
        guard let service = session.service, service.accountInfo.isForegroundUser else {
            dismissWindow(sessionId: session.sessionId)
            return
        }
        if event.name == .changeAccount || from == .start || from == .preparing {
            dismissWindow(sessionId: session.sessionId)
            return
        }
        let meetType = session.meetType
        let meetSubType = service.setting.meetingSubType
        let reason = session.endReason ?? .unknown
        let dependency = session.service?.currentMeetingDependency()
        switch reason {
        case .streamingSDKBad(.streamingLost):
            if meetType == .meet, meetSubType != .screenShare, let info = session.videoChatInfo {
                // 多人会议断线重连
                ByteViewDialogManager.shared.triggerAutoDismiss()
                // 异步一下防止出现两个相同meetingId的MeetingSession
                dismissWindow(sessionId: session.sessionId, animated: false) {
                    if let dependency = dependency {
                        MeetingManager.shared.startMeeting(.rejoin(RejoinParams(info: info, type: .streamingLost)), dependency: dependency, from: nil)
                    } else {
                        Logger.meeting.error("dependency is nil, start rejoin for streamingLost failed. info = \(info)")
                    }
                }
                return
            }
        case .serverBad(.createVCError(let error)):
            if let params = session.enterpriseCallParams, params.isEnterpriseDirectCall, let dependency = dependency {
                PhoneCallUtil.handleError(error, params: params, dependency: dependency)
            }
        default:
            break
        }

        EndToastUtil(session: session, from: from)?.showIdleMessage()

        let ignoresFeedback: Bool
        switch reason {
        case .beInterrupted, .acceptOther, .startAnother, .meetingHasFinished:
            ignoresFeedback = true
        case .hangUp(let inLobby, _), .beKickedOut(let inLobby):
            ignoresFeedback = inLobby
        default:
            ignoresFeedback = false
        }
        if !ignoresFeedback, !service.accountInfo.isGuest, from == .onTheCall, let info = session.videoChatInfo,
           !MeetingManager.shared.hasActiveMeeting {
            // 使用feelgood feedback
            let params: TrackParams = ["participant_type": "lark_user",
                                       "call_type": info.type == .call ? "call" : "meeting"]
            VCTracker.post(name: .vc_display_feelgood_feedback, params: params)
        }

        let interviewQuestionnaireInfo = session.interviewQuestionnaireInfo
        dismissWindow(sessionId: session.sessionId) {
            if let info = interviewQuestionnaireInfo, let dep = dependency {
                InterviewQuestionnaireWindow.show(info, dependency: MeetingInterviewQuestionnaireDependency(dependency: dep))
            }
        }
    }

    private func dismissWindow(sessionId: String, animated: Bool = true, completion: (() -> Void)? = nil) {
        session.service?.router.dismissWindow(animated: animated) { _ in
            completion?()
        }
    }

    private func cleanRtc() {
        guard let service = session.service else { return }
        if session.isPending {
            service.releaseRtc()
        } else {
            service.releaseRtc()
            MeetingRtcEngine.enableAUPrestart(false, for: session.sessionId)
            session.audioDevice?.unlockState()
        }
    }

    private func trackEnd(from: MeetingState) {
        let endReason = session.endReason
        if let reason = endReason, let errorType = reason.toErrorType {
            var params: TrackParams = [.env_id: session.sessionId, "error_type_alarm": errorType,
                                       "on_the_call": from == .onTheCall ? 1 : 0]
            params["fail_create_error_code"] = reason.toErrorCode
            params["conference_id"] = session.meetingId
            params["sid"] = session.videoChatInfo?.sid
            VCTracker.post(name: .vcex_meeting_error, params: params, platforms: [.tea, .slardar])
        }

        if session.isPending { return }
        if session.setting?.meetingSubType == .screenShare && endReason == .beHungUp(nil) {
            VCTracker.post(name: .vc_meeting_finish, params: [.env_id: session.sessionId, "finish_reason": "force_leave"])
        }

        guard from == .onTheCall, let myself = session.myself else { return }
        let meetType = session.meetType
        let reason: String
        if !ReachabilityUtil.isConnected { // 无网络
            reason = "no_network"
        } else if let endReason = endReason {
            reason = endReason.description(meetingType: meetType)
        } else {
            reason = "other"
        }
        switch session.meetType {
        case .call:
            VCTracker.post(name: .vc_call_finish, params: ["finish_reason": reason, "participant_type": "lark_user"])
            if myself.meetingRole == .host {
                VCTracker.post(name: .vc_monitor_caller_hangup)
            } else {
                VCTracker.post(name: .vc_monitor_callee_hangup)
                if !ReachabilityUtil.isConnected {
                    /// 仅限被叫
                    VCTracker.post(name: .vc_call_finish_callee_nonetwork)
                }
            }
        case .meet:
            VCTracker.post(name: .vc_meeting_finish, params: ["finish_reason": reason, "participant_type": "lark_user"])
        default:
            break
        }
    }
}

private struct EndToastUtil {
    let meetingId: String
    let type: MeetingType
    let meetingSubType: MeetingSubType?
    let reason: MeetEndReason
    let from: MeetingState
    let accountInfo: ByteViewNetwork.AccountInfo?
    let startCallParams: StartCallParams?
    let setting: MeetingSettingManager
    let httpClient: HttpClient

    init?(session: MeetingSession, from: MeetingState) {
        guard let service = session.service else { return nil }
        self.meetingId = session.meetingId
        self.type = session.meetType
        self.meetingSubType = session.setting?.meetingSubType
        self.reason = session.endReason ?? .unknown
        self.from = from
        self.startCallParams = session.startCallParams
        self.accountInfo = service.accountInfo
        self.setting = service.setting
        self.httpClient = service.httpClient
    }

    func showIdleMessage() {
        let delayToast = VCScene.isAuxSceneOpen && !MeetingManager.shared.hasActiveMeeting
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delayToast ? 1 : 0)) {
            _showIdleMessage()
        }
    }

    private func _showIdleMessage() {
        // 因心跳停止退出
        if reason == .serverBad(.heartBeatStopped), type == .meet, from == .prelobby || from == .lobby {
            ByteViewDialog.Builder()
                .id(.quiteLobbyByHeartBeatStop)
                .title(I18n.View_G_ConnectionError)
                .message(nil)
                .rightTitle(I18n.View_G_ConfirmButton)
                .show()
            return
        }

        // 因媒体服务重置退出
        if reason == .mediaServiceLost {
            let duration = reason.showDuration
            ForegroundTaskDispatcher.shared.execute {
                Toast.show(I18n.View_G_DeviceErrorOutMeet_Toast, duration: duration)
            }
            return
        }

        var otherUserId: ParticipantId?
        switch reason {
        case .beHungUp(let otherId), .oppositeServerLost(let otherId),
                .oppositeSDKException(let otherId), .oppositeAcceptOther(let otherId):
            otherUserId = otherId
        default:
            break
        }

        if let id = otherUserId {
            if startCallParams?.idType == .some(.reservationId), let reservationId = startCallParams?.id {
                httpClient.getResponse(GetReservationRequest(id: reservationId)) { result in
                    if let response = result.value, let accountInfo = accountInfo, accountInfo.isForegroundUser {
                        let nickName = response.pstnSipUserInfo?.nickname
                        if let content = idleToastContent(otherName: nickName) {
                            Toast.show(content, duration: reason.showDuration)
                        }
                    }
                }
            } else {
                httpClient.participantService.participantInfo(pid: id, meetingId: meetingId) { ap in
                    if let content = idleToastContent(otherName: ap.name) {
                        Toast.show(content, duration: reason.showDuration)
                    }
                }
            }
        } else {
            if let content = idleToastContent() {
                Toast.show(content, duration: reason.showDuration)
            }
        }
    }

    private func idleToastContent(otherName: String? = nil) -> Toast.Content? {
        if type == .meet { // 视频会议
            switch reason {
            case .serverBad(.heartBeatStopped):
                return .plain(I18n.View_G_Disconnected)
            case .serverBad(.acceptError(let vcError)):
                if vcError.isHandled {
                    return nil
                }
                return .plain(I18n.View_G_Disconnected)
            case .streamingSDKBad:
                return .plain(I18n.View_G_Disconnected)
            case .reject:
                return .plain(I18n.View_AM_Declined)
            case .trialTimeout(let plan, let isFree):
                if isFree {
                    BillingTracks.trackDisplayDurationLimitTip(type: "ending", isSuperAdministrator: setting.isSuperAdministrator)
                    let image = UDIcon.getIconByKey(.warningOutlined, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 20, height: 20))
                    let text = I18n.View_G_MeetingEndedDueToTimeLimit
                    return .richText(image, CGSize(width: 20, height: 20), text)
                }
                if setting.shouldUpgradePlan(plan) {
                    return .plain(I18n.View_M_MeetingReachedTimeLimit)
                } else {
                    return .plain(I18n.View_M_MaxDurationReached)
                }
            case .beHungUp:
                if meetingSubType == .screenShare {
                    return .plain(I18n.View_G_SharingToRoomStopped)
                } else {
                    return .plain(I18n.View_M_HostEndedMeeting)
                }
            case .hangUp:
                if meetingSubType == .screenShare {
                    return .plain(I18n.View_G_SharingToRoomStopped)
                } else {
                    return .plain(I18n.View_M_YouLeftMeeting)
                }
            case .userEnd:
                return .plain(I18n.View_M_YouEndedMeeting)
            case .meetingHasFinished:
                return .plain(I18n.View_M_HostEndedMeeting)
            case .beKickedOut:
                return .plain(I18n.View_M_HostRemovedYou)
            case .autoEnd:
                return .plain(I18n.View_MV_AutoEnd_MobileToast)
            case .leave:
                if meetingSubType == .screenShare {
                    return .plain(I18n.View_MV_AlreadyStoppedSharing)
                } else {
                    return nil
                }
            case .leaveBecauseUnsafe:
                return .plain(I18n.View_M_YouLeftMeeting)
            case .otherDeviceReplaced:
                return .plain(I18n.View_G_DeviceBeenReplaced_Toast)
            default:
                return nil
            }
        } else { // 视频通话或者创建会议
            switch reason {
            case .serverBad(.heartBeatStopped):
                return .plain(I18n.View_G_Disconnected)
            case .serverBad(.acceptError(let vcError)):
                if vcError.isHandled {
                    return nil
                }
                return .plain(I18n.View_G_Disconnected)
            case .streamingSDKBad:
                return .plain(I18n.View_G_Disconnected)
            case .beHungUp, .oppositeServerLost, .oppositeSDKException, .oppositeAcceptOther:
                return .plain(I18n.View_G_CallEndedNameBraces(otherName ?? ""))
            case .cancel, .reject, .timeout, .hangUp, .leaveBecauseUnsafe:
                return .plain(I18n.View_G_CallEnded)
            case .beCancelled:
                return .plain(I18n.View_G_CallCanceled)
            case .beRejected:
                return .plain(I18n.View_G_CallDeclined)
            case .callException where meetingSubType == .enterprisePhoneCall:
                return .plain(I18n.View_MV_NumberDialedUnavailableEnded)
            case .mediaServiceLost:
                return .plain(I18n.View_G_DeviceErrorOutMeet_Toast)
            case .otherDeviceReplaced:
                return .plain(I18n.View_G_DeviceBeenReplaced_Toast)
            default:
                return nil
            }
        }
    }
}

private extension MeetEndReason {
    var toErrorType: String? {
        switch self {
        case .unknown:
            return "other"
        case let .serverBad(type):
            switch type {
            case .heartBeatStopped:
                return "timeout"
            case .createVCError:
                return "failCreate"
            case .acceptError:
                return "failAccept"
            }
        case .streamingSDKBad:
            return "SDK"
        default:
            return nil
        }
    }

    var toErrorCode: Int? {
        if case let .serverBad(.createVCError(error)) = self {
            return error.code
        } else {
            return nil
        }
    }

    func description(meetingType: MeetingType) -> String {
        // 由于目前前提条件是onTheCall，所以某些理由不需要关心
        switch self {
        case .beKickedOut: // 被踢
            return "kickout"
        case .userEnd, .beHungUp, .meetingHasFinished: // 结束会议
            return "hang_up"
        case .hangUp: // 正常挂断
            switch meetingType {
            case .call:
                return "hang_up"
            default:
                return "leave"
            }
        case .serverBad, .oppositeServerLost: // 心跳停止
            return "heartbeat_fail"
        case .streamingSDKBad, .oppositeSDKException: // 视频SDK断线
            return "streaming_sdk_bad"
        case .trialTimeout: // 免费时长耗尽
            return "freetime_out"
        case .acceptOther, .oppositeAcceptOther:
            return "another_accept"
        case .beInterrupted:
            return "interrupted"
        case let .startAnother(isJoined):
            return isJoined ? "join_another_meeting" : "create_another_meeting"
        case .leaveBecauseUnsafe:
            return "leaveBecauseUnsafe"
        default:
            return "other"
        }
    }
}

private final class MeetingInterviewQuestionnaireDependency: InterviewQuestionnaireDependency {
    let dependency: MeetingDependency
    init(dependency: MeetingDependency) {
        self.dependency = dependency
    }

    var userId: String { dependency.account.userId }
    var httpClient: HttpClient { dependency.httpClient }
    func openURL(_ url: URL) {
        LarkRouter(dependency: dependency.router).openURL(url)
    }
}
