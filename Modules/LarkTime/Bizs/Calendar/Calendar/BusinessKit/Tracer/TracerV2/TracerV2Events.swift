//
//  TracerV2Events.swift
//  Calendar
//
//  Created by Rico on 2021/6/25.
//

import Foundation

// MARK: - 日历列表页
extension CalendarTracerV2 {

    struct CalendarList: TracerEvent {

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        static let eventName = "cal_calendar_list"

        struct ViewParams: ViewParamType {
            var base = BaseViewParams()
        }
        struct ClickParams: ClickParamType {
            var base = BaseClickParams()
            var calendar_id = ""
            var under_management = ""
        }
    }
}

// MARK: - 点击添加日历弹窗
extension CalendarTracerV2 {

    struct CalendarActionList: TracerEvent {

        static let eventName = "cal_calendar_action_list"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: - 新建日历页
extension CalendarTracerV2 {

    struct CalendarCreate: TracerEvent {
        static let eventName = "cal_calendar_create"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var has_description: String?
            var has_alias: String?
            var auth_value: String?
        }
    }
}

// MARK: - 日历删除确认
extension CalendarTracerV2 {
    struct CalendarDeleteConfirm: TracerEvent {
        static let eventName = "cal_calendar_delete_confirm"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var calendar_id = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var calendar_id = ""
        }
    }
}

// MARK: - 日历详情卡片
extension CalendarTracerV2 {
    struct CalendarCard: TracerEvent {
        static let eventName = "cal_calendar_card"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var calendar_id = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var calendar_id = ""
        }
    }
}

// MARK: - 群忙闲
extension CalendarTracerV2 {
    struct CalendarChat: TracerEvent {
        static let eventName = "cal_calendar_chat"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var has_event = ""
            var chat_id = ""
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var chat_id = ""
        }
    }
}

// MARK: - 单个Profile进入忙闲
extension CalendarTracerV2 {
    struct CalendarProfile: TracerEvent {
        static let eventName = "cal_calendar_profile"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: - 订阅日历
extension CalendarTracerV2 {

    /// 订阅日历
    struct CalendarSubscribe: TracerEvent {
        static let eventName = "cal_calendar_subscribe"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var calendar_id = ""
        }
    }
}

// MARK: - 日程删除确认
extension CalendarTracerV2 {
    struct EventDeleteConfirm: TracerEvent {
        static let eventName = "cal_event_delete_confirm"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var delete_or_exit = ""
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var is_group_remain = ""
            var delete_or_exit = ""
        }
    }
}

// MARK: - 日程删除通知
extension CalendarTracerV2 {
    struct EventDeleteNotification: TracerEvent {
        static let eventName = "cal_event_delete_notification"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var is_group_remain = "none"
        }
    }
}

// MARK: - 创建会议群组
extension CalendarTracerV2 {
    struct EventChatCreateConfirm: TracerEvent {
        static let eventName = "cal_event_chat_create_confirm"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var event_type = ""
            var is_have_mail_parti = ""
            var is_organizer = ""
            var is_organizer_included = ""
            var popup_type = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var event_type = ""
            var is_have_mail_parti = ""
            var is_organizer = ""
            var is_organizer_included = ""
            var popup_type = ""
        }
    }
}

// MARK: - 日程「更多」弹窗
extension CalendarTracerV2 {
    struct EventMore: TracerEvent {
        static let eventName = "cal_event_more"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var is_report = ""
            var is_transfer = ""
            var is_delete = ""
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: - 日程转让
extension CalendarTracerV2 {
    struct EventTransfer: TracerEvent {
        static let eventName = "cal_event_transfer"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: - 日程消息卡片
extension CalendarTracerV2 {

    struct EventCard: TracerEvent {

        static let eventName = "cal_event_card"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        struct ViewParams: ViewParamType {
            var base = BaseViewParams()
            var is_invited = ""
            var is_updated = ""
            var chat_id = ""
            var event_type = ""
            var is_new_card_type = ""
            var is_support_reaction = ""
            var is_bot = ""
            var card_value = ""
            var calendar_id = ""
            var is_share = ""
            var is_reply_card = ""
        }

        struct ClickParams: ClickParamType {
            var base = BaseClickParams()
            var chat_id = ""
            var rsvp_status = ""
            var is_invited = ""
            var is_updated = ""
            var event_type = ""
            var is_new_card_type = ""
            var is_support_reaction = ""
            var is_bot = ""
            var card_value = ""
            var calendar_id = ""
            var is_share = ""
            var is_reply_card = ""
        }
    }
}

// MARK: - 日程详情页
extension CalendarTracerV2 {
    struct EventDetail: TracerEvent {
        static let eventName = "cal_event_detail"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var has_description = ""
            var has_doc = ""
            var event_type = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var file_id: String?
            var file_type: String?
            var rsvp_status = ""
            var vchat_type: String?
            var is_create: String?
            var event_type = ""
            var link_type: String?
            var status: String = ""
            var token: String?
        }

        static func parseFileType(with urlStr: String) -> String {
            var rawStr = "none"
            let components = urlStr.components(separatedBy: "/")
            if components.count >= 2 {
                rawStr = components[components.count - 2]
            }
            let map = [
                "docs": "doc",
                "sheets": "sheet",
                "base": "bitable",
                "mindnotes": "mindnote",
                "slides": "slide"
            ]
            return map[rawStr] ?? rawStr
        }

        static func rsvpStr(status: CalendarEventAttendee.Status) -> String {
            switch status {
            case .accept: return "accept"
            case .decline: return "reject"
            case .tentative: return "not_determined"
            case .needsAction: return "no_rsvp"
            @unknown default: return "none"
            }
        }
    }
}

extension CalendarTracerV2 {
    struct EventDetailParseVC: TracerEvent {
        static let eventName = "cal_event_detail_parse_vc"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        struct ViewParams: ViewParamType {
            var base = BaseViewParams()
            var parse_vc_link_num = ""
        }

        struct ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: - 日程分享页
extension CalendarTracerV2 {
    struct EventShare: TracerEvent {
        static let eventName = "cal_event_share"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        struct ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        struct ClickParams: ClickParamType {
            var base = BaseClickParams()
            var chat_nums: Int?
            var message: String?
        }
    }
}

// MARK: 编辑页有效会议 AI 场景
extension CalendarTracerV2 {
    struct CreateAIMeetingNotes: TracerEvent {
        static let eventName = "cal_event_full_create_ai_notes"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        struct ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        struct ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: - 日程编辑页
extension CalendarTracerV2 {
    struct EventFullCreate: TracerEvent {
        static let eventName = "cal_event_full_create"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        struct ViewParams: ViewParamType {
            var base = BaseViewParams()
            var event_type: String?
            var is_editor = ""
            var from_source: String?
            var attendee_num: Int?
            var schedule_conflict_num: Int?
        }

        struct ClickParams: ClickParamType {
            var base = BaseClickParams()
            var event_type: String?
            var tab_type: String?
            var vc_type: String?
            var has_description: String?
            var has_group_attendee: String?
            var has_architecture_attendee: String?
            var has_title: String?
            var title_length: Int?
            var is_new_create: String?
            var is_time_alias: String?
            var is_title_alias: String?
            var is_rrule_alias: String?
            var rrule_type: String?
            var desc_has_doc: String?
            var reason: String?
            var status: String?
            var template_id: String?
            var has_meeting_notes: String?
            var is_device_timezone: String?
            var have_ai: String?
            var task_type: String?
        }
    }
    
    // 创建页参与者位于不同时区提示 展示
    struct EventCreateDifferentTimezone: TracerEvent {
        static let eventName = "cal_event_full_create_different_timezone"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }
        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: - 视频会议设置
extension CalendarTracerV2 {
    struct EventVCSetting: TracerEvent {
        static let eventName = "cal_vc_setting"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        struct ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        struct ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: - 单个日历的设置页
extension CalendarTracerV2 {
    struct CalendarSetting: TracerEvent {
        static let eventName = "cal_calendar_setting"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var calendar_id = ""
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var calendar_id = ""
            var has_alias = ""
            var auth_value = ""
            var is_title_alias = ""
            var is_desc_alias = ""

        }
    }
}

// MARK: - 日历总设置页
extension CalendarTracerV2 {
    struct SettingCalendar: TracerEvent {
        static let eventName = "setting_calendar"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var is_checked: String?
        }
    }
}

// MARK: 重复性日程截止时间调整提醒弹窗
extension CalendarTracerV2 {
    enum AdjustRemindLocation: String {
        // 完整创建/编辑日程页
        case editEventView = "edit_event_view"
        // 重复性规则编辑弹窗页
        case editRruleView = "edit_rrule_view"
        // 会议室预定页面
        case addResourceView = "add_resource_view"
    }
    struct UtiltimeAdjustRemind: TracerEvent {
        static let eventName = "cal_utiltime_adjust_remind"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var location = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var location = ""
        }
    }
}

// MARK: - 应用内日程提醒卡片
extension CalendarTracerV2 {
    struct EventNotification: TracerEvent {
        static let eventName = "cal_event_notification"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: - 新建-分享选人页面
extension CalendarTracerV2 {
    struct CalendarCreateInvite: TracerEvent {
        static let eventName = "cal_calendar_create_invite"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var calendar_id = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var calendar_id = ""
        }
    }
}

// MARK: - 日历分享邀请页
extension CalendarTracerV2 {
    struct CalendarShareInviteView: TracerEvent {
        static let eventName = "cal_calendar_share_invite"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var calendar_id = ""
            var is_admin_plus: String = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var calendar_id = ""
            var is_admin_plus: String = ""
        }
    }
}

// MARK: - 视图页
extension CalendarTracerV2 {
    struct CalendarMain: TracerEvent {
        static let eventName = "cal_calendar_main"
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()

            var type: String = ""
        }
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }
    }

    struct ChangeTaskConfirm: TracerEvent {
        static let eventName = "cal_change_task_confirm"
        final class ViewParams: ViewParamType {
            var base = BaseViewParams()

            var task_id: String = ""
        }
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()

            var task_id: String = ""
        }
    }
}

// MARK: - 日历分享确认页
extension CalendarTracerV2 {
    struct CalendarShareConfirm: TracerEvent {
        static let eventName = "cal_calendar_share_confirm"

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var calendar_id = ""
            var with_note = "none"
            var is_create_invite = ""
        }

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var calendar_id = ""
        }
    }
}

// MARK: - 日历分享页
extension CalendarTracerV2 {
    struct CalendarShare: TracerEvent {
        static let eventName = "cal_calendar_share"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var calendar_id = ""
            var is_admin_plus = ""
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var calendar_id = ""
            var is_admin_plus = ""
        }
    }
}

// MARK: - 日历已分享页
extension CalendarTracerV2 {
    struct CalendarSubscribers: TracerEvent {
        static let eventName = "cal_calendar_subscribers"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var calendar_id = ""
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var calendar_id = ""
        }
    }
}

// MARK: - 日历已分享页
extension CalendarTracerV2 {
    struct CalendarQRCode: TracerEvent {
        static let eventName = "cal_calendar_qr_code"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var calendar_id = ""
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var calendar_id = ""
        }
    }
}

// MARK: - 邀请订阅日历卡片的动作事件
extension CalendarTracerV2 {
    struct CalendarSubscribeInviteCard: TracerEvent {
        static let eventName = "cal_calendar_subscribe_invite_card"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var calendar_id = ""
            var is_added_by_admin = ""
        }
    }
}

// MARK: - 日程已选参与人页
extension CalendarTracerV2 {
    struct EventAttendeeList: TracerEvent {
        static let eventName = "cal_event_attendee_list"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: - 日程编辑二级页-添加会议室
extension CalendarTracerV2 {
    struct EventAddResource: TracerEvent {
        static let eventName = "cal_event_add_resource"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var top_initial_group_id = ""
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var reousrce_id: String?
            var group_id: String?
            var initial_group_id: String?
            var is_top_group: String?
            var is_top_initial_group: String?
            var is_recently_used: String?
        }
    }
}

// MARK: - 视图页&编辑页 会议室预定失败弹窗提示
extension CalendarTracerV2 {
    struct RoomNoReserveConfirm: TracerEvent {
        static let eventName = "cal_room_no_reserve_confirm"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: 会议室不可预定的气泡弹窗
extension CalendarTracerV2 {
    struct FullCreateRoomsReservePopView: TracerEvent {
        static let eventName = "cal_event_full_create_rooms_reserve_pop_view"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var content = ""
        }
        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: 大人数日程弹窗
extension CalendarTracerV2 {
    struct EventAttendeeReachLimit: TracerEvent {
        static let eventName = "cal_event_attendee_reach_limit"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var content = ""
            var role = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var content = ""
            var role = ""
        }
    }
}

// MARK: 有效会议
extension CalendarTracerV2 {
    struct EventFullCreateNotesPermission: TracerEvent {
        static let eventName = "cal_event_full_create_notes_permission"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: 日程编辑页取消弹窗
extension CalendarTracerV2 {
    struct EventCreateCancelConfirm: TracerEvent {
        static let eventName = "cal_event_create_cancel_confirm"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var will_delete_notes: String = "false"
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var will_delete_notes: String = "false"
        }
    }
}

// MARK: 日历助手卡片
extension CalendarTracerV2 {
    struct BotMessage: TracerEvent {
        static let eventName = "cal_bot_message"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var content = ""
        }
    }
}

// MARK: 新建/编辑日程取消不发送通知选项
extension CalendarTracerV2 {
    struct EventCreateConfirm: TracerEvent {
        static let eventName = "cal_event_create_confirm"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var view_type = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var view_type = ""
            var is_share = "none"
            var is_checked = ""
            var chat_strategy = ""
            var chat_id = ""
        }
    }
}

// MARK: exchange oauth
extension CalendarTracerV2 {
    struct ExchangeAccountIsExpiring: TracerEvent {
        static let eventName = "cal_external_cal_expire"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: 日程高管模式
extension CalendarTracerV2 {
    struct EventCopyFilteredMembers: TracerEvent {
        static let eventName = "cal_event_unable_copy_all_guests_view"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var action_source = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }

    struct EventNoAutoToInvite: TracerEvent {
        static let eventName = "cal_event_admin_set_no_invite_view"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var action_source = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: 日程签到
extension CalendarTracerV2 {
    struct CheckInSetting: TracerEvent {
        static let eventName = "cal_check_in_setting"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()

        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var begin_check_in_type: String?
            var begin_check_in_time: Int64?
            var finish_check_in_type: String?
            var finish_check_in_time: Int64?
            var is_send: String?
            // 是否点击了签到按钮
            var is_check: String?
        }
    }

    struct CheckInfo: TracerEvent {
        static let eventName = "cal_check_info"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()

        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }

    struct NoticeBotCard: TracerEvent {
        static let eventName = "cal_notice_bot_card"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var conf_id: String = ""
            var timestamp: Int64 = 0
            var button_num: Int64 = 0
        }
    }

    struct CancelCheckInEvent: TracerEvent {
        static let eventName = "cal_cancel_check_in_event"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: RSVP 确认弹窗
extension CalendarTracerV2 {
    struct RsvpConfirmForRepeatedEvent: TracerEvent {
        static let eventName = "cal_rsvp_confirm_for_repeated_event"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var type: String = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var type: String = ""
            var accept_type: String?
        }
    }
}

// MARK: 全员日历不可退订弹窗
extension CalendarTracerV2 {
    struct CalendarNoUnsubscribe: TracerEvent {
        static let eventName = "cal_calendar_no_unsubscribe"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var calendar_id: String = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

extension CalendarTracerV2 {
    struct EventZoomSetting: TracerEvent {
        static let eventName = "cal_event_zoom_setting"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: 日程详情描述中doc加载
extension CalendarTracerV2 {
    struct EventDetailDoc: TracerEvent {
        static let eventName = "cal_event_detail_doc"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var has_doc: String = ""
            var event_type: String = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: 日程创建确认
extension CalendarTracerV2 {
    struct EventCreateConform: TracerEvent {
        static let eventName = "cal_event_create_confirm"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var is_share: String = ""
        }
    }
}

// MARK: APP内弹窗通知
extension CalendarTracerV2 {
    struct InAppCardNotification: TracerEvent {
        static let eventName = "cal_inapp_notification"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var time = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var noti_type = ""
            var time = ""
            var click_position = ""
        }
    }
}

// MARK: 申请入群弹窗通知
extension CalendarTracerV2 {
    struct ApplyJoinGroup: TracerEvent {
        static let eventName = "cal_event_apply_join_group"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()

        }
    }
}

// MARK: 参与人权限设置页
extension CalendarTracerV2 {
    struct EventAttendeeAuthSetting: TracerEvent {
        static let eventName = "cal_event_attendee_auth_setting"
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var edit_event_alias: String = ""
            var invite_attendee_alias: String = ""
            var show_attendee_list_alias: String = ""
        }
    }
}

extension CalendarTracerV2 {
    struct SchedulerEventCard: TracerEvent {
        static let eventName = "cal_scheduler_event_card"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var appointment_id: String = ""
            var scheduler_id: String = ""
            var scheduler_event_type: String = ""
            var chat_id: String = ""
            var is_scheduler_creator: String = ""
        }
    }
}

extension CalendarTracerV2 {
    struct RepeatedEventReachLimit: TracerEvent {
        static let eventName = "cal_repeated_event_reach_limit"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var is_new_create: String?
            var limit_number: Int?
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}


extension CalendarTracerV2 {
    struct ToastStatus: TracerEvent {
        static let eventName = "cal_toast_status"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var toast_name: String?
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}

// MARK: 今日事件页
extension CalendarTracerV2 {
    struct TodayEventView: TracerEvent {
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var event_cnt: Int = 0
            var vc_cnt: Int = 0
            var cal_cnt: Int = 0
            var live_cnt: Int = 0
            var today_cal_cnt: Int = 0
            var is_has_today_cal_widget: Int = 0
            var is_top: Int = 0
            var show_cal_id: String = ""
            var feed_tab: String = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }

        static var eventName: String = "feed_event_list_view"
    }

    struct TodayEventCilck: TracerEvent {
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var is_top: Int = 0
            var feed_tab: String = ""
        }

        static var eventName: String = "feed_event_list_click"
    }
}

// MARK: 辅助时区页面
extension CalendarTracerV2 {
    struct AdditionalTimeZoneClick: TracerEvent {
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
            var option: String = ""
        }

        static var eventName: String = "cal_timezone_setting_click"
    }
}

// MARK: 会议群Banner
extension CalendarTracerV2 {
    struct MeetingGroupBannerTransfer: TracerEvent {
        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }

        static var eventName: String = "cal_chat_trans"
    }
}
