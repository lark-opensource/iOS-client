//
//  EventModel.swift
//  CalendarEvent
//
//  Created by zhuchao on 13/12/2017.
//  Copyright © 2017 EE. All rights reserved.
//
import RustPB
import EventKit
import LarkFoundation

public enum DataSource {
    case sdk
    case system
}

protocol CalendarEventEntity {
    typealias Source = CalendarEvent.Source
    typealias Visibility = CalendarEvent.Visibility
    typealias Status = CalendarEvent.Status
    typealias EventType = CalendarEvent.TypeEnum
    typealias Span = CalendarEvent.Span
    typealias NotificationType = CalendarEvent.NotificationType

    var id: String { get set }
    var originalTime: Int64 { get }
    var isEditable: Bool { get }
    var creatorCalendarId: String { get set }
    var calendarId: String { get set }
    var organizerCalendarId: String { get set }
    var organizer: CalendarEventAttendeeEntity { get }
    var serverId: String { get }
    var hasSelfAttendeeStatus: Bool { get }
    var selfAttendeeStatus: CalendarEventAttendee.Status { get }
    var key: String { get }
    var needUpdate: Bool { get set }
    var summary: String { get set }
    var summaryIsEmpty: Bool { get }
    var description: String { get set }
    var isAllDay: Bool { get set }
    var startTime: Int64 { get set }
    var startTimezone: String { get set }
    var endTime: Int64 { get set }
    var endTimezone: String { get set }
    var status: CalendarEvent.Status { get }
    var rrule: String { get set }
    var attendees: [CalendarEventAttendeeEntity] { get set }
    var location: CalendarLocation { get set }
    var reminders: [Reminder] { get set }
    var displayType: CalendarEvent.DisplayType { get }
    var visibility: CalendarEvent.Visibility { get set }
    var isFree: Bool { get set }
    var type: EventType { get set }
    var source: Source { get }
    var serverID: String { get }
    var calColor: ColorIndex { get }
    var eventColor: ColorIndex { get set }
    var guestCanInvite: Bool { get }
    var guestCanModify: Bool { get }
    var guestCanSeeOtherGuests: Bool { get }
    var isSharable: Bool { get }
    var docsDescription: String { get set }
    var creator: CalendarEventAttendeeEntity { get }
    var successor: CalendarEventAttendeeEntity { get }
    var willCreatorAttend: Bool { get }
    var willOrganizerAttend: Bool { get }
    var willSuccessorAttend: Bool { get }
    var isCrossTenant: Bool { get set }
    var notificationType: NotificationType { get set }
    var videoMeeting: VideoMeeting? { get }
    var docsToken: String { get set }
    var userInviteOperatorID: String? { get }
    var inviteOperatorLocalizedName: String { get }
    var hasSuccessor: Bool { get }
    var hasOrganizer: Bool { get }
    var hasCreator: Bool { get }

    // local event should return nil for belowing values
    var shouldShowEditButton: Bool? { get }
    var editButtonDisabled: Bool { get }
    var isDeleteable: Bool? { get }
    var isTransferable: Bool? { get }
    var isVideoMeetingAvailable: Bool? { get }
    var isReportable: Bool? { get }
    var isCreatedByMeetingRoom: (strategy: Bool, requisition: Bool) { get }
    var category: CalendarEvent.Category { get }
    var attachments: [CalendarEventAttachmentEntity] { get set }
    var schemaCollection: Rust.SchemaCollection? { get }
    var eventAttendeeStatistics: EventAttendeeStatistics { get }
    /// 之前的逻辑是用这个字段表示是否展示组织者，现在意思是『是否额外展示创建者』
    var isEventCreatorShow: Bool { get }
    /// 是否展示组织者
    var isEventOrganizerShow: Bool { get }
    /// 创建者是否已离职
    var isEventCreatorResigned: Bool { get }

    func getTitle() -> String
    func visibleAttendees() -> [CalendarEventAttendeeEntity]
    func isOrganizer(primaryCalendarId: String) -> Bool
    func isRecurrence() -> Bool
    func isException() -> Bool
    func isRepetitive() -> Bool
    func debugMessage() -> String
    func getDataSource() -> DataSource
    func getPBModel() -> CalendarEvent
    func getEKEvent() -> EKEvent?
    func instance(with calendar: CalendarModel?,
                  instanceStartTime: Int64,
                  instanceEndTime: Int64,
                  instanceScore: String) -> CalendarEventInstanceEntity
    func canDeleteAll() -> Bool
    func isSchemaDisplay(key: Rust.SchemaCollection.SchemaKey) -> Bool?
    func schemaLink(key: Rust.SchemaCollection.SchemaKey) -> URL?
    func schemaCompatibleLevel() -> Rust.IncompatibleLevel?
}

struct PBCalendarEventEntity: CalendarEventEntity {
    var shouldShowEditButton: Bool? {
        return pb.calendarEventDisplayInfo.isEditableBtnShow
    }

    var editButtonDisabled: Bool {
        return pb.calendarEventDisplayInfo.editBtnDisplayType == .shownExternalAccountExpired
    }

    var shownChatOpenEntryAuth: Bool {
        return pb.calendarEventDisplayInfo.editBtnDisplayType == .shownChatOpenEntryAuth
    }

    var isDeleteable: Bool? {
        return pb.calendarEventDisplayInfo.isDeletableBtnShow
    }

    var isTransferable: Bool? {
        return pb.calendarEventDisplayInfo.isTransferBtnShow
    }

    var isVideoMeetingAvailable: Bool? {
        return pb.calendarEventDisplayInfo.isVideoMeetingBtnShow
    }

    var isEventCreatorShow: Bool {
        return pb.calendarEventDisplayInfo.isEventCreatorShow
    }

    var isEventCreatorResigned: Bool {
        return pb.calendarEventDisplayInfo.displayExtraData.hasEventCreatorResigned_p
    }

    var isEventOrganizerShow: Bool {
        return pb.calendarEventDisplayInfo.isEventOrganizerShow
    }

    var category: CalendarEvent.Category {
        return pb.category
    }

    var isCreatedByMeetingRoom: (strategy: Bool, requisition: Bool) {
        let isStrategy = pb.category == .resourceStrategy
        let isRequisition = pb.category == .resourceRequisition
        return (isStrategy, isRequisition)
    }

    var isReportable: Bool? {
        return pb.calendarEventDisplayInfo.isReportBtnShow
    }

    var docsToken: String {
        get {
            return self.pb.meetingMinuteURL
        }
        set {
            self.pb.meetingMinuteURL = newValue
        }
    }

    var hasSelfAttendeeStatus: Bool {
        return self.pb.hasSelfAttendeeStatus
    }

    var hasSuccessor: Bool {
        return pb.hasSuccessor
    }

    var hasOrganizer: Bool {
        return pb.hasOrganizer
    }

    var hasCreator: Bool {
        return pb.hasCreator
    }

    var willCreatorAttend: Bool {
        return self.pb.willCreatorAttend
    }

    var willOrganizerAttend: Bool {
        return self.pb.willOrganizerAttend
    }

    var willSuccessorAttend: Bool {
        return self.pb.willSuccessorAttend
    }

    func canDeleteAll() -> Bool {
        return self.pb.isDeletable == .all
    }

    var isCrossTenant: Bool {
        get {
            return self.pb.isCrossTenant
        }
        set {
            self.pb.isCrossTenant = newValue
        }
    }

    func debugMessage() -> String {
        return ""
    }

    func getDataSource() -> DataSource {
        return .sdk
    }

    func getEKEvent() -> EKEvent? {
        return nil
    }

    typealias Source = CalendarEvent.Source
    typealias Visibility = CalendarEvent.Visibility
    public typealias Status = CalendarEvent.Status
    typealias SelfAttendeeStatus = CalendarEventAttendee.Status
    typealias DisplayType = CalendarEvent.DisplayType
    typealias EventType = CalendarEvent.TypeEnum

    init(pb: CalendarEvent) {
        self.pb = pb
        let localPb = pb

        _reminders = localPb.reminders.map({ Reminder(pb: $0, isAllDay: localPb.isAllDay) })
        _attendees = localPb.attendees.map({ PBAttendee(pb: $0, displayOrganizerCalId: self.realOrganizerCalId(from: localPb)) })
    }

    init() {
        self.pb = CalendarEvent()
        self.pb.originalTime = 0
        self.pb.key = ""
        self.pb.isEditable = true
        _reminders = []
        _attendees = []
    }

    func getPBModel() -> CalendarEvent {
        return pb
    }

    private var pb: CalendarEvent

    var id: String {
        get { return pb.id }
        set { pb.id = newValue }
    }

    var eventAttendeeStatistics: EventAttendeeStatistics {
        return pb.attendeeInfo
    }

    var videoMeeting: VideoMeeting? {
        guard pb.hasVideoMeeting else {
            return nil
        }
        return VideoMeeting(pb: pb.videoMeeting)
    }

    var originalTime: Int64 {
        return pb.originalTime
    }

    var isEditable: Bool {
        return pb.isEditable
    }

    var userInviteOperatorID: String? {
        let id = pb.userInviteOperator.userInviteOperatorID
        return id.isEmpty ? nil : id
    }

    var inviteOperatorLocalizedName: String {
        return pb.userInviteOperator.userInviteOperatorLocalizedName
    }

    var creatorCalendarId: String {
        get { return pb.creatorCalendarID }
        set { pb.creatorCalendarID = newValue }
    }

    var calendarId: String {
        get { return pb.calendarID }
        set { pb.calendarID = newValue }
    }

    var organizerCalendarId: String {
        get { return pb.organizerCalendarID }
        set { pb.organizerCalendarID = newValue }
    }

    var organizer: CalendarEventAttendeeEntity {
        return PBAttendee(pb: pb.organizer)
    }

    var successor: CalendarEventAttendeeEntity {
        return PBAttendee(pb: pb.successor)
    }

    var serverId: String {
        return pb.serverID
    }

    var selfAttendeeStatus: SelfAttendeeStatus {
        return pb.selfAttendeeStatus
    }

    var key: String {
        return pb.key
    }

    var needUpdate: Bool {
        get { return pb.needUpdate }
        set { pb.needUpdate = newValue }
    }

    var summary: String {
        get { return PBCalendarEventEntity.generateCalendarEventEntitySummary(pb.summary) }
        set { pb.summary = newValue }
    }

    var summaryIsEmpty: Bool {
        return pb.summary.isEmpty
    }

    var description: String {
        get { return pb.description_p }
        set { pb.description_p = newValue }
    }

    var isAllDay: Bool {
        get { return pb.isAllDay }
        set { pb.isAllDay = newValue }
    }

    var startTime: Int64 {
        get { return pb.startTime }
        set { pb.startTime = newValue }
    }

    var startTimezone: String {
        get { return pb.startTimezone }
        set { pb.startTimezone = newValue }
    }

    var endTime: Int64 {
        get { return pb.endTime }
        set { pb.endTime = newValue }
    }

    var endTimezone: String {
        get { return pb.endTimezone }
        set { pb.endTimezone = newValue }
    }

    var status: Status {
        return pb.status
    }

    var rrule: String {
        get { return pb.rrule }
        set { pb.rrule = newValue }
    }

    var notificationType: NotificationType {
        get { return pb.notificationType }
        set { pb.notificationType = newValue }
    }

    /// 需要一个中间层 存储 attendees, 因为pb里面没有isNewAddes字段，attendees不能是单纯的计算属性
    private var _attendees: [CalendarEventAttendeeEntity] = []
    var attendees: [CalendarEventAttendeeEntity] {
        get {
            return _attendees
        }
        set {
            // swiftlint:disable force_cast
            pb.attendees = newValue.map({ $0.originalModel() as! CalendarEventAttendee })
            _attendees = newValue
        }
    }

    var location: CalendarLocation {
        get { return pb.location }
        set { pb.location = newValue }
    }

    private var _reminders: [Reminder]
    var reminders: [Reminder] {
        get { return _reminders }
        set {
            pb.reminders = newValue.map({ $0.toPB() })
            _reminders = newValue
        }
    }

    var displayType: DisplayType {
        return pb.displayType
    }

    var visibility: Visibility {
        get { return pb.visibility }
        set { pb.visibility = newValue }
    }

    var isFree: Bool {
        get { return pb.isFree }
        set { pb.isFree = newValue }
    }

    var type: EventType {
        get { return pb.type }
        set { pb.type = newValue }
    }

    var docsDescription: String {
        get { return pb.docsDescription }
        set { pb.docsDescription = newValue }
    }

    var source: Source {
        return pb.source
    }

    var serverID: String {
        return pb.serverID
    }

    var calColor: ColorIndex {
        return pb.calColorIndex
    }

    var eventColor: ColorIndex {
        get {
            return pb.colorIndex.isNoneColor ? pb.calColorIndex : pb.colorIndex
        }
        set {
            pb.colorIndex = newValue
        }
    }

    var guestCanModify: Bool {
        return pb.guestCanModify
    }

    var guestCanInvite: Bool {
        return pb.guestCanInvite
    }

    var guestCanSeeOtherGuests: Bool {
        return pb.guestCanSeeOtherGuests
    }

    var isSharable: Bool {
        return pb.calendarEventDisplayInfo.shareBtnDisplayType == .shareable
    }

    var creator: CalendarEventAttendeeEntity {
        return PBAttendee(pb: pb.creator)
    }

    var attachments: [CalendarEventAttachmentEntity] {
        get { return pb.attachments.map { CalendarEventAttachmentEntity(pb: $0) } }
        set { pb.attachments = newValue.map { $0.pb } }
    }

    func getTitle() -> String {
        return self.summary.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : self.summary
    }

    static func generateCalendarEventEntitySummary(_ originalSummary: String) -> String {
        return originalSummary.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : originalSummary
    }

    var schemaCollection: Rust.SchemaCollection? {
        guard pb.hasSchema else {
            return nil
        }
        return pb.schema
    }

    var eventMeetingChatExtra: EventMeetingChatExtra {
        return pb.eventMeetingChatExtra
    }
}

extension CalendarEventEntity {

    func visibleAttendees() -> [CalendarEventAttendeeEntity] {
        return self.attendees
            .filter({ !$0.isResource && !($0.status == .removed) })
    }

    func isOrganizer(primaryCalendarId: String) -> Bool {
        return self.organizerCalendarId == primaryCalendarId
    }

    func isRecurrence() -> Bool {
        return !self.rrule.isEmpty
    }

    /// 是否是本地日程
    func isLocalEvent() -> Bool {
        return self.getDataSource() == .system
    }

    func isLarkEvent() -> Bool {
        return self.getDataSource() == .sdk && !isGoogleEvent() && !isExchangeEvent()
    }

    func meetingRoomString() -> String {
        return meetingRoomArray().joined(separator: ", ")
    }

    func meetingRoomArray() -> [String] {
        return attendees
            .filter({ $0.isResource && $0.status == .accept && !$0.isDisabled })
            .map({ (entity) -> String in
                return entity.localizedDisplayName
            })
    }

    func isException() -> Bool {
        return self.originalTime != 0
    }

    func isGoogleEvent() -> Bool {
        return source == .google
    }

    func isExchangeEvent() -> Bool {
        return source == .exchange
    }

    func isEmailEvent() -> Bool {
        return source == .email
    }

    /// 重复性相关的
    func isRepetitive() -> Bool {
        return self.isRecurrence() || self.isException()
    }

    func realOrganizerCalId(from pb: CalendarEvent) -> String {
        // shared calendars wont have organizer since the "organizer" is not a user
        return pb.hasOrganizer ? pb.organizerCalendarID : pb.creatorCalendarID
    }

    // 通过一个event生成一个instance, 三个参数能传就尽量传入
    func instance(with calendar: CalendarModel?,
                  instanceStartTime: Int64,
                  instanceEndTime: Int64,
                  instanceScore: String) -> CalendarEventInstanceEntity {
        var instance = CalendarEventInstance()
        instance.id = "0"
        instance.eventID = id
        instance.calendarID = calendarId
        instance.organizerID = organizer.id

        instance.startTime = instanceStartTime
        instance.endTime = instanceEndTime
        let startDate = getDateFromInt64(instanceStartTime)
        let endDate = getDateFromInt64(instanceEndTime)
        instance.startDay = getJulianDay(date: startDate)
        instance.startMinute = getJulianMinute(date: startDate)
        instance.endDay = getJulianDay(date: endDate)
        instance.endMinute = getJulianMinute(date: endDate)

        instance.startTimezone = startTimezone
        instance.endTimezone = endTimezone
        instance.key = key
        instance.originalTime = originalTime
        instance.summary = summary
        instance.isAllDay = isAllDay
        instance.status = status
        instance.calColorIndex = calColor
        instance.colorIndex = eventColor
        instance.selfAttendeeStatus = selfAttendeeStatus
        instance.isFree = isFree
        instance.eventServerID = serverID
        instance.location = location
        instance.visibility = visibility
        instance.importanceScore = instanceScore
        instance.meetingRooms = attendees
            .filter { $0.isResource }
            .filter { $0.status != .decline && $0.status != .removed }
            .map { $0.localizedDisplayName }
        instance.displayType = displayType
        instance.source = source
        instance.isEditable = isEditable
        instance.category = category

        if let calendar = calendar {
            instance.calAccessRole = calendar.selfAccessRole
        }

        let instanceEntity = CalendarEventInstanceEntityFromPB(withInstance: instance)
        return instanceEntity
    }

    func isSchemaDisplay(key: Rust.SchemaCollection.SchemaKey) -> Bool? {
        guard
            let schemaCollection = self.schemaCollection,
            let schema = schemaCollection.schemaEntity(forKey: key),
            schema.hasUiLevel  else {
            return nil
        }
        return schema.uiLevel != .hide
    }

    func schemaLink(key: Rust.SchemaCollection.SchemaKey) -> URL? {
        guard
            let schemaCollection = self.schemaCollection,
            let schema = schemaCollection.schemaEntity(forKey: key),
            schema.hasAppLink else {
            return nil
        }
        return URL(string: schema.appLink)
    }

    func schemaCompatibleLevel() -> Rust.IncompatibleLevel? {
        // 将版本号转为Int方便与最低兼容版本比较，若版本号规则修改，此方法应一并修改
        // 例如：3.29.0-alpha(String) -> 329(Int)
        var computeCurrentVersion: Int? {
            let version = LarkFoundation.Utils.appVersion
            var result = ""
            var count = 0
            for c in version {
                if c == "." {
                    count += 1
                    if count == 2 {
                        break
                    }
                    continue
                }
                result.append(c)
            }
            // 如果次版本为一位数，例如3.2，需要补充一个0
            // 例如： 3.2.0-alpha(String) -> 302(Int)
            if result.count == 2 {
                result.insert("0", at: result.index(before: result.endIndex))
            }
            return Int(result)
        }

        guard
            let schemaCollection = self.schemaCollection,
            schemaCollection.hasCompatibility,
            schemaCollection.compatibility.hasMinimumCompatibilityVer,
            let currentVersion = computeCurrentVersion else {
            return nil
        }

        if currentVersion >= schemaCollection.compatibility.minimumCompatibilityVer {
            return nil
        } else {
            return schemaCollection.compatibility.incompatibleLevel
        }
    }
}
