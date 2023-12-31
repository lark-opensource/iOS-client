//
//  EventEditViewModel.swift
//  Calendar
//
//  Created by 张威 on 2020/2/13.
//

import UIKit
import RxSwift
import RxCocoa
import CalendarFoundation
import UniverseDesignDialog
import LarkLocationPicker
import LKCommonsLogging
import LarkContainer
import Foundation

enum EventEditModelType: String {
    case webinarAttendees
    case attendees
    case meetingRooms
    case attachment
    case meetingNotes
    case notes
    case permission
    case expand
    case calendar
    case event
    case saving
}

// 描述保存按钮的状态
enum EventEditSaveStatus {
    // 不可点击
    case disabled
    // 可点击，点击后进入保存逻辑
    case enabled
    // 可点击，但是不能保存，弹 alert 提醒
    case alert(message: String)
}

final class EventEditViewModel: UserResolverWrapper {

    let logger = Logger.log(EventEditViewModel.self, category: "calendar.EventEditViewModel")

    // ViewData
    var rxSummaryViewData: BehaviorRelay<EventEditSummaryViewDataType> = .init(value: SummaryViewData())
    var rxSpeakerViewData: BehaviorRelay<EventEditWebinarAttendeeViewDataType> = .init(value: WebinarAttendeeViewData(attendeeType: .speaker))
    var rxAudienceViewData: BehaviorRelay<EventEditWebinarAttendeeViewDataType> = .init(value: WebinarAttendeeViewData(attendeeType: .audience))
    var rxAttendeeViewData: BehaviorRelay<EventEditAttendeeViewDataType> = .init(value: AttendeeViewData())
    var rxGuestPermissionViewData: BehaviorRelay<EventEditGuestPermissionViewDataType> = .init(value: GuestPermissionViewData())
    var rxArrangeDateViewData: BehaviorRelay<EventEditArrangeDateViewDataType> = .init(value: ArrangeDateViewData())
    var rxPickDateViewData: BehaviorRelay<EventEditPickDateViewData> = .init(value: PickDateViewData())
    var rxTimeZoneViewData: BehaviorRelay<EventEditTimeZoneViewData> = .init(value: TimeZoneViewData())
    var rxVideoMeetingViewData: BehaviorRelay<EventEditVideoMeetingViewDataType> = .init(value: VideoMeetingData())
    var rxCalendarViewData: BehaviorRelay<EventEditCalendarViewDataType> = .init(value: CalendarViewData())
    var rxColorViewData: BehaviorRelay<EventEditColorViewDataType> = .init(value: ColorViewData())
    var rxVisibilityViewData: BehaviorRelay<EventEditVisibilityViewDataType> = .init(value: VisibilityViewData())
    var rxFreeBusyViewData: BehaviorRelay<EventEditFreeBusyViewDataType> = .init(value: FreeBusyViewData())
    var rxMeetingRoomViewData: BehaviorRelay<EventEditMeetingRoomViewDataType> = .init(value: MeetingRoomViewData())
    var rxLocationViewData: BehaviorRelay<EventEditLocationViewDataType> = .init(value: LocationViewData())
    var rxCheckInViewData: BehaviorRelay<EventEditCheckInViewDataType> = .init(value: CheckInViewData())
    var rxReminderViewData: BehaviorRelay<EventEditReminderViewDataType> = .init(value: ReminderViewData())
    var rxRruleViewData: BehaviorRelay<EventEditRruleViewDataType> = .init(value: RruleViewData())
    var rxAttachmentViewData: BehaviorRelay<EventEditAttachmentViewDataType> = .init(value: AttachmentViewData())
    var rxMeetingNotesViewData: BehaviorRelay<EventEditMeetingNotesViewDataType> = .init(value: MeetingNotesViewData())
    var rxNotesViewData: BehaviorRelay<EventEditNotesViewDataType> = .init(value: EventNotesViewData())
    var rxDeleteViewData: BehaviorRelay<EventEditDeleteViewDataType> = .init(value: EventEditDeleteViewData())
    var rxWebinarFooterLabelData: BehaviorRelay<String?> = .init(value: nil)

    // 获取 docs data 数据
    var docsDataGetter: (() -> Observable<(data: String, plainText: String)>)? {
        get { notesModel?.docsDataGetter }
        set { notesModel?.docsDataGetter = newValue }
    }
    // 获取 html data 数据
    var htmlDataGetter: (() -> Observable<String>)? {
        get { notesModel?.htmlDataGetter }
        set { notesModel?.htmlDataGetter = newValue }
    }

    // webinar 日程 vc 设置二级信息获取
    var webinarDataGetter: (() -> CalendarWebinarConfigResult?)?
    
    // 会议室当前个人用量
    var rxOverUsageLimit: BehaviorRelay<Bool> = .init(value: false)

    var rxHasGetCalendar: BehaviorRelay<Bool> = .init(value: false)

    // viewModel 是否有过改变，用于 modelPresent 设置
    var rxEventHasChanged = BehaviorRelay(value: false)
    // viewModel 的时间和 rrule 是否有过改变，用于会议室相关的逻辑
    var rxEventDateOrRruleChanged = BehaviorRelay(value: false)

    // 用户开始编辑前的 eventModel，退出取消编辑时，用于判断是否应该弹窗提醒
    var eventModelBeforeEditing: EventEditModel?

    // 是否创建过Zoom 本地存一份config，为处理 videoMeeting oneof的customConfig，在更换会议config后仍需检查是否创建过zoom，用于删除无用zoom会议
    var localZoomConfigs: Rust.ZoomVideoMeetingConfigs?

    // 当前编辑页显示的时区类型
    var rxTimezoneDisplayType: BehaviorRelay<TimezoneDisplayType> = .init(value: .deviceTimezone)

    // dependencies
    var input: EventEditInput
    let actionSource: EventEditActionSource
    let setting: Setting
    let rxIs12HourStyle: BehaviorRelay<Bool>
    let attendeeTotalLimit: Int
    let departmentMemberUpperLimit: Int
    let attendeeTimeZoneEnableLimit: Int
    let legoInfo: EventEditLegoInfo
    let interceptor: EventEditInterceptor
    let title: String?
    let span: Rust.Span
    var udDialogWidth: CGFloat = 0
    // 重复性日程FG默认false，经商讨 端上约定 进编辑页时从后端拉取FG，拉不到取默认值
    /// 以下两个fg已全量。TODO： 待移除
    var recurrenceEventGrayFG: Bool = false
    var recurrenceEventGrayFG_V2: Bool = false
    var isGroupManager: Bool = false // 是否是管理员
    var notiCheckBoxTuple: (checkedVals: [Bool], type: EventEdit.NotiOptionCheckBoxType)?
    var extraData: EventEditExtraData? = .init()

    let disposeBag = DisposeBag()

    let userResolver: UserResolver

    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var calendarMyAIService: CalendarMyAIService?

    var availableCalendars: [EventEditCalendar] = []

    // 标记是否已经因为修改时间「提醒审批类会议室撤回」弹窗
    var hasPubishApprovalAlertForChangingDate: Bool = false

    private(set) var models: [EventEditModelType: ModelManager] = [:]
    var needRenewalReminder: Bool = false
    // 用于记录编辑行为，用于埋点
    var actionState = EventEditActionState()

    init(
        userResolver: UserResolver,
        input: EventEditInput,
        actionSource: EventEditActionSource,
        setting: Setting,
        attendeeTotalLimit: Int,
        departmentMemberUpperLimit: Int,
        attendeeTimeZoneEnableLimit: Int,
        rxIs12HourStyle: BehaviorRelay<Bool>?,
        legoInfo: EventEditLegoInfo,
        interceptor: EventEditInterceptor,
        title: String?,
        span: Rust.Span = .noneSpan
    ) {
        self.userResolver = userResolver
        self.input = input
        self.actionSource = actionSource
        self.setting = setting
        self.rxIs12HourStyle = rxIs12HourStyle ?? .init(value: true)
        self.attendeeTotalLimit = attendeeTotalLimit
        self.attendeeTimeZoneEnableLimit = attendeeTimeZoneEnableLimit
        self.departmentMemberUpperLimit = departmentMemberUpperLimit
        self.interceptor = interceptor
        self.legoInfo = legoInfo
        self.title = title
        self.span = span

        self.makeModels()
        self.bindViewData()
        preLoadUDDialogWidth()
    }

}

// MARK: Make Models
extension EventEditViewModel {

    var models_manager: [ModelManager] {
        return Array(self.models.values)
    }

    private func registerModels() {
        // 可插拔的模块
        if legoInfo.shouldShow(.webinarAttendee) {
            models[.webinarAttendees] = makeWebinarAttendeeModel()
        }
        if legoInfo.shouldShow(.attendee) {
            models[.attendees] = makeAttendeeModel()
        }
        if legoInfo.shouldShow(.meetingRoom) {
            models[.meetingRooms] = makeMeetingRoomModel()
        }
        if legoInfo.shouldShow(.description) {
            models[.notes] = makeNotesModel()
        }
        if legoInfo.shouldShow(.attachment) {
            models[.attachment] = makeAttachmentModel()
        }
        if legoInfo.shouldShow(.meetingNotes) {
            models[.meetingNotes] = makeMeetingNotesModel()
        }
        // 必须的模块
        models[.event] = makeEventModel()
        models[.calendar] = makeCalendarModel()
        models[.saving] = makeSavingModel()
        models[.permission] = makePermissionModel()
    }

    private func makeModels() {
        self.registerModels()
        DispatchQueue.global().async {
            self.models_manager.forEach({
                $0.loopDetect(modelsMap: self.models_manager)
                $0.setup(modelsKeyMap: self.models_manager)
            })
        }
        
        Observable.combineLatest(models_manager.map { $0.initCompleted })
            .subscribe(onCompleted: { [weak self] in
                guard let self = self else { return }
                self.models_manager.forEach({ $0.initLater?() })
                self.adjustEditModelIfNeeded()
                if let event = self.eventModel?.rxModel?.value {
                    self.eventModelBeforeEditing = event
                }
                self.loadRecurrenceEventGrayFGStatus()
            }).disposed(by: self.disposeBag)
    }
}

// MARK: Adjust Edit Model

extension EventEditViewModel {

    // 全天日程的 endDate，如果是 2020.05.21 00:00:00，则调整为前一天的最后一秒
    //   譬如：2020.05.21 00:00:00
    //   调为：2020.05.20 23:59:59
    // 前提条件：可编辑、全天日程
    func adjustEndDateForAllDay() {
        guard permissionModel?.rxPermissions.value.date.isEditable ?? false,
              var editModel = eventModel?.rxModel?.value,
              editModel.isAllDay else {
            return
        }

        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = editModel.timeZone
        let startOfDay = calendar.startOfDay(for: editModel.endDate)
        if Int64(startOfDay.timeIntervalSince1970) == Int64(editModel.endDate.timeIntervalSince1970) {
            editModel.endDate = editModel.endDate.addingTimeInterval(-1)
        }

        editModel.startDate = editModel.startDate.utcToLocalDate()
        editModel.endDate = editModel.endDate.utcToLocalDate()
        editModel.timeZone = .current
        eventModel?.rxModel?.accept(editModel)
    }

    func adjustEditModelIfNeeded() {
        self.adjustEndDateForAllDay()
    }

}

extension EventEditViewModel {
    // 用于加载 新版重复性会议群会议纪要FG
    private func loadRecurrenceEventGrayFGStatus() {
        guard let eventID = self.eventModel?.rxModel?.value.eventID, let event = self.eventModel?.rxModel?.value.getPBModel() else {
            EventEdit.logger.info("get eventID failed: nil")
            return
        }

        self.calendarApi?.authEventsByEventIDs(eventIds: [eventID])
            .flatMap { [weak self] authresponse -> Observable<GetMeetingEventResponse> in
                guard let self = self else { return .just(GetMeetingEventResponse())}
                // 重复性日程FG
                self.recurrenceEventGrayFG = authresponse.grayedEventMap[eventID] ?? false
                self.recurrenceEventGrayFG_V2 = authresponse.grayedEventMapV2[eventID] ?? false
                EventEdit.logger.info("authEventsByEventIDs success with :recurrenceEventGrayFG = \(self.recurrenceEventGrayFG)  , recurrenceEventGrayFG_V2 = \(self.recurrenceEventGrayFG_V2)")
                // 获取 操作者角色（管理员身份）
                return self.calendarApi?.asnycMeetingEventRequest(calendarId: event.calendarID,
                                                                  key: event.key,
                                                                  originalTime: event.originalTime) ?? .empty()
            }.subscribe(onNext: { [weak self] res in
                guard let self = self else { return }

                self.isGroupManager = res.meeting.calendarOwnerIsChatManager

                EventEdit.logger.info("asnycMeetingEventRequest success with :isGroupManager = \(self.isGroupManager)")
            }).disposed(by: disposeBag)
    }
}

extension EventEditViewModel {
    private func preLoadUDDialogWidth() {
        DispatchQueue.main.async {
            self.udDialogWidth = UDDialog.Layout.dialogWidth
        }
    }
}

extension EventEditViewModel {
    var eventTimezone: TimeZone {
        eventModel?.rxModel?.value.timeZone ?? .current
    }

    // 判断日程时区和设备时区是否不同
    var areTimezonesDifferent: Bool {
        let timezones: [TimeZone] = [.current, eventTimezone]
        let isDiff = TimeZoneUtil.areTimezonesDifferent(timezones: timezones)
        EventEdit.logger.info("areTimezonesDifferent: \(isDiff)")
        return isDiff
    }
}

#if !LARK_NO_DEBUG
// MARK: 编辑页便捷调试数据
extension EventEditViewModel: ConvenientDebugInfo {
    var eventDebugInfo: Rust.Event? {
        eventModel?.rxModel?.value.getPBModel()
    }

    var calendarDebugInfo: Rust.Calendar? {
        calendarManager?.allCalendars.first(where: { $0.serverId == eventDebugInfo?.calendarID ?? "" })?.getCalendarPB()
    }

    var meetingRoomInstanceDebugInfo: RoomViewInstance? { nil }

    var meetingRoomDebugInfo: Rust.MeetingRoom? { nil }

    var otherDebugInfo: [String: String]? { nil }
}
#endif

// 用于记录编辑行为的实体，用于埋点
struct EventEditActionState {
    // 是否更改过标题
    var isChangedTitle = false
}

// 用于决定显示哪个时区
enum TimezoneDisplayType {
    case deviceTimezone
    case eventTimezone
}
