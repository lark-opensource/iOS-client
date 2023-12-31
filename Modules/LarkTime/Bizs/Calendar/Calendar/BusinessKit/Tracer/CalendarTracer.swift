//
//  CalendarTracer.swift
//  Calendar
//
//  Created by linlin on 2018/3/21.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import LarkUIKit
import LKCommonsTracker
// swiftlint:disable identifier_name
// swiftlint:disable file_length

typealias Tracer = CalendarTracer

final class CalendarTracer {

    static let shareInstance = CalendarTracer()
    static var shared: CalendarTracer { shareInstance }

    func writeEvent(eventId: String, params: [String: Any] = [:]) {
        var tempParams = params
        tempParams["platform"] = Display.pad ? "iPad" : "iPhone"
        Tracker.post(TeaEvent(eventId, category: nil, params: tempParams))
    }

    func groupFreeBusyChooseMember(type: String) {
        writeEvent(eventId: "cal_findtime_open_member", params: ["action_type": type])
    }

    func groupFreeBusyChooseMemberCount(memberCount: Int) {
        writeEvent(eventId: "cal_findtime_member_confirm", params: ["member_count": memberCount])
    }

    func calTransformWhenRemoveEvent(isWebinar: Bool = false) {
        writeEvent(eventId: "cal_transform", params: ["action_source": "delete_event", "event_type": isWebinar ? "webinar" : "normal"])
    }

    // 转普通群二次确认
    func trackToNormalGroupPopupClicked(_ accept: Bool) {
        writeEvent(eventId: "cal_transform_popup", params: ["action_type": accept ? "yes" : "no",
                                                   "action_source": "banner"])
    }

    enum SearchType: String {
        case search
        case recom
    }

    enum PageType: String {
        case contacts
        case mtgrooms
        case public_cal
    }

    /// RSVP附言
    func rsvpReplyFromEventDetail() {
        writeEvent(eventId: "cal_rsvp_rply", params: ["action_source": "event_detail"])
    }
}

// MARK: - 性能监控相关
extension CalendarTracer {
//    enum ViewType: String {
//        case list, day, threeday, month
//    }
    /// 首屏渲染时间
    func perfCalLaunch(costTime: Double,
                       launchTimeTracer: LaunchTimeTracer?,
                       viewType: CalendarTracer.ViewType) {

        var viewTypeStr = viewType.rawValue
        var params: [String: Any] = ["cost_time": costTime,
                      "view_type": viewTypeStr,
                      "memory_length": TimerMonitorHelper.shared.getCalendarLaunchMem()]
        if let launchTimeTracer = launchTimeTracer {
            params["launch_later_app_time"] = launchTimeTracer.launchLaterApp.cost
            params["data_source"] = launchTimeTracer.getInstance.isTraced() ? "disk" : "rust"
            params["show_grid_cost"] = launchTimeTracer.showGrid.cost
            params["get_instance_cost"] = launchTimeTracer.getInstance.cost
            params["handle_instance_cost"] = launchTimeTracer.handleInstance.cost
            params["viewDidLoad_cost"] = launchTimeTracer.viewDidLoad.cost
            params["get_instanceLayout_cost"] = launchTimeTracer.getInstanceLayout.cost
            params["init_view_cost"] = launchTimeTracer.initEventVC.cost
            params["didAppearGap_cost"] = launchTimeTracer.didAppearGap.cost
            params["instanceRenderGap_cost"] = launchTimeTracer.instanceRenderGap.cost
            params["load_setting_cost"] = launchTimeTracer.loadSetting.cost
            params["render_instance_cost"] = launchTimeTracer.renderInstance.cost
            params["cached_instances_lenght"] = TimerMonitorHelper.shared.getCachedInstanceLength()
            params["data_length"] = TimerMonitorHelper.shared.getFirstScreenInstancesLength()
            params["launch_type"] = "cold_launch"
        } else {
            params["launch_type"] = "cold_launch_new"
        }

        operationLog(message: params.description, optType: "perf_cal_launch")
        var buildConfig = "release"
        #if DEBUG
        buildConfig = "debug"
        #endif

        debugPrint("xxx perf_cal_launch cost \(params)")

        if buildConfig == "release" {
            if costTime > 550 {
                Tracker.post(SlardarEvent(
                    name: "cal_old_home_launch_assert",
                    metric: ["cost": costTime],
                    category: ["view_type": viewTypeStr],
                    extra: params
                ))
                normalErrorLog(params.description, type: "perf_cal_launch")
            }
            writeEvent(eventId: "perf_cal_launch",
                       params: params)
        }

    }

    /// 邀请 分享 转让 侧边栏 提醒 视图页
    enum ActionSource: String {
        case msg_invite, msg_share, msg_transfer, side_bar, remind, instance, search, mail, off_line, vc_unique, room, local, refresh, rsvp_card
    }

    func detailViewLoadTime(costTime: Double,
                            actionSource: ActionSource, calEventId: String, originalTime: Int64, uid: String, viewType: HomeSceneMode? ) {

        var params = ["cost_time": costTime,
                      "action_source": actionSource.rawValue,
                      "cal_event_id": calEventId,
                      "original_time": originalTime,
                      "uid": uid] as [String: Any]

        var viewTypeStr: String = ""
        if let type = viewType {
            switch type {
            case .list:
                viewTypeStr = "list"
            case .month:
                viewTypeStr = "month"
            case .day(.three):
                viewTypeStr = "three"
            case .day(.single):
                viewTypeStr = "day"
            default: break
            }
            params["view_type"] = viewTypeStr
        }

        writeEvent(eventId: "perf_cal_event_show",
                   params: params)
    }

    /// sdk请求时间
    func perfCalSdkCall(costTime: Double, command: String) {
        writeEvent(eventId: "perf_cal_sdk_call",
                   params: ["cost_time": costTime,
                            "command": command])
    }

    /// getInstance 接口调用时间
    func perfCalGetIns(costTime: Double, dataLength: Int, querySpan: Int64) {
        writeEvent(eventId: "perf_cal_get_ins",
                   params: ["cost_time": costTime,
                            "query_span": querySpan,
                            "data_length": dataLength])
    }

    /// 日历通用的性能埋点
    func calPerfCommon(costTime: Double, sceneType: String, extraName: String, calNum: Int? = nil, calEventId: String? = nil, originalTime: Int64? = nil, uid: String? = nil, viewType: String? = nil,versionName: String? = nil, totalInstanceNum: Int? = nil) {
        var params = ["cost_time": costTime,
                      "scene_type": sceneType,
                      "extra_name": extraName] as [String: Any]
        if let viewType = viewType {
            params["view_type"] = viewType
        }
        if let calNum = calNum {
            params["cal_num"] = calNum
        }
        if let calEventId = calEventId {
            params["cal_event_id"] = calEventId
        }
        if let originalTime = originalTime {
            params["original_time"] = originalTime
        }
        if let uid = uid {
            params["uid"] = uid
        }
        if let versionName = versionName {
            params["version_name"] = versionName
        }
        
        if let totalInstanceNum = totalInstanceNum {
            params["total_instance_num"] = totalInstanceNum
        }
        writeEvent(eventId: "cal_perf_common",
                   params: params)
    }

    /// 日历通用的性能埋点
    func calPerfCacheHitRatio(hitCount: Int, requestCount: Int, viewType: String) {
        writeEvent(eventId: "cal_instance_cache",
                   params: ["hit_count": hitCount,
                            "request_count": requestCount,
                            "view_type": viewType])
    }

    func calEventLatencyDev(costTime: Double, click: String, isSuccess: Bool, errorCode: String, calEventID: String, originalTime: Int64, uid: String, extraName: String? = nil) {

        var params = ["cost_time": costTime,
                      "click": click,
                      "is_success": isSuccess.description,
                      "error_code": errorCode,
                      "cal_event_id": calEventID,
                      "original_time": originalTime,
                      "uid": uid] as [String: Any]
        if let extraName = extraName {
            params["extra_name"] = extraName
        }

        writeEvent(eventId: "cal_event_latency_dev",
                   params: params)
    }

    func freeBusyTapToLeft() {
        writeEvent(eventId: "cal_left")
    }

    func perfZoomMeetingCreate(costTime: Double) {
        writeEvent(eventId: "cal_stability_dev",
                   params: ["cost_time": costTime,
                            "scene_type": "create_zoom_vc_info"])
    }

}

// MARK: - 本地日历相关
extension CalendarTracer {
    func grandAccess(haveAccess: Bool) {
        let param = haveAccess ? "allow" : "do_not_allow"
        writeEvent(eventId: "event_settings_subscribe_local_calendar",
                   params: ["access_grand": param])
    }

    func subscribeLocalCalendar(_ count: Int) {
        writeEvent(eventId: "event_local_calendar_on_count",
                   params: ["switch_on_acct_count": count])
    }

    func jumpToPrivacySetting() {
        writeEvent(eventId: "event_local_grant_access_manual")
    }

    func editEvent(isTimeChanged: Bool,
                   isTitleChanged: Bool,
                   isAlarmsChanged: Bool,
                   isSiteChanged: Bool,
                   isRepeatChanged: Bool,
                   isDescChanged: Bool) {
        let actionID = Int(arc4random())
        if isTimeChanged {
            writeEvent(eventId: "event_local_calendar_detail_edit",
                       params: ["edit_info": "time", "actionid": actionID])
        }
        if isTitleChanged {
            writeEvent(eventId: "event_local_calendar_detail_edit",
                       params: ["edit_info": "title", "actionid": actionID])
        }
        if isAlarmsChanged {
            writeEvent(eventId: "event_local_calendar_detail_edit",
                       params: ["edit_info": "alerts", "actionid": actionID])
        }
        if isSiteChanged {
            writeEvent(eventId: "event_local_calendar_detail_edit",
                       params: ["edit_info": "site", "actionid": actionID])
        }
        if isRepeatChanged {
            writeEvent(eventId: "event_local_calendar_detail_edit",
                       params: ["edit_info": "repeat", "actionid": actionID])
        }
        if isDescChanged {
            writeEvent(eventId: "event_local_calendar_detail_edit",
                       params: ["edit_info": "description", "actionid": actionID])
        }
    }

    func deleteEvent() {
        let actionID = Int(arc4random())
        writeEvent(eventId: "event_local_calendar_detail_edit",
                   params: ["edit_info": "delete", "actionid": actionID])
    }
}

// swiftlint:disable nesting

// MARK: - 点击进入日历tab
extension CalendarTracer {
    enum ViewType: String {
        case list
        case day
        case threeday
        case month
        case week
        case none = ""

        init(mode: DayViewSwitcherMode) {
            switch mode {
            case .month:
                self = .month
            case .schedule:
                self = .list
            case .singleDay:
                self = .day
            case .threeDay:
                self = .threeday
            case .week:
                    self = .week
            }
        }
    }

    enum EventType: String {
        case meeting = "meeting"
        case event = "event"
        case email = "email"
        case localEvent = "local_event"
        case googleEvent = "google_event"
        case exchangeEvent = "exchange_event"
        case unknown = ""

        init(calendarEventEntity: CalendarEventEntity) {
            self = .unknown
            if calendarEventEntity.isGoogleEvent() {
                self = .googleEvent
            } else if calendarEventEntity.isExchangeEvent() {
                self = .exchangeEvent
            } else if calendarEventEntity.isLocalEvent() {
                self = .localEvent
            } else if calendarEventEntity.isEmailEvent() {
                self = .email
            } else if calendarEventEntity.type == .meeting {
                self = .meeting
            } else {
                self = .event
            }
        }
    }

    struct CalTab {
        enum ThemeType: String {
            case dark
            case light

            init(skinType: CalendarSkinType) {
                switch skinType {
                case .light:
                    self = .light
                case .dark:
                    self = .dark
                @unknown default:
                    self = .light
                }
            }

        }
    }

    /// 点击tab进入日历页
    ///
    /// - Parameters:
    ///   - viewType: 日历页所在的视图类型
    ///   - themeType: 日历皮肤的类型
    func calTab(viewType: ViewType, calendarID: String, themeType: CalTab.ThemeType) {
        writeEvent(eventId: "cal_tab", params:
            ["view_type": viewType.rawValue,
             "theme_type": themeType.rawValue,
             "calendar_id": calendarID])
    }
}

// MARK: - RSVP 回复状态
extension CalendarTracer {
    struct CalReplyEventParam {
        enum ActionSource: String {
            case eventDetail = "event_detail"
            case cardMessage = "card_message"
        }

        enum CalEventResp: String {
            case acpt
            case decl
            case mayb
            case unknown = "" // 本地日程，黑盒，拿不到具体的操作

            init?(status: CalendarEventAttendeeEntity.Status) {
                switch status {
                case .accept:
                    self = .acpt
                case .decline:
                    self = .decl
                case .tentative:
                    self = .mayb
                @unknown default:
                    return nil
                }
            }
        }

        enum CardMessageType: String {
            case invitation = "invitation"
            case shareEvent = "share_event"
            case none = "no_value"
        }
    }

    func calReplyEventInCard(event: CalendarEventEntity, status: CalendarEventAttendee.Status, chatId: String, cardMessageType: CalReplyEventParam.CardMessageType) {
        let statusMap: [CalendarEventAttendee.Status: CalendarTracer.CalReplyEventParam.CalEventResp] = [
            .accept: .acpt,
            .decline: .decl,
            .tentative: .mayb
        ]
        var meetingRoomCount = 0
        var groupCount = 0
        var userCount = 0
        var thirdPartyAttendeeCount = 0
        for attendee in event.attendees {
            if attendee.isResource {
                meetingRoomCount += 1
                continue
            }
            if attendee.isGroup {
                groupCount += 1
                continue
            }
            if attendee.isThirdParty {
                thirdPartyAttendeeCount += 1
                continue
            }
            userCount += 1
        }
        calReplyEvent(actionSource: .cardMessage,
                      calEventResp: statusMap[status] ?? .unknown,
                      cardMessageType: cardMessageType,
                      meetingRoomCount: meetingRoomCount,
                      thirdPartyAttendeeCount: thirdPartyAttendeeCount,
                      groupCount: groupCount,
                      userCount: userCount,
                      eventType: CalendarTracer.EventType(calendarEventEntity: event),
                      viewType: CalendarTracer.ViewType(mode: CalendarDayViewSwitcher().mode),
                      eventId: event.serverId,
                      chatId: chatId,
                      isCrossTenant: event.isCrossTenant)
    }

    func calReplyEvent(actionSource: CalReplyEventParam.ActionSource,
                       calEventResp: CalReplyEventParam.CalEventResp,
                       cardMessageType: CalReplyEventParam.CardMessageType,
                       meetingRoomCount: Int,
                       thirdPartyAttendeeCount: Int,
                       groupCount: Int,
                       userCount: Int,
                       eventType: EventType,
                       viewType: ViewType,
                       eventId: String,
                       chatId: String,
                       isCrossTenant: Bool) {
        writeEvent(eventId: "cal_reply_event",
                   params: ["action_source": actionSource.rawValue,
                            "cal_event_resp": calEventResp.rawValue,
                            "card_message_type": cardMessageType.rawValue,
                            "mtgroom_count": meetingRoomCount,
                            "third_party_attendee_count": thirdPartyAttendeeCount,
                            "group_count": groupCount,
                            "user_count": userCount,
                            "event_type": eventType.rawValue,
                            "view_type": viewType.rawValue,
                            "event_id": eventId,
                            "is_cross_tenant": isCrossTenant.description,
                            "chat_id": chatId])
    }

}

// MARK: - 切换日期等的日历导航
extension CalendarTracer {
    struct CalNavigationParam {
        enum ActionSource: String {
            case freeBusyViewer = "free_busy_viewer"
            case defaultView = "default_view"
            case calProfile = "cal_profile"
            case calWidget = "cal_widget"
        }

        enum NavigationType: String {
            case prev
            case next
            case today
            case byDate = "by_date"
            case widgetPrev = "cal_widget_prev"
            case widgetNext = "cal_widget_next"
        }
    }

    func calNavigation(actionSource: CalNavigationParam.ActionSource,
                       navigationType: CalNavigationParam.NavigationType,
                       viewType: ViewType) {
        writeEvent(eventId: "cal_navigation",
                   params: ["action_source": actionSource.rawValue,
                            "navigation_type": navigationType.rawValue,
                            "view_type": viewType.rawValue])
    }
}

// MARK: 编辑日程
extension CalendarTracer {
    struct CalFullEditEventParam {
        enum ActionSource: String {
            case eventDetail = "event_detail"
            case createEventButton = "create_event_button"
            case fastEventEditor = "fast_event_editor"
            case calProfile = "cal_profile"
            case instanceBlock = "instance_block"
            case findTimeGroup = "find_time_group"
            case findTimeSingle = "find_time_single"
            case qrCode = "code_calendar" // 二维码签到
        }

        enum EditType: String {
            case new
            case edit
        }

        enum TimeConfilct: String {
            case workTime = "work_time"
            case noConflict = "no_conflict"
            case eventConflict = "event_conflict"
            case unknown = ""
        }
    }

    func calFullEditEvent(actionSource: CalFullEditEventParam.ActionSource,
                          editType: CalFullEditEventParam.EditType,
                          mtgroomCount: Int,
                          thirdPartyAttendeeCount: Int,
                          groupCount: Int,
                          userCount: Int,
                          timeConfilct: CalFullEditEventParam.TimeConfilct) {
        writeEvent(eventId: "cal_full_edit_event",
                   params: ["action_source": actionSource.rawValue,
                            "mtgroom_count": mtgroomCount,
                            "edit_type": editType.rawValue,
                            "third_party_attendee_count": thirdPartyAttendeeCount,
                            "group_count": groupCount,
                            "user_count": userCount,
                            "time_conflict": timeConfilct.rawValue])
    }

    func calEditClose(editType: CalFullEditEventParam.EditType) {
        writeEvent(eventId: "cal_full_event_editor_close", params: ["edit_type": editType.rawValue])
    }

    func calEditGroupExpand() {
        writeEvent(eventId: "cal_full_event_editor_new", params: ["action_type": "group_expand"])
    }

    enum AddEmailAttendeeActionType: String {
        case invite, enter
    }

    func calAddEmailAttendee(from actionType: AddEmailAttendeeActionType) {
        writeEvent(eventId: "cal_email_guest",
                   params: ["action_type": actionType.rawValue])
    }
}

// MARK: 开始视频会议
extension CalendarTracer {
    struct CalOpenVideoMeetingParam {
        enum ActionSource: String {
            case eventDetail = "event_detail"
            case cardMessage = "card_message"
        }
    }

    func calOpenVideoMeeting(eventType: EventType) {
        writeEvent(eventId: "cal_open_video_mtg",
                   params: ["action_source": CalOpenVideoMeetingParam.ActionSource.eventDetail.rawValue,
                            "event_type": eventType.rawValue,
                            "action_target_status": "open"])
    }

    func calJoinVideoMeeting(eventType: EventType) {
        writeEvent(eventId: "cal_open_video_mtg",
                   params: ["action_source": CalOpenVideoMeetingParam.ActionSource.eventDetail.rawValue,
                            "event_type": eventType.rawValue,
                            "action_target_status": "join"])
    }

    func calCopyVideoMeeting(eventType: EventType) {
        writeEvent(eventId: "cal_video_link_mtg",
                   params: ["action_source": CalOpenVideoMeetingParam.ActionSource.eventDetail.rawValue,
                            "event_type": eventType.rawValue])
    }

    enum VideoMeetingSettingType: String {
        case vcPreSettingView = "vc_meeting_pre_setting_view"
    }

    enum EventClickType {
        case editVCSetting(VideoMeetingSettingType)
        case joinMore
        case joinPhone
        case joinPhoneMore
        case enterGroupChat
        case showGroupAttendeeList
        case showAttendeeList
        case showUserProfile

        var value: String {
            switch self {
            case .editVCSetting:
                return "edit_vc_setting"
            case .joinMore:
                return "join_more"
            case .joinPhone:
                return "join_phone"
            case .joinPhoneMore:
                return "join_phone_more"
            case .enterGroupChat:
                return "enter_group_chat"
            case .showGroupAttendeeList:
                return "show_group_attendee_list"
            case .showAttendeeList:
                return "show_attendee_list"
            case .showUserProfile:
                return "show_user_profile"
            }
        }

        var target: String {
            switch self {
            case .editVCSetting(let type):
                return type.rawValue
            case .joinMore:
                return "none"
            case .joinPhone:
                return "none"
            case .joinPhoneMore:
                return "none"
            case .enterGroupChat:
                return "im_chat_main_view"
            case .showGroupAttendeeList:
                return "none"
            case .showAttendeeList:
                return "none"
            case .showUserProfile:
                return "profile_main_view"
            }
        }
    }

    enum EventDetailClickStatus: String {
        case on
        case off
    }
}

// MARK: 删除日程
extension CalendarTracer {
    struct CalDeleteEventParam {
        enum ActionSource: String {
            case eventDetail = "event_detail"
            case fullEventEditor = "full_event_editor"
        }
        enum deleteType: String {
            case today = "delete_today"
            case future = "delete_future"
            case detele_all = "delete_all"
        }

        enum NotifyEventChanges: String {
            case notify
            case notNotify = "not_notify"
            case noValue = "no_value"
            case notNotifyForDeleteAttendee = "not_notify_for_delete_attendee"

            init(_ notificationType: NotificationType) {
                switch notificationType {
                case .defaultNotificationType:
                    self = .noValue
                case .noNotification:
                    self = .notNotify
                case .sendNotification:
                    self = .notify
                case .noNotificationForDeleteAttendee:
                    self = .notNotifyForDeleteAttendee
                @unknown default:
                    self = .noValue
                    break
                }
            }
        }
    }

    func calDeleteEvent(actionSource: CalDeleteEventParam.ActionSource,
                        eventType: EventType,
                        notifyEventChanged: CalDeleteEventParam.NotifyEventChanges,
                        viewType: ViewType,
                        eventId: String,
                        isCrossTenant: Bool,
                        deleteType: CalDeleteEventParam.deleteType,
                        meetingRoomCount: Int,
                        thirdPartyAttendeeCount: Int = 0) {
        writeEvent(eventId: "cal_delete_event",
                   params: ["action_source": actionSource.rawValue,
                            "event_type": eventType.rawValue,
                            "notify_event_changes": notifyEventChanged.rawValue,
                            "view_type": viewType.rawValue,
                            "event_id": eventId,
                            "is_cross_tenant": isCrossTenant.description,
                            "delete_type": deleteType.rawValue,
                            "mtgroom_count": meetingRoomCount,
                            "third_party_attendee_count": thirdPartyAttendeeCount])
    }
}

// MARK: - 会议室视图

// MARK: - 二维码签到
extension CalendarTracer {
    // 进入页面
    func codeScan(params: [String: String]) {
        writeEvent(eventId: "cal_code_scan", params: params)
    }

    // 点击签到按钮
    func codeCheckIn(params: [String: String]) {
        writeEvent(eventId: "cal_code_checkid", params: params)
    }

    // 点击预订按钮
    func codeCreateEvent(params: [String: String]) {
        writeEvent(eventId: "cal_code_create_event", params: params)
    }

    // 点击调起忙闲
    func codeViewCalendar(params: [String: String]) {
        writeEvent(eventId: "cal_code_view_calendar", params: params)
    }
}

// MARK: - 会议室表单
extension CalendarTracer {
    struct MeetingRoomFormParams {
        enum FormEnterSource: String {
            case chooseMeetingRoom = "choose_meeting_room"
            case editMeetingInfo = "edit_meeting_info"
        }

        enum Action {
            case confirm
            case cancel
        }

        enum NextPage: String {
            case eventDetail = "event_detail_page"
            case chooseMeetingRoom = "choose_meeting_room"
        }
    }
    func enterFormViewController(source: MeetingRoomFormParams.FormEnterSource) {
        writeEvent(eventId: "cal_fill_format", params: ["enter_source": source.rawValue])
    }

    func formComplete(action: MeetingRoomFormParams.Action, nextPage: MeetingRoomFormParams.NextPage) {
        writeEvent(eventId: "cal_fill_format_complete_click", params: ["is_done": action == .confirm,
                                                                       "target": nextPage.rawValue])
    }

    func formJumpToChatter() {
        writeEvent(eventId: "cal_format_profile_click", params: ["source": "cal_format_page"])
    }
}

// MARK: - 移动端点击find_time
extension CalendarTracer {
    struct CalFindTimeParam {
        enum Source: String {
            /// 个人卡片
            case calProfile = "cal_profile"
            /// 编辑页
            case fullEventEditor = "full_event_editor"
        }
    }

    /// 移动端进入忙闲视图
    ///
    /// - Parameters:
    ///   - meetingRoomCount: 会议室数量
    ///   - thirdPartyAttendeeCount: 第三方参与人数量
    ///   - actionSource: 入口
    ///   - groupCount: 群数量
    ///   - userCount: 参与人数量
    func enterFreeBusy(meetingRoomCount: Int,
                       thirdPartyAttendeeCount: Int = 0, // 目前能查看忙闲的地方都不支持写邮箱
                       actionSource: CalFindTimeParam.Source,
                       groupCount: Int,
                       userCount: Int) {
        writeEvent(eventId: "cal_find_time",
                   params: ["mtgroom_count": meetingRoomCount,
                            "third_party_attendee_count": thirdPartyAttendeeCount,
                            "action_source": actionSource.rawValue,
                            "group_count": groupCount,
                            "user_count": userCount])
    }
}

// MARK: 点击编辑会议纪要
extension CalendarTracer {
    struct CalEditEventDocParam {
        enum ActionSource: String {
            case eventDetail = "event_detail"
            case chatSideBar = "chat_side_bar"
        }

        enum EditType: String {
            case new
            case open
        }
    }

    func calEditEventDoc(eventType: EventType,
                         actionSource: CalEditEventDocParam.ActionSource,
                         eventId: String,
                         fileId: String,
                         isCrossTenant: Bool,
                         editType: CalEditEventDocParam.EditType) {
        writeEvent(eventId: "cal_edit_event_doc",
                   params: ["event_type": eventType.rawValue,
                            "action_source": actionSource.rawValue,
                            "event_id": eventId,
                            "file_id": fileId,
                            "is_cross_tenant": isCrossTenant.description,
                            "edit_type": editType.rawValue])
    }
}

// MARK: 修改时间
extension CalendarTracer {
    struct CalTimeChangeParam {
        enum ActionSource: String {
            case freeBusyViewer = "free_busy_viewer"
        }

        enum TimeConflict: String {
            case workTime = "work_time"
            case eventConflict = "event_conflict"
            case noConflict = "no_conflict"
        }
    }

    func calTimeChange(timeConflict: CalTimeChangeParam.TimeConflict) {
        writeEvent(eventId: "cal_time_change",
                   params: ["action_source": CalTimeChangeParam.ActionSource.freeBusyViewer.rawValue,
                            "time_conflict": timeConflict.rawValue])
    }
}

// MARK: 删除日历
extension CalendarTracer {
    func calDeleteCalendar() {
        writeEvent(eventId: "cal_delete_calendar")
    }
}

// MARK: 点击设置日历的可见性
extension CalendarTracer {
    struct CalToggleCalendarVisibilityParam {
        enum ActionTargetStatus: String {
            case on
            case off

            init(isChecked: Bool) {
                if isChecked {
                    self = .on
                } else {
                    self = .off
                }
            }
        }

        enum CalendarType: String {
            case contacts
            case meetingRoom = "mtgrooms"
            case publicCalendar = "public_cal"
            case unknown = ""
        }

        enum ActionSource: String {
            case sidebar = "calendars_list_side_view"
        }

        static let CalendarTypeKey = "calendarType"
    }

    func calToggleCalendarVisibility(actionTargetStatus: CalToggleCalendarVisibilityParam.ActionTargetStatus,
                                     calendarType: CalToggleCalendarVisibilityParam.CalendarType) {
        writeEvent(eventId: "cal_toggle_calendar_visibility",
                   params: ["action_target_status": actionTargetStatus.rawValue,
                            "calendar_type": calendarType.rawValue,
                            "action_source": CalToggleCalendarVisibilityParam.ActionSource.sidebar.rawValue])
    }
}

// MARK: 设置工作时间点击应用到其他日期
extension CalendarTracer {
    func calSettingCopyWorkTime() {
        writeEvent(eventId: "cal_settings_copy_work_time")
    }
}

// MARK: 抢占会议室
extension CalendarTracer {
    /// 进入正常的抢占会议室页面
    func enterSeizeMeetingRoom(isNormal: Bool) {
        writeEvent(eventId: "cal_reclaim_enter",
                   params: ["page_type": isNormal ? "normal" : "others"])
    }

    /// 点击倒计时上抢占的按钮
    func tapSeize() {
        writeEvent(eventId: "cal_reclaim")
    }

    /// 点击日程列表上的立即抢占按钮
    func tapSeizeNow() {
        writeEvent(eventId: "cal_reclaim_now")
    }
}
// MARK: 日历设置中修改成员权限
extension CalendarTracer {
    struct CalCalEditMemberPermission {
        enum MemberType: String {
            case individual
            case group

            init(isGroup: Bool) {
                if isGroup {
                    self = .group
                } else {
                    self = .individual
                }
            }
        }

        enum CalMemberPermission: String {
            case owner
            case writer = "editor"
            case reader
            case freeBusyReader = "fb_reader"

            init(accessRole: CalendarModel.AccessRole) {
                switch accessRole {
                case .owner:
                    self = .owner
                case .writer:
                    self = .writer
                case .reader:
                    self = .reader
                @unknown default:
                    self = .freeBusyReader
                }
            }
        }
    }

    func calCalEditMemberPermission(memberType: CalCalEditMemberPermission.MemberType,
                                    calMemberPermission: CalCalEditMemberPermission.CalMemberPermission) {
        writeEvent(eventId: "cal_cal_edit_member_permission",
                   params: ["member_type": memberType.rawValue,
                            "cal_member_permission": calMemberPermission.rawValue])
    }
}

// MARK: 日历设置中添加成员
extension CalendarTracer {
    struct CalCalAddMemberParam {
        enum MemberType: String {
            case individual
            case group

            init(isGroup: Bool) {
                if isGroup {
                    self = .group
                } else {
                    self = .individual
                }
            }
        }

        enum MemberPermission: String {
            case owner
            case writer = "editor"
            case reader
            case freeBusyReader = "fb_reader"

            init(accessRole: CalendarModel.AccessRole) {
                switch accessRole {
                case .owner:
                    self = .owner
                case .writer:
                    self = .writer
                case .reader:
                    self = .reader
                @unknown default:
                    self = .freeBusyReader
                }
            }
        }
    }

    func calCalAddMember(memberType: CalCalAddMemberParam.MemberType,
                         memberPermission: CalCalAddMemberParam.MemberPermission) {
        writeEvent(eventId: "cal_cal_add_member",
                   params: ["member_type": memberType.rawValue,
                            "cal_member_permission": memberPermission.rawValue])
    }
}

// MARK: 进入日历编辑页面
extension CalendarTracer {
    struct CalGoEditCalendarParam {
        enum EditType: String {
            case new
            case edit
        }

        enum ActionSource: String {
            case sideBar = "calendar_list_side_view"
            case actionSheet = "quick_action_sheet"
        }

        enum CalendarType: String {
            case contacts
            case meetingRoom = "mtgrooms"
            case shareCalendars = "public_cal"

            init(type: CalendarModel.CalendarType) {
                switch type {
                case .resources:
                    self = .meetingRoom
                case .other:
                    self = .shareCalendars
                @unknown default:
                    self = .contacts
                }
            }
        }
    }

    func calGoEditCalendar(editType: CalGoEditCalendarParam.EditType,
                           actionSource: CalGoEditCalendarParam.ActionSource,
                           calendarType: CalGoEditCalendarParam.CalendarType) {
        writeEvent(eventId: "cal_go_edit_calendar",
                   params: ["edit_type": editType.rawValue,
                            "action_source": actionSource.rawValue,
                            "calendar_type": calendarType.rawValue])
    }
}

// MARK: 移动端忙闲视图，点击头像后，切换忙闲列表中人的位置
extension CalendarTracer {
    struct CalChangeFreeBusyLocation {
        enum ActionTargetStatus: String {
            case showArrow = "on"
            case moveToLeft = "left"
        }
    }

    func calChangeFreebusyLocation(status: CalChangeFreeBusyLocation.ActionTargetStatus) {
        writeEvent(eventId: "cal_change_freebusy_location",
                   params: ["action_target_status": status.rawValue])
    }
}

// MARK: 确定「转让日程」
extension CalendarTracer {
    func calTransferEvent(eventType: EventType, eventId: String, transferUserId: String, calendarType: String, isCrossTenant: String, removeOriginalOrganizer: Bool) {
        let viewType = CalendarTracer.ViewType(mode: CalendarDayViewSwitcher().mode)
        writeEvent(eventId: "cal_transfer_event",
                   params: ["event_type": eventType.rawValue,
                            "event_id": eventId,
                            "transfer_user_id": transferUserId,
                            "is_cross_tenant": isCrossTenant.description,
                            "view_type": viewType.rawValue,
                            "calendar_type": calendarType,
                            "action_target_status": removeOriginalOrganizer])
    }
}

// MARK: 点击日程详情上的more按钮（省略号）
extension CalendarTracer {
    func calEventDetailMore() {
        writeEvent(eventId: "cal_event_detail_more",
                   params: ["action_source": "event_detail"])
    }
}

// MARK: 点击进入
extension CalendarTracer {
    func calEventDetailVCSetting() {
        writeEvent(eventId: "cal_vc_settings")
    }
}

// MARK: 点击查看显示不下的主题或重复性
extension CalendarTracer {
    struct CalDetailMoreParam {
        enum ElementType: String {
            case title
            case _repeat = "repeat"
        }
    }

    func calDetailMore(elementType: CalDetailMoreParam.ElementType) {
        writeEvent(eventId: "cal_more",
                   params: ["element_type": elementType.rawValue])
    }
}

// MARK: 查看参与人列表
extension CalendarTracer {
    struct CalShowAttendeeListParam {
        enum ActionSource: String {
            case eventDetail = "event_detail"
            case edit = "full_event_editor"
        }
    }

    func calShowAttendeeList(actionSource: CalShowAttendeeListParam.ActionSource) {
        writeEvent(eventId: "cal_show_attendee_list",
                   params: ["action_source": actionSource.rawValue])
    }
}

// MARK: - 长按复制的pv，uv
extension CalendarTracer {
    struct CalDetailCopyParam {
        enum ElementType: String {
            case title
            case time
            case _repeat = "repeat"
            case location
            case mtgroom
            case description
        }
    }

    func calDetailCopy(elementType: CalDetailCopyParam.ElementType) {
        // 最新打点文件不在需要参数了
        writeEvent(eventId: "cal_detail_copy")
    }
}

// MARK: - 查看参与人个人卡片
extension CalendarTracer {
    struct CalShowUserCardParam {
        enum ActionSource: String {
            case eventDetail = "event_detail"
            case invitation
            case calendarSubscription = "calendar_subscription_modal"
            case seizeMeetingroom = "seize_mtgroom"
        }
    }

    func calShowUserCard(actionSource: CalShowUserCardParam.ActionSource) {
        writeEvent(eventId: "cal_show_user_card",
                   params: ["action_source": actionSource.rawValue])
    }
}

// MARK: - 修改日历公开权限
extension CalendarTracer {
    struct CalCalPermissionChangeParam {
        enum CalendarPermission: String {
            case `private`
            case `public`
            case freebusy = "fb"

            init(access: CalendarAccess) {
                switch access {
                case .privacy:
                    self = .private
                case .publicCalendar:
                    self = .public
                case .freeBusy:
                    self = .freebusy
                }
            }
        }
    }

    func calCalPermissionChange(permission: CalCalPermissionChangeParam.CalendarPermission) {
        writeEvent(eventId: "cal_cal_permission_change",
                   params: ["action_source": permission.rawValue])
    }
}

// MARK: - 取消订阅日历
extension CalendarTracer {
    struct CalUnsubscribeCalendarParam {
        enum ActionSource: String {
            case subscribe = "calendar_subscription_model"
            case manage = "calendar_manager"
        }

        enum CalendarType: String {
            case contacts
            case meetingRoom = "mtgrooms"
            case publicCalendar = "public_cal"

            init(pageType: PageType) {
                switch pageType {
                case .contacts:
                    self = .contacts
                case .mtgrooms:
                    self = .meetingRoom
                case .public_cal:
                    self = .publicCalendar
                }
            }
        }
    }

    func calUnsubscribeCalendar(actionSource: CalUnsubscribeCalendarParam.ActionSource,
                                calendarType: CalUnsubscribeCalendarParam.CalendarType) {
        writeEvent(eventId: "cal_unsubscribe_calendar",
                   params: ["action_source": actionSource.rawValue,
                            "calendar_type": calendarType.rawValue])
    }
}

extension CalendarTracer {
    struct CalendarSettingFirstWeekdayParam {
        enum TargetValue: String {
            case sunday = "0"
            case monday = "1"
            case saturday = "6"

            init(daysOfWeek: DaysOfWeek) {
                switch daysOfWeek {
                case .sunday:
                    self = .sunday
                case .monday:
                    self = .monday
                case .saturday:
                    self = .saturday
                default:
                    assertionFailureLog()
                    self = .sunday
                }
            }
        }
    }

    func calSettingFirstWeekday(targetValue: CalendarSettingFirstWeekdayParam.TargetValue) {
        writeEvent(eventId: "cal_settings_first_week_day",
                   params: ["target_value": targetValue.rawValue])
    }
}

// MARK: - 其他历法
extension CalendarTracer {

    struct CalSettingsSecondaryCalendar {
        enum CalendarType: String {
            case lunar
            case none

            init(alternateCalendar: AlternateCalendarEnum) {
                switch alternateCalendar {
                case .noneCalendar:
                    self = .none
                case .chineseLunarCalendar:
                    self = .lunar
                @unknown default:
                    self = .none
                }
            }
        }
    }

    func calSettingsSecondaryCalendar(calendarType: CalSettingsSecondaryCalendar.CalendarType) {
        writeEvent(eventId: "cal_settings_secondary_calendar",
                   params: ["calendar_type": calendarType.rawValue])
    }
}

// MARK: - 已过去的日程颜色变淡
extension CalendarTracer {
    struct CalSettingReduceBrightnessParam {
        enum ActionTargetStatus: String {
            case on
            case off

            init(isOn: Bool) {
                if isOn {
                    self = .on
                } else {
                    self = .off
                }
            }
        }
    }

    func calSettingReduceBrightness(actionTargetStatus: CalSettingReduceBrightnessParam.ActionTargetStatus) {
        writeEvent(eventId: "cal_settings_reduce_brightness",
                   params: ["action_target_status": actionTargetStatus.rawValue])
    }
}

// MARK: - 启用工作时间
extension CalendarTracer {
    struct CalSettingWorkHour {
        enum ActionTargetStatus: String {
            case on
            case off

            init(isOn: Bool) {
                if isOn {
                    self = .on
                } else {
                    self = .off
                }
            }
        }
    }

    func calSettingWorkHour(actionTargetStatus: CalSettingWorkHour.ActionTargetStatus) {
        writeEvent(eventId: "cal_settings_work_hours",
                   params: ["action_target_status": actionTargetStatus.rawValue])
    }
}

// MARK: - 更新皮肤
extension CalendarTracer {
    struct CalSettingThemeParam {
        enum ThemeType: String {
            case dark
            case light

            init(type: CalendarSkinType) {
                switch type {
                case .dark:
                    self = .dark
                case .light:
                    self = .light
                @unknown default:
                    self = .light
                }
            }
        }
    }

    func calSettingTheme(themeType: CalSettingThemeParam.ThemeType) {
        writeEvent(eventId: "cal_settings_theme",
                   params: ["theme_type": themeType.rawValue])
    }
}

// MARK: - 显示已经拒绝的日程
extension CalendarTracer {
    struct CalSettingShowRejectedParam {
        enum ActionTargetStatus: String {
            case on
            case off

            init(isOn: Bool) {
                if isOn {
                    self = .on
                } else {
                    self = .off
                }
            }
        }
    }

    func calSettingShowRejected(actionTargetStatus: CalSettingShowRejectedParam.ActionTargetStatus) {
        writeEvent(eventId: "cal_settings_show_rejected",
                   params: ["action_target_status": actionTargetStatus.rawValue])
    }
}

// MARK: - “已接受”的日程才能收到提醒
extension CalendarTracer {
    struct CalSettingsNotifyAcceptedOnly {
        enum ActionTargetStatus: String {
            case on
            case off

            init(isOn: Bool) {
                self = isOn ? .on : .off
            }
        }
    }

    func calSettingsNotifyAcceptedOnly(actionTargetStatus: CalSettingsNotifyAcceptedOnly.ActionTargetStatus) {
        writeEvent(eventId: "cal_settings_notify_accepted_only",
                   params: ["action_target_status": actionTargetStatus.rawValue])
    }
}

// MARK: - 别人拒绝自己的邀请日程是否提醒
extension CalendarTracer {

    func calSettingsDecliningEventNotification(actionTargetStatus: CalSettingShowRejectedParam.ActionTargetStatus) {
        writeEvent(eventId: "cal_settings_declining_event_notification",
                   params: ["action_target_status": actionTargetStatus.rawValue])
    }
}

// MARK: - 前往修改系统时区
extension CalendarTracer {
    func calSettingsChangeDeviceTimezone() {
        writeEvent(eventId: "cal_settings_change_device_timezone")
    }
}

// MARK: - 日历设置-时常
extension CalendarTracer {
    func calSettingEventDur(_ duration: Int) {
        writeEvent(eventId: "cal_settings_event_dur",
                   params: ["target_value": duration])
    }
}

// MARK: - 日历设置-全天
extension CalendarTracer {
    func calSettingAlldayNotification(_ duration: Int32?) {
        writeEvent(eventId: "cal_settings_allday_notification",
                   params: ["target_value": duration ?? ""])
    }
}

// MARK: - 日历设置-非全天
extension CalendarTracer {
    func calSettingNonAlldayNotification(_ duration: Int32?) {
        writeEvent(eventId: "cal_settings_nallday_notification",
                   params: ["target_value": duration ?? ""])
    }
}

// MARK: - 导入谷歌日历
extension CalendarTracer {
    struct CalSettingImportGoogleParam {
        enum ActionTargetStatus: String {
            case on
            case off

            init(isOn: Bool) {
                if isOn {
                    self = .on
                } else {
                    self = .off
                }
            }
        }
    }

    func calSettingImportGoogle(actionTargetSource: CalSettingImportGoogleParam.ActionTargetStatus) {
        writeEvent(eventId: "cal_settings_import_google",
                   params: ["action_target_status": actionTargetSource.rawValue,
                            "action_source": "settings"])
    }
}

// MARK: - 设置开启或关闭本地日历
extension CalendarTracer {
    struct CalSettingLocalCalendarParam {
        enum ActionTargetStatus: String {
            case on
            case off

            init(isOn: Bool) {
                if isOn {
                    self = .on
                } else {
                    self = .off
                }
            }
        }
    }

    func calSettingsLocalCalendar(actionTargetSource: CalSettingLocalCalendarParam.ActionTargetStatus) {
        writeEvent(eventId: "cal_settings_local_calendar",
                   params: ["action_target_status": actionTargetSource.rawValue])
    }
}

// MARK: - 会议等banner的关闭
extension CalendarTracer {
    struct CalBannerCloseParam {
        enum BannerType: String {
            case meeting
            case toNormalGroup = "degrade_meeting"
        }
    }

    func calBannerClose(bannerType: CalBannerCloseParam.BannerType) {
        writeEvent(eventId: "cal_banner_close",
                   params: ["banner_type": bannerType.rawValue])
    }
}

// MARK: 操作小日历
extension CalendarTracer {
    struct CalCalWidgetOperationParam {
        enum ActionSource: String {
            case defaultView = "default_view"
            case profile = "cal_profile"
        }

        enum ActionTargetStatus: String {
            case open
            case close
        }
    }

    func calCalWidgetOperation(actionSource: CalCalWidgetOperationParam.ActionSource,
                               actionTargetStatus: CalCalWidgetOperationParam.ActionTargetStatus) {
        writeEvent(eventId: "cal_calwidget_operation",
                   params: ["action_type": "click",
                            "action_source": actionSource.rawValue,
                            "action_target_status": actionTargetStatus.rawValue])
    }
}

// MARK: - 分享日程
extension CalendarTracer {

    enum ShareType: String {
        case chat
        case image
        case screenshot
        case link
        case wechat
        case moment
        case qq
        case weibo
        case more
        case album
    }

    func calEventShareImage(type: ShareType) {
        writeEvent(eventId: "cal_share_image",
                   params: ["action_type": type.rawValue])
    }

    func calEventShareSucess(type: ShareType) {
        writeEvent(eventId: "cal_share_succeed",
                   params: ["action_source": type.rawValue])
    }

    func calShareEvent(eventType: EventType,
                       meetingRoomCount: Int,
                       thirdPartyAttendeeCount: Int,
                       groupCount: Int,
                       userCount: Int,
                       eventId: String,
                       chatId: String,
                       isCrossTenant: String,
                       type: ShareType = .chat) {
        let viewType = CalendarTracer.ViewType(mode: CalendarDayViewSwitcher().mode)
        writeEvent(eventId: "cal_share_event",
                   params: ["action_source": "event_detail",
                            "event_type": eventType.rawValue,
                            "mtgroom_count": meetingRoomCount,
                            "third_party_attendee_count": thirdPartyAttendeeCount,
                            "group_count": groupCount,
                            "user_count": userCount,
                            "event_id": eventId,
                            "chat_id": chatId,
                            "action_type": type.rawValue,
                            "view_type": viewType.rawValue,
                            "is_cross_tenant": isCrossTenant.description])
    }
}

// MARK: - 加入被分享的日程
extension CalendarTracer {
    struct CalJoinEventParam {
        enum ActionSource: String {
            case eventDetail = "event_detail"
            case cardMessage = "card_message"
        }
    }

    func calJoinEvent(actionSource: CalJoinEventParam.ActionSource,
                      eventType: EventType,
                      eventId: String,
                      chatId: String,
                      isCrossTenant: Bool) {
        writeEvent(eventId: "cal_join_event",
                   params: ["action_source": actionSource.rawValue,
                            "event_type": eventType.rawValue,
                            "event_id": eventId,
                            "chat_id": chatId,
                            "is_cross_tenant": isCrossTenant.description])
    }
}

// MARK: - 点击进入会议群聊
extension CalendarTracer {
    struct CalEnterMeetingParam {
        enum ActionSource: String {
            case eventDetail = "event_detail"
        }
    }

    func calEnterMeeting(actionSource: CalEnterMeetingParam.ActionSource,
                         eventType: EventType,
                         meetingRoomCount: Int,
                         thirdPartyAttendeeCount: Int,
                         groupCount: Int,
                         userCount: Int,
                         isCrossTenant: Bool,
                         eventId: String,
                         chatId: String,
                         viewType: CalendarTracer.ViewType) {
        writeEvent(eventId: "cal_enter_meeting",
                   params: ["action_source": actionSource.rawValue,
                            "event_type": eventType.rawValue,
                            "mtgroom_count": meetingRoomCount,
                            "third_party_attendee_count": thirdPartyAttendeeCount,
                            "group_count": groupCount,
                            "user_count": userCount,
                            "is_cross_tenant": isCrossTenant.description,
                            "event_id": eventId,
                            "chat_id": chatId,
                            "view_type": viewType.rawValue])
    }
}

// MARK: - 保存日程
extension CalendarTracer {
    struct CalSaveEventParam {
        enum ActionSource: String {
            case instance = "instance_block"
            case groupFreeBusy = "chat_findtime"
            case profile = "cal_profile"
            case createEventBtn = "create_event_btn"
            case qrCode = "scan_code"
        }
        enum EditType: String {
            case new
            case edit
        }

        enum NotifyEventChanges: String {
            case notify = "true"
            case notNotify = "false"
            case none = "no_value"
            case notNotifyForDeleteAttendee = "not_notify_for_delete_attendee"

            init(_ notificationType: NotificationType) {
                switch notificationType {
                case .defaultNotificationType:
                    self = .none
                case .noNotification:
                    self = .notNotify
                case .sendNotification:
                    self = .notify
                case .noNotificationForDeleteAttendee:
                    self = .notNotifyForDeleteAttendee
                @unknown default:
                    self = .none
                    break
                }
            }
        }
    }

    enum CalSaveEventChatType: String {
        case group = "group"
        case single = "single"
        case unknown = "no_value"

        init(actionSource: EventEditActionSource) {
            self = .unknown
            switch actionSource {
            case .chatter: self = .single
            case .chat: self = .group
            default: break
            }
        }
    }

    struct EventSaveParams {
        enum EditType: String {
            case new
            case edit
        }
        enum EventType: String {
            case meeting = "meeting"
            case lark = "event"
            case local = "local_event"
            case google = "google_event"
            case exchange = "exchange_event"
        }
        enum VideoMeetingType: String {
            case larkVC = "lark_vc"
            case customVC = "custom_vc"
            case noVC = "no_vc"
            case live = "lark_livestream"
            case zoom = "zoom"
            case unknown = "unknown"
        }

        var eventId: String = ""
        var eventType: EventType = .lark
        var editType: EditType = .edit
        var vcType: VideoMeetingType = .unknown
        var actionSource: EventEditActionSource = .detail
        var meetingRoomCount: Int = 0
        var groupAttendeeCount: Int = 0
        var userAttendeeCount: Int = 0
        var emailAttendeeCount: Int = 0
        var succeed: Bool = true
        var role: String = "attendee"
        var notifyType: CalSaveEventParam.NotifyEventChanges = .none
        var isCrossTenant: Bool = false
        var modifiedEmailguest: Bool = false
        var chatId: String?
        var meetingRoomID = ""
    }

    private func descOfActionSource(_ actionSource: EventEditActionSource) -> String {
        switch actionSource {
        case .addButton: return "fast_event_editor"
        case .timeBlock: return "instance_block"
        case .detail: return "full_event_editor"
        case .profile: return "cal_profile"
        case .chatter: return "chat_findtime"
        case .chat: return "chat_findtime"
        case .appLink: return "app_link"
        case .qrCode: return "code_calendar"
        case .unknown: return "unknown"
        case .vcMenu: return "vc_event"
        }
    }

    func saveEventFromEditing(_ params: EventSaveParams) {
        var paramDict = [String: Any]()
        paramDict["event_type"] = params.eventType.rawValue
        paramDict["edit_type"] = params.editType.rawValue
        paramDict["action_source"] = descOfActionSource(params.actionSource)
        paramDict["mtgroom_count"] = params.meetingRoomCount
        paramDict["group_count"] = params.groupAttendeeCount
        paramDict["user_count"] = params.userAttendeeCount
        paramDict["third_party_attendee_count"] = params.emailAttendeeCount
        paramDict["event_id"] = !params.eventId.isEmpty ? params.eventId : "no_value"
        paramDict["savetype"] = params.succeed ? "success" : "failed"
        paramDict["role"] = params.role
        paramDict["vc_type"] = params.vcType.rawValue
        paramDict["view_type"] = CalendarTracer.ViewType(mode: CalendarDayViewSwitcher().mode).rawValue
        paramDict["notify_event_changes"] = params.notifyType.rawValue
        paramDict["is_cross_tenant"] = params.isCrossTenant.description
        paramDict["chat_type"] = CalSaveEventChatType(actionSource: params.actionSource).rawValue
        paramDict["modified_emailguest"] = params.modifiedEmailguest.description
        paramDict["chat_id"] = params.chatId ?? "no_value"
        paramDict["resource_id"] = params.meetingRoomID
        writeEvent(eventId: "cal_save_event", params: paramDict)
    }

    func editVCSet(actionSource: EventEditActionSource) {
        var paramDict = [String: Any]()
        paramDict["action_source"] = descOfActionSource(actionSource)
        writeEvent(eventId: "cal_vc_type_set", params: paramDict)
    }
}

extension CalendarTracer {
    func calProfileBlock() {
        writeEvent(eventId: "cal_profile_block",
                   params: ["action_source": "cal_profile"])
    }
}

// MARK: 日程搜索: 选中搜索结果
extension CalendarTracer {
    struct CalSearchResultParam {
        enum ActionSource: String {
            case fast
            case advanced
        }
    }

    func calSearchResult(actionSource: CalSearchResultParam.ActionSource) {
        writeEvent(eventId: "cal_search_result",
                   params: ["action_source": actionSource.rawValue])
    }
}

// MARK: 日程搜索: 高级搜索
extension CalendarTracer {

    func calSearchAdvanced(hasResult: Bool) {
        writeEvent(eventId: "cal_search_advanced",
                   params: ["search_result": hasResult.description,
                            "entry_action": "no_value"])
    }
}

// MARK: 邀请邮件参与人（不依赖larkMail版
extension CalendarTracer {
    struct CalAddAccountParam {
        enum ActionSource: String {
            case accountManagement = "account_management"
            case quickActionSheet = "quick_action_sheet"
            case search
            case defaultView = "default_view"
        }
    }

    func calAddAccount(actionSource: CalAddAccountParam.ActionSource) {
        writeEvent(eventId: "cal_add_account", params: ["action_source": actionSource.rawValue])
    }

}

// MARK: 附件
extension CalendarTracer {
    struct CalAttachmentOperationParam {
        enum SourceType: String {
            case detail
            case edit
        }
    }

    func calAttachmentOperation(sourceType: CalAttachmentOperationParam.SourceType) {
        writeEvent(eventId: "cal_attachment_operation",
                         params: ["action_type": "preview",
                                  "source_type": sourceType.rawValue])
    }
}

// MARK: 多时区
extension CalendarTracer {

    enum TimeZoneEntryType: String {
        case day, threeday, chat, findtime, profile
    }

    // 视图页「多时区」入口被点击
    func calClickTimeZoneEntry(from entryType: TimeZoneEntryType) {
        writeEvent(
            eventId: "cal_timezone_view",
            params: ["action_source": entryType.rawValue]
        )
    }

    enum TimeZoneSelectType: String {
        // 勾选设备时区
        case device
        // 勾选最近时区
        case recent
    }

    // 勾选视图弹窗视图搜索页的某个条目
    func calQuickSelectTimeZone(_ selectType: TimeZoneSelectType) {
        writeEvent(
            eventId: "cal_timezone_select",
            params: ["action_type": selectType.rawValue]
        )
    }

    // 勾选视图弹窗视图搜索页的某个条目
    func calSelectTimeZoneSearchingResult() {
        writeEvent(eventId: "cal_timezone_search")
    }

    // 视图页「多时区」被单击
    func calClickDatePickerOnEditPage() {
        writeEvent(eventId: "cal_timezone_tips")
    }

    // 编辑页 - 时间二级页 - guest local time 模块的 cell 被点击
    func calClickGuestLocalTime() {
        writeEvent(eventId: "cal_localtime_guests")
    }

}

// 会议室详情
extension CalendarTracer {
    struct MeetomgRoomDetailParam {
        enum ActionSource: String {
            case fullEventEditor = "full_event_editor"
            case calSubscribe = "cal_subscribe"
            case eventDetail = "event_detail"
            case search = "cal_mtgroom_search"
            case qrCode = "scan_code"
        }
        enum EditType: String {
            case new
            case edit
        }
    }

    // 会议室详情入口点击
    func calClickMeetingRoomInfo(from entryType: MeetomgRoomDetailParam.ActionSource,
                            with editType: MeetomgRoomDetailParam.EditType) {
        writeEvent(
            eventId: "cal_mtroom_profile",
            params: ["action_source": entryType.rawValue,
                     "edit_type": editType.rawValue]
        )
    }

    // 搜索页进入
    func calClickMeetingRoomInfoFromSearch() {
        writeEvent(eventId: "cal_mtroom_profile",
                   params: ["action_source": MeetomgRoomDetailParam.ActionSource.search.rawValue])
    }

    // 详情页进入
    func calClickMeetingRoomInfoFromDetail() {
        writeEvent(eventId: "cal_mtroom_profile",
                   params: ["action_source": MeetomgRoomDetailParam.ActionSource.eventDetail.rawValue])
    }

    // 订阅日历进入
    func calClickMeetingRoomInfoFromSubscribe() {
        writeEvent(eventId: "cal_mtroom_profile",
                   params: ["action_source": MeetomgRoomDetailParam.ActionSource.calSubscribe.rawValue])
    }

    // 二维码签到
    func calClickMeetingRoomInfoFromQRCode() {
        writeEvent(eventId: "cal_mtroom_profile",
                   params: ["action_source": MeetomgRoomDetailParam.ActionSource.qrCode.rawValue])
    }
}

// MARK: - 会议室视图
extension CalendarTracer {
    func showMeetingRoomView() {
        writeEvent(eventId: "cal_resource_main_view")
    }

    enum MeetingRoomViewAction {
        case changeDate // 切换日期
        case changeBuilding
        case changeEquipment
        case changeCapacity
        case resourceDetail(meetingRoomCalendarID: String)
    }

    func meetingRoomViewActions(action: MeetingRoomViewAction) {
        var params = [String: String]()
        params["target"] = "none"

        switch action {
        case .changeDate:
            params["click"] = "change_date"
        case .changeBuilding:
            params["click"] = "search_room"
        case .changeEquipment:
            params["click"] = "search_device"
        case .changeCapacity:
            params["click"] = "search_num"
        case .resourceDetail(let meetingRoomCalendarID):
            params["click"] = "resource_details"
            params["target"] = "cal_resource_book_view"
            params["resource_id"] = meetingRoomCalendarID
            // 会议室视图点击会议室详情必然会跳到忙闲页
            writeEvent(eventId: "cal_resource_book_view", params: ["resource_id": meetingRoomCalendarID])
        }

        writeEvent(eventId: "cal_resource_main_click", params: params)
    }

    enum MeetingRoomFreeBusyAction {
        case goDetailView
        case createNewEvent
        case changeDate
    }

    func meetingRoomFreeBusyActions(meetingRoomCalendarID: String, action: MeetingRoomFreeBusyAction) {
        var params = ["resource_id": meetingRoomCalendarID]
        switch action {
        case .createNewEvent:
            params["click"] = "full_create_event"
            params["target"] = "cal_event_full_create_view"
        case .goDetailView:
            params["click"] = "event_details"
            params["target"] = "none"
        case .changeDate:
            params["click"] = "change_date"
            params["target"] = "none"
        }
        writeEvent(eventId: "cal_resource_book_click", params: params)
    }

    func calendarMeetingRoomSwitcherShow() {
        writeEvent(eventId: "cal_top_sidebar_view")
    }

    enum CalendarMeetingRoomSwitcherAction: String {
        case calendarView = "calendar_view"
        case meetingRoomView = "resource_view"
        case meeting
        case createEvent = "full_create_event"
        case calendarMainSetting = "calendar_main_setting"
        case createWebinar = "create_webinar"
    }

    func calendarMeetingRoomSwitcherActions(action: CalendarMeetingRoomSwitcherAction) {
        var params = ["click": action.rawValue]

        switch action {
        case .meetingRoomView:
            params["target"] = "cal_resource_main_view"
        case .calendarView:
            params["target"] = "cal_calendar_main_view"
        case .meeting:
            params["target"] = "cal_add_vc_view"
        case .createEvent, .createWebinar:
            params["target"] = "cal_event_full_create_view"
        case .calendarMainSetting:
            params["target"] = "setting_calendar_view"
        }

        writeEvent(eventId: "cal_top_sidebar_click", params: params)
    }
}

// MARK: 会议室筛选
extension CalendarTracer {
    /// - Parameters:
    ///     - actionSource: full_event_editor / cal_subscribe / search_meeting
    ///     - editType: new / edit
    func calMeetingRoomFilterTapped(actionSource: String, editType: String? = nil) {
        var params: [String: String] = [:]
        params["action_source"] = actionSource
        if let type = editType {
            params["edit_type"] = type
        }

        writeEvent(eventId: "cal_filter", params: params)
    }

    /// - Parameters:
    ///     - actionSource: full_event_editor / cal_subscribe / search_meeting
    func calMeetingRoomFilterSaved(actionSource: String, chooseInfo: [String: String], smallTargetValue: Int = 0) {
        var params: [String: String] = [:]
        params["action_source"] = actionSource
        params["small_target_value"] = String(smallTargetValue)
        chooseInfo.forEach { (key, value) in
            params[key] = value
        }

        writeEvent(eventId: "cal_filter_save", params: params)
    }

}

// add VC
extension CalendarTracer {

    func calMainView() {
        let viewType = CalendarTracer.ViewType(mode: CalendarDayViewSwitcher().mode).rawValue

        writeEvent(eventId: "cal_calendar_main_view", params: [
            "view_type": viewType
        ])
    }

}

// MARK: 从个人卡片点击进入忙闲页
extension CalendarTracer {
    func calProfileTapped(userId: String, calendarId: String) {
        writeEvent(eventId: "cal_profile", params: [
            "to_user_id": userId,
            "calendar_id": calendarId
        ])
    }
}

// MARK: - 通知
extension CalendarTracer {
    enum InAppCardNotificationClick: String {
        case close
        case detail
        case card
    }
}

// For Calendar Card
extension CalendarTracer {

    func calBotDetail() { writeEvent(eventId: "cal_bot_detail") }

    func joinFromShare() { writeEvent(eventId: "cal_share_attend") }

    func calOpenEventDetail(cardMessageType: String, botCardType: String, eventServerID: String, isCrossTenant: Bool) {
        writeEvent(eventId: "cal_open_event_detail",
                   params: ["action_source": "card_message",
                            "card_message_type": cardMessageType,
                            "event_id": eventServerID,
                            "botCardType": botCardType,
                            "event_type": "event",
                            "view_type": "",
                            "is_cross_tenant": isCrossTenant.description])
    }

    func calEventResp(replyStatus: CalendarEventAttendee.Status) {
        let replyStatus = convertReplyStatusToEventLabel(replyStatus: replyStatus)
        writeEvent(eventId: "cal_bot",
                   params: ["cal_event_resp": replyStatus])
    }

    /// RSVP附言
    func rsvpReplyFromCardMessage() {
        writeEvent(eventId: "cal_rsvp_rply", params: ["action_source": "card_message"])
    }

    private func convertReplyStatusToEventLabel(replyStatus: CalendarEventAttendee.Status) -> String {
        switch replyStatus {
        case .accept:
            return "acpt"
        case .decline:
            return "decl"
        case .tentative:
            return "mayb"
        default:
            return "unowned"
        }
    }

    func calJoinEvent(actionSource: CalJoinEventParam.ActionSource,
                      eventType: EventType,
                      eventId: String,
                      isCrossTenant: Bool,
                      chatId: String) {
        writeEvent(eventId: "cal_join_event",
                   params: ["action_source": actionSource.rawValue,
                            "event_type": eventType.rawValue,
                            "event_id": eventId,
                            "is_cross_tenant": isCrossTenant ? "yes" : "no",
                            "chat_id": chatId])
    }
}

// 邀请问卷埋点
extension CalendarTracer {
    func calFeelGood() {
        writeEvent(eventId: "cal_calendar_feel_good_view")
    }
}
// Calendar Manager
extension CalendarTracer {

    struct AccountManageParam {
        enum ActionSource: String {
            /// 设置页
            case setting = "cal_setting"
            /// 其他
            case other = "other"
        }
    }

    func accountManageShow(from source: AccountManageParam.ActionSource) {
        var params = [
            "action_source": source.rawValue
        ]
        writeEvent(eventId: "cal_tripartite_manage_view", params: params)
    }

    func accountManagerClick(clickParam: String, target: String?, isOpen: Bool? = nil) {
        var params = [
            "click": clickParam
        ]
        if let target = target {
            params["target"] = target
        }

        if let isOpen = isOpen {
            params["is_open"] = isOpen ? "true" : "false"
        }
        writeEvent(eventId: "cal_tripartite_manage_click", params: params)
    }
}

// Calendar Detail {
extension CalendarTracer {

    func calDetailView(isSubscribed: Bool,
                       isPrivate: Bool,
                       calendarID: String) {
        writeEvent(eventId: "cal_calendar_detail_view",
                   params: [
                    "subscribed": isSubscribed.description,
                    "is_private": isPrivate.description,
                    "is_external_open": false.description,
                    "calendar_id": calendarID])
    }

    func calDetailClick(calendarID: String, clickType: String) {
        writeEvent(eventId: "cal_calendar_detail_click",
                   params: [
                    "click": clickType,
                    "calendar_id": calendarID,
                    "target": "none"
                ])
    }
    enum MainClickType: String {
        case quick_create_event // 点击任意空闲时段快速创建日程
        case day_change // 移动端滑动行为
        case calendar_list_open // 移动端点击右上角「选择日历」图标
        case timezone_setting // 移动端右上角设置时区域

        var target: String? {
            switch self {
            case .quick_create_event:
                return "cal_event_full_create_view"
            case .day_change:
                 return "none"
            case .calendar_list_open:
                return "cal_calendar_list_view"
            default:
                return nil
            }
        }
    }

    func calMainClick(type: MainClickType) {
        var params: [String: String] = [:]
        params["click"] = type.rawValue
        if let target = type.target {
            params["target"] = target
        }
        writeEvent(eventId: "cal_calendar_main_click",
                   params: params)
    }
}

extension CalendarTracer {
    func userNotInEventToast(chatId: String) {
        writeEvent(eventId: "cal_toast_status",
                   params: ["chat_id": chatId,
                            "toast_name": "no_permission_to_view"])
    }
}
