//
//  EventEditPermissionManager.swift
//  Calendar
//
//  Created by 张威 on 2020/3/10.
//

import RxCocoa
import RxSwift
import EventKit
import RustPB
import LarkFoundation
import LarkContainer

/// 日程编辑 - 权限管理

final class EventEditPermissionManager: EventEditModelManager<EventEditPermissions> {

    @ScopedInjectedLazy var pushService: RustPushService?
    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?

    let rxPermissions: BehaviorRelay<EventEditPermissions>

    private let disposeBag = DisposeBag()


    init(userResolver: UserResolver,
         identifier: String,
         input: EventEditInput,
         eventModel: EventEditModel,
         primaryCalendar: CalendarModel,
         isVideoMeetingLiving: Bool = false) {
        let permissionModel = EventEditPermissions(input: input,
                                                   event: eventModel,
                                                   primaryCalendar: primaryCalendar,
                                                   isVideoMeetingLiving: isVideoMeetingLiving)
        rxPermissions = BehaviorRelay(value: permissionModel)
        super.init(userResolver: userResolver, identifier: identifier, rxModel: rxPermissions)
        observeEventMeetingChangePushIfIsEdit()
    }

    func updateEventModel(_ eventModel: EventEditModel) {
        let permissions = rxPermissions.value.updatedBy(event: eventModel, isVideoMeetingLiving: rxPermissions.value.isVideoMeetingLiving)
        if permissions != rxPermissions.value {
            rxPermissions.accept(permissions)
        }
    }

    // 因权限问题而无法保存日程的 alert message
    func alertMessageForSavingForbidden() -> String? {
        guard !rxPermissions.value.saving.isEditable else { return nil }
        return BundleI18n.Calendar.Calendar_Edit_CantEditNeedUpdateToast()
    }

    private func observeEventMeetingChangePushIfIsEdit() {
        var meetingUniqueID = ""
        switch rxPermissions.value.input {
        case .editFrom(let event, let instance), .editWebinar(let event, let instance):
            meetingUniqueID = event.videoMeeting.uniqueID
            break
        default:
            return
        }
        // 如果进入编辑页之前会议已经开始时，不会发送 push，先主动拉取一次会议状态
        updateVideoMeetingStatus()
        pushService?.rxVideoStatus
            .filter { $0.uniqueId == meetingUniqueID || meetingUniqueID.isEmpty }
            .map { $0.status }
            .bind { [weak self] _ in
                EventEdit.logger.info("onpush video status changed")
                self?.updateVideoMeetingStatus()
            }.disposed(by: disposeBag)
    }

    // 刷新视频会议状态
    private func updateVideoMeetingStatus() {
        let event: Rust.Event, instance: Rust.Instance
        switch rxPermissions.value.input {
        case .editWebinar(let pbEvent, let pbInstance), .editFrom(let pbEvent, let pbInstance):
            event = pbEvent
            instance = pbInstance
        default:
            return
        }
        
        let videoMeeting = VideoMeeting(pb: event.videoMeeting)
        guard videoMeeting.type == .vchat else {
            return
        }
        let uniqueId = videoMeeting.uniqueId
        var source: VideoMeetingEventType = .normal
        if event.source == .people {
            source = .interview
        }
        let instanceDetails = CalendarInstanceDetails(uniqueID: uniqueId, key: event.key, originalTime: instance.originalTime, instanceStartTime: instance.startTime, instanceEndTime: instance.endTime)
        calendarApi?.getVideoMeetingStatusRequest(instanceDetails: instanceDetails, source: source)
            .subscribe(onNext: { [weak self] vcStatus in
                guard let self = self else { return }
                let isVideoMeetingLiving = vcStatus.status == .live
                EventEdit.logger.info("refresh meeting status, is meeting living: \(vcStatus.status == .live)")
                let permissions = self.rxPermissions.value.updatedBy(event: self.rxPermissions.value.event, isVideoMeetingLiving: isVideoMeetingLiving)
                if permissions != self.rxPermissions.value {
                    self.rxPermissions.accept(permissions)
                }
            })
            .disposed(by: disposeBag)
    }
}

struct EventEditPermissions {

    private(set) var deletion = PermissionOption.writable           // 删除
    private(set) var saving = PermissionOption.writable             // 保存/编辑

    private(set) var summary = PermissionOption.writable            // 标题
    private(set) var attendees = PermissionOption.writable          // 参与人（集合）
    private(set) var guestPermission = PermissionOption.writable    // 参与人权限设置
    private(set) var date = PermissionOption.writable               // 选择时间
    private(set) var videoMeeting = PermissionOption.writable       // 视频会议
    private(set) var calendar = PermissionOption.writable           // 日历
    private(set) var color = PermissionOption.writable              // 颜色
    private(set) var visibility = PermissionOption.writable         // 可见性
    private(set) var freeBusy = PermissionOption.writable           // 忙/闲
    private(set) var meetingRooms = PermissionOption.writable       // 会议室（集合）
    private(set) var meetingRoomsForm = PermissionOption.writable   // 表单会议室（集合）
    private(set) var location = PermissionOption.writable           // 地址
    private(set) var checkIn = PermissionOption.writable            // 签到配置
    private(set) var reminders = PermissionOption.writable          // 提醒（集合）
    private(set) var rrule = PermissionOption.writable              // 重复性规则
    private(set) var attachments = PermissionOption.writable        // 附件（集合）
    private(set) var notes = PermissionOption.writable              // 描述
    private(set) var meetingNotes = PermissionOption.writable       // 有效会议文档
    private(set) var notesEventPermission = PermissionOption.none   // 日程协作人有效会议文档权限的编辑权

    fileprivate let input: EventEditInput
    private(set) var event: EventEditModel

    private let primaryCalendar: CalendarModel

    private var primaryCalendarID: String {
        primaryCalendar.serverId
    }

    private typealias OriginModels = (pbEvent: CalendarEvent, pbInstance: CalendarEventInstance)
    private let originModels: OriginModels?
    private(set) var isVideoMeetingLiving: Bool
    init(input: EventEditInput,
         event: EventEditModel,
         primaryCalendar: CalendarModel,
         isVideoMeetingLiving: Bool = false) {
        self.input = input
        self.event = event
        self.primaryCalendar = primaryCalendar
        self.isVideoMeetingLiving = isVideoMeetingLiving
        switch input {
        case .editFromLocal(let ekEvent):
            originModels = nil
            setupForEditingLocalEvent(ekEvent)
        case .editFrom(let pbEvent, let pbInstance):
            originModels = (pbEvent, pbInstance)
            setupForEditing()
            mergeWithSchema(in: pbEvent)
        case .createWithContext, .copyWithEvent:
            originModels = nil
            setupForCreating()
            if let calendar = event.calendar {
                mergeWithSchema(in: calendar.getPBModel())
            }
        case .createWebinar, .editWebinar:
            originModels = nil
            setupForCreatingWebinar()
            if let calendar = event.calendar {
                mergeWithSchema(in: calendar.getPBModel())
            }
        }
        setNotesEventPermission()
    }

    private mutating func setupForCreatingWebinar() {
        deletion = .none
        if case .createWebinar = input {
            attachments = .none
        } else {
            attachments = .readable
        }
        guard let calendarSource = event.calendar?.source, calendarSource == .lark else { return }

        let calendarType = event.calendar?.getPBModel().type
        if calendarType != .primary && calendarType != .other {
            videoMeeting = .none
        } else {
            videoMeeting = .writable
        }
        if !AppConfig.eventDesc {
            notes = .none
        }

        reminders = .none
        checkIn = .none
        rrule = .none
        guestPermission = .none
        meetingNotes = .none

        meetingRoomAndRruleConflict()
    }

    private mutating func setupForCreating() {
        deletion = .none
        attachments = .writable
        guard let calendarSource = event.calendar?.source else { return }
        switch calendarSource {
        case .exchange, .google:
            guestPermission = .none
            color = .readable
            attachments = .readable
            meetingRooms = .none
            checkIn = .none
            meetingNotes = .none
            if case .exchange = calendarSource {
                visibility = .readable
            }
        default:
            break
        }

        let calendarType = event.calendar?.getPBModel().type
        if calendarType != .primary && calendarType != .other {
            videoMeeting = .none
        } else {
            videoMeeting = .writable
        }
        if !AppConfig.eventDesc {
            notes = .none
        }

        meetingRoomAndRruleConflict()

    }

    private func isEditableForEKEvent(_ ekEvent: EKEvent) -> Bool {
        if let result = ekEvent.value(forKey: "isEditable") as? Bool {
            return result
        }
        guard let calendar = ekEvent.calendar, calendar.allowsContentModifications else {
            return false
        }
        return ekEvent.organizer == nil || (ekEvent.organizer?.isCurrentUser ?? false )
    }

    private mutating func setupForEditingLocalEvent(_ ekEvent: EKEvent) {
        calendar = .none
        color = .none
        visibility = .none
        freeBusy = .none
        meetingRooms = .none
        videoMeeting = .none
        attendees = .readable
        attachments = .none
        guestPermission = .none
        meetingNotes = .none
        if !isEditableForEKEvent(ekEvent) {
            summary = .readable
            date = .readable
            location = .readable
            rrule = .readable
            notes = .readable
            deletion = .none
        }
        if !AppConfig.eventDesc {
            notes = .none
        }
    }

    private mutating func meetingRoomAndRruleConflict() {
        // 会议室 与 rrule 冲突处理
        let duration = Int64(event.endDate.timeIntervalSince(event.startDate))
        /// 重复性的 全量审批，不支持修改时间和rrule
        if event.meetingRooms.hasFullApprovalMeetingRoom() && event.rrule != nil {
            rrule = .readable
            date = .readable
        }
        /// 重复性的 被触发的条件审批，不支持修改rrule
        if event.meetingRooms.hasConditionApprovalMeetingRoom(duration: duration) && event.rrule != nil {
            rrule = .readable
        }
    }

    private mutating func setupForEditing() {
        guard let originModels = originModels else { return }
        let isOrginalEditable = originModels.pbInstance.isEditable

        videoMeeting = .readable

        if event.getPBModel().isDeletable == .self_
            && FG.eventRemoveOffline
            && event.calendar?.source ?? .lark == .lark {
            deletion = .none
        } else {
            deletion = .writable
        }

        meetingRoomAndRruleConflict()

        if !isOrginalEditable {
            summary = .readable
            date = .readable
            location = .readable
            rrule = .readable
            attachments = .readable
            notes = .readable
            checkIn = .readable
            guestPermission = .none
            calendar = .readable
        }

        let attendeesPermissionByOriginData = { () -> PermissionOption in
            if isOrginalEditable {
                return .writable
            }
            if originModels.pbEvent.guestCanInvite {
                return .writable
            } else if originModels.pbEvent.guestCanSeeOtherGuests {
                return .readable
            } else {
                return .none
            }
        }

        guard let calendarSource = event.calendar?.source else { return }
        switch calendarSource {
        case .local:
            attendees = .readable
            calendar = .none
            color = .none
            visibility = .none
            freeBusy = .none
            meetingRooms = .none
            attachments = .none
            videoMeeting = .none
            checkIn = .none
            guestPermission = .none
            meetingNotes = .none
        case .google:
            guestPermission = .none
            attendees = attendeesPermissionByOriginData()
            meetingRooms = .none
            videoMeeting = .readable
            attachments = .readable
            color = .readable
            checkIn = .none
            meetingNotes = .none
            if !event.isEditable {
                visibility = .readable
                freeBusy = .readable
            }
        case .exchange:
            guestPermission = .none
            meetingRooms = .none
            location = .readable
            notes = .readable
            color = .readable
            visibility = .readable
            videoMeeting = .none
            attachments = .readable
            attendees = attendeesPermissionByOriginData()
            checkIn = .none
            meetingNotes = .none
        case .lark:
            attendees = attendeesPermissionByOriginData()
            // 全天日程，如果没有 date 编辑权限，则不允许添加会议室
            meetingRooms = (event.isAllDay && !isOrginalEditable) ? .readable : .writable

            let calendarType = event.calendar?.getPBModel().type
            if calendarType != .primary && calendarType != .other {
                videoMeeting = .none
            } else if isOrginalEditable
                        && event.videoMeeting.videoMeetingType != .larkLiveHost
                        && event.videoMeeting.videoMeetingType != .unknownVideoMeetingType
                        && !isVideoMeetingLiving {
                videoMeeting = .writable
            } else {
                videoMeeting = .readable
            }

            if originModels.pbEvent.selfAttendeeStatus == .needsAction {
                color = .readable
            }

            if !isOrginalEditable && event.calendar?.id != primaryCalendarID {
                meetingNotes = .none
            }

            if event.getPBModel().source == .email {
                meetingRooms = .none
                meetingNotes = .none
                if !event.videoMeeting.hasVideoMeetingType || event.videoMeeting.videoMeetingType == .noVideoMeeting {
                    videoMeeting = .none
                }

                if !event.checkInConfig.checkInEnable {
                    checkIn = .none
                }
            }
        }
        if !AppConfig.eventDesc {
            notes = .none
        }

        setupForSpan(span: event.span)

        // 例外日程，不展示 rrule
        if originModels.pbEvent.originalTime != 0 {
            rrule = .none
        }

        /// 在非组织者日历查看日程，不展示该入口
        if originModels.pbEvent.calendarID != originModels.pbEvent.organizerCalendarID {
            guestPermission = .none
        }

    }

    /// https://bytedance.feishu.cn/docx/doxcnVASpKxeOzSLZm4xx1aWMUh  FG下掉后需要重写这块逻辑
    private mutating func setupForSpan(span: Rust.Span) {
        guard let originModels = originModels else { return }
        let isOriginalEditable = originModels.pbInstance.isEditable // 完全编辑权限
        let isExceptionEvent = originModels.pbInstance.originalTime != 0 // 例外日程
        let isRecurrentEvent = !originModels.pbEvent.rrule.isEmpty && originModels.pbEvent.originalTime == 0 // 重复性日程
        switch span {
        case .thisEvent:
            if isOriginalEditable && isRecurrentEvent {
                calendar = .readable
                rrule = .readable
                meetingRoomsForm = .readable
            } else if !isOriginalEditable && isRecurrentEvent {
                color = .readable
                freeBusy = .readable
                visibility = .readable
                reminders = .readable
                meetingRoomsForm = .readable
            } else if isOriginalEditable && isExceptionEvent {
                calendar = .readable
            }
        case .futureEvents:
            if originModels.pbEvent.isDeletable != .all {
                deletion = .none
            }
            if isOriginalEditable {
                calendar = .readable
            }
            if isRecurrentEvent {
                // 重复性日程此场景会议室表单置灰显示
                meetingRoomsForm = .readable
            }
        @unknown default:
            return
        }
    }

    private mutating func mergeWithSchema(_ schema: Rust.SchemaCollection) {
        let schemaPermissionOf = { (key: Rust.SchemaCollection.SchemaKey) -> PermissionOption in
            guard let entity = schema.schemaEntity(forKey: key), entity.hasUiLevel else {
                return .writable
            }
            switch entity.uiLevel {
            case .readonly: return .readable
            case .editable: return .writable
            case .hide: return .none
            @unknown default: return .none
            }
        }
        self.deletion = min(self.deletion, schemaPermissionOf(.delete))
        self.summary = min(self.summary, schemaPermissionOf(.summary))
        self.attendees = min(self.attendees, schemaPermissionOf(.attendee))
        self.guestPermission = min(self.guestPermission, schemaPermissionOf(.guestPermission))
        self.date = min(self.date, schemaPermissionOf(.date))
        self.calendar = min(self.calendar, schemaPermissionOf(.calendar))
        self.color = min(self.color, schemaPermissionOf(.color))
        self.visibility = min(self.visibility, schemaPermissionOf(.visibility))
        self.freeBusy = min(self.freeBusy, schemaPermissionOf(.freeBusy))
        self.meetingRooms = min(self.meetingRooms, schemaPermissionOf(.meetingRoom))
        self.location = min(self.location, schemaPermissionOf(.location))
        self.reminders = min(self.reminders, schemaPermissionOf(.reminder))
        self.rrule = min(self.rrule, schemaPermissionOf(.rrule))
        self.notes = min(self.notes, schemaPermissionOf(.notes))
        self.meetingNotes = min(self.meetingNotes, schemaPermissionOf(.meetingMinutes))

        // 判断是否存在兼容问题，如果存在，则不允许编辑
        guard schema.hasCompatibility && schema.compatibility.hasMinimumCompatibilityVer else {
            return
        }
        // larkVersion (String) -> Schema Version (Int)
        // eg: "3.29.xxx" -> 329; "3.1.xxx" -> 301
        let versionComponents = LarkFoundation.Utils.appVersion.components(separatedBy: ".")
        guard versionComponents.count >= 2 else {
            return
        }
        let (majorVerStr, minorVerStr) = (versionComponents[0], versionComponents[1])
        let verStr: String
        if minorVerStr.isEmpty {
            verStr = "\(majorVerStr)00"
        } else if minorVerStr.count == 1 {
            verStr = "\(majorVerStr)0\(minorVerStr)"
        } else {
            verStr = "\(majorVerStr)\(minorVerStr)"
        }
        guard let curVerNum = Int(verStr) else {
            assertionFailure()
            return
        }
        if case .disableEdit = schema.compatibility.incompatibleLevel,
           curVerNum < schema.compatibility.minimumCompatibilityVer {
            self.saving = .readable
        }
    }

    // merge 日历自定义权限配置（for editing）
    private mutating func mergeWithSchema(in event: Rust.Event) {
        guard event.hasSchema else { return }
        mergeWithSchema(event.schema)
    }

    // merge 日历自定义配置权限（for creating）
    private mutating func mergeWithSchema(in calendar: RustPB.Calendar_V1_Calendar) {
        guard calendar.hasCalendarEventSchema else { return }
        mergeWithSchema(calendar.calendarEventSchema)
    }

    fileprivate func updatedBy(event: EventEditModel, isVideoMeetingLiving: Bool) -> Self {
        return EventEditPermissions(input: self.input,
                                    event: event,
                                    primaryCalendar: primaryCalendar,
                                    isVideoMeetingLiving: isVideoMeetingLiving)
    }

}

extension EventEditPermissions: Equatable {

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.deletion == rhs.deletion
            && lhs.saving == rhs.saving
            && lhs.summary == rhs.summary
            && lhs.attendees == rhs.attendees
            && lhs.guestPermission == rhs.guestPermission
            && lhs.date == rhs.date
            && lhs.videoMeeting == rhs.videoMeeting
            && lhs.calendar == rhs.calendar
            && lhs.color == rhs.color
            && lhs.visibility == rhs.visibility
            && lhs.freeBusy == rhs.freeBusy
            && lhs.meetingRooms == rhs.meetingRooms
            && lhs.location == rhs.location
            && lhs.reminders == rhs.reminders
            && lhs.rrule == rhs.rrule
            && lhs.attachments == rhs.attachments
            && lhs.notes == rhs.notes
            && lhs.isVideoMeetingLiving == rhs.isVideoMeetingLiving
            && lhs.notesEventPermission == rhs.notesEventPermission
    }

}

extension EventEditPermissions {
    private mutating func setNotesEventPermission() {
        let currentCalendar = event.calendar
        let canEditCalId = {
            if let calendar = currentCalendar,
               calendar.isShared {
                return event.creatorCalendarId
            } else {
                return event.organizerCalendarId
            }
        }()
        /// 权限逻辑：主日历日程仅 组织者（角色） 在 组织者日历上（位置） 有编辑权限，共享日历日程角色为创建者
        if currentCalendar?.id == event.organizerCalendarId,
           primaryCalendar.serverId == canEditCalId
            {
            self.notesEventPermission = .writable
        } else {
            self.notesEventPermission = .none
        }
    }
}
