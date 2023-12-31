//
//  ThemeAlertTracker.swift
//  ByteView
//
//  Created by Juntong Chen on 2021/6/3.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork

final class ThemeAlertTrackerV2 {

    /// 会中弹窗显示
    static func trackDisplayPopupAlert(content: ThemeAlertContent, params: TrackParams = [:]) {
        var params = params
        params[.content] = content.trackStr
        VCTracker.post(name: .vc_meeting_popup_view,
                       params: params)
    }

    /// 会中弹窗点击事件
    static func trackClickPopupAlert(content: ThemeAlertContent, action: String, target: String? = nil, contextId: String? = nil, params: TrackParams = [:]) {
        var params = params
        params[.content] = content.trackStr
        params[.click] = action
        if let targetStr = target {
            params[.target] = targetStr
        }
        if let contextId = contextId {
            params["context_id"] = contextId
        }
        VCTracker.post(name: .vc_meeting_popup_click,
                       params: params)
    }

    // 开启录制
    static func trackStartRecordDev(isError: Bool, errorCode: Int? = nil, conferenceId: String? = nil, userType: String? = nil) {
        trackRecordDev(actionName: "record_start", isError: isError, errorCode: errorCode, conferenceId: conferenceId, userType: userType)
    }
    // 请求录制
    static func trackRequestRecordDev(isError: Bool, errorCode: Int? = nil, conferenceId: String? = nil, userType: String? = nil) {
        trackRecordDev(actionName: "record_request_start", isError: isError, errorCode: errorCode, conferenceId: conferenceId, userType: userType)
    }
    // 停止录制
    static func trackStopRecordDev(isError: Bool, errorCode: Int? = nil, conferenceId: String? = nil, userType: String? = nil) {
        trackRecordDev(actionName: "record_stop", isError: isError, errorCode: errorCode, conferenceId: conferenceId, userType: userType)
    }
    // 同意录制
    static func trackAcceptRecordDev(isError: Bool, errorCode: Int? = nil, conferenceId: String? = nil, userType: String? = nil) {
        trackRecordDev(actionName: "record_host_accept", isError: isError, errorCode: errorCode, conferenceId: conferenceId, userType: userType)
    }
    // 拒绝录制
    static func trackRefuseRecordDev(isError: Bool, errorCode: Int? = nil, conferenceId: String? = nil, userType: String? = nil) {
        trackRecordDev(actionName: "record_host_refuse", isError: isError, errorCode: errorCode, conferenceId: conferenceId, userType: userType)
    }

    static func trackRecordDev(actionName: String, isError: Bool, errorCode: Int? = nil, conferenceId: String? = nil, userType: String? = nil) {
        var params: [String: Any] = ["action_name": actionName, "is_error": isError]
        if let code = errorCode {
            params["server_error_code"] = code
        }
        if let conferenceId = conferenceId {
            params["conference_id"] = conferenceId
        }
        if let userType = userType {
            params["user_type"] = userType
        }
        VCTracker.post(name: .vc_meeting_control_result_dev,
                       params: TrackParams(params))
    }

    static func getUserType(meetingType: MeetingType?, meetingRole: Participant.MeetingRole?) -> String {
        guard let meetingType = meetingType, let meetingRole = meetingRole else { return "" }
        var userType: String = ""
        switch (meetingType, meetingRole) {
        case (.call, .host):
            userType = "caller"
        case (.call, .participant):
            userType = "callee"
        case (.meet, .host):
            userType = "host"
        case (.meet, .coHost):
            userType = "cohost"
        case (.meet, .participant):
            userType = "attendee"
        default:
            break
        }
        return userType
    }
}

extension ThemeAlertTrackerV2 {

    /// 弹窗内容
    enum ThemeAlertContent: String {
        /// 请求取消静音
        case requestUnmute = "unmute"
        /// 参会人请求录制
        case recordRequest = "record_request"
        /// 主持人确认自行开启录制
        case recordReconfirm = "record_reconfirm"
        /// 主持人是否同意参会人的请求
        case recordRequestConfirm = "record_request_confirm"
        /// 确认请求录制
        case recordStop = "record_stop"

        /// 主持人确认开始转录
        case transcribeStart = "transcribe_start"
        /// 主持人确认停止转录
        case transcribeStop = "transcribe_stop"

        /// 确认字幕选择弹窗
        case subtitleSelection = "subtitle_selection"
        /// 删除虚拟背景图
        case deleteVirtualBackground = "delete_virtual_background"
        /// 单人会议静音状态开启录制弹窗
        case recordUnmute = "record_unmute"
        /// 主持人请求打开麦克风
        case hostAskUnmute = "host_mic_on"
        /// 静音时打开麦克风
        case unmuteOnOutputMuted = "mic_on"
        /// 参会人发出直播请求
        case sendLiveRequest = "send_live_request"
        /// 主持人收到直播请求
        case reveiveLiveRequest = "receive_live_request"

        var trackStr: String {
            return self.rawValue
        }
    }

}
