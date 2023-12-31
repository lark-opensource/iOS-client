//
//  MeetingTracks.swift
//  ByteView
//
//  Created by kiri on 2020/10/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker
import RxSwift
import UIKit
import ByteViewSetting
import ByteViewUI

final class MeetingTracks {

    private static let onTheCallPage = TrackEventName.vc_meeting_page_onthecall
    private static let meetingChatBox = TrackEventName.vc_meeting_chat_box

    /// 调用创建会议接口
    static func trackCreateVideoChat() {
        VCTracker.post(name: .vc_monitor_caller_start)
    }

    /// 创建会议失败
    /// - 参考文档：
    ///   - https://wiki.bytedance.net/pages/viewpage.action?pageId=88686455
    ///   - https://docs.bytedance.net/doc/GcytE2me92uRt1m4z1lvPa
    static func trackCreateVideoChatFailed(placeholderId: String, error: VCError, isVoiceCall: Bool) {
        let failReason: Int
        switch error.code {
        case 10008, 10009: // 网络错误
            failReason = 1
        case 220003: // 被叫忙线
            failReason = 2
        case 220002: // 被叫版本不支持
            failReason = 3
        case 220001, 222301, 222302: // 主叫忙线
            failReason = 4
        case 220005: // 主叫版本不支持
            failReason = 5
        case 220000..<230000: // 服务端其他错误
            failReason = 6
        case 10000..<11000: // Lark错误
            failReason = 7
        default: // 未知错误
            failReason = 100
        }
        VCTracker.post(name: .vc_call_fail, params: [.env_id: placeholderId, "call_fail_reason": failReason, "only_voice": isVoiceCall ? 1 : nil])
    }

    /// 切换小视图
    static func trackSwitchView(isSharing: Bool) {
        VCTracker.post(name: .vc_call_page_onthecall,
                       params: [.action_name: "switchview", .extend_value: ["is_sharing": isSharing ? 1 : 0]])
    }

    /// 1v1或2人会议时，点击小窗切换位置
    static func trackClickSwitch() {
        VCTracker.post(name: .vc_call_page_onthecall,
                       params: [.action_name: "click_switchboth"])
    }

    /// 1v1升级邀请按钮点击
    static func trackUpgradeInvite() {
        VCTracker.post(name: .vc_call_page_onthecall, params: [.action_name: "invite"])
    }

    /// 分享视频会议链接
    static func trackShareLink() {
        VCTracker.post(name: .vc_in_meeting_link_share)
    }

    /// 分享会议链接
    static func trackShareMeetingLink() {
        VCTracker.post(name: onTheCallPage,
                       params: [.from_source: "meeting_info",
                                .action_name: "share"])
    }

    /// 显示日历详情
    static func trackDailyDetail() {
        VCTracker.post(name: onTheCallPage, params: [.action_name: "show_meeting_info"])
    }

    /// 复制入会信息
    static func trackCopyMeetingInfo() {
        VCTracker.post(name: onTheCallPage,
                       params: [.from_source: "meeting_info",
                                .action_name: "copy_join_info"])
    }

    /// 复制会议ID
    static func trackCopyMeetingID() {
        VCTracker.post(name: .vc_meeting_card_click,
                       params: [.click: "copy_meeting_id"])
    }

    /// 复制会议链接
    static func trackCopyMeetingLink() {
        VCTracker.post(name: .vc_meeting_card_click,
                       params: [.click: "copy_meeting_link"])
    }

    /// 扩容最大参会人数
    static func trackExpandMaxParticipants(isSuperAdministrator: Bool) {
        VCTracker.post(name: .vc_meeting_card_click,
                       params: [.click: "videochat_participant_limit",
                                .target: "help_desk"])
        VCTracker.post(name: .common_pricing_popup_click,
                       params: ["function_type": "videochat_participant_limit",
                                "admin_flag": isSuperAdministrator ? "true" : "false",
                                "target": "none",
                                "click": "go_auth",
                                "from_source": "meeting_card"])
    }

    /// 升级单次会议时间
    static func trackUpgradeMeetingTime(isSuperAdministrator: Bool) {
        VCTracker.post(name: .vc_meeting_card_click,
                       params: [.click: "videochat_duration_limit",
                                .target: "help_desk"])
        VCTracker.post(name: .common_pricing_popup_click,
                       params: ["function_type": "videochat_duration_limit",
                                "admin_flag": isSuperAdministrator ? "true" : "false",
                                "target": "none",
                                "click": "go_upgrade",
                                "from_source": "meeting_card"])
    }

    /// 更多电话号码
    static func trackMorePhoneNumbers() {
        VCTracker.post(name: onTheCallPage,
                       params: [.from_source: "meeting_info",
                                .action_name: "more_phone_numbers"])
        VCTracker.post(name: .vc_meeting_card_click,
                       params: [.click: "more_telephone_numbers"])
    }

    /// 从日历详情进入群聊
    static func trackEnterGroup() {
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "enter_meeting_group"])
        VCTracker.post(name: .vc_meeting_card_click,
                       params: [.from_source: "enter_chat"])
    }

    /// 分享会议到
    static func trackShareToParticipants(_ isConfirmed: Bool) {
        let actionName = isConfirmed ? "confirm" : "cancel"
        VCTracker.post(name: .vc_meeting_page_invite,
                       params: [.action_name: actionName, .from_source: "share_card"])
    }

    /// 分享会议页面事件
    static func trackShareView() {
        VCTracker.post(name: .public_share_view)
    }

    /// 参会人列表邀请按钮展示
    static func trackShowInviteInParticipants() {
        VCTracker.post(name: .public_share_view,
                       params: [.from_source: "user_list_top",
                                .target: ""])
    }
    /// 参会人列表邀请按钮点击
    static func trackInviteInParticipantsClick() {
        VCTracker.post(name: .public_share_click,
                       params: [.from_source: "user_list_top",
                                .target: ""
                       ])
    }

    static func trackShowInviteTabShare() {
        VCTracker.post(name: .public_share_view,
                       params: [.tab: "tab_share",
                                .from_source: "user_list_top"
                       ])
    }

    static func trackShowInviteTabPhone() {
        VCTracker.post(name: .public_share_view,
                       params: [.tab: "tab_phone",
                                .from_source: "user_list_top"
                       ])
    }

    static func trackShowInviteTabSIP() {
        VCTracker.post(name: .public_share_view,
                       params: [.tab: "tab_sip",
                                .from_source: "user_list_top"
                       ])
    }

    static func trackInviteSIPInClick() {
        VCTracker.post(name: .public_share_click,
                       params: [.click: "sip_in",
                                .from_source: "user_list_top"
                       ])
    }

    static func trackInviteSIPOutClick() {
        VCTracker.post(name: .public_share_click,
                       params: [.click: "sip_out",
                                .from_source: "user_list_top"
                       ])
    }

    static func trackTabPhoneCallClick() {
        VCTracker.post(name: .public_share_click,
                       params: [.click: "call_in_phone_tab",
                                .from_source: "user_list_top"
                       ])
    }

    static func trackTabSIPCallClick(roomType: String) {
        VCTracker.post(name: .public_share_click,
                       params: [.click: "call_in_sip_tab",
                                .sip_or_h323: roomType,
                                .from_source: "user_list_top"
                       ])
    }

    /// 确认提醒
    static func trackReplyPrompt(_ prompt: VideoChatPrompt, action: ReplyPromptRequest.Action, placeholderId: String? = nil) {
        switch prompt.type {
        case .calendarStart:
            let params: TrackParams = [.from_source: "calendar_reminder",
                                       .action_name: action == .confirm ? "join_meeting" : "cancel",
                                       .conference_id: prompt.calendarStartPrompt?.meetingID,
                                       .env_id: placeholderId,
                                       "interactive_id": ""]
            VCTracker.post(name: .vc_meeting_lark_hint, params: params)
        default:
            break
        }
    }

    static func trackSlide() {
        VCTracker.post(name: .vc_call_page_onthecall, params: [.action_name: "slide"])
    }

    static func trackScreenDisplay(page: Int) {
        var params: TrackParams = [.action_name: "screen_display"]
        params[.extend_value] = ["screen_type": page]
        VCTracker.post(name: .vc_call_page_onthecall, params: params)
    }

    /// 会中点击查看参会人profile
    static func trackDidTapUserProfile() {
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "user_profile"])
    }

    /// 宫格视图点击取消邀请
    static func trackDidTapCancelInvite() {
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "cancel"])
    }

    /// 会中单流放大
    static func trackSingleVideoZoomIn() {
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "zoom_in"])
    }

    /// 会中单流放大消失
    static func trackSingleVideoZoomOut() {
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "zoom_out"])
    }

    /// 会中点击参会人列表
    static func trackTapParticipants() {
        VCTracker.post(name: onTheCallPage,
                       params: [.action_name: "user_list"])
    }

    static func trackLabSelectedTap(param: (LabFromSource, EffectType)) {
        let (source, type) = param
        var typeStr = ""

        let sourceStr: TrackEventName
        switch source {
        case .preview:
            sourceStr = .vc_meeting_page_preview
        case .inMeet:
            sourceStr = .vc_labs_setting_page
        case .preLobby:
            sourceStr = .vc_pre_waitingroom
        case .inLobby:
            sourceStr = .vc_meeting_page_waiting_rooms
        }

        switch type {
        case .virtualbg:
            typeStr = "tab_virtual_background"
        case .animoji:
            typeStr = "tab_avatar"
        case .filter:
            typeStr = "tab_filter"
        case .retuschieren:
            typeStr = "tab_touch_up"
        }
        VCTracker.post(name: sourceStr, params: [.action_name: typeStr])
    }

    static func trackCreateAuxWindow(createWay: String) {
        VCTracker.post(name: onTheCallPage, params: [.action_name: "aux_window_create", .from_source: "aux_window_create_\(createWay)"])
    }

    static func trackCloseAuxWindow() {
        VCTracker.post(name: onTheCallPage, params: [.action_name: "aux_window_click_close"])
    }

    static func trackAllCloseAuxWindow() {
        VCTracker.post(name: onTheCallPage, params: [.action_name: "aux_window_closed"])
    }
}

// MARK: New Trackers
final class MeetingTracksV2 {

    private static let keyIsSharing: TrackParamKey = "is_sharing"
    private static let keyIsMinimised: TrackParamKey = "is_minimised"
    private static let keyIsMore: TrackParamKey = "is_more"

    /// 点击扩展箭头查看会议详情
    static func trackClickMeetingDetail(isSharingContent: Bool, isMinimized: Bool, isMore: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "info_more",
                                .target: TrackEventName.vc_meeting_card_view,
                          keyIsSharing: isSharingContent,
                        keyIsMinimised: isMinimized,
                             keyIsMore: isMore])
    }

    /// 展开会议详情
    static func trackEnterMeetingDetail() {
        VCTracker.post(name: .vc_meeting_card_view)
    }

    /// 复制入会信息
    static func trackCopyMeetingInfo() {
        VCTracker.post(name: .vc_meeting_card_click,
                       params: [.click: "copy_meeting_in"])
    }

    /// 分享页面关闭
    static func trackShareClickClose(isMeetingLocked: Bool) {
        VCTracker.post(name: .public_share_click, params: [.click: "close",
                                                           "is_meeting_locked": isMeetingLocked])
    }

    /// 关闭分享、电话邀请、sip 页面
    static func trackInviteAggClickClose(location: String, fromCard: Bool) {
        VCTracker.post(name: .public_share_click, params: [.click: "close",
                                                           .target: "none",
                                                           .location: location,
                                                           .from_source: fromCard ? "meeting_card" : "user_list_top"])
    }

    /// 分享会议
    static func trackShareClickShare(hasInfo: Bool, shareNum: Int) {
        VCTracker.post(name: .public_share_click, params: [.click: "confirm",
                                                           .shareNum: shareNum,
                                                           "is_info": hasInfo])
    }

    /// 入会范围选择联系人和群
    static func trackGroupPermissionShow() {
        VCTracker.post(name: .vc_entry_auth_choose_view)
    }

    /// 入会范围选择联系人和群 - 关闭
    static func trackGroupPermissionClose() {
        VCTracker.post(name: .vc_entry_auth_choose_click, params: [.click: "close"])
    }

    /// 入会范围选择联系人和群 - 保存
    static func trackGroupPermissionSave(shareNum: Int) {
        VCTracker.post(name: .vc_entry_auth_choose_click, params: [.click: "confirm",
                                                                   .shareNum: shareNum])
    }

    /// 复制入会信息
    static func trackCopyMeetingInfoClick() {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "participants_copy_info"])
    }

    /// 分享会议至会话
    static func trackShareMeeting() {
        VCTracker.post(name: .vc_meeting_card_click,
                       params: [.click: "share",
                                .target: "public_share_view"])
    }

    /// 邀请按钮弹出的电话邀请点击
    static func trackInvitePhoneClick() {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "participant_phone_invite",
                                .target: "public_share_view"])
    }
    /// 邀请按钮弹出的 SIP/H323 邀请
    static func trackInviteSIPClick() {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "participant_sip_h323_invite",
                                .target: "public_share_view"])
    }

    /// 进入会中设置页面
    static func trackToolBarDisplay() {
        VCTracker.post(name: .vc_meeting_control_bar_view)
    }

    /// 进入会中IM页面
    static func trackChatMessageDisplay(fromSource: String) {
        VCTracker.post(name: .vc_meeting_chat_send_message_view,
                       params: [.from_source: fromSource])
    }

    /// 会中展开表情页面
    static func trackDisplayMeetingChatReactionView() {
        VCTracker.post(name: .vc_meeting_control_bar_view)
    }

    /// 会中点击发送表情Reaction
    /// - Parameter reactionName: 表情的Key
    static func trackClickSendReaction(_ reactionName: String, location: String, isRecent: Bool, isChangeSkin: Bool) {
        VCTracker.post(name: .vc_meeting_chat_reaction_click,
                       params: [.click: "send_reaction",
                                "reaction_name": reactionName,
                                "location": location,
                                "if_change_skin_tone": isChangeSkin,
                                "if_frequently_used": isRecent])
    }

    static func trackClickConditionEmoji(_ emojiName: String, location: String, isChangeSkin: Bool? = nil) {
        if let isChangeSkin = isChangeSkin {
            VCTracker.post(name: .vc_meeting_chat_reaction_click,
                           params: [.click: emojiName,
                                    "location": location,
                                    "if_change_skin_tone": isChangeSkin])
        } else {
            VCTracker.post(name: .vc_meeting_chat_reaction_click,
                           params: [.click: emojiName,
                                    "location": location])
        }
    }

    static func trackHandsUpEmojiHoldDown(skinKey: String) {
        VCTracker.post(name: .vc_meeting_chat_reaction_click,
                       params: [.click: "hold_down_reaction",
                                "reaction_name": skinKey])
    }

    static func trackClickFoldReaction() {
        VCTracker.post(name: .vc_meeting_chat_reaction_click,
                       params: [.click: "fold_reaction"])
    }

    static func trackClickUnfoldReaction() {
        VCTracker.post(name: .vc_meeting_chat_reaction_click,
                       params: [.click: "unfold_reaction"])
    }

    static func trackClickAllowSendMessage(allowSendMessage: Bool, fromSource: TrackFromSource) {
        VCTracker.post(name: .vc_meeting_hostpanel_click,
                       params: [.click: "send_message_permission",
                                "is_check": allowSendMessage,
                                "from_source": fromSource.rawValue])
    }

    static func trackClickAllowSendReaction(allowSendReaction: Bool, fromSource: TrackFromSource) {
            VCTracker.post(name: .vc_meeting_hostpanel_click,
                           params: [.click: "send_reaction_permission",
                                    "is_check": allowSendReaction,
                                    "from_source": fromSource.rawValue])
    }

    static func trackClickAllowRequestRecord(allowRequestRecord: Bool, fromSource: TrackFromSource) {
            VCTracker.post(name: .vc_meeting_hostpanel_click,
                           params: [.click: "request_record",
                                    "is_check": allowRequestRecord,
                                    "from_source": fromSource.rawValue])
    }

    static func trackStatusReactionHandsUpCount(_ count: Int, isWebinar: Bool) {
        var params: TrackParams = [.click: "all_hands_down"]
        if isWebinar {
            params[.location] = "panelist_list"
            params["panelist_raise_hands_num"] = count
        } else {
            params[.location] = "userlist"
            params["raise_hands_num"] = count
        }
        VCTracker.post(name: .vc_meeting_onthecall_click, params: params)
    }

    static func trackAttendeeStatusReactionHandsUpCount(_ count: Int) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "all_hands_down", .location: "atendee_list", "attendee_raise_hands_num": count])
    }

    /// 会中主页展示时上报、会中最小化浮窗展示时上报
    /// - Parameter isFloating: 是否处于小窗状态
    static func trackDisplayOnTheCallPage(_ isFloating: Bool, isSharing: Bool, meeting: InMeetMeeting) {
        VCTracker.post(name: .vc_meeting_onthecall_view,
                       params: [
                        "is_minimised": isFloating,
                        "is_space_mic_open": meeting.setting.isKeyboardMuteEnabled,
                        "is_chat_translate_open": meeting.setting.translateLanguageSetting.isAutoTranslationOn,
                        "is_sharing": isSharing,
                        "is_show_interview_record": meeting.data.isPeopleMinutesOpened
                       ])
    }

    /// 1v1通话接通时上报耗时(对方点击接听到会议真的创建出来的时间)
    /// 开始计时
    static func startTrack1v1ConnectionDuration() {
        MeetingTracksTimeInterval.startTrack1v1ConnectionStartTime = Date().timeIntervalSince1970
    }

    /// 1v1通话接通时上报耗时(对方点击接听到会议真的创建出来的时间)
    /// 终止计时并上报
    static func endTrack1v1ConnectionDuration() {
        guard let startTime = MeetingTracksTimeInterval.startTrack1v1ConnectionStartTime else { return }
        VCTracker.post(name: .vc_meeting_onthecall_view,
                       params: [
                        "create_duration": (Date().timeIntervalSince1970 - startTime) * 1000,
                        "call_type": "call"
                       ])
        MeetingTracksTimeInterval.startTrack1v1ConnectionStartTime = nil
    }

    /// 共享屏幕情况下，点击停止共享
    static func trackClickStopSharingScreen(isSharingContent: Bool, isMinimized: Bool, isMore: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "stop_share_screen",
                                .location: "top_bar",
                          keyIsSharing: isSharingContent,
                        keyIsMinimised: isMinimized,
                             keyIsMore: isMore])
    }

    // MARK: - 参会人列表页面埋点，为了方便统计也适用OnTheCall相关的EventName上报

    /// 点击叉号关闭参会人列表
    static func trackClickCloseButton(isSharingContent: Bool, isMinimized: Bool, isMore: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "close_userlist",
                          keyIsSharing: isSharingContent,
                        keyIsMinimised: isMinimized,
                             keyIsMore: isMore])
    }

    /// 点击共享按钮(参会人列表)
    static func trackClickShareButton(isSharingContent: Bool, isMinimized: Bool, isMore: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "participants_share",
                                .target: TrackEventName.public_share_view,
                          keyIsSharing: isSharingContent,
                        keyIsMinimised: isMinimized,
                             keyIsMore: isMore])
    }

    /// 点击“全部”(参会人列表)
    static func trackClickAllParticipants(isSharingContent: Bool, isMinimized: Bool, isMore: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "all_participants",
                          keyIsSharing: isSharingContent,
                        keyIsMinimised: isMinimized,
                             keyIsMore: isMore])
    }

    /// 点击“建议”(参会人列表)
    static func trackClickSuggestions(isSharingContent: Bool, isMinimized: Bool, isMore: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "suggestions",
                          keyIsSharing: isSharingContent,
                        keyIsMinimised: isMinimized,
                             keyIsMore: isMore])
    }

    /// 点击全员静音(参会人列表)
    static func trackClickMuteAllButton(isMinimized: Bool, isMore: Bool, meeting: InMeetMeeting) {
        var params: TrackParams = [
            BreakoutRoomTracksV2.Key.isBreakoutRoomStart: meeting.data.isOpenBreakoutRoom,
            .click: "mute_all",
            keyIsSharing: meeting.shareData.isSharingContent,
            keyIsMinimised: isMinimized,
            keyIsMore: isMore]
        params[BreakoutRoomTracksV2.Key.userLocation] = BreakoutRoomTracksV2.selfLocation(meeting)
        VCTracker.post(name: .vc_meeting_onthecall_click, params: params)
    }

    /// 点击取消全员静音(参会人列表)
    static func trackClickUnmuteAllButton(isMinimized: Bool, isMore: Bool, meeting: InMeetMeeting) {
        var params: TrackParams = [
            BreakoutRoomTracksV2.Key.isBreakoutRoomStart: meeting.data.isOpenBreakoutRoom,
            .click: "unmute_all",
            keyIsSharing: meeting.shareData.isSharingContent,
            keyIsMinimised: isMinimized,
            keyIsMore: isMore
        ]
        params[BreakoutRoomTracksV2.Key.userLocation] = BreakoutRoomTracksV2.selfLocation(meeting)
        VCTracker.post(name: .vc_meeting_onthecall_click, params: params)
    }

    static func trackKeyboarMute(isSharingContent: Bool, duration: Int) {
        let params: TrackParams = [
            .click: "release_space",
            keyIsSharing: isSharingContent,
            "space_open_duration": duration
        ]
        VCTracker.post(name: .vc_meeting_onthecall_click, params: params)
    }

    /// 共享屏幕情况下，点击标注
    static func trackClickAnnotate(isSharingContent: Bool, isMinimized: Bool, isMore: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "annotate",
                                .target: "vc_meeting_annotate_view",
                          keyIsSharing: isSharingContent,
                        keyIsMinimised: isMinimized,
                             keyIsMore: isMore])
    }


    /// 点击麦克风
    /// - Parameters:
    ///   - isMuted: 是否关闭麦克风
    ///   - isSharingContent: 是否正在共享内容
    ///   - isFloating: 是否是小窗
    ///   - isMore: 按钮是否在“更多”中
    static func trackClickMic(_ isMuted: Bool, meetingType: MeetingType, isSharingContent: Bool, isMinimized: Bool, isMore: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "mic",
                                .option: isMuted ? "close" : "open",
                                "is_sharing": isSharingContent,
                                "is_minimised": isMinimized,
                                "is_more": isMore])

        VCTracker.post(name: meetingType.trackName, params: [
            .action_name: "mic", .from_source: "control_bar",
            .extend_value: ["is_sharing": isSharingContent ? 1 : 0, "action_enabled": isMuted ? 0 : 1]
        ])
    }

    /// 点击摄像头
    /// - Parameters:
    ///   - isCamEnabled: 摄像头是否开启
    ///   - isSharingContent: 是否正在共享内容
    ///   - isMinimized: 是否是小窗
    ///   - isMore: 按钮是否在“更多”中
    static func trackClickCam(_ isCamEnabled: Bool, isSharingContent: Bool, isMinimized: Bool, isMore: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "cam",
                                .option: !isCamEnabled ? "open" : "close",
                                "is_sharing": isSharingContent,
                                "is_minimised": isMinimized,
                                "is_more": isMore])
    }

    /// 点击音频播放设备
    /// - Parameters:
    ///   - device: 当前使用的音频播放设别
    ///   - isSharingContent: 是否正在共享内容
    ///   - isMinimized: 是否是小窗
    ///   - isMore: 按钮是否在“更多”中
    static func trackClickAudioOutput(isSheet: Bool, device: String, isSharingContent: Bool, isMinimized: Bool, isMore: Bool) {
        let target = isSheet ? TrackEventName.vc_meeting_loudspeaker_view : nil
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "speaker",
                                .target: target,
                                "is_sharing": isSharingContent,
                                "is_minimised": isMinimized,
                                "is_more": isMore,
                                .option: device])
    }

    /// 通用的点击操作，只有 click 和 target 两个参数和 isSharing isMinimised isMore contextId 四个通用参数的的
    /// - Parameters:
    ///   - action: 点击的动作
    ///   - isSharingContent: 是否正在共享内容
    ///   - isMinimized: 是否是小窗
    ///   - isMore: 按钮是否在“更多”中
    ///   - isMeetingLocked: 会议是否锁定，可选
    ///   - contextId: 请求的contextID，方便和服务端的logID对应, 可选
    static func trackMeetingClickOperation(action: MeetingTracksClickAction, isSharingContent: Bool, isMinimized: Bool = false, isMore: Bool = false, isFromNotes: Bool = false, isMeetingLocked: Bool? = nil, isKeepPstn: Bool? = nil, contextId: String? = nil) {
        guard action != .unknown else { return }
        var params: TrackParams = [.click: action.trackStr,
                                   .target: action.trackTarget,
                                   "is_sharing": isSharingContent,
                                   "is_minimised": isMinimized,
                                   "is_more": isMore,
                                   "is_keep_phone": isKeepPstn,
                                   "position": isFromNotes ? "meeting_notes" : "toolbar"]
        if let isMeetingLocked = isMeetingLocked {
            params["is_meeting_locked"] = isMeetingLocked
        }
        if let isKeepPstn = isKeepPstn {
            params["is_keep_phone"] = isKeepPstn
        }
        if let contextId = contextId {
            params["context_id"] = contextId
        }
        VCTracker.post(name: .vc_meeting_onthecall_click, params: params)
    }

    static func trackLeaveMeeting(_ meeting: InMeetMeeting, holdPSTN: Bool) {
        let action = MeetingTracksClickAction.clickLeave
        let params: TrackParams = [
            .click: action.trackStr,
            .target: action.trackTarget,
            "is_sharing": meeting.shareData.isSharingContent,
            "is_keep_phone": holdPSTN,
            BreakoutRoomTracksV2.Key.userLocation: BreakoutRoomTracksV2.selfLocation(meeting),
            BreakoutRoomTracksV2.Key.isBreakoutRoomStart: meeting.data.isOpenBreakoutRoom
        ]
        VCTracker.post(name: .vc_meeting_onthecall_click, params: params)
    }

    // 点击直播item失败
    static func trackClickLiveItemFail(errorCode: Int? = nil, errorDescription: String? = nil) {
        var params: TrackParams = [.click: "live", .action_name: "create_or_get_live_fail"]
        if let errorCode = errorCode {
            params["error_code"] = errorCode
        }
        if let errorDescription = errorDescription {
            params["reason"] = errorDescription
        }
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: params)
    }

    // 开始/结束直播失败
    static func trackStartLiveFail(meetingId: String, isStart: Bool, errorCode: Int? = nil, errorDescription: String? = nil) {
        var params: TrackParams = [.action_name: isStart ? "t_start_live_fail" : "t_end_live_fail", "meeting_id": meetingId]
        if let errorCode = errorCode {
            params["error_code"] = errorCode
        }
        if let errorDescription = errorDescription {
            params["reason"] = errorDescription
        }
        VCTracker.post(name: .vc_live_meeting_setting_click,
                       params: params)
    }

    // 在会中 toolbar 点击”邀请会议室系统“
    static func trackSIPInviteClick(isMore: Bool, isMeetingLocked: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "room_system_invite",
                                .target: TrackEventName.vc_meeting_room_system_invite_view,
                                "is_meeting_locked": isMeetingLocked,
                             keyIsMore: isMore])
    }

    // 在会议室系统邀请页，点击”呼叫“按钮
    static func trackSIPInviteButtonClick(roomType: MeetingRoomType, isMeetingLocked: Bool) {
        VCTracker.post(name: .vc_meeting_room_system_invite_click,
                       params: [.click: "call",
                                "is_meeting_locked": isMeetingLocked,
                                "room_type": roomType])
    }

    /// Preview页面展示时埋点
    /// - Parameter isWaiting: 是否在等候室中
    static func trackShowPreviewVC(isInWaitingRoom status: Bool, isCamOn: Bool, isMicOn: Bool) {
        VCTracker.post(name: .vc_meeting_pre_view,
                       params: [.is_starting_auth: status,
                                "is_cam_on": isCamOn,
                                "is_mic_on": isMicOn])
    }

    // 点击参会人列表中的用户设置
    static func trackParticipantsSettingButtonClick(isSharingContent: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "user_setting",
                                                                   .target: TrackEventName.vc_meeting_hostpanel_view,
                                                                   .isSharing: isSharingContent])
    }

    // 会中主持人操作页
    static func trackEnterHostpanel(fromSource: TrackFromSource) {
        VCTracker.post(name: .vc_meeting_hostpanel_view, params: [.from_source: fromSource.rawValue])
    }

    static func trackTipDontRemindAgain(clickTarget: String) {
        VCTracker.post(name: .vc_interview_meeting_dont_remind_again_popup_click, params: [.click: clickTarget, .target: "none"])
    }
}

// 横屏相关埋点
extension MeetingTracksV2 {

    enum OrientationChangeReason: String {
        /// 点击左上角转换按钮
        case click_switch_button
        /// 重力感应切换
        case gravity
        /// 共享表格（切为横屏）
        case share_sheet
        /// 开始妙享文档 / 思维笔记（切为竖屏）
        case share_doc_note
        /// 点击没有适配横屏的功能，包括直播、同传、响铃页、飞书主端页面等（切为竖屏）
        case click_function
        /// 离开会议
        case leave
    }

    /// 横竖屏点击切换事件
    static func trackChangeOrientation(toLandscape: Bool, reason: OrientationChangeReason) {

        let doTrack: (Bool) -> Void = { toLandscape in
            VCTracker.post(name: .vc_meeting_onthecall_click,
                           params: [.click: "change_screen_direction",
                                    .target: "none",
                                    .option: toLandscape ? "protrait_to_landscape" : "landscape_to_portrait",
                                    "reason": reason.rawValue])
        }

        doTrack(toLandscape)
    }

    /// 点击 topbar 返回按钮
    static func trackClickMobileBack() {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "mobile_back_button",
                                .target: "none"])
    }

    /// 会中点击切换同传语言
    static func trackChooseInterpretationLang(beforeLang: String, afterLang: String) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "choose_interpretation_language",
                                .target: "none",
                                "before_language": beforeLang,
                                "after_language": afterLang])
    }

    /// 移动端横屏状态下拖动麦克风
    static func trackHaulMic(isSharing: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "mobile_haul_mic",
                                keyIsSharing: isSharing])
    }

    /// 点击onthecall界面的略缩字幕窗口
    static func trackClickSubtitleMiniWindow() {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "subtitle_mini_click_window",
                                .target: "vc_meeting_subtitle_view"])
    }

    static func trackCloseSubtitleMiniWindow() {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: "subtitle_mini_close"])
    }

    static func trackShareScreenZoom(shareID: String, isZoomIn: Bool, isClick: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: isZoomIn ? "viewer_zoom_in" : "viewer_zoom_out",
                                "shared_id": shareID,
                                "type": isClick ? "double_click" : "two_finger_pinch"])
    }

    static func trackClickEnterprisePromotion(isToolBar: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: isToolBar ? "information_page" : "unfold_information_page"])
    }

    static func trackEnterprisePromotionShow(_ isShow: Bool) {
        VCTracker.post(name: .vc_interview_information_page_server,
                       params: ["status": isShow ? "start" : "end"])
    }

    static func trackDragSubtitle() {
        VCTracker.post(name: .vc_meeting_subtitle_click, params: [.click: "drag", "page_type": "realtime_subtitle"])
    }
}

private enum MeetingTracksTimeInterval {
    static var startTrack1v1ConnectionStartTime: TimeInterval?
}

enum MeetingTracksClickAction: String {
    /// 点击麦克风
    case clickMic = "mic"
    /// 点击摄像头
    case clickCamera = "cam"
    /// 控制栏点击主持人操作
    case clickHostPanel = "host_panel"
    /// 点击参会人
    case clickUserList = "userlist"
    /// 控制栏点击聊天
    case clickChat = "chat"
    /// 控制栏点击共享
    case clickShare = "share"
    /// 控制栏点击录音
    case clickRecord = "record"
    /// 控制栏点击转录
    case clickTranscribe = "transcribe"
    /// 控制栏点击录制
    case clickReaction = "reaction"
    /// 控制栏点击传译
    case clickInterpretation = "interpretation"
    /// 控制栏点击字幕
    case clickSubtitle = "subtitle"
    /// 控制栏点击直播
    case clickLive = "live"
    /// 控制栏点击复制直播链接
    case clickCopyLiveLink = "copy_live_link"
    /// 控制栏点击特效
    case clickEffect = "effect"
    /// 控制栏点击电话邀请
    case clickPhoneInvite = "phone_invite"
    /// 控制栏点击设置
    case clickSetting = "setting"
    /// 点击离开会议
    case clickLeave = "leave"
    /// 控制栏点击全员结束会议
    case clickEndMeeting = "end_meeting"
    /// 点击收起控制栏
    case clickHideControlBar = "hide_control_bar"
    /// 点击听筒/扬声器
    case clickReceiver = "is_receiver"
    /// 错误的类型
    case unknown = "unknown"

    var trackStr: String {
        return self.rawValue
    }

    var trackTarget: String? {
        if self == .clickInterpretation {
            // https://bytedance.feishu.cn/wiki/wikcnzZCPkuMunwsJCukkZGOZIg
            // 这个可能是当时漏了一个view，先不用管吧，毕竟其他端都是按照这个文档来的应该 by liwang.dylan
            return "vc_meeting_interpretation"
        } else {
            return _trackTarget?.rawValue
        }
    }

    private var _trackTarget: TrackEventName? {
        switch self {
        case .clickHostPanel:
            return .vc_meeting_hostpanel_view
        case .clickChat:
            return .vc_meeting_chat_send_message_view
        case .clickShare:
            return .vc_meeting_sharewindow_view
        case .clickRecord:
            return .vc_meeting_popup_view
        case .clickReaction:
            return .vc_meeting_chat_reaction_view
        case .clickInterpretation:
            return .vc_meeting_interpretation_view
        case .clickSubtitle:
            return .vc_meeting_subtitle_view
        case .clickLive:
            return .vc_live_meeting_setting_view
        case .clickEffect:
            return .vc_meeting_setting_view
        case .clickPhoneInvite:
            return .vc_meeting_phone_invite_view
        case .clickSetting:
            return .vc_meeting_setting_view
        case .clickEndMeeting:
            return .vc_meeting_popup
        default:
            return nil
        }
    }
}
