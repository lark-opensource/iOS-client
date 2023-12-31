//
//  MeetTabTracks.swift
//  ByteView
//
//  Created by 陈俊潼 on 2021/6/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

final class MeetTabTracks {

    /// 视屏会议独立 Tab 展示
    static func trackEnterMeetTab() {
        VCTracker.post(name: .vc_tab_view)
    }

    /// 会议独立 tab 会议详情页展示
    static func trackEnterMeetingDetail(isOngoing: Bool? = nil, isCall: Bool? = nil, meetingID: String? = nil, ifCallkit: Bool = false) {
        var params: TrackParams = [:]
        if let isOngoing = isOngoing {
            params[.from_source] = isOngoing ? "ongoing" : "history"
        }
        if let isCall = isCall {
            params["meeting_type"] = isCall ? "call" : "meeting"
        }
        if let meetingID = meetingID {
            params[.conference_id] = meetingID
        }
        params["if_callkit"] = ifCallkit.description
        VCTracker.post(name: .vc_tab_list_view, params: params)
    }

    /// 视屏会议独立 Tab 展示
    static func trackEnterMeetingCollection(isAIType: Bool) {
        VCTracker.post(name: .vc_tab_cluster_view, params: ["cluster_type": isAIType ? "algorithm" : "repetitive_schedule"])
    }

    /// 点击按钮
    static func trackMeetTabOperation(_ action: MeetTabAction, with addedParams: [String: String] = [:]) {
        var params: TrackParams = [.click: action.trackStr, .target: action.target]
        params.updateParams(addedParams)
        VCTracker.post(name: .vc_tab_click, params: params)
    }

    static func trackClickTabListItem(with meetingId: String) {
        VCTracker.post(name: .vc_tab_click, params: [.click: "meeting_list", .target: TrackEventName.vc_tab_list_view, .conference_id: meetingId])
    }

    private static let clickTab = TrackEventName.vc_tab_list_click

    static func trackMeetTabDetailOperation(_ action: MeetTabDetailAction, isOngoing: Bool? = nil, isCall: Bool? = nil, meetingID: String? = nil) {
        var params: TrackParams = [.click: action.trackStr, .target: action.target]
        if let isOngoing = isOngoing {
            params[.from_source] = isOngoing ? "ongoing" : "history"
        }
        if let isCall = isCall {
            params["meeting_type"] = isCall ? "call" : "meeting"
        }
        if let meetingID = meetingID {
            params[.conference_id] = meetingID
        }
        VCTracker.post(name: clickTab, params: params)
    }

    static func trackClickCollection(with meetingId: String) {
        VCTracker.post(name: .vc_tab_cluster_click, params: [.click: "record", .target: TrackEventName.vc_tab_list_view, .conference_id: meetingId])
    }

    static func trackClickMinutesCollection(with meetingId: String) {
        VCTracker.post(name: .vc_tab_list_click, params: [.click: "discussion_records", .conference_id: meetingId])
    }

    /// 点击发送消息
    static func trackClickChat() {
        VCTracker.post(name: clickTab, params: [.click: "chat", .target: "im_chat_main_view"])
    }

    /// 点击拨打语音电话
    static func trackClickVoiceCall() {
        VCTracker.post(name: clickTab, params: [.click: "voice_call", .target: TrackEventName.vc_meeting_calling_view])
    }

    /// 点击拨打视频电话
    static func trackClickVideoCall() {
        VCTracker.post(name: clickTab, params: [.click: "video_call", .target: TrackEventName.vc_meeting_calling_view])
    }

    /// 点击加入会议
    static func trackClickJoinMeeting() {
        VCTracker.post(name: clickTab, params: [.click: "join_meeting", .target: TrackEventName.vc_meeting_pre_view])
    }

    /// 点击录制文件（妙记）
    static func trackClickMM() {
        VCTracker.post(name: clickTab, params: [.click: "click_mm", .target: "vc_minutes_detail_view"])
    }

    /// 转发妙记
    static func trackClickForwardMM() {
        VCTracker.post(name: clickTab, params: [.click: "mm_share"])
    }

    /// 点击会中分享的其他链接
    static func trackClickLink() {
        VCTracker.post(name: clickTab, params: [.click: "click_link"])
    }

    /// 点击返回上一页
    static func trackClickClose() {
        VCTracker.post(name: clickTab, params: [.click: "close"])
    }

    /// 点击设置页
    static func trackClickMeetSetting() {
        VCTracker.post(name: .vc_tab_click, params: [.click: "open_all_setting", .target: "vc_meeting_setting_view"])
    }

    static func trackMeetSettingPopup() {
        VCTracker.post(name: .vc_meeting_setting_view, params: [.location: "vctab"])
    }
}

extension MeetTabTracks {

    enum MeetTabAction: String {
        case clickNewMeeting = "new_meeting"
        case clickJoinMeeting = "join_meeting"
        case clickShareScreen = "share_screen"
        case clickLarkMinutes = "lark_minutes"
        case clickSchedule = "schedule"
        case clickWebinarSchedule = "book_new_webinar"
        case clickUpcomingMore = "upcoming_view_more"
        case clickUpcomingCell = "upcoming_meeting"
        case clickOngoingCell = "ongoing_meeting"
        case clickOngoingJoin = "ongoing_join_meeting"
        case clickOngoingJoined = "ongoing_joined"
        case clickTabLoadFailed = "tab_loading_failed"
        case clickListLoadFailed = "history_loading_failed"
        case clickUpcomingCopy = "upcoming_conference_id"
        case clickOngoingCopy = "ongoing_conference_id"

        var trackStr: String {
            return self.rawValue
        }

        var target: String {
            switch self {
            case .clickSchedule:
                return "cal_event_full_create_view"
            case .clickWebinarSchedule:
                return "cal_webinarEvent_full_create_view"
            case .clickNewMeeting:
                return "vc_meeting_pre_view"
            case .clickJoinMeeting:
                return "vc_meeting_pre_view"
            case .clickShareScreen:
                return "vc_meeting_sharewindow_view"
            case .clickLarkMinutes:
                return "vc_minutes_list_view"
            case .clickUpcomingMore:
                return "cal_calendar_main_view"
            case .clickUpcomingCell:
                return "cal_event_detail_view"
            case .clickOngoingCell:
                return "vc_tab_list_view"
            case .clickOngoingJoin:
                return "vc_meeting_pre_view"
            case .clickOngoingJoined:
                return "vc_meeting_onthecall_view"
            case .clickTabLoadFailed:
                return "vc_tab_view"
            case .clickListLoadFailed:
                return "vc_tab_view"
            case .clickUpcomingCopy:
                return "none"
            case .clickOngoingCopy:
                return "none"
            }
        }
    }

    enum MeetTabDetailAction: String {
        case clickUserGroup = "user_group"
        case clickUserGroupIcon = "user_group_icon"
        case clickUserLink = "user_link"
        case clickShare = "share"
        case clickJoined = "joined"
        case clickCopyInviteLink = "copy_invite_link"
        case clickWaiting = "waiting"
        case clickCalendarDetail = "detail_in_cal"
        case clickRecordCollection = "record_collection"

        var trackStr: String {
            return self.rawValue
        }

        var target: String {
            switch self {
            case .clickUserGroup:
                return "none"
            case .clickUserGroupIcon:
                return "profile_main_view"
            case .clickUserLink:
                return "profile_main_view"
            case .clickShare:
                return "public_share_view"
            case .clickJoined:
                return "vc_meeting_onthecall_view"
            case .clickCopyInviteLink:
                return "vc_tab_popup_view"
            case .clickWaiting:
                return "vc_meeting_waiting_view"
            case .clickCalendarDetail:
                return "cal_event_detail_view"
            case .clickRecordCollection:
                return "vc_tab_cluster_view"
            }
        }
    }
}
