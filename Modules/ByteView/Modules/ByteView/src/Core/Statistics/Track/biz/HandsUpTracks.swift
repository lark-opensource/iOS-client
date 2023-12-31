//
//  HandsUpTracks.swift
//  ByteView
//
//  Created by wulv on 2020/8/10.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker
import ByteViewMeeting

final class HandsUpTracks {

    static let onTheCallPage = TrackEventName.vc_meeting_page_onthecall
    static let meetingPopupPage = TrackEventName.vc_meeting_popup
    static let userListPage = TrackEventName.vc_meeting_page_userlist

    static func trackAttentionAppearOfHandsUp(count: Int, meeting: InMeetMeeting) {
        trackAttentionOfHandsUp(action: "display", count: count, meeting: meeting)
    }

    static func trackAttentionDetailOfHandsUp(count: Int, meeting: InMeetMeeting) {
        trackAttentionOfHandsUp(action: "view_details", count: count, meeting: meeting)
    }

    static func trackAttentionPassOfHandsUp(user: ByteviewUser, count: Int, meeting: InMeetMeeting) {
        trackAttentionOfHandsUp(action: "unmute", userID: user.id, deviceID: user.deviceId, count: count, meeting: meeting)
    }

    static func trackAttentionClosedOfHandsUp(count: Int, meeting: InMeetMeeting) {
        trackAttentionOfHandsUp(action: "close", count: count, meeting: meeting)
    }

    static func trackAttentionProfileOfHandsUp(user: ByteviewUser, count: Int, meeting: InMeetMeeting) {
        trackAttentionOfHandsUp(name: onTheCallPage,
                                action: "user_profile",
                                userID: user.id,
                                deviceID: user.deviceId,
                                count: count,
                                meeting: meeting)
    }

    private static func trackAttentionOfHandsUp(name: TrackEventName = meetingPopupPage,
                                                action: String,
                                                userID: String? = nil,
                                                deviceID: String? = nil,
                                                count: Int,
                                                meeting: InMeetMeeting) {
        var params: TrackParams = [.action_name: action,
                                   .from_source: "raise_hand_notification",
                                   BreakoutRoomTracks.Amount.key: count,
                                   BreakoutRoomTracks.Start.key: BreakoutRoomTracks.isStart(meeting)]
        params[BreakoutRoomTracks.Location.key] = BreakoutRoomTracks.selfLocation(meeting)
        var extends: [String: Any] = [:]
        if let userId = userID {
            extends["attendee_uuid"] = EncryptoIdKit.encryptoId(userId)
        }
        if let deviceId = deviceID {
            extends["attendee_device_id"] = deviceId
        }
        if !extends.isEmpty {
            params[.extend_value] = extends
        }
        VCTracker.post(name: name, params: params)
    }

    static func trackHandsDownByHost(user: ByteviewUser, isSearch: Bool) {
        VCTracker.post(name: userListPage,
                       params: [.from_source: isSearch ? "search_userlist" : "userlist",
                                .action_name: "lower_hand",
                                .extend_value: ["attendee_uuid": user.id, "attendee_device_id": user.deviceId]])
    }

    static func trackHandsDownBySelf(isSearch: Bool) {
        VCTracker.post(name: userListPage,
                       params: [.from_source: isSearch ? "search_userlist" : "userlist",
                                .action_name: "self_lower_hand"])
    }

    static func trackAllowParticipantUnmuteByHost(_ allowParticipantUnmute: Bool) {
        VCTracker.post(name: onTheCallPage,
                       params: [.from_source: "control_bar",
                                .action_name: "participants_unmute_permission",
                                .extend_value: ["action_enabled": Int(allowParticipantUnmute ? 1 : 0)]])
    }

    static func trackConfirmMuteAllByHost(_ allowParticipantUnmute: Bool, confirm: Bool,
                                          isOpenBreakoutRoom: Bool, isInBreakoutRoom: Bool) {
        var params: TrackParams = [.from_source: "mute_all", .action_name: confirm ? "confirm" : "cancel",
                                   BreakoutRoomTracks.Start.key: BreakoutRoomTracks.isStart(isOpenBreakoutRoom)]
        if confirm {
            params["participants_unmute_permission"] = Int(allowParticipantUnmute ? 1 : 0)
        }
        params[BreakoutRoomTracks.Location.key] = BreakoutRoomTracks.selfLocation(isInBreakoutRoom)
        VCTracker.post(name: meetingPopupPage, params: params)

        VCTracker.post(name: .vc_meeting_popup_click,
                       params: [.click: confirm ? "confirm" : "cancel",
                                "if_self_unmute": allowParticipantUnmute,
                                .content: "mute_all"])
    }

    /// 参会者申请发言/开麦确认弹窗、参会者申请撤销弹窗
    static func trackConfirmHandsUp(_ confirm: Bool,
                                    isHandsUp: Bool,
                                    isMicrophone: Bool,
                                    isAudience: Bool,
                                    isOpenBreakoutRoom: Bool,
                                    isInBreakoutRoom: Bool) {
        let confirmActionName = isHandsUp ? "raise_hand" : "lower_hand"
        let cancelActionName = isHandsUp ? "cancel" : "keep_raising"
        var params: TrackParams = [.from_source: isHandsUp ? "self_unmute" : "self_lower_hand",
                                   .action_name: confirm ? confirmActionName : cancelActionName,
                                   BreakoutRoomTracks.Start.key: BreakoutRoomTracks.isStart(isOpenBreakoutRoom)]
        params[BreakoutRoomTracks.Location.key] = BreakoutRoomTracks.selfLocation(isInBreakoutRoom)
        VCTracker.post(name: meetingPopupPage, params: params)

        let actionName: String = confirm ? "confirm" : "cancel"
        let contentName: String
        if isHandsUp {
            contentName = isMicrophone ? "self_microphone_disabled" : "self_camera_disabled"
        } else {
            contentName = isMicrophone ? "withdraw_microphone" : "withdraw_camera"
        }
        let modeStatus = isAudience ? "audience" : "normal"
        var params2: TrackParams = [BreakoutRoomTracksV2.Key.isBreakoutRoomStart: isOpenBreakoutRoom,
                                    .click: actionName, .content: contentName, "mode_status": modeStatus]
        params2[BreakoutRoomTracksV2.Key.userLocation] = BreakoutRoomTracksV2.selfLocation(isInBreakoutRoom)
        VCTracker.post(name: .vc_meeting_popup_click, params: params2)
    }
}

// MARK: New Trackers
final class HandsUpTracksV2 {

    /// 拒绝主持人开启麦克风/摄像头邀请
    static func trackRejectInvite(isAudience: Bool, isMicrophone: Bool) {
        VCTracker.post(name: .vc_speaking_open_server,
                       params: ["status": "fail",
                                "product_type": "vc",
                                "mode_status": isAudience ? "audience" : "normal",
                                "speaking_type": isMicrophone ? "mic" : "cam",
                                "action_type": "reject_invite"])
    }

    /// 切换允许参会人打开麦克风
    static func trackAllowParticipantUnmuteByHost(enabled: Bool, fromSource: TrackFromSource, isMeetingLocked: Bool) {
        VCTracker.post(name: .vc_meeting_hostpanel_click,
                       params: [.click: "participants_unmute_permission",
                                "is_meeting_locked": isMeetingLocked,
                                "host_tab": "advanced_options",
                                "is_check": enabled,
                                .from_source: fromSource.rawValue])
    }

    /// 主持人收到申请弹窗内容时的显示事件
    static func trackHandsUpPopup(handsUpType: HandsUpType, requestNum: Int? = nil) {
        var params: TrackParams = [:]
        if handsUpType == .localRecord {
            params[.content] = ThemeAlertTrackerV2.ThemeAlertContent.recordRequestConfirm
            params[.recordType] = "local_record"
            if let requestNum = requestNum {
                params["record_request_num"] = requestNum
            }
        } else {
            params[.content] = ThemeAlertTrackerV2.ThemeAlertContent.requestUnmute
        }
        VCTracker.post(name: .vc_meeting_popup_view,
                       params: params)
    }

    /// 主持人收到申请弹窗内容时的点击事件
    static func trackClickHeadsUpRequestPopup(action: HeadsUpNotifAction, handsUpType: HandsUpType, requestNum: Int? = nil) {
        var params: TrackParams = [.click: action.trackStr, .content: handsUpType.trackContent]
        if handsUpType == .localRecord {
            params[.recordType] = "local_record"
            if let requestNum = requestNum {
                params["record_request_num"] = requestNum
            }
        }
        VCTracker.post(name: .vc_meeting_popup_click,
                       params: params)
    }

    /// 参会者申请发言确认弹窗、参会者申请撤销弹窗
    static func trackClickSelfUnmutePopup(handsStatus: ParticipantHandsStatus, isCancel: Bool, meeting: InMeetMeeting) {
        let actionName: String
        let contentName: String
        contentName = handsStatus == .putUp ? "self_unmute" : "self_lower_hand"
        if isCancel {
            actionName = "cancel"
        } else {
            actionName = handsStatus == .putUp ? "raise_hand" : "confirm"
        }
        var params: TrackParams = [BreakoutRoomTracksV2.Key.isBreakoutRoomStart: meeting.data.isOpenBreakoutRoom,
                                   .click: actionName,
                                   .content: contentName]
        params[BreakoutRoomTracksV2.Key.userLocation] = BreakoutRoomTracksV2.selfLocation(meeting)
        VCTracker.post(name: .vc_meeting_popup_click, params: params)
    }

    /// 全员静音确认弹窗
    static func trackClickUnmuteAllPopup(confirm: Bool, permitSelfUnmute: Bool) {
        VCTracker.post(name: .vc_meeting_popup_click,
                       params: [.click: confirm ? "confirm" : "cancel",
                                "if_self_unmute": permitSelfUnmute,
                                .content: "mute_all"])
    }

    enum HeadsUpNotifAction: String {
        case viewDetails = "detail_info"
        case unmute = "confirm"
        case userProfile = "user_profile"
        case close = "close"

        var trackStr: String {
            return self.rawValue
        }
    }

}
