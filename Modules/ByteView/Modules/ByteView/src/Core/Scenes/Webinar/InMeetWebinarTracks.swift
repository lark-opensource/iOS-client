//
// Created by liujianlong on 2022/10/27.
//

import Foundation
import ByteViewTracker

/// https://bytedance.feishu.cn/sheets/shtcnRBlPLEt0VNRQq7YEAbO1sh?sheet=KFuJbbI
enum InMeetWebinarTracks {
    // 会中弹窗显示事件
    enum PopupView {
        // webinar_invite_tobe_panelist: 邀请观众成为嘉宾(观众侧弹窗)
        static func webinarInviteToBePanelist() {
            VCTracker.post(name: .vc_meeting_popup_view, params: [
                .content: "webinar_invite_tobe_panelist"
            ])
        }
        /*
        // panelist_invite_success: 被邀观众将以嘉宾身份入会(邀请成功)
        static func panelListInviteSuccess() {
            VCTracker.post(name: .vc_meeting_popup_view, params: [
                .content: "panelist_invite_success",
            ])
        }

        // panelist_invite_fail: 被邀观众拒绝以嘉宾身份入会(邀请被拒)
        static func panelListInviteFail() {
            VCTracker.post(name: .vc_meeting_popup_view, params: [
                .content: "panelist_invite_success",
            ])
        }

        // set_attendee_success: 将嘉宾设为观众成功后的toast
        static func setAttendeeSuccess() {
            VCTracker.post(name: .vc_meeting_popup_view, params: [
                .content: "set_attendee_success",
            ])
        }
         */

        /// role_change_fail: 嘉宾、观众切换事件失败toast
        /// - Parameters:
        ///   - action: panelist_to_attendee: 将嘉宾切换为观众, attendee_to_panelist: 将观众切换为嘉宾
        ///   - reason: version: 被操作者的版本不支持切换, device_model: 被操作者的设备类型不支持切换, others: 其它导致失败的原因
        static func roleChangeFail(action: String,
                                   errorCode: Int?) {
            let reason: String
            switch errorCode {
            case VCError.DeviceVersionNotSupportBecomeAttendee.code:
                reason = "version"
            case VCError.DeviceTypeNotSupportBecomeAttendee.code:
                reason = "device_model"
            default:
                reason = "others"
            }
            VCTracker.post(name: .vc_meeting_popup_view, params: [
                .content: "role_change_fail",
                "reason": reason,
                "action": action
            ])
        }

        // host_request_unmute：收到主持人请求开麦的弹窗
        static func hostRequestUnmute() {
            VCTracker.post(name: .vc_meeting_popup_view, params: [
                .content: "host_request_unmute"
            ])
        }
    }

    enum PopupClick {
        // webinar_set_panelist_confirm: 确认被设置为嘉宾
        // webinar_set_panelist_refuse: 确认继续当观众"
        static func acceptHostRequestBecomeParticipant(accept: Bool) {
            VCTracker.post(name: .vc_meeting_popup_click, params: [
                .content: "webinar_invite_tobe_panelist",
                .click: accept ? "webinar_set_panelist_confirm" : "webinar_set_panelist_refuse"
            ])
        }

        // host_request_unmute：收到主持人请求开麦的弹窗
        static func acceptHostRequestUnmute(accept: Bool) {
            VCTracker.post(name: .vc_meeting_popup_click, params: [
                .content: "host_request_unmute",
                .click: accept ? "unmute" : "mute"
            ])
        }
    }

    enum RoleChange {
        /// webinar角色切换转场失败时的按钮展示事件
        /// - Parameter action: panelist_to_attendee: 将嘉宾切换为观众, attendee_to_panelist: 将观众切换为嘉宾
        static func buttonView(action: String) {
            VCTracker.post(name: .vc_webinar_role_change_rejoin_view, params: [
                "action_type": action
            ])
        }

        static func rejoinButtonClick(action: String) {
            VCTracker.post(name: .vc_webinar_role_change_rejoin_click, params: [
                .click: "rejoin",
                "action_type": action
            ])
        }

        static func leaveButtonClick(action: String) {
            VCTracker.post(name: .vc_webinar_role_change_rejoin_click, params: [
                .click: "leave",
                "action_type": action
            ])
        }
    }

    enum HostPanel {
        // panelist_self_unmute: 允许嘉宾自己打开麦克风
        // panelist_change_name: 允许嘉宾修改会中姓名
        // attendee_apply_unmute: 允许观众申请发言
        // attendee_change_name: 允许观众修改会中姓名
        static func attendeeChangeName(isCheck: Bool, fromSource: String) {
            VCTracker.post(name: .vc_meeting_hostpanel_click, params: [
                .click: "attendee_change_name",
                "is_check": isCheck,
                "from_source": fromSource
            ])
        }
        static func attendeeApplyUnmute(isCheck: Bool, fromSource: String) {
            VCTracker.post(name: .vc_meeting_hostpanel_click, params: [
                .click: "attendee_apply_unmute",
                "is_check": isCheck,
                "from_source": fromSource
            ])
        }
        static func panelistChangeName(isCheck: Bool, fromSource: String) {
            VCTracker.post(name: .vc_meeting_hostpanel_click, params: [
                .click: "panelist_change_name",
                "is_check": isCheck,
                "from_source": fromSource
            ])
        }
       static func panelistSelfUnmute(isCheck: Bool, fromSource: String) {
           VCTracker.post(name: .vc_meeting_hostpanel_click, params: [
               .click: "panelist_self_unmute",
               "is_check": isCheck,
               "from_source": fromSource
           ])
       }
    }

    // set_panelist: 将观众设置为嘉宾
    static func setPanelist(userID: String, location: String) {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [
            .click: "set_panelist",
            .location: location,
            "set_user_id": EncryptoIdKit.encryptoId(userID)
        ])
    }

    // set_attendee: 将嘉宾设置为观众
    static func setAttendee(userID: String, location: String) {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [
            .click: "set_attendee",
            .location: location,
            "set_user_id": EncryptoIdKit.encryptoId(userID)
        ])
    }

    static func startWebinarFromRehearsal() {
        VCTracker.post(name: .vc_meeting_popup_click, params: [
            .click: "start_webinar_from_rehearsal"
        ])
    }

    static func endRehearsalForAll() {
        VCTracker.post(name: .vc_meeting_popup_click, params: [
            .click: "end_rehearsal"
        ])
    }
}
