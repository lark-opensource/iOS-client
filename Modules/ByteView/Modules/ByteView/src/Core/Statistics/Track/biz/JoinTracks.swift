//
//  JoinTracks.swift
//  ByteView
//
//  Created by kiri on 2020/10/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

final class JoinTracks {
    enum JoinMeetingType {
        /// 通过会议ID加入会议
        case meetingId(String)
        /// 加入日历会议
        case calendar(String)
        // 群id入会
        case group(String, editsTopic: Bool?)
        /// 会议号加入
        case meetNumber(String)
    }

    enum PopupAction {
        case close
        case cancel
        case sendRequest
        case confirm

        var trackName: String {
            switch self {
            case .close: return "close"
            case .cancel: return "cancel"
            case .confirm: return "confirm"
            case .sendRequest: return "send_request"
            }
        }
    }

    /// 会议入口
    static func trackMeetingEntry(sessionId: String, source: String, isHost: Bool = false) {
        TrackContext.shared.updateContext(for: sessionId) { context in
            if context.isIdle {
                context.reset()
            }
            context.meetingType = .meet
            if isHost {
                context.host = context.account
            }
        }
        DevTracker.post(.criticalPath(.meeting_entry).category(.meeting).params([.env_id: sessionId, .from_source: source]))
        VCTracker.post(name: .vc_meeting_lark_entry, params: [.from_source: source, .env_id: sessionId])
        VCTracker.post(name: .vc_meeting_click, params: [.env_id: sessionId])
    }

    static func trackMeetingEntryFailed(sessionId: String, source: String, error: Error) {
        let reason = entryErrorToReason(error)
        VCTracker.post(name: .vc_meeting_lark_entry_fail,
                       params: [.from_source: source, "fail_reason": reason, .env_id: sessionId])
        DevTracker.post(
            .warning(.join_meeting_precheck_failed)
            .category(.meeting)
            .params([.env_id: sessionId, .from_source: source, .error_msg: reason, .error_code: error.toErrorCode() ?? -1])
        )
    }

    /// 会中发起/加入视频会议
    static func trackJoinMeetingPopup(placeholderId: String, action: PopupAction, previousMeetingId: String, previousInteractiveId: String?) {
        let params: TrackParams = [
            .action_name: action.trackName,
            .env_id: placeholderId,
            .from_source: "onthecall_join_meeting",
            .extend_value: ["pre_conference_id": previousMeetingId,
                            "pre_interactive_id": previousInteractiveId]
        ]
        VCTracker.post(name: .vc_meeting_popup, params: params)
    }

    /// 跨设备发起新会议
    static func trackLarkHint() {
        VCTracker.post(name: .vc_meeting_lark_hint, params: [.action_name: "attend_new"])
    }

    static func trackStartCallRequest(contextId: String, startCallParams: CallEntryParams) {
        var params: TrackParams = [.from_source: startCallParams.source, "context_id": contextId]
        if startCallParams.isVoiceCall {
            params["only_voice"] = 1
        }
        VCTracker.post(name: .vc_call_click, params: params)
    }

    static func trackAcceptCallRequest(contextId: String) {
        var params = getParamsForKey(.vc_call_accept)
        params["context_id"] = contextId
        VCTracker.post(name: .vc_call_accept, params: params)
        clearParamsForKey(.vc_call_accept)
    }

    static func trackJoinMeetingRequest(contextId: String, params: JoinMeetingParams) {
        var result: TrackParams = [.action_name: params.meetSetting.trackName, "user_type": "attendee"]
        switch params.joinType {
        case .meetingId(let meetingId, _):
            result[.conference_id] = meetingId
        case .uniqueId(let uniqueId):
            result["unique_id"] = uniqueId
        case .groupId(let groupId):
            result["chat_id"] = EncryptoIdKit.encryptoId(groupId)
            if let topic = params.topicInfo {
                result[.extend_value] = ["is_customize_title": topic.isCustomized ? 1 : 0]
            }
        case .meetingNumber(let number):
            result["meeting_num"] = EncryptoIdKit.encryptoId(number)
        default:
            // interview和openplatform之前没埋参数，不清楚是否遗漏
            break
        }
        result["call_type"] = "meeting"
        result["context_id"] = contextId
        VCTracker.post(name: .vc_meeting_attend, params: result)
    }

    static func trackRejoinMeetingRequest(contextId: String, meetingId: String) {
        // 之前rejoin埋点没获取任何信息，不清楚是否遗漏
        VCTracker.post(name: .vc_meeting_attend, params: ["context_id": contextId])
    }

    /// 加入会议失败
    static func trackJoinMeetingFailed(placeholderId: String, error: Error, timestamp: TimeInterval, isFromCallKitRinging: Bool = false) {
        let reason: String = {
            if !ReachabilityUtil.isConnected {
                return "no_network"
            }
            if let errorCode = error.toErrorCode() {
                return "\(errorCode)"
            } else {
                return "unknown"
            }
        }()
        let tsString = String(format: "%.2f", round(100000 * timestamp) / 100)
        let params: TrackParams = [.env_id: placeholderId, "fail_reason": reason, "attend_timestamp": tsString,
                                   .from_source: isFromCallKitRinging ? "call_kit" : nil]
        VCTracker.post(name: .vc_meeting_attend_fail, params: params)
        DevTracker.post(.warning(.join_meeting_failed).category(.meeting).params(params))
    }

    private static func entryErrorToReason(_ error: Error) -> String {
        let vcerror = VCError(error: error)

        switch vcerror {
        case .unknown:
            return "unknown"
        case .meetingHasFinished:
            return "meeting_finished"
        case .participantsOverload:
            return "meeting_user_full"
        case .meetingLocked:
            return "meeting_locked"
        case .meetingNumberInvalid:
            return "meeting_id_overdue"
        case .otherDeviceVoIP:
            return "another_device_voip_onthecall"
        case .hostVersionLow:
            return "version_not_available"
        case .hostIsInRinging:
            return "receive_ringing"
        case .hostBusy, .hostIsInVC, .hostIsInVOIP:
            return "already_onthecall"
        case .chatPostNoPermission:
            return "disable_speak"
        case .tenantInBlacklist:
            return "black_list"
        case .meetingExpired:
            return "meeting_id_overdue"
        case .badNetwork:
            return "no_network"
        default:
            return "code_\(vcerror.code)"
        }
    }
}

extension JoinTracks {
    @RwAtomic
    private static var cachedKeyPairs: [TrackEventName: TrackParams] = [:]

    static func mergeParamsForKey(_ eventName: TrackEventName, params: TrackParams) {
        if let storedParams = cachedKeyPairs[eventName] {
            var mergeParams = params
            mergeParams.updateParams(storedParams.rawValue, isOverwrite: false)
            cachedKeyPairs[eventName] = mergeParams
        } else {
            cachedKeyPairs[eventName] = params
        }
    }

    static func getParamsForKey(_ eventName: TrackEventName) -> TrackParams {
        if let storedParams = cachedKeyPairs[eventName] {
            return storedParams
        } else {
            return [:]
        }
    }

    static func clearParamsForKey(_ eventName: TrackEventName) {
        cachedKeyPairs.removeValue(forKey: eventName)
    }

}

final class JoinTracksV2 {

    static func trackMeetingEntry(sessionId: String, source: String) {
        if source == "msg_link" {
            VCTracker.post(name: .vc_meeting_entry_click, params: [
                .env_id: sessionId,
                .click: source,
                .target: TrackEventName.vc_meeting_pre_view
            ])
        }
    }
}
