//
//  RustPushService.swift
//  Calendar
//
//  Created by zhuheng on 2021/3/9.
//
import RxSwift
import RustPB
import ServerPB
import LKCommonsLogging

typealias EventAlertId = String
typealias ExternalAccountEmail = String
typealias CalendarIds = [String]

extension Rust {
    public typealias ExternalCalendar = RustPB.Calendar_V1_PushExternalSyncNotification
    public typealias GoogleBindSetting = RustPB.Calendar_V1_PushGoogleBindSettingNotification
    public typealias CalendarEventChanged = RustPB.Calendar_V1_PushCalendarEventChangedNotification
    public typealias MeetingMinuteEditors = RustPB.Calendar_V1_PushMeetingMinuteEditors
    public typealias CalendarReminder = RustPB.Calendar_V1_PushCalendarEventReminderResponse
    public typealias MeetingEventRef = RustPB.Calendar_V1_MeetingEventRef
    public typealias PushMeeting = RustPB.Calendar_V1_PushMeetingNotification
    public typealias MeetingRoomInstanceChanged = RustPB.Calendar_V1_PushRoomViewInstanceChangeNotification
    public typealias ChangedActiveEvent = RustPB.Calendar_V1_ChangedActiveEvent
    public typealias MeetingChatBannerChanged = RustPB.Calendar_V1_PushMeetingChatBannerChangedNotification
    public typealias CalendarSyncInfo = RustPB.Calendar_V1_CalendarSyncInfo
}

final class RustPushService {
    /// 会议群横幅关闭通知
    var rxMeetingBannerClosed: PublishSubject<(String, ServerPB_Entities_ScrollType)> = .init()
    /// 日程提醒卡片
    var rxEventReminder: PublishSubject<Rust.CalendarReminder> = .init()
    /// 日程提醒卡片关闭
    var rxReminderCardClosed: PublishSubject<EventAlertId> = .init()
    /// 视频会议信息变更
    var rxVideoMeetingInfos: PublishSubject<[Rust.VideoMeetingNotiInfo]> = .init()
    /// 视频会议信息变更
    let rxVideoLiveHostStatus: PublishSubject<Rust.AssociatedLiveStatus> = .init()
    /// 精细化更新
    let rxCalendarEventChanged: PublishSubject<Rust.CalendarEventChanged> = .init()
    /// 视频会议状态变更
    let rxVideoStatus: PublishSubject<(uniqueId: String, status: Rust.VideoMeetingStatus)> = .init()
    /// google 绑定
    let rxGoogleCalAccount: PublishSubject<ExternalAccountEmail> = .init()
    /// 三方日历变更
    let rxExternalCalendar: PublishSubject<Rust.ExternalCalendar> = .init()
    /// google 绑定设置
    let rxGoogleBind: PublishSubject<Rust.GoogleBindSetting> = .init()
    /// 日历刷新
    let rxCalendarRefresh: PublishSubject<[Rust.CalendarSyncInfo]> = .init()
    /// 日历设置刷新
    let rxSettingRefresh: PublishSubject<Void> = .init()
    /// 视频会议刷新
    let rxMeetingChange: PublishSubject<[Rust.MeetingEventRef]> = .init()
    /// 会议纪要状态刷新
    let rxMeetingMinuteEditors: PublishSubject<Rust.MeetingMinuteEditors> = .init()
    /// 日历同步
    let rxCalendarSync: PublishSubject<Void> = .init()
    /// 活跃详情页变更
    let rxActiveEventChanged: PublishSubject<[Rust.ChangedActiveEvent]> = .init()

    let rxMeetingRoomInstanceChanged: PublishSubject<[String]> = .init()
    /// 租户设置更新（row 为需更新字段）
    let rxTenantSettingChanged: PublishSubject<Calendar_V1_CalendarTenantSettingsRow> = .init()
    /// 会议群日程Banner信息更新
    let rxMeetingChatBannerChanged: PublishSubject<Calendar_V1_PushMeetingChatBannerChangedNotification> = .init()
    /// 事件页面数据更新
    let rxTodayInstanceChanged: PublishSubject<Void> = .init()
    /// calendar设置feed事件临时置顶push
    let rxFeedTempTop: PublishSubject<Bool> = .init()
    /// Inline AI 推送的ai状态
    let rxInlineAiTaskStatus: PublishSubject<Rust.InlineAITaskStatusPushResponse> = .init()
    /// 时间容器变更通知
    let rxTimeContainerChanged: PublishSubject<[String]> = .init()
    /// container上的timeBlock发生变化
    let rxTimeBlocksChange: PublishSubject<[String]> = .init()

    static let logger = Logger.log(RustPushService.self, category: "Calendar.RustPushService")
}
