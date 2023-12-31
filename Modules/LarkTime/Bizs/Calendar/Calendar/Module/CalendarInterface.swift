//
//  CalendarInterface.swift
//  Calendar
//
//  Created by zhuheng on 2021/2/28.
//

import Foundation
import EENavigator
import RxSwift
import RxRelay
import EventKit
import LarkUIKit
import UIKit
import RustPB

// public protocol
public protocol CalendarInterface {

    func calendarHome() -> CalendarHome

    /// 显示选择时区组件
    /// - Parameters:
    ///   - timeZone: 当前选择时区
    ///   - from: present 的父容器
    ///   - onTimeZoneSelect: 选择时区回调
    /// - Note:
    ///   - 选择后记录最近使用时区
    func showTimeZoneSelectController(with timeZone: TimeZone?,
                                      from: UIViewController,
                                      onTimeZoneSelect: @escaping (TimeZone) -> Void)

    func eventTimeDescription(start: Int64,
                              end: Int64,
                              isAllDay: Bool) -> String

    func getMeetingSummaryBadgeStatus(_ chatId: String, handler: @escaping (Result<Bool, Error>) -> Void)

    func registerMeetingSummaryPush() -> Observable<(String, Int)>

    func toNormalGroup(chatID: String) -> Observable<Void>

    func searchCalendarEvent(query: String) -> Observable<[LarkCalendarEventSearchResult]>

    func getIsOrganizer(chatID: String) -> Observable<Bool>

    func showAddExternalAccountHint(in viewController: UIViewController) -> Observable<Bool>

    func getEventInfo(chatId: String) -> Observable<CalendarChatMeetingEventInfo?>

    func getOldFreeBusyController(userId: String, isFromProfile: Bool) -> UIViewController

    func getSearchController(query: String?, searchNavBar: SearchNaviBar?) -> UIViewController

    func getOldGroupFreeBusyController(chatId: String, chatType: String, createEventBody: CalendarCreateEventBody?) -> UIViewController

    func getEventDetailFromShare(getterModel: DetailControllerGetterModel) -> UIViewController

    func getCreateEventController(for createBody: CalendarCreateEventBody) -> UIViewController

    func getCalendarEventShareBinder(controllerGetter: @escaping () -> UIViewController, model: ShareEventCardModel) -> EventShareBinder

    func getCalendarEventCardBinder(controllerGetter: @escaping () -> UIViewController, model: InviteEventCardModel) -> EventCardBinder
    
    func getCalendarEventRSVPCardBinder(controllerGetter: @escaping () -> UIViewController, model: RSVPCardModel) -> EventRSVPBinder

    func getEventContentController(with chatId: String,
                                   isFromChat: Bool) -> UIViewController

    func getEventContentController(with pbEvent: Rust.Event, scene: EventDetailScene) -> UIViewController?

    func handleCreateEventSucceed(pbEvent: Rust.Event, fromVC: UIViewController)

    /// 日程详情页
    func getEventContentController(with key: String,
                                    calendarId: String,
                                    originalTime: Int64,
                                    startTime: Int64?,
                                    endTime: Int64?,
                                    instanceScore: String,
                                    isFromChat: Bool,
                                    isFromNotification: Bool,
                                    isFromMail: Bool,
                                    isFromTransferEvent: Bool,
                                    isFromInviteEvent: Bool,
                                   scene: EventDetailScene) -> UIViewController

    func getEventContentController(with uniqueID: String,
                                   startTime: Int64,
                                   instance_start_time: Int64,
                                   instance_end_time: Int64,
                                   original_time: Int64,
                                   vchat_meeting_id: String,
                                   key: String) -> UIViewController

    func getSeizeMeetingroomController(token: String) -> UIViewController

    func getSettingsController(fromWhere: CalendarSettingBody.FromWhere) -> UIViewController

    func appLinkEventEditController(calendarId: String,
                                           key: String,
                                           originalTime: Int64,
                                           startTime: Int64?) -> Observable<(UIViewController?, Bool)>
    
    func appLinkEventEditController(token: String) -> Observable<UIViewController?>
    
    func appLinkNewEventController(startTime: Date?, endTime: Date?, summary: String?) -> UIViewController

    func applinkEventDetailController(key: String,
                                      calendarId: String,
                                      source: String,
                                      token: String?,
                                      originalTime: Int64,
                                      startTime: Int64?,
                                      endTime: Int64?,
                                      isFromAPNS: Bool) -> UIViewController

    func appLinkCalendarSettingController(calendarId: String) -> UIViewController?

    func appLinkNewCalendarController(summary: String?,
                                      _ willShowSidebar: @escaping () -> Void) -> UINavigationController

    func appLinkExternalAccountManageController() -> UINavigationController

    func getLocalDetailController(identifier: String) -> UIViewController

    // 目前有mail特化逻辑
    func getEventEditController(legoInfo: EventEditLegoInfo,
                                editMode: EventEditMode,
                                interceptor: EventEditInterceptor,
                                title: String?) -> GetControllerResult

    func traceEventDetailVideoMeetingShowIfNeed(event: Rust.Event, with isInMeeting: Bool)

    func traceEventDetailVideoMeetingClick(event: Rust.Event, click: String, target: String)

    func traceEventDetailOpenVideoMeeting(event: Rust.Event)

    func traceEventDetailJoinVideoMeeting(event: Rust.Event)

    func traceEventDetailCopyVideoMeeting(event: Rust.Event)

    func traceEventDetailVCSetting()

    func reciableTraceEventDetailStartEnterMeeting()

    func reciableTraceEventDetailEndEnterMeeting()

    func reciableTraceEventDetailEnterMeetingFailed(errorCode: Int, errorMessage: String)
    
    func getFreeBusyController(body: CalendarFreeBusyBody) -> UIViewController
    
    func getGroupFreeBusyController(chatId: String, chatType: String, createEventBody: CalendarCreateEventBody?) -> UIViewController

    func getAllCalendarsForSearchBiz() -> Observable<[CalendarForSearch]>
}

public struct CalendarForSearch {
    public var serverId: String
    public var summary: String
    public var isVisible: Bool
    public var isOwnerAccessRole: Bool
    public var color: UIColor
}

public enum GetControllerResult {
    case success(UIViewController)
    case error(String)
}

extension CalendarInterface {
    // 兼容之前接口
    func getSearchController(query: String?) -> UIViewController {
        getSearchController(query: query, searchNavBar: nil)
    }
}

// MARK: Public struct
/// 与会议群有关的信息
public struct MeetingEventInfo {
    public let startTime: Int64
    public let endTime: Int64
    public let alertName: String

    public init(startTime: Int64, endTime: Int64, alertName: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.alertName = alertName
    }
}

/// 会议群 日程和纪要分离，互不阻塞在群应用中的显示
public struct CalendarChatMeetingEventInfo {
    public let meetingEventInfo: MeetingEventInfo?
    public let url: URL? // 会议纪要URL

    public init(meetingEventInfo: MeetingEventInfo?, url: URL?) {
        self.url = url
        self.meetingEventInfo = meetingEventInfo
    }
}

public protocol EventInfo {}

// MARK: Router
public struct CalendarSettingBody: CodablePlainBody {
    public static let pattern = "//client/calendar/setting"
    public let fromWhere: FromWhere
    public enum FromWhere: Encodable, Decodable {
        case todayEvent
        case none
    }

    public init(fromWhere: FromWhere = .none) {
        self.fromWhere = fromWhere
    }
}

public struct CalendarFreeBusyBody: CodableBody {
    private static let prefix = "//client/calendar/freebusy"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)")
    }

    public var _url: URL {
        return URL(string: "\(CalendarFreeBusyBody.prefix)/?\(uid)")!
    }

    public var uid: String = ""
    public var isFromProfile: Bool = false

    public init(uid: String = "",
                isFromProfile: Bool = false) {
        self.uid = uid
        self.isFromProfile = isFromProfile
    }
}

public struct CalendarEventDetailBody: CodablePlainBody {
    public static let pattern = "//client/calendar/event/detail"

    public var eventKey: String = ""
    public var calendarId: String = ""
    public var originalTime: Int64 = 0
    public var startTime: Int64?
    public var isFromChat: Bool = false
    public var isFromNotification: Bool = false
    public var sysEventIdentifier: String = ""
    public var isFromAPNS: Bool = false

    public init(
        eventKey: String,
        calendarId: String,
        originalTime: Int64,
        startTime: Int64? = nil,
        sysEventIdentifier: String,
        isFromChat: Bool,
        isFromNotification: Bool,
        isFromAPNS: Bool = false) {

        self.eventKey = eventKey
        self.calendarId = calendarId
        self.originalTime = originalTime
        self.sysEventIdentifier = sysEventIdentifier
        self.isFromChat = isFromChat
        self.isFromNotification = isFromNotification
        self.isFromAPNS = isFromAPNS
        self.startTime = startTime
    }
}

public struct CalendarEventDetailWithTimeBody: CodablePlainBody {
    public static let pattern = "//client/calendar/event/withTimeDetail"

    public var eventKey: String = ""
    public var calendarId: String = ""
    public var originalTime: Int64 = 0
    public var startTime: Int64 = 0
    public var endTime: Int64 = 0

    public init(
        eventKey: String,
        calendarId: String,
        originalTime: Int64,
        startTime: Int64,
        endTime: Int64) {

        self.eventKey = eventKey
        self.calendarId = calendarId
        self.originalTime = originalTime
        self.startTime = startTime
        self.endTime = endTime
    }
}

public struct CalendarEventDetailFromMail: CodablePlainBody {
    public static let pattern = "//client/calendar/event/detailFromMail"

    public var eventKey: String = ""
    public var calendarId: String = ""
    public var originalTime: Int64 = 0

    public init(
        eventKey: String,
        calendarId: String,
        originalTime: Int64) {

        self.eventKey = eventKey
        self.calendarId = calendarId
        self.originalTime = originalTime
    }
}

public struct CalendarEeventDetailFromMeeting: CodablePlainBody {
    public static let pattern = "//client/calendar/event/detailFromMeeting"

    public let chatId: String

    public init(chatId: String) {
        self.chatId = chatId
    }
}

/// 视频卡片日程详情路由
public struct CalendarEventDetailWithUniqueIdBody: CodablePlainBody {
    public static let pattern = "//client/calendar/event/detailWithUniqueId"
    public let uniqueId: String
    public let key: String
    public let originalTime: Int64
    public let videoStartTimeStamp: Int64
    public let videoEndTimeStamp: Int64
    public let meetingID: String
    public init(
        uniqueId: String,
        key: String,
        originalTime: Int64,
        videoStartTimeStamp: Int64,
        videoEndTimeStamp: Int64,
        meetingID: String) {
        self.uniqueId = uniqueId
        self.key = key
        self.originalTime = originalTime
        self.videoStartTimeStamp = videoStartTimeStamp
        self.videoEndTimeStamp = videoEndTimeStamp
        self.meetingID = meetingID
        }
}

public struct CalendarDocsFromMeeting: CodablePlainBody {
    public static let pattern = "//client/calendar/event/docsFromMeeting"

    public let chatId: String

    public let alertName: String

    public init(chatId: String, alertName: String) {
        self.chatId = chatId
        self.alertName = alertName
    }
}

public struct CalendarEventSubSearch: CodablePlainBody {
    public static let pattern = "//client/calendar/search/searchMain"

    public let query: String?

    public init(query: String?) {
        self.query = query
    }
}

public struct CalendarAdditionalTimeZoneBody: CodablePlainBody {
    public static let pattern = "//client/calendar/additionalTimeZone"

    public let activateDay: Int

    public init(activateDay: Int) {
        self.activateDay = activateDay
    }
}

public struct CalendarAdditionalTimeZoneManagerBody: PlainBody {
    public static let pattern = "//client/calendar/setting/additionalTimeZone"

    public let provider: SettingPageProvider

    public init(provider: SettingPageProvider) {
        self.provider = provider
    }
}

public struct CalendarTodayEventBody: CodablePlainBody {
    public static let pattern = "//client/calendar/event/todayevent"

    let feedTab: String
    let isTop: Bool
    let showCalendarID: String
    let feedID: String
    public init(feedTab: String,
                isTop: Bool,
                showCalendarID: String,
                feedID: String) {
        self.feedTab = feedTab
        self.isTop = isTop
        self.showCalendarID = showCalendarID
        self.feedID = feedID
    }
}

public struct CalendarCreateEventBody: PlainBody {
    public static var pattern: String = "//client/calendar/create/event"

    /// 日程参与人
    public enum Attendee {
        case meWithMeetingRoom(meetingRoom: Rust.MeetingRoom)
        /// 单聊
        case p2p(chatId: String, chatterId: String)
        /// 普通群
        /// - Parameter chatId: 群 id
        /// - Parameter memberCount: 群成员数量
        case group(chatId: String, memberCount: Int)

        /// 会议群（会议群作为参与人，成员会被打散）
        /// - Parameter chatId: 群 id
        /// - Parameter memberCount: 群成员数量
        case meetingGroup(chatId: String, memberCount: Int)

        /// 群部分成员
        /// - Parameter chatId: 群 id
        /// - Parameter memberCount: 群成员数量
        case partialGroupMembers(chatId: String, memberChatterIds: [String])

        /// 会议群部分成员
        /// - Parameter chatId: 群 id
        /// - Parameter memberCount: 群成员数量
        case partialMeetingGroupMembers(chatId: String, memberChatterIds: [String])
    }

    /// 编辑场景
    public enum Scene {
        /// 编辑页
        case edit
        /// 忙闲页
        case freebusy
        /// webinar 新建
        case webinar
    }

    /// 标题
    public var summary: String?
    /// 开始时间
    public var startDate: Date = Date()
    /// 结束时间
    public var endDate: Date?
    /// 是否是全天
    public var isAllDay: Bool = false
    /// 时区
    public var timeZone: TimeZone = .current
    /// 参与人
    public var attendees: [Attendee] = []
    /// perferred 场景
    public var perferredScene: Scene = .edit
    /// 会议室
    public var meetingRoom: [(fromResource: Rust.MeetingRoom, buildingName: String, tenantId: String)]
    /// 飞书视频会议
    public var isOpenLarkVC: Bool = true

    public init(
        summary: String? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isAllDay: Bool = false,
        timeZone: TimeZone = .current,
        attendees: [Attendee] = [],
        perferredScene: Scene = .edit,
        meetingRoom: [(fromResource: Rust.MeetingRoom, buildingName: String, tenantId: String)] = [],
        isOpenLarkVC: Bool = true
    ) {
        self.summary = summary
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.timeZone = timeZone
        self.attendees = attendees
        self.perferredScene = perferredScene
        self.meetingRoom = meetingRoom
        self.isOpenLarkVC = isOpenLarkVC
    }

}

public protocol LarkCalendarEventSearchResult {
    var calendarId: String { get }
    var eventKey: String { get }
    var originalTime: Int64 { get }
    var title: String { get }
    var subtitle: String { get }
    var isLarkEvent: Bool { get }
    var startTime: Int64 { get }
    var endTime: Int64 { get }
    var titleHitTerms: [String] { get }
    var subtitleHitTerms: [String] { get }
    var timeDisplay: String { get }
}

public struct FreeBusyInGroupBody: CodablePlainBody {
    public static let pattern = "//client/calendar/event/freeBusyInGroup"
    public var chatId: String = ""
    public var chatType: String = ""

    public init(chatId: String, chatType: String) {
        self.chatId = chatId
        self.chatType = chatType
    }
}

struct EventSearchResult: LarkCalendarEventSearchResult {
    let searchContent: CalendarGeneralSearchContent

    var startTime: Int64 {
        return searchContent.startTime
    }
    var endTime: Int64 {
        return searchContent.endTime
    }
    var calendarId: String {
        return searchContent.calendarId
    }
    var eventKey: String {
        return searchContent.eventKey
    }
    var originalTime: Int64 {
        return searchContent.originalTime
    }
    var title: String {
        return searchContent.title
    }
    var subtitle: String {
        return searchContent.subtitle
    }
    var isLarkEvent: Bool {
        return searchContent.isLarkEvent
    }
    var titleHitTerms: [String] {
        return searchContent.titleHitTerms
    }
    var subtitleHitTerms: [String] {
        return searchContent.subtitleHitTerms
    }
    var timeDisplay: String {
        return searchContent.timeDisplay
    }

    init(searchContent: CalendarGeneralSearchContent) {
        self.searchContent = searchContent
    }
}
