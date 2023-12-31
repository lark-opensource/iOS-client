//
//  EventEditViewModel+Save.swift
//  Calendar
//
//  Created by 张威 on 2020/11/11.
//

import UIKit
import RxCocoa
import RxSwift
import EventKit
import CalendarFoundation
import LarkTimeFormatUtils
import RustPB
import ServerPB
import UniverseDesignToast
import UniverseDesignDialog
import EENavigator
import LarkUIKit
import Metal

struct EventEditExtraData {
    var extraApplyGroupData: CalendarNotiGroupApplySavedData?
    var deleteOriginalMeetingNotes: Observable<Void>?
}

struct CalendarNotiGroupApplySavedData {
    var key: String
    var calendarID: String
    var originalTime: Int64
    var addChatIDs: [Int64]
    var addChatCalendarIDs: [Int64]
    var addMeetingChatChatter: Bool = false
    var addMeetingMinuteCollaborator: Bool = false
    var needReason: Bool = false

    init(key: String, calendarID: String, originalTime: Int64, addChatIDs: [Int64], addChatCalendarIDs: [Int64], addMeetingChatChatter: Bool, addMeetingMinuteCollaborator: Bool, needReason: Bool) {
        self.key = key
        self.calendarID = calendarID
        self.originalTime = originalTime
        self.addChatIDs = addChatIDs
        self.addChatCalendarIDs = addChatCalendarIDs
        self.addMeetingChatChatter = addMeetingChatChatter
        self.addMeetingMinuteCollaborator = addMeetingMinuteCollaborator
        self.needReason = needReason
    }
}

// MARK: - Terminal

extension EventEditViewModel {
    enum SaveTerminal: Error {
        // 数据没变
        case notChanged

        // 继续编辑
        case backToEdit

        // 重复性规则截止时间不合法
        case rruleEndDateNotValid

        // 切换日历失败
        case switchCalendarFailed

        // 保存失败，sdk 错误
        case failedToSave(sdkError: Error)

        // 有未完全填写的表单
        case incompletedForm([String])

        // 日程参与人未同步，无法保存
        case notSyncAttendee

        // webinar VC setting not valid
        case webinarVCSettingNotValid(String)

        // 无法取得 calendarAPI
        case apiUnavailable
    }
}

extension EventEditViewModel {
    enum SavingMessage {
        case alert(EventEdit.Alert)
        case actionSheet(EventEdit.ActionSheet)
        // 会议室审批弹窗
        case meetingRoomApprovalAlert(EventEdit.MeetingRoomApprovalAlert)
        // 日程通知弹窗
        case notiOptionAlert(EventEdit.NotiOptionAlert)
        // 日程分享到会话弹窗（无邀请）
        case alertWithShareCheck(EventEdit.CheckBoxAlert)
        // present UIViewController
        case present(UIViewController)
        // 同步 rust 变化
        case syncEventChanged(event: Rust.Event, span: Span)
        // 展示 loading
        case showLoadingToast(String)
        // dismiss loading
        case dismissLoadingToast
        // show error tip
        case showErrorTip(String)
    }

}

private let void: Void = ()

private typealias CheckChangedFunc = (label: String, func: (Rust.Event, Rust.Event) -> Bool)

extension EventEditViewModel {

    typealias RxSaveStage<State> = RxStage<State, SavingMessage>

    // MARK: Check ReachAttendeeCountControlLimit
    private func checkReachAttendeeCountControlLimit(with context: PBEventSaveContext) -> RxSaveStage<Void> {
        let limitReason: AttendeesLimitReason?
        let eventFields: (calendarId: String, key: String, originalTime: Int64)
        switch input {
        case .editWebinar(let pbEvent, _):
            eventFields = (pbEvent.calendarID, pbEvent.key, pbEvent.originalTime)
            let count = (pbEvent.webinarInfo.speakers.attendees + pbEvent.webinarInfo.audiences.attendees).deduplicated().count
            limitReason = self.webinarAttendeeModel?.attendeesUpperLimitReason(with: count)
        case .editFrom(let pbEvent, _):
            eventFields = (pbEvent.calendarID, pbEvent.key, pbEvent.originalTime)
            limitReason = self.attendeeModel?.attendeesUpperLimitReason(with: self.attendeeModel?.rxAttendeeData.value.breakUpAttendeeCount ?? 0)
        default:
            // 创建场景在添加参与人的时候会进行处理
            if input.isFromAI {
                return handleAttendeeLimitedReasonFromAI(context: context)
            } else {
                return .complete()
            }
        }

        guard let reason = limitReason else {
            return .complete()
        }
        let title: String
        let content: String
        let makeActions: ((StageForwarder<Void, SavingMessage>) -> [EventEdit.ActionItem])
        switch reason {
        case .reachControlLimit(let limit):
            title = I18n.Calendar_G_GuestLimitReached(number: limit)
            content = I18n.Calendar_G_MoreGuestGoRequest
            makeActions = { forwarder in
                [
                    .init(title: I18n.Calendar_G_ContinueSave_Button) {
                        forwarder.complete()
                    },
                    .init(title: I18n.Calendar_G_RequestPermission_Button, titleColor: UIColor.ud.primaryContentDefault) {
                        let approveVM = EventAttendeeLimitApproveViewModel(userResolver: self.userResolver,
                                                                           calendarId: eventFields.calendarId,
                                                                           key: eventFields.key,
                                                                           originalTime: eventFields.originalTime)
                        approveVM.approveCommitSucceedHandler = {
                            forwarder.complete()
                        }
                        approveVM.cancelCommitHandler = {
                            forwarder.terminate(SaveTerminal.backToEdit)
                        }
                        let approveVC = EventAttendeeLimitApproveViewController(viewModel: approveVM)
                        let naviController = LkNavigationController(rootViewController: approveVC)
                        forwarder.deliver(.present(naviController))
                    }
                ]
            }
        case .reachRecurEventLimit(let limit):
            // webinar 日程没有重复性，不会走到这里
            // 当前参与者数量
            let currentCount = Int(self.attendeeModel?.rxAttendeeData.value.breakUpAttendeeCount ?? 0)
            // 原始参与者数量
            let originalCount = Int(context.orginalPBModels?.event.attendeeInfo.totalNo ?? 0)
            // 原日程是例外日程
            let orginalEventIsException = context.event.originalTime != 0

            // 例外日程、重复性日程编辑所有 且 参与人数没有变化 两个场景，允许保存
            if (orginalEventIsException || context.span == .allEvents) && currentCount == originalCount {
                return .complete()
            }

            title = I18n.Calendar_G_GuestLimitReached(number: limit)
            content = I18n.Calendar_G_GuestRecurNoExceedLimit(number: limit)
            makeActions = { fowarder in
                [
                    .init(title: I18n.Calendar_Common_GotIt) {
                        fowarder.terminate(SaveTerminal.backToEdit)
                    }
                ]
            }
            let isFromCreating = input.isFromCreating
            let event = eventModel?.rxModel?.value.getPBModel()
            CalendarTracerV2.RepeatedEventReachLimit.traceView {
                $0.mergeEventCommonParams(commonParam: .init(event: event))
                $0.is_new_create = isFromCreating.description
                $0.limit_number = limit
            }
        default:
            return .complete()
        }
        return .create { forwarder -> Disposable in
            var alertCxt = EventEdit.Alert()
            alertCxt.title = title
            alertCxt.content = content
            alertCxt.actions = makeActions(forwarder)
            forwarder.deliver(.alert(alertCxt))
            return Disposables.create()
        }

    }
    
    private func handleAttendeeLimitedReasonFromAI(context: PBEventSaveContext) -> RxSaveStage<Void> {
        let limitReason = self.attendeeModel?.attendeesUpperLimitReason(with: self.attendeeModel?.rxAttendeeData.value.breakUpAttendeeCount ?? 0, isForAI: true)
        guard let reason = limitReason else {
            return .complete()
        }
        let title: String
        let content: String
        let makeActions: ((StageForwarder<Void, SavingMessage>) -> [EventEdit.ActionItem]) = { fowarder in
            [
                .init(title: I18n.Calendar_Common_GotIt) {
                    fowarder.terminate(SaveTerminal.backToEdit)
                }
            ]
        }
        switch reason {
        case .notTenantCertificated(let limit):
            title = I18n.Calendar_G_GuestLimitReached(number: limit)
            content = I18n.Calendar_G_ToAddNeedVerify_Note(number: limit)
        case .reachControlLimit(let limit), .reachFinalLimit(let limit):
            title = I18n.Calendar_G_GuestLimitReached(number: limit)
            content = I18n.Calendar_G_MaxRemoveThenTry_Note(number: limit)
        case .reachRecurEventLimit(let limit):
            title = I18n.Calendar_G_GuestLimitReached(number: limit)
            content = I18n.Calendar_G_GuestRecurNoExceedLimit(number: limit)
            CalendarTracerV2.RepeatedEventReachLimit.traceView {
                $0.mergeEventCommonParams(commonParam: .init(event: context.event))
                $0.is_new_create = self.input.isFromCreating.description
                $0.limit_number = limit
            }
        @unknown default: break
        }
        
        return .create { forwarder -> Disposable in
            var alertCxt = EventEdit.Alert()
            alertCxt.title = title
            alertCxt.content = content
            alertCxt.actions = makeActions(forwarder)
            forwarder.deliver(.alert(alertCxt))
            return Disposables.create()
        }
    }

    // MARK: Check Changed

    private func notChanged(between pb0: Rust.Event, and pb1: Rust.Event) -> Bool {
        return pb0.hashValue == pb1.hashValue
    }

    private func checkChanged(with context: PBEventSaveContext) -> RxSaveStage<Void> {
        guard let originalPBModel = context.orginalPBModels else {
            return .complete()
        }
        var originalEvent = originalPBModel.event
        if context.span != .allEvents {
            originalEvent.startTime = originalPBModel.instance.startTime
            originalEvent.endTime = originalPBModel.instance.endTime
        }
        originalEvent.attendees.sort { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
        context.event.attendees.sort { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
        if notChanged(between: originalEvent, and: context.event),
           !(meetingNotesModel?.notesHasEdit ?? false) {
            EventEdit.logger.info("rust event not changed")
            return .terminate(SaveTerminal.notChanged)
        }
        return .complete()
    }

    // 检查是否所有的会议室表单是否有交白卷的情况
    private func checkMeetingRoomForm(context: PBEventSaveContext) -> RxSaveStage<Void> {
        let meetingRooms = context.event.attendees.filter { $0.category == .resource }
        let meetingRoomIDWithForm = meetingRooms.compactMap { meetingRoom -> (String, Rust.CustomizationForm)? in
            if let bizData = meetingRoom.schemaExtraData.bizData.first(where: { $0.type == .resourceCustomization }) {
                return (meetingRoom.attendeeCalendarID, bizData.resourceCustomization.customizationData)
            }
            return nil
        }

        func checkQuestionCompletion(question: Rust.CustomizationQuestion) -> Bool {
            if question.isRequired {
                switch question.customizationType {
                case .singleSelect:
                    fallthrough
                case .multipleSelect:
                    return question.options.contains { $0.isSelected }
                case .input:
                    return !question.inputContent.isEmpty
                @unknown default:
                    return false
                }
            } else {
                return true
            }
        }

        return .create { forwarder -> Disposable in
            // 1. 从表单中拿到所有的选项
            // 2. 通过选项和表单走rust接口获取所有visible的问题
            // 3. 判断其中所有必选的问题是否都有答案

            guard let rustApi = self.calendarApi else {
                forwarder.terminate(SaveTerminal.apiUnavailable)
                return Disposables.create()
            }

            Observable.from(meetingRoomIDWithForm)
                .flatMap { meetingRoomID, form -> Observable<String> in
                    let selectionKeyValues = form.compactMap { question -> (String, [String])? in
                        let selectedOptionKeys = question.options.filter(\.isSelected).map(\.optionKey)
                        if selectedOptionKeys.isEmpty {
                            return nil
                        } else {
                            return (question.indexKey, selectedOptionKeys)
                        }
                    }
                    .map { (key, selectionKeys) -> (String, Calendar_V1_ParseCustomizedConfigurationRequest.SelectedKeys) in
                        var selections = Calendar_V1_ParseCustomizedConfigurationRequest.SelectedKeys()
                        selections.selectedOptionKeys = selectionKeys
                        return (key, selections)
                    }
                    return rustApi
                        .parseForm(inputs: Dictionary(uniqueKeysWithValues: selectionKeyValues), originalForm: form)
                        .compactMap { form -> String? in
                            let completion = form
                                .map(checkQuestionCompletion(question:))
                                .reduce(true) { $0 && $1 }
                            if completion {
                                return nil
                            } else {
                                return meetingRoomID
                            }
                        }
                }
                .toArray()
                .subscribe(onSuccess: {
                    if $0.isEmpty {
                        forwarder.complete(())
                    } else {
                        forwarder.terminate(SaveTerminal.incompletedForm($0))
                    }
                }) { error in
                    forwarder.terminate(SaveTerminal.failedToSave(sdkError: error))
                }

            return Disposables.create()
        }
    }

    // MARK: checkMeetingNotesStatus
    private func checkMeetingNotesStatus(with context: PBEventSaveContext) -> RxSaveStage<Void> {
        guard let meetingNotesModel = meetingNotesModel,
              meetingNotesModel.notesHasEdit else { return .complete() }
        var instanceRelatedData = Rust.InstanceRelatedData()

        var instanceStartTime: Int64 = 0
        if let originalFourTuple = meetingNotesModel.originalFourTuple {
            instanceStartTime = originalFourTuple.instanceStartTime
        } else {
            instanceStartTime = context.event.startTime
        }
        if context.event.isAllDay {
            let toUTCDayStart: ((Int64) -> Int64) = { timeStamp in
                var formatter = DateFormatter()
                formatter.timeZone = TimeZone(identifier: "UTC")
                formatter.dateFormat = "yyyy-MM-dd"

                let dateString = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(timeStamp)))

                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                if let date = formatter.date(from: "\(dateString) 00:00:00") {
                    return Int64(date.timeIntervalSince1970)
                }
                return timeStamp
            }
            /// 时间戳转化为 UTC 的 0点
            instanceStartTime = toUTCDayStart(instanceStartTime)
        }
        instanceRelatedData.instanceStartTime = instanceStartTime


        if let originalNotes = meetingNotesModel.originalNotes {
            instanceRelatedData.instanceDocData.originalDocToken = originalNotes.token
        }
        if let currentNotes = meetingNotesModel.currentNotes {
            instanceRelatedData.instanceDocData.docToken = currentNotes.token
            instanceRelatedData.instanceDocData.docType = .init(rawValue: currentNotes.type) ?? .docx
            instanceRelatedData.instanceDocData.docOwnerID = currentNotes.docOwnerId ?? 0
            instanceRelatedData.instanceDocData.docBotID = currentNotes.docBotId ?? 0
            instanceRelatedData.instanceDocData.notesEventPermission = Rust.NotesEventPermission(rawValue: currentNotes.eventPermission.rawValue) ?? .canEdit
            if let notesType = currentNotes.notesType {
                instanceRelatedData.instanceDocData.notesType = notesType.toRustPB()
            }
        }
        context.instanceRelatedData = instanceRelatedData
        EventEdit.logger.debug("save meeting notes, docOwnerID:\(instanceRelatedData.instanceDocData.docOwnerID),docBotID:\(instanceRelatedData.instanceDocData.docBotID),hasOriginalToken:\(meetingNotesModel.originalNotes != nil)")
        return .complete()
    }

    // MARK: Check Exist Invalid MeetingRoom
    private func checkMeetingRoomsStatus(with context: PBEventSaveContext) -> RxSaveStage<Void> {
        if context.willtMeetingRoomFail {
            return .create { forwarder -> Disposable in
                var alertCxt = EventEdit.Alert()
                alertCxt.title = BundleI18n.Calendar.Calendar_Room_SomeNoReserveConfirm_Pop
                alertCxt.actions = [
                    .init(title: BundleI18n.Calendar.Calendar_Common_Cancel) {
                        DayScene.logger.info("checked by user: not change")
                        CalendarTracerV2.RoomNoReserveConfirm.traceClick {
                            $0.click("cancel").target("cal_event_full_create_view")
                        }
                        forwarder.terminate(SaveTerminal.backToEdit)
                    },
                    .init(title: BundleI18n.Calendar.Calendar_Common_Save, titleColor: UIColor.ud.primaryContentDefault) {
                        DayScene.logger.info("checked by user: change")
                        CalendarTracerV2.RoomNoReserveConfirm.traceClick {
                            $0.click("save").target("cal_calendar_main_view")
                        }
                        forwarder.complete()
                    }
                ]
                forwarder.deliver(.alert(alertCxt))
                CalendarTracerV2.RoomNoReserveConfirm.traceView()
                return Disposables.create()
            }
        } else {
            return .complete()
        }
    }

    // MARK: Check Switch Calendar
    private func checkSwitchCalendar(with context: PBEventSaveContext) -> RxSaveStage<Void> {
        EventEdit.logger.info("check switch calendar. from calId: \(context.orginalPBModels?.event.calendarID ?? ""), to calId: \(context.calendarId)")
        guard let originalEvent = context.orginalPBModels?.event,
              originalEvent.calendarID != context.calendarId else {
            return .complete()
        }

        var needsAlert: Bool
        if !originalEvent.rrule.isEmpty {
            EventEdit.logger.info("change rrule event calendar, needs alert")
            needsAlert = true
        } else if context.event.originalTime != 0 {
            EventEdit.logger.info("change exception event calendar, needs alert")
            needsAlert = true
        } else {
            needsAlert = false
        }
        guard needsAlert else { return .complete() }

        EventEdit.logger.info("start switching calendar...")

        return .create { forwarder -> Disposable in
            var alertCxt = EventEdit.Alert()
            alertCxt.title = BundleI18n.Calendar.Calendar_Edit_ChangeCalendarRecurringEventDialogTitle
            alertCxt.content = BundleI18n.Calendar.Calendar_Edit_ChangeCalendarRecurringEventDialogContent
            let actionTitles = (
                confirm: BundleI18n.Calendar.Calendar_Edit_ChangeCalendarRecurringEventDialogButton,
                cancel: BundleI18n.Calendar.Calendar_Common_Cancel
            )
            alertCxt.actions = [
                .init(title: actionTitles.cancel) {
                    forwarder.terminate(SaveTerminal.backToEdit)
                },
                .init(title: actionTitles.confirm, titleColor: UIColor.ud.primaryContentDefault) {
                    forwarder.complete(void)
                }
            ]
            forwarder.deliver(.alert(alertCxt))
            return Disposables.create()
        }
    }

    // MARK: Set Calendar Visible
    private func checkCalendarVisible(with context: PBEventSaveContext) -> RxSaveStage<Void> {
        var needsSetCalendarVisible: Bool
        if input.isFromCreating {
            needsSetCalendarVisible = true
        } else if let originalEvent = context.orginalPBModels?.event,
                  originalEvent.calendarID != context.calendarId {
            needsSetCalendarVisible = true
        } else {
            needsSetCalendarVisible = false
        }
        if needsSetCalendarVisible {
            // NOTE: Rust 层依赖显式设置目标日历为 visibile 的逻辑，否则可能保存切换失败
            calendarManager?.updateCalendarVisibility(serverId: context.calendarId, visibility: true, isLocal: false)
                .subscribe(onError: {[weak self] error in
                    if error.errorType() == .exceedMaxVisibleCalNum,
                       let window = self?.userResolver.navigator.mainSceneWindow {
                        UDToast.showFailure(with: I18n.Calendar_Detail_TooMuchViewReduce, on: window)
                    }
                })
                .disposed(by: disposeBag)
        }
        return .complete()
    }

    // check 是否例外日程的 rruleEndDate 和 meetingRoom 是否冲突
    // 若冲突了，返回 `.forward(true)`，否则返回 `.forward(false)`
    private func checkConflictBetweenRruleEndDateAndMeetingRoomForException(
        originalEvent: Rust.Event,
        editedEvent: Rust.Event
    ) -> RxSaveStage<Bool> {
        let hasRoom = editedEvent.attendees.contains { $0.category == .resource && $0.status != .removed }
        guard hasRoom, let api = self.calendarApi else { return .complete(false) }

        // 获取例外对应的源日程，取其 rrule.endDate，判断是否与会议室有效时长（最多两年）有冲突
        let source: Observable<RxSaveStage<Bool>.Element> = api.getEvent(
            calendarId: originalEvent.calendarID,
            key: originalEvent.key,
            originalTime: 0
        )
        .map { [weak self] relatedEvent -> Bool in
            guard let self = self else { return false }
            guard !relatedEvent.rrule.isEmpty,
                let rrule = EKRecurrenceRule.recurrenceRuleFromString(relatedEvent.rrule) else {
                EventEdit.logger.error("rrule is empty")
                return false
            }
            // 判断重复性截止时间是否合法
            let isEndDateValid = self.isRruleEndDateValid(
                of: rrule,
                by: Date(timeIntervalSince1970: TimeInterval(relatedEvent.startTime)),
                model: self.eventModel?.rxModel?.value
            )
            return !isEndDateValid
        }
        .do(onError: {
            EventEdit.logger.error("get original event for exception failed: \($0)")
        })
        .catchErrorJustReturn(false)
        .map { RxSaveStage<Bool>.Element.state($0) }

        return .init(source: source)
    }

    // 终止保存：弹窗提示「重复性规则截止时间不合法」
    func terminateBecauseOfInvalidRruleEndDate() -> RxSaveStage<Void> {
        EventEdit.logger.info("publish rruleEndDate notValidAlert")
        return .create { [weak self] forwarder in
            guard let self = self,
                let (name, maxEndDate) = self.meetingRoomMaxEndDateInfo() else {
                forwarder.complete(void)
                return Disposables.create()
            }
            var alertContext = EventEdit.Alert()
            alertContext.title = BundleI18n.Calendar.Calendar_Common_Notice
            // 使用设备时区
            let customOptions = Options(
                timeFormatType: .long,
                datePrecisionType: .day
            )
            let dateStr = TimeFormatUtils.formatDate(from: maxEndDate, with: customOptions)

            if self.selectedMeetingRooms.count > 1 {
                alertContext.content = BundleI18n.Calendar.Calendar_Meeting_ReserveLimtTIpMulti(MeetingRoom: name, DueDate: dateStr)
            } else {
                alertContext.content = BundleI18n.Calendar.Calendar_Meeting_ReserveLimtTIp(DueDate: dateStr)
            }
            alertContext.actions = [
                .init(title: BundleI18n.Calendar.Calendar_Common_Confirm) {
                    EventEdit.logger.info("user confirm rruleEndDate notValidAlert")
                    forwarder.terminate(SaveTerminal.rruleEndDateNotValid)
                }
            ]
            forwarder.deliver(.alert(alertContext))
            return Disposables.create()
        }
    }

    // swiftlint:enable cyclomatic_complexity
    private func getGroupSimpleMembers(event: EventEditModel) -> [String: [Rust.IndividualSimpleAttendee]] {
        var result = [String: [Rust.IndividualSimpleAttendee]]()
        event.attendees.forEach { attendee in
            if case .group(let group) = attendee {
                result[group.chatId] = group.memberSeeds
            }
        }
        return result
    }

    // swiftlint:disable cyclomatic_complexity
    private func mergedEvent(from baseEvent: Rust.Event, with refEvent: Rust.Event) -> Rust.Event {
        guard let permissions = permissionModel?.rxPermissions.value else { return baseEvent }
        var pb = baseEvent
        if permissions.summary.isEditable {
            pb.summary = refEvent.summary
        }
        if permissions.date.isEditable {
            pb.startTime = refEvent.startTime
            pb.endTime = refEvent.endTime
            pb.isAllDay = refEvent.isAllDay
            pb.startTimezone = refEvent.startTimezone
            pb.endTimezone = refEvent.endTimezone
        }

        if permissions.videoMeeting.isEditable {
            pb.videoMeeting = refEvent.videoMeeting
        }
        if permissions.color.isEditable {
            pb.colorIndex = refEvent.colorIndex
        }
        if permissions.visibility.isEditable {
            pb.visibility = refEvent.visibility
        }
        if permissions.freeBusy.isEditable {
            pb.isFree = refEvent.isFree
        }
        if permissions.reminders.isEditable {
            pb.reminders = refEvent.reminders
        }
        if permissions.location.isEditable {
            pb.location = refEvent.location
        }
        if permissions.checkIn.isEditable {
            pb.checkInConfig = refEvent.checkInConfig
        }
        if permissions.rrule.isEditable {
            pb.rrule = refEvent.rrule
        }

        if permissions.meetingRooms.isEditable && !permissions.attendees.isEditable {
            // 只有会议室编辑权限，保存日程时不允许有 userAttendee，否则sdk报错
            let oriUserAttendee = pb.attendees.filter { $0.category != .resource }
            let resourceAttendee = refEvent.attendees.filter { $0.category == .resource }
            pb.attendees = resourceAttendee + oriUserAttendee
        } else if !permissions.meetingRooms.isEditable && permissions.attendees.isEditable {
            // 只有参与人编辑权限。目前暂时没有这种情况，先写着以防万一
            let oriResourceAttendee = pb.attendees.filter { $0.category == .resource }
            let userAttendee = refEvent.attendees.filter { $0.category != .resource }
            pb.attendees = oriResourceAttendee + userAttendee
        } else if permissions.attendees.isEditable && permissions.attendees.isEditable {
            // 有参与人 & 会议室编辑权限
            pb.attendees = refEvent.attendees
            pb.webinarInfo = refEvent.webinarInfo
        }

        if permissions.attachments.isEditable {
            pb.attachments = refEvent.attachments
        }
        if permissions.notes.isEditable {
            pb.docsDescription = refEvent.docsDescription
            pb.description_p = refEvent.description_p
        }
        if permissions.calendar.isEditable {
            pb.calendarID = refEvent.calendarID
        }
        if permissions.guestPermission.isEditable {
            pb.guestCanModify = refEvent.guestCanModify
            pb.guestCanInvite = refEvent.guestCanInvite
            pb.guestCanSeeOtherGuests = refEvent.guestCanSeeOtherGuests
            pb.meetingNotesConfig = refEvent.meetingNotesConfig
        }
        return pb
    }
    // swiftlint:enable cyclomatic_complexity

    private func initEventForRust(with context: PBEventSaveContext) {
        assert(context.hasEvent == false)
        guard let event = eventModel?.rxModel?.value,
              let permissions = permissionModel?.rxPermissions.value else { return }
        if permissions.attendees.isEditable || permissions.meetingRooms.isEditable {
            if input.isWebinarScene {
                context.webinarAttendeeContext.rejectedGroupUsersMap = webinarAttendeeModel?.rejectedGroupUserMap ?? [:]
                context.webinarAttendeeContext.resourceSimpleAttendees = resourceSimpleAttendees
                context.webinarAttendeeContext.speakersContext.individualSimpleAttendees = speakerIndividualSimpleAttendees
                context.webinarAttendeeContext.speakersContext.groupSimpleAttendees = speakerGroupSimpleAttendees
                context.webinarAttendeeContext.audiencesContext.individualSimpleAttendees = audienceIndividualSimpleAttendees
                context.webinarAttendeeContext.audiencesContext.groupSimpleAttendees = audienceGroupSimpleAttendees
            } else {
                context.attendeeContext.groupSimpleMembers = groupSimpleMembers
                context.attendeeContext.individualSimpleAttendees = individualSimpleAttendees
                context.attendeeContext.groupSimpleAttendees = groupSimpleAttendees
                context.attendeeContext.resourceSimpleAttendees = resourceSimpleAttendees
                context.attendeeContext.totalAttendeeLoaded = totalAttendeesLoaded
                context.attendeeContext.rejectedGroupUsersMap = rejectedGroupUsersMap

            }

        }

        guard let orginalPBModels = context.orginalPBModels else {
            context.event = event.getPBModel()
            return
        }

        // originalAttendeeContext 设置
        if input.isWebinarScene {
            context.webinarAttendeeContext.originalResourceSimpleAttendees = orginalPBModels.event.attendees.filter({ $0.category == .resource }).map({ $0.toResourceSimpleAttendee() })

            context.webinarAttendeeContext.speakersContext.originalIndividualSimpleAttendees = originalSpeakerIndividualAttendees
            context.webinarAttendeeContext.speakersContext.originalGroupSimpleAttendees = orginalPBModels.event.webinarInfo
                .speakers.attendees.filter({ $0.category == .group }).map({ $0.toGroupSimpleAttendee() })

            context.webinarAttendeeContext.audiencesContext.originalIndividualSimpleAttendees = originalAudienceIndividualAttendees
            context.webinarAttendeeContext.audiencesContext.originalGroupSimpleAttendees = orginalPBModels.event.webinarInfo
                .audiences.attendees.filter({ $0.category == .group }).map({ $0.toGroupSimpleAttendee() })
        } else {
            context.attendeeContext.originalIndividualSimpleAttendees = originalIndividualAttendees
            context.attendeeContext.originalGroupSimpleAttendees = orginalPBModels.event.attendees.filter({ $0.category == .group }).map({ $0.toGroupSimpleAttendee() })
            context.attendeeContext.originalResourceSimpleAttendees = orginalPBModels.event.attendees.filter({ $0.category == .resource }).map({ $0.toResourceSimpleAttendee() })
        }

        var baseEvent = orginalPBModels.event
        baseEvent.startTime = orginalPBModels.instance.startTime
        baseEvent.endTime = orginalPBModels.instance.endTime
        let refEvent = event.getPBModel()
        context.event = mergedEvent(from: baseEvent, with: refEvent)
    }

    // MARK: Check Approval Reason

    // 添加会议室审批理由
    private func checkMeetingRoomApprovalReason(with context: PBEventSaveContext) -> RxSaveStage<Void> {
        // swiftlint:disable nesting
        typealias Filter = (_ attendee: Rust.Attendee, _ event: Rust.Event) -> Bool
        // swiftlint:enable nesting

        // 筛选全量审批会议室
        let approvalFilter: Filter = { attendee, _ in
            if attendee.category == .resource && attendee.status != .removed {
                return attendee.attendeeSchema.hasApprovalKey
            }
            return false
        }
        // 筛选条件审批会议室
        let conditionalApprovalFilter: Filter = { attendee, event in
            if attendee.category == .resource && attendee.status != .removed {
                let approvalType = attendee.schemaExtraData.cd.approvalType
                let needApproval = approvalType.shouldTriggerApprovalOff(duration: context.event.endTime - context.event.startTime)
                // 条件审批和重复矛盾 如果触发了条件审批且有rrule 会议室无效
                let rrule = event.rrule
                return needApproval && rrule.isEmpty
            }
            return false
        }

        // 编辑前后全量审批会议室
        let originalApprovalMeetingRooms = context.orginalPBModels.map { originalEvent in
            originalEvent.event.attendees.filter { approvalFilter($0, originalEvent.event) }.map(\.attendeeCalendarID)
        } ?? []

        // 编辑前后所有条件审批会议室
        let originalConditionalApprovalMeetingRooms = context.orginalPBModels.map { originalEvent in
            originalEvent.event.attendees.filter { conditionalApprovalFilter($0, originalEvent.event) }.map(\.attendeeCalendarID)
        } ?? []

        // 所有带有审批条件的会议室 考虑到顺序 这里不用 approvalMeetingRooms+conditionalApprovalMeetingRooms
        let allTargetMeetingRooms = context.event.attendees.filter { approvalFilter($0, context.event) || conditionalApprovalFilter($0, context.event) }

        let dateChanged = context.orginalPBModels.map { _, originalInstance in
            originalInstance.startTime != context.event.startTime || originalInstance.endTime != context.event.endTime
        } ?? false

        // 最终计算出的需要弹窗的会议室
        let resultMeetingRooms = allTargetMeetingRooms.filter { meetingRoom in
            let relatedToFuture = context.event.endTime > Int64(Date().timeIntervalSince1970)
            guard relatedToFuture else { return false }
            if dateChanged {
                // 如果编辑前后日期有变化 所有带审批条件的会议室都需要重新审批
                return true
            } else {
                // 否则只处理新增的会议室（两个original都没有就代表新增)
                return !originalApprovalMeetingRooms.contains(meetingRoom.attendeeCalendarID) && !originalConditionalApprovalMeetingRooms.contains(meetingRoom.attendeeCalendarID)
            }
        }

        let itemInfos = resultMeetingRooms.map { ($0.displayName, $0.schemaExtraData.cd.approvalType.conditionalApprovalTriggerDuration) }
        guard !itemInfos.isEmpty else {
            return .complete()
        }
        // 添加审批 reason
        let addApprovalMessage = { [weak self, weak context] (reason: String) in
            guard let self = self ,let context = context else { return }
            var request = Rust.SchemaExtraData.ApprovalRequest()
            request.reason = reason
            var bizData = Rust.SchemaExtraData.BizData()
            bizData.type = .approvalRequest
            bizData.approvalRequest = request

            let ids = resultMeetingRooms.map { $0.attendeeCalendarID }
            var resourceSimpleAttendees = self.input.isWebinarScene ? context.webinarAttendeeContext.resourceSimpleAttendees : context.attendeeContext.resourceSimpleAttendees
            for i in 0 ..< resourceSimpleAttendees.count
                where ids.contains(resourceSimpleAttendees[i].calendarID) {
                if let index = resourceSimpleAttendees[i].schemaExtraData.bizData.firstIndex(where: { $0.type == .approvalRequest }) {
                    resourceSimpleAttendees[i].schemaExtraData.bizData.remove(at: index)
                }
                resourceSimpleAttendees[i].schemaExtraData.bizData.append(bizData)
            }
            if self.input.isWebinarScene {
                context.webinarAttendeeContext.resourceSimpleAttendees = resourceSimpleAttendees
            } else {
                context.attendeeContext.resourceSimpleAttendees = resourceSimpleAttendees
            }

            for i in 0 ..< context.event.attendees.count
                where context.event.attendees[i].category == .resource
                && ids.contains(context.event.attendees[i].attendeeCalendarID) {
                if let index = context.event.attendees[i].schemaExtraData.bizData.firstIndex(where: { $0.type == .approvalRequest }) {
                    context.event.attendees[i].schemaExtraData.bizData.remove(at: index)
                }
                context.event.attendees[i].schemaExtraData.bizData.append(bizData)
            }
        }
        // - 弹窗: `s.onInteract(.meetingRoomApprovalAlert(approvalAlert))`
        // - 添加审批 reason: `addApprovalMessage(reason)`
        // - 下一步: `s.onForward()`
        return .create { forwarder in
            let approvalAlert = EventEdit.MeetingRoomApprovalAlert(
                title: BundleI18n.Calendar.Calendar_Approval_PopUpTitle,
                itemTitles: itemInfos,
                confirmHandler: { reason in
                    let reason = reason.trimmingCharacters(in: .whitespaces)
                    assert(!reason.isEmpty)
                    addApprovalMessage(reason)
                    EventEdit.logger.info("check reason of approval meetingRooms")
                    forwarder.complete(void)
                },
                cancelHandler: {
                    EventEdit.logger.info("backToEdit")
                    forwarder.terminate(SaveTerminal.backToEdit)
                }
            )
            forwarder.deliver(.meetingRoomApprovalAlert(approvalAlert))
            return Disposables.create()
        }
    }

    // MARK: Check Attachments
    private func checkExistUploadingAttachment(with context: PBEventSaveContext) -> RxSaveStage<Void> {
        if context.attachmentStatus.existUploadingAttachment {
            return .create { forwarder -> Disposable in
                var alertCxt = EventEdit.Alert()
                alertCxt.content = I18n.Calendar_G_WaitTillUploadSave
                alertCxt.actions = [
                    .init(title: I18n.Calendar_Common_GotIt, titleColor: UIColor.ud.primaryContentDefault) {
                        DayScene.logger.info("checked by user: change")
                        forwarder.terminate(SaveTerminal.backToEdit)
                    }
                ]
                forwarder.deliver(.alert(alertCxt))
                return Disposables.create()
            }
        } else {
            return .complete()
        }
    }

    // MARK: Check Attachments
    private func checkExistFailedAttachment(with context: PBEventSaveContext) -> RxSaveStage<Void> {
        if context.attachmentStatus.existFailedAttachment {
            return .create { forwarder -> Disposable in
                var alertCxt = EventEdit.Alert()
                alertCxt.title = I18n.Calendar_Attachment_Popup
                alertCxt.content = I18n.Calendar_Attachment_Popupsubtitle
                alertCxt.actions = [
                    .init(title: BundleI18n.Calendar.Calendar_Common_Cancel) {
                        DayScene.logger.info("checked by user: not change")
                        forwarder.terminate(SaveTerminal.backToEdit)
                    },
                    .init(title: BundleI18n.Calendar.Calendar_Common_Confirm, titleColor: UIColor.ud.primaryContentDefault) {
                        DayScene.logger.info("checked by user: change")
                        forwarder.complete()
                    }
                ]
                forwarder.deliver(.alert(alertCxt))
                return Disposables.create()
            }
        } else {
            return .complete()
        }
    }

    // MARK: Check Attendee Sync
    private func checkAttendeesSync(with context: PBEventSaveContext) -> RxSaveStage<Void> {
        return .create { forwarder in
            let alert = SavingMessage.alert(.init(title: BundleI18n.Calendar.Calendar_Common_SaveEventNoteTitle,
                                                  content: BundleI18n.Calendar.Calendar_Edit_CantSaveEvent,
                                                  actions: [
                                                    .init(title: BundleI18n.Calendar.Lark_Guide_SpotlightButtonKnow,
                                                          handler: { forwarder.terminate(SaveTerminal.notSyncAttendee) })
                                                  ]))
            if context.span == .futureEvents && context.event.serverID == "0" && context.event.dirtyType != .noneDirtyType {
                forwarder.deliver(alert)
            } else {
                forwarder.complete(void)
            }

            return Disposables.create()
        }
    }

    // MARK: Check Notification

    private func titleForNotiBoxType(_ notiBoxType: NotificationBoxType) -> String? {
        let titlesForNotiAlert: [NotificationBoxType: String] = [
            .createWithOtherAttendees: BundleI18n.Calendar.Calendar_Detail_SendInvitationsToAttendees,
            .editInfoWithOtherAttendees: BundleI18n.Calendar.Calendar_Detail_SendUpdatesToAttendees,
            .editAddAttendees: BundleI18n.Calendar.Calendar_Detail_SendInvitationsToNewAttendeesOnly,
            .editRemoveAttendees: BundleI18n.Calendar.Calendar_Detail_SendCancellationsToRemovedAttendees,
            .editInfoAndAddAttendees: BundleI18n.Calendar.Calendar_Detail_SendInvitationsToNewAttendeesAndUpdatesToExistingAttendees,
            .editInfoAndRemoveAttendees: BundleI18n.Calendar.Calendar_Detail_SendCancellationsToRemovedAttendeesAndUpdatesToRemainingAttendees,
            .editInfoAndRemoveAllOtherAttendees: BundleI18n.Calendar.Calendar_Detail_SendCancellationsToRemovedAttendees,
            .editAddAndRemoveAttendees: BundleI18n.Calendar.Calendar_Detail_SendInvitationsToNewAttendeesAndCancellationsToRemovedAttendees,
            .editInfoAndAddAndRemoveAttendees: BundleI18n.Calendar.Calendar_Detail_SendInvitationsToNewAttendeesCancellationsToRemovedAttendeesAndUpdatesToExistingAttendees
        ]
        return titlesForNotiAlert[notiBoxType]
    }

    private func notiAlertSubtitle(from notiBoxParams: NotificationBoxParam, isInGray: Bool) -> String? {
        if isInGray {
            switch notiBoxParams.chatRule {
                // 发生时机 编辑重复性日程的此次日程，当参与人发生变更时
            case .openEntryAuth:
                return BundleI18n.Calendar.Calendar_G_VerificationOnNoFreeEnterExit_Group
            @unknown default:
                break
            }
        }

        switch notiBoxParams.meetingRule {
        case .addAllAttendeesEnterNewMeetingGroupSubtitle, .popAllAttendeesEnterNewMeetingGroupBox:
            return isInGray ? nil : BundleI18n.Calendar.Calendar_Meeting_NewMeeting
        case .nothing:
            break
        @unknown default:
            break
        }

        switch notiBoxParams.mailRule {
        case .addMailAttendeesDefaultReceiveNotificationSubtitile:
            return BundleI18n.Calendar.Calendar_CalMail_InvitePopUpWindowSubtitle
        case .mailRuleNothing:
            break
        @unknown default:
            break
        }
        return nil
    }

    // 弹窗：将日程分享到原会话中
    private func publishShareAlert(
        byForwarder forwarder: StageForwarder<Void, SavingMessage>,
        context: PBEventSaveContext
    ) {
        guard context.isForCreating, context.chatIdForSharing?.isEmpty == false else {
            forwarder.complete(void)
            return
        }
        var alert = EventEdit.NotiOptionAlert(title: BundleI18n.Calendar.Calendar_Edit_ShareEventInChatConfirm)
        alert.actions = [
            .init(title: BundleI18n.Calendar.Calendar_Edit_ShareEventInChatConfirmShareButton, titleColor: UIColor.ud.primaryContentDefault) { _ in
                forwarder.complete(void)
            },
            .init(title: BundleI18n.Calendar.Calendar_Edit_ShareEventInChatConfirmDontShareButton) { _ in
                context.chatIdForSharing = nil
                forwarder.complete(void)
            },
            .init(title: BundleI18n.Calendar.Calendar_Detail_BackToEdit) { _ in
                forwarder.terminate(SaveTerminal.backToEdit)
            }
        ]
        forwarder.deliver(.notiOptionAlert(alert))
    }

    // 弹窗：发通知
    private func publishNotiAlert(
        byForwarder forwarder: StageForwarder<Void, SavingMessage>,
        withParams notiBoxParams: NotificationBoxParam,
        context: PBEventSaveContext,
        isInGray: Bool
    ) {
        guard let alertTitle = titleForNotiBoxType(notiBoxParams.notificationInfos.type) else {
            context.event.notificationType = .defaultNotificationType
            context.chatIdForSharing = nil
            forwarder.complete(void)
            return
        }

        if notiBoxParams.meetingRule == .popAllAttendeesEnterNewMeetingGroupBox {
            // 单独处理
            var alertContext = EventEdit.Alert()
            alertContext.content = alertTitle
            alertContext.actions = [
                .init(title: BundleI18n.Calendar.Calendar_Common_Confirm) { [weak context] in
                    context?.event.notificationType = .defaultNotificationType
                    context?.chatIdForSharing = nil
                    forwarder.complete(void)
                },
                .init(title: BundleI18n.Calendar.Calendar_Common_Cancel) {
                    forwarder.terminate(SaveTerminal.backToEdit)
                }
            ]
            forwarder.deliver(.alert(alertContext))
            return
        }
        // 新建场景的埋点
        let trackBeginning = { [weak self] in
            guard context.isForCreating else { return }
            CalendarTracerV2.EventCreateConform.traceView {
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: self?.eventModel?.rxModel?.value.getPBModel(), startTime: Int64(self?.eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
            }
        }
        let trackEnding = { [weak self] (params: [String: Any]) in
            guard context.isForCreating else { return }
            CalendarTracerV2.EventCreateConform.traceClick {
                if let clickParam = params["click"] {
                    $0.click("\(clickParam)")
                }

                if let shareParam = params["is_share"] {
                    $0.is_share = "\(shareParam)"
                }

                $0.target("none")
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: self?.eventModel?.rxModel?.value.getPBModel(), startTime: Int64(self?.eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
            }
        }

        var alert = EventEdit.NotiOptionAlert(title: alertTitle)
        if context.orginalPBModels == nil && context.chatIdForSharing != nil {
            alert.checkBoxTitle = BundleI18n.Calendar.Calendar_Edit_CreateAndShareEvent
        }

        alert.subtitle = notiAlertSubtitle(from: notiBoxParams, isInGray: isInGray)

        if !context.isForCreating {
            if isInGray && recurrenceEventGrayFG_V2 && checkHasAddOnMember(notiBoxParams.notificationInfos.type) && !checkAddonAttendeeIsOnlyMail() {
                if eventModel?.rxModel?.value.span == .thisEvent {
                    alert.checkBoxTitleList = getCurrentCheckBoxTitles().titles
                    alert.checkBoxType = getCurrentCheckBoxTitles().type
                }
            }
        }

        alert.actions = [
            .init(title: BundleI18n.Calendar.Calendar_Detail_Send, titleColor: UIColor.ud.primaryContentDefault) { checked in
                let checkedDesc = checked?.description ?? "none"
                if checkedDesc != "true" {
                    context.chatIdForSharing = nil
                }
                context.event.notificationType = .sendNotification
                forwarder.complete(void)
                EventEdit.logger.info("check notification. checkBoxSelected: \(checkedDesc), type: sendNotification")
                trackEnding(["click": "send", "is_share": checkedDesc, "target": "none"])
            },
            .init(title: BundleI18n.Calendar.Calendar_Detail_DontSend) { checked in
                let checkedDesc = checked?.description ?? "none"
                context.chatIdForSharing = nil
                context.event.notificationType = .noNotification
                forwarder.complete(void)
                EventEdit.logger.info("check notification. checkBoxSelected: \(checkedDesc), type: noNotification")
                trackEnding(["click": "unsend", "target": "none"])
            },
            .init(title: BundleI18n.Calendar.Calendar_Detail_BackToEdit) { _ in
                forwarder.terminate(SaveTerminal.backToEdit)
                EventEdit.logger.info("check notification. backToEdit")
                trackEnding(["click": "cancel", "target": "none"])
            }
        ]
        forwarder.deliver(.notiOptionAlert(alert))
        trackBeginning()
    }

    // 用于计算压缩中部参数的文案 例如： 将通过 “请问单位...” 加入群组
    private func getCompressableSubtitle(_ name: String) -> String {
        let font = UIFont.systemFont(ofSize: 16)
        let containerWidth = udDialogWidth - 44
        let keyLength = I18n.Calendar_G_CreateGroupOrAssit_PopGroupName(group: "").getWidth(font: font)

        let totalStr = I18n.Calendar_G_CreateGroupOrAssit_PopGroupName(group: name)
        let totalStrLength = totalStr.getWidth(font: font)

        let ellipsisStr = "..."
        let ellipsisStrLength = ellipsisStr.getWidth(font: font)

        let avaiableLength = containerWidth * 1 - keyLength - 1
        if totalStrLength < containerWidth * 1 - 1 { return totalStr }
        var resStr = ""
        var curLength: CGFloat = 0
        for i in name {
            if curLength < avaiableLength - ellipsisStrLength {
                curLength += "\(i)".getWidth(font: font)
                resStr += "\(i)"
            } else {
                return I18n.Calendar_G_CreateGroupOrAssit_PopGroupName(group:resStr + ellipsisStr)
            }
        }
        return totalStr
    }

    private func doubleCheckWhenCreate(
        byForwarder forwarder: StageForwarder<Void, SavingMessage>,
        withParams notiBoxParams: NotificationBoxParam,
        context: PBEventSaveContext
    ) {
        var alertContext = EventEdit.CheckBoxAlert(title: I18n.Calendar_G_ConfirmToCreatePop)
        if FG.clientCreateGroupOption && notiBoxParams.canCreateRSVPCard && !input.isWebinarScene {
            let rsvpBotOptional = FG.rsvpBotOptional
            if let chat = notiBoxParams.inviteRSVPChat, !chat.id.isEmpty {
                switch chat.type{
                case .p2P:
                    if rsvpBotOptional {
                        alertContext.subTitle = I18n.Calendar_G_InviteWillBeSentToThisChat_Desc
                        alertContext.defaultSelectType = getDefaultSelectType(caseType: .p2pCase, name: chat.name)
                        alertContext.allConfirmTypes = [.p2pChatName(name: chat.name), .calendarAssistant]
                    } else {
                        alertContext.subTitle = I18n.Calendar_G_InviteToNamePop(name: chat.name)
                    }
                case .group, .topicGroup:
                    if rsvpBotOptional {
                        alertContext.subTitle = I18n.Calendar_G_InviteWillBeSentToThisChat_Desc
                        alertContext.defaultSelectType = getDefaultSelectType(caseType: .reuseGroupCase, name: chat.name)
                        alertContext.allConfirmTypes = [.reuseGroupName(name: chat.name), .calendarAssistant]
                    } else {
                        alertContext.subTitle = I18n.Calendar_G_CreateGroupOrAssit_Pop
                        alertContext.content = self.getCompressableSubtitle(chat.name)
                    }
                @unknown default:
                    break
                }
            } else {
                if rsvpBotOptional {
                    alertContext.subTitle = I18n.Calendar_G_InviteWillBeSentToThisChat_Desc
                    alertContext.defaultSelectType = getDefaultSelectType(caseType: .newGroupCase, name: "")
                    alertContext.allConfirmTypes = [.newMeetingGroup, .calendarAssistant]
                } else {
                    let num = attendeeModel?.rxAttendeeData.value.breakUpAttendeeCount ?? 0
                    alertContext.subTitle = I18n.Calendar_G_CreateGroupSendInvite(number: num)
                }
            }
        } else {
            if context.orginalPBModels == nil && context.chatIdForSharing != nil {
                alertContext.checkBoxTitle = BundleI18n.Calendar.Calendar_Edit_CreateAndShareEvent
            }
        }

        alertContext.confirmHandler = { (isChecked, type) in
            if !isChecked { context.chatIdForSharing = nil }
            context.event.notificationType = .sendNotification
            self.changeCalendarSetting(type: type, context: context)
            let toAssistant = self.canSendToAssistant(type: type)
            context.createRsvpCardInfo.createRsvpCard = notiBoxParams.canCreateRSVPCard && FG.clientCreateGroupOption && !self.input.isWebinarScene && !toAssistant
            context.createRsvpCardInfo.inviteRsvpChatID = notiBoxParams.inviteRSVPChat?.id ?? ""
            forwarder.complete(void)
            var strategy: String = "no_chat"
            if let chat = notiBoxParams.inviteRSVPChat, !chat.id.isEmpty {
                strategy = "reuse_chat"
            } else {
                if notiBoxParams.canCreateRSVPCard {
                    if type == .calendarAssistant {
                        strategy = "bot"
                    } else {
                        strategy = "new_chat"
                    }
                }
            }
            
            CalendarTracerV2.EventCreateConfirm.traceClick {
                $0.click("confirm")
                $0.view_type = "new_create"
                $0.is_share = isChecked.description
                $0.chat_strategy = strategy
                $0.chat_id = notiBoxParams.inviteRSVPChat?.id ?? ""
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: context.event))
            }
        }
        alertContext.cancelHandler = {
            forwarder.terminate(SaveTerminal.backToEdit)
            CalendarTracerV2.EventCreateConfirm.traceClick {
                $0.click("cancel")
                $0.view_type = "new_create"
            }
        }

        CalendarTracerV2.EventCreateConfirm.traceView { $0.view_type = "new_create" }
        forwarder.deliver(.alertWithShareCheck(alertContext))
    }
    
    private func canSendToAssistant(type: SelectConfirmType?) -> Bool{
        switch type {
        case .calendarAssistant:
            return true
        case .newMeetingGroup, .p2pChatName(_), .reuseGroupName(_):
            return false
        case .none:
            return false
        }
    }
    
    private func changeCalendarSetting(type: SelectConfirmType?, context: PBEventSaveContext) {
        var calendarEventEditNotifyFavor = context.calendarSetting.calendarEventEditNotifyFavor
        switch type {
        case .calendarAssistant:
            calendarEventEditNotifyFavor = .bot
        case .newMeetingGroup, .p2pChatName(_), .reuseGroupName(_):
            calendarEventEditNotifyFavor = .chat
        default:
            break
        }
        context.calendarSetting.calendarEventEditNotifyFavor = calendarEventEditNotifyFavor
    }

    /*
     1. 有删人的 - 向被删除的参与者发送通知？
     2. 除时间外其他字段更新 - 向参与者发送日程更新通知？
     3. 1、2 都有就加起来
     4. 1、2 都没有的 - 确定修改日程吗
    */
    private func doubleCheckWhenEdit(
        byForwarder forwarder: StageForwarder<Void, SavingMessage>,
        withParams notiBoxParams: NotificationBoxParam,
        context: PBEventSaveContext,
        isInGray: Bool
    ) {
        let title: String?
        var userHasChoice = true
        var viewType = "" // For tracing
        switch notiBoxParams.notificationInfos.type {
        case .editInfoWithOtherAttendees, .editInfoAndAddAttendees:
            if notiBoxParams.notificationInfos.timeChanged {
                title = I18n.Calendar_G_ConfirmToEditPop
                userHasChoice = false
                viewType = "save_change"
            } else {
                title = I18n.Calendar_Detail_SendUpdatesToAttendees
                viewType = "update_notice"
            }
        case .editInfoAndAddAndRemoveAttendees, .editInfoAndRemoveAttendees:
            if notiBoxParams.notificationInfos.timeChanged {
                title = I18n.Calendar_Detail_SendCancellationsToRemovedAttendees
                viewType = "delete_attendee"
            } else {
                title = I18n.Calendar_Detail_SendCancellationsToRemovedAttendeesAndUpdatesToRemainingAttendees
                viewType = "delete_attendee_and_update_notice"
            }
        case .editRemoveAttendees, .editInfoAndRemoveAllOtherAttendees, .editAddAndRemoveAttendees:
            title = I18n.Calendar_Detail_SendCancellationsToRemovedAttendees
            viewType = "delete_attendee"
        case .editAddAttendees:
            title = I18n.Calendar_G_ConfirmToEditPop
            userHasChoice = false
            viewType = "save_change"
        @unknown default: title = nil
        }

        guard let alertTitle = title else {
            context.event.notificationType = .defaultNotificationType
            context.chatIdForSharing = nil
            forwarder.complete(void)
            return
        }

        var subTitle = notiAlertSubtitle(from: notiBoxParams, isInGray: isInGray)
        if userHasChoice {
            var alert = EventEdit.NotiOptionAlert(title: alertTitle)

            if isInGray && recurrenceEventGrayFG_V2 && checkHasAddOnMember(notiBoxParams.notificationInfos.type) && !checkAddonAttendeeIsOnlyMail() {
                if eventModel?.rxModel?.value.span == .thisEvent {
                    alert.checkBoxTitleList = getCurrentCheckBoxTitles().titles
                    alert.checkBoxType = getCurrentCheckBoxTitles().type
                } else {
                    alert.subtitle = subTitle
                }
            } else {
                alert.subtitle = subTitle
            }

            alert.actions = [
                .init(title: BundleI18n.Calendar.Calendar_Detail_Send, titleColor: UIColor.ud.primaryContentDefault) { _ in
                    context.event.notificationType = .sendNotification
                    forwarder.complete(void)
                    CalendarTracerV2.EventCreateConfirm.traceClick {
                        $0.click("send")
                        $0.view_type = viewType
                    }
                },
                .init(title: BundleI18n.Calendar.Calendar_Detail_DontSend) { _ in
                    context.event.notificationType = .noNotificationForDeleteAttendee
                    forwarder.complete(void)
                    CalendarTracerV2.EventCreateConfirm.traceClick {
                        $0.click("unsend")
                        $0.view_type = viewType
                    }
                },
                .init(title: BundleI18n.Calendar.Calendar_Detail_BackToEdit) { _ in
                    forwarder.terminate(SaveTerminal.backToEdit)
                    CalendarTracerV2.EventCreateConfirm.traceClick {
                        $0.click("cancel")
                        $0.view_type = viewType
                    }
                }
            ]
            forwarder.deliver(.notiOptionAlert(alert))
        } else {
            if notiBoxParams.mailRule == .addMailAttendeesDefaultReceiveNotificationSubtitile && notiBoxParams.chatRule != .openEntryAuth {
                subTitle = nil
            }
            
            var alert = EventEdit.Alert(title: alertTitle, content: subTitle)

                if isInGray && recurrenceEventGrayFG_V2 && checkHasAddOnMember(notiBoxParams.notificationInfos.type) && !checkAddonAttendeeIsOnlyMail() {
                    if eventModel?.rxModel?.value.span == .thisEvent {
                        alert.checkBoxTitleList = getCurrentCheckBoxTitles().titles
                        alert.checkBoxType = getCurrentCheckBoxTitles().type
                    } else {
                        alert.content = subTitle
                    }
                } else {
                    alert.content = subTitle
                }

            alert.actions = [
                .init(title: BundleI18n.Calendar.Calendar_Common_Cancel, actionType: .cancel) {
                    forwarder.terminate(SaveTerminal.backToEdit)
                    CalendarTracerV2.EventCreateConfirm.traceClick {
                        $0.click("cancel")
                        $0.view_type = viewType
                    }
                },
                .init(title: BundleI18n.Calendar.Calendar_Common_Confirm, titleColor: .ud.primaryContentDefault, actionType: .confirm) {
                    context.event.notificationType = .sendNotification
                    forwarder.complete(void)
                    CalendarTracerV2.EventCreateConfirm.traceClick {
                        $0.click("confirm")
                        $0.view_type = viewType
                    }
                }
            ]
            forwarder.deliver(.alert(alert))
        }
        CalendarTracerV2.EventCreateConfirm.traceView { $0.view_type = viewType }
    }

    private func checkNotiForCreating(with context: PBEventSaveContext) -> RxSaveStage<Void> {
        guard context.orginalPBModels == nil else { return .complete() }

        let newSimpleAttendees: Rust.EventSimpleAttendee?
        switch input {
        case .createWebinar:
            // 嘉宾、观众去重复 + 会议室
            newSimpleAttendees = ((context.event.webinarInfo.speakers.attendees +
                                   context.event.webinarInfo.audiences.attendees).deduplicated() +
                                  context.event.attendees.filter { $0.category == .resource }
            ).toEventSimpleAttendee()
        case .createWithContext, .copyWithEvent:
            newSimpleAttendees = context.event.attendees.toEventSimpleAttendee()
        default:
            assertionFailure("cannot run here")
            return .complete()
        }
        guard let api = calendarApi else { return .complete() }
        return api.judgeNotificationBoxType(
            operationType: .opCreateEvent,
            span: .noneSpan,
            event: context.event,
            originalEvent: nil,
            instanceStartTime: nil,
            newSimpleAttendees: newSimpleAttendees,
            originalSimpleAttendees: nil,
            groupSimpleMembers: context.attendeeContext.groupSimpleMembers,
            shareToChatId: context.chatIdForSharing,
            attendeeTotalNum: Int32(attendeeModel?.rxAttendeeData.value.breakUpAttendeeCount ?? 0)
        )
            .map { RxSaveStage<NotificationBoxParam>.Element.state($0) }
            .asStage()
            .joinStage { notiBoxParam -> RxSaveStage<Void> in
                EventEdit.logger.info("judgeNotificationBoxType response: \(notiBoxParam)")
                if case .createWithOtherAttendees = notiBoxParam.notificationInfos.type {
                    if FG.rsvpNoticeOffline {
                        return .create { [weak self] forwarder -> Disposable in
                            self?.doubleCheckWhenCreate(byForwarder: forwarder, withParams: notiBoxParam, context: context)
                            return Disposables.create()
                        }
                    }
                    // 发送通知 + 分享到会话（如果有 chatIdForSharing）
                    return .create { [weak self] forwarder -> Disposable in
                        EventEdit.logger.info("publishNotiAlert")
                        self?.publishNotiAlert(byForwarder: forwarder, withParams: notiBoxParam, context: context, isInGray: false)
                        return Disposables.create()
                    }
                } else {
                    context.event.notificationType = .defaultNotificationType
                    guard context.chatIdForSharing?.isEmpty == false else {
                        return .complete()
                    }
                    // 分享到会话
                    return .create { [weak self] forwarder -> Disposable in
                        EventEdit.logger.info("publishShareAlert")
                        self?.publishShareAlert(byForwarder: forwarder, context: context)
                        return Disposables.create()
                    }
                }
            }
            .catchError { (error, forwarder) -> Disposable in
                if error is SaveTerminal {
                    forwarder.terminate(error)
                    return Disposables.create()
                }
                EventEdit.logger.error("judgeNotificationBoxType failed: \(error)")
                context.event.notificationType = .defaultNotificationType
                context.chatIdForSharing = nil
                forwarder.complete(void)
                return Disposables.create()
            }
    }

    private func checkNotiForEditing(with context: PBEventSaveContext) -> RxSaveStage<Void> {
        guard var (originalEvent, originalInstance) = context.orginalPBModels,
              let api = calendarApi else {
            return .complete()
        }
        EventEdit.logger.info("check api: judgeNotificationBoxType")
        // 对于重复性日程，请求参数需要用 instance 的时间
        originalEvent.startTime = originalInstance.startTime
        originalEvent.endTime = originalInstance.endTime

        var newSimpleAttendees = Rust.EventSimpleAttendee()
        var originalSimpleAttendees = Rust.EventSimpleAttendee()
        if input.isWebinarScene {
            newSimpleAttendees.individualAttendees = Rust.IndividualSimpleAttendee.deduplicated(
                of: context.webinarAttendeeContext.speakersContext.individualSimpleAttendees +
                context.webinarAttendeeContext.audiencesContext.individualSimpleAttendees)
            newSimpleAttendees.groupAttendees = Rust.GroupSimpleAttendee.deduplicated(of: context.webinarAttendeeContext.speakersContext.groupSimpleAttendees + context.webinarAttendeeContext.audiencesContext.groupSimpleAttendees)
            newSimpleAttendees.resourceAttendees = context.webinarAttendeeContext.resourceSimpleAttendees

            originalSimpleAttendees.individualAttendees = Rust.IndividualSimpleAttendee.deduplicated(of: context.webinarAttendeeContext.speakersContext.originalIndividualSimpleAttendees + context.webinarAttendeeContext.audiencesContext.originalIndividualSimpleAttendees)
            originalSimpleAttendees.groupAttendees =  Rust.GroupSimpleAttendee.deduplicated(of: context.webinarAttendeeContext.speakersContext.originalGroupSimpleAttendees + context.webinarAttendeeContext.audiencesContext.originalGroupSimpleAttendees)
            originalSimpleAttendees.resourceAttendees = context.webinarAttendeeContext.originalResourceSimpleAttendees
        } else {
            newSimpleAttendees = context.event.attendees.toEventSimpleAttendee()
            originalSimpleAttendees = context.attendeeContext.getOriginalEventSimpleAttendee()
        }

        return api.judgeNotificationBoxType(
            operationType: .opEditEvent,
            span: context.span,
            event: context.event,
            originalEvent: originalEvent,
            instanceStartTime: originalInstance.startTime,
            newSimpleAttendees: newSimpleAttendees,
            originalSimpleAttendees: originalSimpleAttendees,
            shareToChatId: context.chatIdForSharing,
            attendeeTotalNum: Int32(attendeeModel?.rxAttendeeData.value.breakUpAttendeeCount ?? 0)
        )
        .map { RxSaveStage<(NotificationBoxParam)>.Element.state($0) }
            .asStage()
            .joinStage { notiBoxParam -> RxSaveStage<Void> in
                return .create { [weak self] forwarder -> Disposable in
                    EventEdit.logger.info("publishNotiAlert")
                    if FG.rsvpNoticeOffline {
                        self?.doubleCheckWhenEdit(byForwarder: forwarder, withParams: notiBoxParam, context: context, isInGray: self?.recurrenceEventGrayFG ?? false)
                    } else {
                        self?.publishNotiAlert(byForwarder: forwarder, withParams: notiBoxParam, context: context, isInGray: self?.recurrenceEventGrayFG ?? false)
                    }
                    return Disposables.create()
                }
            }
            .catchError { (error, forwarder) -> Disposable in
                if error is SaveTerminal {
                    forwarder.terminate(error)
                    return Disposables.create()
                }
                EventEdit.logger.error("judgeNotificationBoxType failed: \(error)")
                context.event.notificationType = .defaultNotificationType
                context.chatIdForSharing = nil
                forwarder.complete(void)
                return Disposables.create()
            }
    }

    private func checkNoti(with context: PBEventSaveContext) -> RxSaveStage<Void> {
        return checkNotiForCreating(with: context)
            .joinStage { [weak self] _ -> RxSaveStage<Void> in
                return self?.checkNotiForEditing(with: context) ?? .empty()
            }
    }

    private func appendOwnerForSwitchingCalendar(with context: PBEventSaveContext) -> RxSaveStage<Void> {
        // 如果是目标日历是主日历，且没有在参与人中，则自动插入，且标记为 removed
        guard let calendar = eventModel?.rxModel?.value.calendar, calendar.isPrimary,
              !context.event.attendees.contains(where: { $0.attendeeCalendarID == calendar.id }) else {
            return .complete()
        }

        return .create { [weak self] forwarder -> Disposable in
            guard let self = self, let api = self.calendarApi else {
                forwarder.complete(void)
                return Disposables.create()
            }
            return api.getAttendees(uids: [calendar.userChatterId])
                .subscribe(
                    onNext: { attendees in
                        guard var pb = attendees.first(where: { $0.attendeeCalendarId == calendar.id })?.pb else {
                            assertionFailure("get attendee failed. attendee: \(calendar.userChatterId)")
                            EventEdit.logger.error("get attendee failed. attendee: \(calendar.userChatterId)")
                            forwarder.complete(void)
                            return
                        }
                        pb.status = .removed
                        context.event.attendees.append(pb)
                        forwarder.complete(void)
                    },
                    onError: { err in
                        EventEdit.logger.error("get attendee failed. err: \(err)")
                        forwarder.complete(void)
                    }
                )
        }
    }

    // 检查是否有增加参与者
    private func checkHasAddOnMember(_ notiBoxType: NotificationBoxType) -> Bool {
        switch notiBoxType {
        case .editAddAndRemoveAttendees, .editAddAttendees, .editInfoAndAddAndRemoveAttendees, .editInfoAndAddAttendees:
            return true
        @unknown default:
            return false
        }
    }

    private func getCurrentCheckBoxTitles() -> (titles: [String], type: EventEdit.NotiOptionCheckBoxType) {
        var titles: [String] = []
        var type: EventEdit.NotiOptionCheckBoxType = .unknown
        guard let event = eventModel?.rxModel?.value.getPBModel() else {
            return (titles: titles, type: type)
        }

        // 会议群类型、开启了群验证 且  组织者或在群里
        if (event.type == .meeting && event.eventMeetingChatExtra.isChatOpenEntryAuth)
            && (event.calendarID == event.organizerCalendarID || event.eventMeetingChatExtra.isInMeetingChat) {
            titles.append(I18n.Calendar_Detail_NewGuestsJoinMeetingGroup)
            type = .group
        }

        if !event.meetingMinuteURL.isEmpty {
            titles.append(I18n.Calendar_Detail_GrantAccessToMinutes)
            type = type == .unknown ? .doc : .all
        }

        return (titles: titles, type: type)
    }

    // 获取新增的个人参与人、群参与人
    private func getAddOnIndividuialAttendees(_ context: PBEventSaveContext) -> (addChatCalendarIDs: [Int64], addChatIDs: [Int64]) {
        var addChatCalendarIDs: [Int64] = []
        var addChatIDs: [Int64] = []
        let originalSimpleAttendees = context.orginalPBModels?.event.attendees.toEventSimpleAttendee()
        let newSimpleAttendees = context.attendeeContext.getEventSimpeAttendee()

        newSimpleAttendees.individualAttendees.map { item in
            if let individualAttendees = originalSimpleAttendees?.individualAttendees, !individualAttendees.isEmpty && !individualAttendees.contains(item) {
                if let id = Int64(item.calendarID), item.status != .removed && item.category != .thirdPartyUser {
                    addChatCalendarIDs.append(id)
                }
            }
        }

        newSimpleAttendees.groupAttendees.map { item in
            if let groupAttendees = originalSimpleAttendees?.groupAttendees {
                if groupAttendees.isEmpty || (!groupAttendees.isEmpty && !groupAttendees.contains(item)) {
                    if let id = Int64(item.groupID), item.status != .removed {
                        addChatIDs.append(id)
                    }
                }
            }
        }

        return (addChatCalendarIDs, addChatIDs)
    }

    private func checkAddonAttendeeIsOnlyMail() -> Bool {
        let originalSimpleAttendees = eventModelBeforeEditing?.getPBModel().attendees
        let newSimpleAttendees = eventModel?.rxModel?.value.attendees
        var isOnlyMail: Bool = true
        newSimpleAttendees?.forEach { item in
            if let pbItem = item.getPBModel(), let originAttendee = originalSimpleAttendees, !originAttendee.isEmpty,
               !originAttendee.contains(pbItem) {
                if pbItem.category != .thirdPartyUser, pbItem.status != .removed {
                    isOnlyMail = false
                }
            }
        }
        return isOnlyMail
    }

    private func prepareAddMeetingCollaboratorData(_ context: PBEventSaveContext) {
        let addOnAttendee = getAddOnIndividuialAttendees(context)
        if addOnAttendee.addChatIDs.isEmpty, addOnAttendee.addChatCalendarIDs.isEmpty { return }
        guard let notiCheckBoxTuple = notiCheckBoxTuple else { return }

        var needReason: Bool = false
        let key: String = context.event.key
        let calendarID: String = context.event.calendarID
        let originalTime: Int64 = context.event.originalTime
        var addMeetingChatChatter: Bool = false
        var addMeetingMinuteCollaborator: Bool = false

        switch notiCheckBoxTuple.type {
        case .group:
            addMeetingChatChatter = notiCheckBoxTuple.checkedVals.first ?? false
        case .doc:
            addMeetingMinuteCollaborator = notiCheckBoxTuple.checkedVals.first ?? false
        case .all:
            addMeetingChatChatter = notiCheckBoxTuple.checkedVals.first ?? false
            addMeetingMinuteCollaborator = notiCheckBoxTuple.checkedVals.last ?? false
        default: break
        }
        needReason = addMeetingChatChatter
        // 没勾选/是管理员/组织者 不需要走申请弹窗
        if !needReason || isGroupManager || (eventModel?.rxModel?.value.getPBModel().calendarID == eventModel?.rxModel?.value.getPBModel().organizerCalendarID) {
            calendarApi?.AddMeetingCollaboratorRequest(uniqueKey: key, operatorCalendarID: calendarID, originalTime: originalTime, addChatID: addOnAttendee.addChatIDs, addCalendarID: addOnAttendee.addChatCalendarIDs, addMeetingChatChatter: addMeetingChatChatter, addMeetingMinuteCollaborator: addMeetingMinuteCollaborator, addChatterApplyReason: "")
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] res in
                    EventEdit.logger.info("AddMeetingCollaboratorRequest success.with \(res.status)")
                    switch res.status {
                    case .addMeetingMinuteCollFailed:
                        if let window = self?.userResolver.navigator.mainSceneWindow {
                            UDToast.showFailure(with: I18n.Calendar_G_AuthorizeFailCheckPermit_Toast, on: window)
                        }
                    case .bothFailed, .addMeetingChatCollFailed:
                        if let window = self?.userResolver.navigator.mainSceneWindow {
                            UDToast.showFailure(with: I18n.Calendar_G_OopsWrongRetry, on: window)
                        }
                    @unknown default: break
                    }
                }, onError: { [weak self] (error) in
                    EventEdit.logger.error("AddMeetingCollaboratorRequest failed with \(error)")
                })
                .disposed(by: disposeBag)
        } else {
            self.extraData?.extraApplyGroupData = CalendarNotiGroupApplySavedData(key: key, calendarID: calendarID, originalTime: originalTime, addChatIDs: addOnAttendee.addChatIDs, addChatCalendarIDs: addOnAttendee.addChatCalendarIDs, addMeetingChatChatter: addMeetingChatChatter, addMeetingMinuteCollaborator: addMeetingMinuteCollaborator, needReason: true)
        }
    }

    // 切换日历
    private func switchCalendar(with context: PBEventSaveContext) -> RxSaveStage<Bool> {
        guard let originalEvent = context.orginalPBModels?.event,
              let api = self.calendarApi,
            originalEvent.calendarID != context.calendarId else {
            return .complete(false)
        }
        EventEdit.logger.info("start switching calendar...")

        return RxSaveStage<Void>.create { forwarder -> Disposable in
            EventEdit.logger.info("deliver message: show loading toast")
            forwarder.deliver(.showLoadingToast(BundleI18n.Calendar.Calendar_Toast_Saving))
            forwarder.complete(void)
            return Disposables.create()
        }.joinStage { [weak self] (_, forwarder) in
            guard let self = self else {
                forwarder.complete(false)
                return
            }
            api.switchEventCalendar(
                from: originalEvent.calendarID,
                to: context.calendarId,
                withEventKey: originalEvent.key,
                originalTime: originalEvent.originalTime
            )
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] newEvent in
                    guard let self = self else { return }
                    EventEdit.logger.info("switch calendar succeed")
                    context.orginalPBModels?.event = newEvent
                    context.event = self.mergedEvent(from: newEvent, with: context.event)

                    guard case .editFrom(_, var pbInstance) = self.input else {
                        assertionFailure()
                        return
                    }
                    // 切换日历后，更新编辑页的 input
                    pbInstance.id = newEvent.id
                    pbInstance.calendarID = newEvent.calendarID
                    self.input = .editFrom(pbEvent: newEvent, pbInstance: pbInstance)

                    forwarder.deliver(.syncEventChanged(event: newEvent, span: context.span))
                    forwarder.deliver(.dismissLoadingToast)
                    forwarder.complete(true)
                },
                onError: { err in
                    EventEdit.logger.error("switch calendar failed. err: \(err)")
                    forwarder.terminate(SaveTerminal.switchCalendarFailed)
                }
            )
            .disposed(by: context.disposeBag)
        }
    }

    // MARK: Check Group Limit

    private func checkGroupLimit(with context: PBEventSaveContext) -> RxSaveStage<Void> {
        guard let originalEvent = context.orginalPBModels?.event,
              let api = self.calendarApi,
            originalEvent.calendarID != context.calendarId else {
            return .complete(void)
        }
        EventEdit.logger.info("canAppendeedAttendeesSyncToMeeting")

        let eventEntity = PBCalendarEventEntity(pb: context.event)
        return api.canAppendeedAttendeesSyncToMeeting(event: eventEntity,
                                                              originalEvent: originalEvent)
            .map { RxSaveStage<Bool>.Element.state($0) }
            .asStage()
            .joinStage { yesOrNo -> RxSaveStage<Void> in
                EventEdit.logger.info("canAppendeedAttendeesSyncToMeeting response: \(yesOrNo)")
                return .create { forwarder -> Disposable in
                    if yesOrNo {
                        forwarder.complete(void)
                        return Disposables.create()
                    }

                    var alert = EventEdit.Alert()
                    alert.title = BundleI18n.Calendar.Calendar_Alert_GroupNumLimitTitle
                    alert.content = BundleI18n.Calendar.Calendar_Alert_GroupNumLimitDes2
                    alert.actions = [
                        .init(
                            title: BundleI18n.Calendar.Calendar_Common_Confirm,
                            handler: {
                                forwarder.complete(void)
                                EventEdit.logger.info("user confirmed for checkGroupLimit")
                            }
                        )
                    ]
                    forwarder.deliver(.alert(alert))
                    return Disposables.create()
                }
            }
            .catchError { (error, forwarder) -> Disposable in
                assertionFailure("canAppendeedAttendeesSyncToMeeting failed: \(error)")
                EventEdit.logger.error("canAppendeedAttendeesSyncToMeeting failed: \(error)")
                forwarder.complete(void)
                return Disposables.create()
            }
    }

    // MARK: Saving

    private func saveToLocal(with context: EKEventSaveContext) -> RxSaveStage<EKEvent> {
        let token = SensitivityControlToken.saveEventOnEventEditView
        do {
            EventEdit.logger.info("will save local event")
            try LocalCalendarManager.saveEvent(for: token, event: context.event, span: context.span)
            EventEdit.logger.info("did save local event")
            return .complete(context.event)
        } catch {
            SensitivityControlToken.logFailure("save local event failed, may because sensitivity control for :\(token),  error: \(error)")
            EventEdit.logger.info("failed to save local event: \(context.debugDescription)")
            return .terminate(error)
        }
    }

    private func saveToRust(with context: PBEventSaveContext) -> RxSaveStage<Rust.Event>? {
        guard let api = self.calendarApi else { return nil }
        prepareAddMeetingCollaboratorData(context)
        let saveEvent: Observable<Rust.Event>
        if !input.isWebinarScene {
            saveEvent = api.saveEvent(
                event: context.event,
                originalEvent: context.orginalPBModels?.event,
                instance: context.orginalPBModels?.instance,
                span: context.span,
                shareToChatId: context.chatIdForSharing ?? "",
                newSimpleAttendees: context.attendeeContext.getEventSimpeAttendee(),
                originalSimpleAttendees: context.attendeeContext.getOriginalEventSimpleAttendee(),
                groupSimpleMembers: context.attendeeContext.groupSimpleMembers,
                rejectedUserMap: context.attendeeContext.rejectedGroupUsersMap,
                createRsvpCardInfo: context.createRsvpCardInfo,
                instanceRelatedData: context.instanceRelatedData,
                createEventUid: context.myAiUid ?? "",
                needRenewalReminder: context.needRenewalReminder
            )
        } else {
            saveEvent = api.saveWebinarEvent(
                event: context.event,
                originalEvent: context.orginalPBModels?.event,
                newSimpleAttendees: context.webinarAttendeeContext.getWebinarEventAttendeeInfo(),
                originalSimpleAttendees: context.webinarAttendeeContext.getOriginalWebinarEventAttendeeInfo(),
                rejectedUserMap: context.attendeeContext.rejectedGroupUsersMap,
                data: context.webinarData)
        }
        return RxSaveStage<Void>.create { forwarder in
            if self.input.isWebinarScene {
                forwarder.deliver(.showLoadingToast(I18n.Calendar_Toast_Saving))
            }
            forwarder.complete(void)
            return Disposables.create()
        }.joinStage { _ in
            return saveEvent.flatMap({ [weak self] event -> Observable<Rust.Event> in
                guard let self = self else { return .just(event) }
                if self.input.isWebinarScene {
                    // webinar 日程保存时请求一次服务端获取更新的 event，目的是让详情页不用请求就能拿到准确的 webinar 信息
                    return api.getServerPBEvent(serverId: event.serverID)
                        .map { $0 ?? event }
                        .catchErrorJustReturn(event)
                }
                return api.getEventPB(calendarId: event.calendarID, key: event.key, originalTime: event.originalTime)
            })
            .map { RxSaveStage<Rust.Event>.Element.state($0) }
            .asStage()
        }
    }

}

// MARK: - Saving
extension EventEditViewModel {

    fileprivate final class WebinarPBEventSaveAttendeeContext {
        var rejectedGroupUsersMap: [String: [Int64]] = [:]
        var resourceSimpleAttendees: [Rust.ResourceSimpleAttendee] = []
        var speakersContext = PBEventSaveAttendeeContext()
        var audiencesContext = PBEventSaveAttendeeContext()

        var originalResourceSimpleAttendees: [Rust.ResourceSimpleAttendee] = []

        func getWebinarEventAttendeeInfo() -> WebinarEventAttendeeInfo {
            var attendeeInfo = WebinarEventAttendeeInfo()
            attendeeInfo.speaker.attendees = speakersContext.individualSimpleAttendees
            attendeeInfo.speaker.groupAttendee = speakersContext.groupSimpleAttendees
            attendeeInfo.audience.attendees = audiencesContext.individualSimpleAttendees
            attendeeInfo.audience.groupAttendee = audiencesContext.groupSimpleAttendees
            attendeeInfo.resourceAttendees = resourceSimpleAttendees
            return attendeeInfo
        }

        func getOriginalWebinarEventAttendeeInfo() -> WebinarEventAttendeeInfo {
            var attendeeInfo = WebinarEventAttendeeInfo()
            attendeeInfo.speaker.attendees = speakersContext.originalIndividualSimpleAttendees
            attendeeInfo.speaker.groupAttendee = speakersContext.originalGroupSimpleAttendees
            attendeeInfo.audience.attendees = audiencesContext.originalIndividualSimpleAttendees
            attendeeInfo.audience.groupAttendee = audiencesContext.originalGroupSimpleAttendees
            attendeeInfo.resourceAttendees = originalResourceSimpleAttendees
            return attendeeInfo
        }
    }

    /// 保存非本地日程的参与人相关信息，新日程的 attendee
    fileprivate final class PBEventSaveAttendeeContext {
        var groupSimpleMembers = [String: [Rust.IndividualSimpleAttendee]]()
        var individualSimpleAttendees: [Rust.IndividualSimpleAttendee]
        var groupSimpleAttendees: [Rust.GroupSimpleAttendee]
        var resourceSimpleAttendees: [Rust.ResourceSimpleAttendee]
        var rejectedGroupUsersMap: [String: [Int64]]
        // 标识 originalTotalAttendees 这个字段是否已经全量的参与人了
        var totalAttendeeLoaded: Bool = true

        // originalAttendee 信息
        var originalIndividualSimpleAttendees: [Rust.IndividualSimpleAttendee] = []
        var originalGroupSimpleAttendees: [Rust.GroupSimpleAttendee] = []
        var originalResourceSimpleAttendees: [Rust.ResourceSimpleAttendee] = []

        convenience init() {
            self.init(groupSimpleMembers: [:],
                      individualSimpleAttendees: [],
                      groupAttendees: [],
                      resourceAttendees: [],
                      rejectedGroupUsersMap: [:],
                      totalAttendeeLoaded: true)
        }

        init(groupSimpleMembers: [String: [Rust.IndividualSimpleAttendee]],
             individualSimpleAttendees: [Rust.IndividualSimpleAttendee],
             groupAttendees: [Rust.GroupSimpleAttendee],
             resourceAttendees: [Rust.ResourceSimpleAttendee],
             rejectedGroupUsersMap: [String: [Int64]],
             totalAttendeeLoaded: Bool) {
            self.groupSimpleMembers = groupSimpleMembers
            self.individualSimpleAttendees = individualSimpleAttendees
            self.groupSimpleAttendees = groupAttendees
            self.resourceSimpleAttendees = resourceAttendees
            self.rejectedGroupUsersMap = rejectedGroupUsersMap
            self.totalAttendeeLoaded = totalAttendeeLoaded
        }

        func getEventSimpeAttendee() -> Rust.EventSimpleAttendee {
            var eventSimpleAttendee = Rust.EventSimpleAttendee()
            eventSimpleAttendee.individualAttendees = individualSimpleAttendees
            eventSimpleAttendee.groupAttendees = groupSimpleAttendees
            eventSimpleAttendee.resourceAttendees = resourceSimpleAttendees
            return eventSimpleAttendee
        }

        func getOriginalEventSimpleAttendee() -> Rust.EventSimpleAttendee {
            var eventSimpleAttendee = Rust.EventSimpleAttendee()
            eventSimpleAttendee.individualAttendees = originalIndividualSimpleAttendees
            eventSimpleAttendee.groupAttendees = originalGroupSimpleAttendees
            eventSimpleAttendee.resourceAttendees = originalResourceSimpleAttendees
            return eventSimpleAttendee
        }
    }

    typealias AttachmentStatusTuple = (existFailedAttachment: Bool, existUploadingAttachment: Bool)

    /// 保存非本地日程的 context
    fileprivate final class PBEventSaveContext: CustomDebugStringConvertible {
        // 需要保持到 rust 的 event
        var event: Rust.Event = Rust.Event() {
            didSet {
                self.hasEvent = true
            }
        }
        var hasEvent: Bool = false
        var willtMeetingRoomFail: Bool
        var attachmentStatus: AttachmentStatusTuple
        let calendarId: String
        var orginalPBModels: (event: Rust.Event, instance: Rust.Instance)?
        var span: Span = .noneSpan
        var chatIdForSharing: String?
        var myAiUid: String?
        var attendeeContext: PBEventSaveAttendeeContext
        var webinarAttendeeContext: WebinarPBEventSaveAttendeeContext
        var isForCreating: Bool { orginalPBModels == nil }
        var createRsvpCardInfo: Rust.EventCreateRsvpCardInfo = Rust.EventCreateRsvpCardInfo()
        var instanceRelatedData: Rust.InstanceRelatedData?
        var disposeBag = DisposeBag()
        var webinarData: String?
        var calendarSetting: CalendarSetting

        // 强制改动必须生效于重复性日程的所有日程
        var forceApplyToAllEvent = false

        var debugDescription: String {
            let eventInfo = "\(event.calendarID), \(event.key), \(event.originalTime)"
            let originalEventInfo: String
            let originalInstanceInfo: String
            let attendeeInfo: String
            if let original = orginalPBModels {
                originalEventInfo = "\(original.event.calendarID), \(original.event.key), \(original.event.originalTime)"
                originalInstanceInfo = "\(original.instance.calendarID), \(original.instance.key), \(original.instance.originalTime), \(original.instance.startTime)"
                attendeeInfo = "origin attendee count: \(original.event.attendees.count), event attendee count: \(event.attendees.count)"
            } else {
                originalEventInfo = ""
                originalInstanceInfo = ""
                attendeeInfo = "event attendee count: \(event.attendees.count)"
            }
            return """
            event: \(eventInfo),
            originalEvent: \(originalEventInfo),
            originalInstance: \(originalInstanceInfo),
            calendarId: \(calendarId),
            span: \(span),
            chatIdForSharing: \(chatIdForSharing ?? ""),
            attendeeInfo: \(attendeeInfo)
            """
        }
        var needRenewalReminder: Bool

        init(calendarId: String,
             willtMeetingRoomFail: Bool,
             attachmentStatus: AttachmentStatusTuple,
             calendarSetting: CalendarSetting,
             needRenewalReminder: Bool = false) {
            self.calendarId = calendarId
            self.willtMeetingRoomFail = willtMeetingRoomFail
            self.attachmentStatus = attachmentStatus
            self.needRenewalReminder = needRenewalReminder
            self.attendeeContext = PBEventSaveAttendeeContext()
            self.webinarAttendeeContext = WebinarPBEventSaveAttendeeContext()
            self.calendarSetting = calendarSetting
        }
    }

    /// 保存本地日程的 context
    fileprivate final class EKEventSaveContext: CustomDebugStringConvertible {
        var event: EKEvent
        var span: EKSpan?
        var disposeBag = DisposeBag()

        var debugDescription: String {
            return """
            event: (\(event.calendarItemIdentifier), \(String(describing: event.eventIdentifier))),
            span: \(span),
            """
        }

        init(event: EKEvent) {
            self.event = event
        }
    }

    /// 保存日程的 context
    fileprivate enum EventSaveContext: CustomDebugStringConvertible {
        case pbType(PBEventSaveContext)
        case ekType(EKEventSaveContext)

        var debugDescription: String {
            switch self {
            case .pbType(let context): return context.debugDescription
            case .ekType(let context): return context.debugDescription
            }
        }
    }

    private func makeSaveContext() -> EventSaveContext {

        let attachmentsStatus = { [weak self] () -> AttachmentStatusTuple in
            guard let attachmentModel = self?.attachmentModel else { return (false, false) }
            let attachmentsShowed = attachmentModel.rxDisplayingAttachmentsInfo.value.attachments.filter { !$0.isDeleted }
            let existFailedAttachment = attachmentsShowed.contains {
                switch $0.status {
                case .failed(_): return true
                default: return false
                }
            }
            let existUploadingAttachment = attachmentsShowed.contains {
                switch $0.status {
                case .uploading(_), .awaiting: return true
                default: return false
                }
            }
                        
            return (existFailedAttachment, existUploadingAttachment)
        }

        switch input {
        case .editFromLocal:
            let context = EKEventSaveContext(event: eventModel?.rxModel?.value.getEKEvent() ?? EventEditModel().getEKEvent())
            let span = { (span: Rust.Span) -> EKSpan? in
                switch span {
                case .thisEvent:
                    return .thisEvent
                case .futureEvents:
                    return .futureEvents
                @unknown default:
                    return nil
                }
            }
            context.span = span(eventModel?.rxModel?.value.span ?? .noneSpan)
            return .ekType(context)
        case .editFrom(let pbEvent, let pbInstance), .editWebinar(let pbEvent, let pbInstance):
            assertLog(eventModel?.rxModel?.value.calendar?.id != nil)
            let context = PBEventSaveContext(
                calendarId: eventModel?.rxModel?.value.calendar?.id ?? "",
                willtMeetingRoomFail: !self.rxMeetingRoomViewData.value.items.allSatisfy { $0.isValid },
                attachmentStatus: attachmentsStatus(),
                calendarSetting: self.setting.getPB(),
                needRenewalReminder: self.needRenewalReminder
            )
            context.orginalPBModels = (pbEvent, pbInstance)
            context.span = eventModel?.rxModel?.value.span ?? .noneSpan
            initEventForRust(with: context)
            return .pbType(context)
        case .createWithContext(let createContext):
            let context = PBEventSaveContext(
                calendarId: eventModel?.rxModel?.value.calendar?.id ?? "",
                willtMeetingRoomFail: !self.rxMeetingRoomViewData.value.items.allSatisfy { $0.isValid },
                attachmentStatus: attachmentsStatus(),
                calendarSetting: self.setting.getPB(),
                needRenewalReminder: needRenewalReminder
            )
            let calendarSource = eventModel?.rxModel?.value.calendar?.source ?? .lark
            let calendarIsThirdParty = [.exchange, .google].contains(calendarSource)
            context.chatIdForSharing = calendarIsThirdParty ? nil : createContext.chatIdForSharing
            context.myAiUid = createContext.myAiUid
            initEventForRust(with: context)
            return .pbType(context)
        case .copyWithEvent:
            let context = PBEventSaveContext(
                calendarId: eventModel?.rxModel?.value.calendar?.id ?? "",
                willtMeetingRoomFail: !self.rxMeetingRoomViewData.value.items.allSatisfy { $0.isValid },
                attachmentStatus: attachmentsStatus(),
                calendarSetting: self.setting.getPB(),
                needRenewalReminder: needRenewalReminder
            )
            initEventForRust(with: context)
            return .pbType(context)
        case .createWebinar:
            let context = PBEventSaveContext(
                calendarId: eventModel?.rxModel?.value.calendar?.id ?? "",
                willtMeetingRoomFail: !self.rxMeetingRoomViewData.value.items.allSatisfy { $0.isValid },
                attachmentStatus: attachmentsStatus(),
                calendarSetting: self.setting.getPB(),
                needRenewalReminder: needRenewalReminder
            )
            initEventForRust(with: context)
            return .pbType(context)
        }
    }

    private func saveEKEvent(with context: EKEventSaveContext) -> RxSaveStage<EKEvent> {
        let rxStart = RxSaveStage<Void>.complete()
        return rxStart
            // 保存日程到本地
            .joinStage { [weak self] _ -> RxSaveStage<EKEvent> in
                return self?.saveToLocal(with: context) ?? .empty()
            }
    }

    private func saveSimpleEvent(with context: PBEventSaveContext) -> RxSaveStage<Rust.Event> {
        let rxStart = RxSaveStage<Void>.complete()
        return rxStart
            // Check 是否有修改
            .joinStage { [weak self] _ -> RxSaveStage<Void> in
                return self?.checkChanged(with: context) ?? .empty()
            }
            // Check 会议室审批（弹窗，填写审批理由）
            .joinStage { [weak self] _ -> RxSaveStage<Void> in
                return self?.checkMeetingRoomApprovalReason(with: context) ?? .empty()
            }
            // 直接返回 Event
            .joinStage { [weak self] _ -> RxSaveStage<Rust.Event> in
                return Observable.just(context.event)
                    .map { RxSaveStage<Rust.Event>.Element.state($0) }
                    .asStage()
            }
    }

    private func savePBEvent(with context: PBEventSaveContext) -> RxSaveStage<Rust.Event> {
        let rxStart = RxSaveStage<Void>.complete()
        return rxStart
            // some attachments is uploading(Block)
            .joinStage{ [weak self] _ -> RxSaveStage<Void> in
                return self?.checkExistUploadingAttachment(with: context) ?? .empty()
            }
            // webinar 场景获取 vc setting
            .joinStage { [weak self] _ -> RxSaveStage<Void> in
                return self?.checkWebinarVCSetting(with: context) ?? .empty()
            }
            // Check 是否达到管控上限
            .joinStage { [weak self] _ -> RxSaveStage<Void> in
                return self?.checkReachAttendeeCountControlLimit(with: context) ?? .empty()
            }
            // Check 是否有修改
            .joinStage { [weak self] _ -> RxSaveStage<Void> in
                return self?.checkChanged(with: context) ?? .empty()
            }
            .joinStage { [weak self] _ -> RxSaveStage<Void> in
                return self?.checkMeetingNotesStatus(with: context) ?? .empty()
            }
            // 检查表单是否为空白
            .joinStage { [weak self] _ -> RxSaveStage<Void> in
                self?.checkMeetingRoomForm(context: context) ?? .empty()
            }
            // 检查是否有会预订失败的会议室
            .joinStage { [weak self] _ -> RxSaveStage<Void> in
                self?.checkMeetingRoomsStatus(with: context) ?? .empty()
            }
            // check 附件全部上传完成
            .joinStage{ [weak self] _ -> RxSaveStage<Void> in
                return self?.checkExistFailedAttachment(with: context) ?? .empty()
            }
            // Check 切换日历弹窗
            .joinStage { [weak self] _ -> RxSaveStage<Void> in
                return self?.checkSwitchCalendar(with: context) ?? .empty()
            }
            // Check 会议室审批（弹窗，填写审批理由）
            .joinStage { [weak self] _ -> RxSaveStage<Void> in
                return self?.checkMeetingRoomApprovalReason(with: context) ?? .empty()
            }
            // Check 会议群参与人上限
            .joinStage { [weak self] _ -> RxSaveStage<Void> in
                return self?.checkGroupLimit(with: context) ?? .empty()
            }
            // Check 通知
            .joinStage { [weak self] _ -> RxSaveStage<Void> in
                return self?.checkNoti(with: context) ?? .empty()
            }
            // Check 日历的可见性（新建场景 & 切花日历场景）
            .joinStage { [weak self] _ -> RxSaveStage<Void> in
                return self?.checkCalendarVisible(with: context) ?? .empty()
            }
            // 切换日历
            .joinStage { [weak self] _ -> RxSaveStage<Bool> in
                return self?.switchCalendar(with: context) ?? .complete(false)
            }
            .joinStage { [weak self] yesOrNo -> RxSaveStage<Void> in
                guard let self = self, yesOrNo else {
                    return .complete(void)
                }
                return self.appendOwnerForSwitchingCalendar(with: context)
            }
            // 保存日程到 Rust 层
            .joinStage { [weak self] _ -> RxSaveStage<Rust.Event> in
                return self?.saveToRust(with: context) ?? .empty()
            }
    }

    func saveEvent() -> RxSaveStage<EventSaveResult> {
        let context = makeSaveContext()
        let saveStage: RxSaveStage<EventSaveResult>
        EventEdit.logger.info("will save event. context: \(context.debugDescription)")

        switch context {
        case .ekType(let context):
            saveStage = saveEKEvent(with: context)
                .joinStage { ekEvent -> RxSaveStage<EventSaveResult> in
                    return .complete(.ekType(ekEvent))
                }
        case .pbType(let context):
            let saveMode: RxSaveStage<Rust.Event>
            switch interceptor {
            case .none, .needResult: saveMode = savePBEvent(with: context)
            case .onlyResult: saveMode = saveSimpleEvent(with: context)
            }
            saveStage = saveMode
                .joinStage { pbEvent -> RxSaveStage<EventSaveResult> in
                    return .complete(.pbType(pbEvent, context.span))
                }
        }
        return saveStage
            .joinStage { [weak self] result -> RxSaveStage<EventSaveResult> in
                guard let self = self, case .pbType(let context) = context else {
                    EventEdit.logger.info("context info or self nil!")
                    return .complete(result)
                }
                /// 如果用户记忆规则改变了，则保存
                if context.calendarSetting.calendarEventEditNotifyFavor != self.setting.getPB().calendarEventEditNotifyFavor {
                    return .create { [weak self] forwarder -> Disposable in
                        guard let self = self, let api = self.calendarApi else {
                            forwarder.complete(result)
                            return Disposables.create()
                        }
                        return api.saveCalendarSettings(setting: context.calendarSetting)
                            .subscribe(
                                onNext: {
                                    EventEdit.logger.info("save calendar setting success")
                                    forwarder.complete(result)
                                },
                                onError: { err in
                                    EventEdit.logger.info("save calendar setting fail: \(err)")
                                    forwarder.complete(result)
                                })
                    }
                }
                return .complete(result)
            }
            .joinStage { [weak self] result -> RxSaveStage<EventSaveResult> in
                self?.trackSavingEvent(context: context, saveResult: result)
                EventEdit.logger.info("did save event. context: \(context.debugDescription)")
                return .complete(result)
            }
            .catchError { [weak self] (error, forwarder) -> Disposable in
                self?.trackSavingEvent(context: context, saveResult: nil)
                EventEdit.logger.error("save event failed. context: \(context.debugDescription)")
                forwarder.terminate(error)
                return Disposables.create()
            }
    }

    // swiftlint:disable cyclomatic_complexity
    private func trackSavingEvent(context: EventSaveContext, saveResult: EventSaveResult?) {
        var params = CalendarTracer.EventSaveParams()
        params.succeed = saveResult != nil
        params.actionSource = actionSource
        if case .pbType(let pbContext) = context {
            for attendee in pbContext.event.attendees where attendee.status != .removed {
                switch attendee.category {
                case .resource: params.meetingRoomCount += 1
                case .group: params.groupAttendeeCount += 1
                case .thirdPartyUser: params.emailAttendeeCount += 1
                @unknown default: params.userAttendeeCount += 1
                }
            }
            params.editType = input.isFromCreating ? .new : .edit

            if params.editType == .new {
                params.role = "organizer"
            } else {
                let organizerOrCreatorCalendarID = [pbContext.event.organizerCalendarID, pbContext.event.creatorCalendarID]
                let isOrganizer = organizerOrCreatorCalendarID.contains(pbContext.event.calendarID)
                let role = isOrganizer ? "organizer" : "attendee"
                params.role = role
            }

            if let saveResult = saveResult, case .pbType(let pbEvent, _) = saveResult {
                if pbEvent.type == .meeting {
                    params.eventType = .meeting
                } else {
                    switch pbEvent.source {
                    case .exchange: params.eventType = .exchange
                    case .google: params.eventType = .google
                    default: params.eventType = .lark
                    }
                }
                switch pbEvent.videoMeeting.videoMeetingType {
                case .unknownVideoMeetingType: params.vcType = .unknown
                case .vchat: params.vcType = .larkVC
                case .other: params.vcType = .customVC
                case .larkLiveHost: params.vcType = .live
                case .noVideoMeeting: params.vcType = .noVC
                case .googleVideoConference: params.vcType = .customVC
                case .zoomVideoMeeting: params.vcType = .zoom
                @unknown default: break
                }
            }
            params.notifyType = .init(pbContext.event.notificationType)
            params.isCrossTenant = pbContext.event.isCrossTenant
            params.eventId = pbContext.event.serverID
            params.chatId = input.chatIdForSharing
            if let firstMeetingRoom = pbContext.event.attendees.first(where: { $0.category == .resource }) {
                params.meetingRoomID = firstMeetingRoom.attendeeCalendarID
            }
            DispatchQueue.main.async {
                CalendarTracerV2.EventFullCreate.traceClick {
                    let vc_type: String
                    let videoMeeting = pbContext.event.videoMeeting
                    switch videoMeeting.videoMeetingType {
                    case .unknownVideoMeetingType: vc_type = "unknown"
                    case .vchat: vc_type = "lark_vc"
                    case .other:
                        if videoMeeting.otherConfigs.icon == .live {
                            vc_type = "custom_vc_livestream"
                        } else {
                            vc_type = "custom_vc_meeting"
                        }
                    case .larkLiveHost: vc_type = "lark_livestream"
                    case .noVideoMeeting: vc_type = "no_vc"
                    case .googleVideoConference: vc_type = "custom_vc"
                    case .zoomVideoMeeting: vc_type = "zoom"
                    @unknown default: vc_type = ""
                    }
                    $0.click("save").target("none")
                    $0.vc_type = vc_type
                    $0.event_type = self.input.isWebinarScene ? "webinar" : "normal"
                    $0.has_description = (!pbContext.event.description_p.isEmpty).description
                    $0.has_title = self.checkIsSummaryExist(pbContext.event.summary)
                    $0.title_length = pbContext.event.summary.count
                    $0.is_new_create = (params.editType == .new) ? "true" : "false"
                    let linkTypeExist = DocUtils.docUrlDetector(pbContext.event.description_p, userNavigator: self.userResolver.navigator)
                    let titleTypeExist = DocUtils.docUrlDetector(pbContext.event.docsDescription, userNavigator: self.userResolver.navigator)
                    $0.desc_has_doc = (linkTypeExist || titleTypeExist) ? "true" : "false"
                    $0.has_meeting_notes = (self.meetingNotesModel?.currentNotes != nil).description
                    if params.editType == .edit {
                        if let originalEventModel = self.eventModelBeforeEditing {
                            $0.is_time_alias = self.checkChangedForDate(with: pbContext.event, and: originalEventModel.getPBModel()).description
                            $0.is_title_alias = self.checkChangedForSummary(with: pbContext.event, and: originalEventModel.getPBModel()).description
                            $0.is_rrule_alias = self.checkChangedForRrule(with: pbContext.event, and: originalEventModel.getPBModel()).description
                        }
                    }
                    $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.eventModel?.rxModel?.value.getPBModel(), startTime: Int64(self.eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
                }
            }
        } else {
            params.editType = .edit
            params.eventType = .local
        }
        Tracer.shared.saveEventFromEditing(params)
    }

    private func checkIsSummaryExist(_ summary: String?) -> String {
        if let summary = summary, !summary.isEmpty {
            return "true"
        }
        return "false"
    }

    func trackInvitedGroupCheckStatus(isSelected: Bool) {
        CalendarTracerV2.EventCreateConfirm.traceClick {
            $0.click("invite_to_group")
            $0.is_checked = isSelected.description
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: eventModel?.rxModel?.value.getPBModel(), startTime: Int64(eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
        }
    }

    func trackMinutesCheckStatus(isSelected: Bool) {
        CalendarTracerV2.EventCreateConfirm.traceClick {
            $0.click("permission_to_edit_minutes")
            $0.is_checked = isSelected.description
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: eventModel?.rxModel?.value.getPBModel(), startTime: Int64(eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
        }
    }
}

// MARK: - Save Result

extension EventEditViewModel {

    /// 日程保存结果
    enum EventSaveResult: CustomDebugStringConvertible {
        case pbType(Rust.Event, Span)
        case ekType(EKEvent)

        var debugDescription: String {
            switch self {
            case .pbType(let event, _): return event.dt.description
            case .ekType(let event): return event.description
            }
        }
    }
}

extension Array where Element == Rust.Attendee {
    func toEventSimpleAttendee() -> Rust.EventSimpleAttendee {
        var eventSimpleAttendees = Rust.EventSimpleAttendee()
        self.forEach { attendee in
            if let dependency = attendee.dependency {
                switch dependency {
                case .user(let userAttendee):
                    eventSimpleAttendees.individualAttendees.append(attendee.toIndividualSimpleAttendee())
                case .group(let group):
                    eventSimpleAttendees.groupAttendees.append(attendee.toGroupSimpleAttendee())
                case .thirdPartyUser(let emailAttendee):
                    eventSimpleAttendees.individualAttendees.append(attendee.toIndividualSimpleAttendee())
                case .resource(let resource):
                    eventSimpleAttendees.resourceAttendees.append(attendee.toResourceSimpleAttendee())
                @unknown default:
                    break
                }
            }
        }

        eventSimpleAttendees.individualAttendees = eventSimpleAttendees
            .individualAttendees.sorted(by: { $0.calendarID.localizedCompare($1.calendarID) == .orderedAscending })

        return eventSimpleAttendees
    }

    func toWebinarEventSimpleAttendee() -> Calendar_V1_WebinarEventSimpleAttendee {
        var eventSimpleAttendees = Calendar_V1_WebinarEventSimpleAttendee()
        self.forEach { attendee in
            if let dependency = attendee.dependency {
                switch dependency {
                case .user(let userAttendee):
                    eventSimpleAttendees.attendees.append(attendee.toIndividualSimpleAttendee())
                case .group(let group):
                    eventSimpleAttendees.groupAttendee.append(attendee.toGroupSimpleAttendee())
                case .thirdPartyUser(let emailAttendee):
                    eventSimpleAttendees.attendees.append(attendee.toIndividualSimpleAttendee())
                default:
                    break
                }
            }
        }
        return eventSimpleAttendees
    }

    // 用于对参与人的过滤，不包含会议室
    func deduplicated() -> Self {
        let attendees = EventEditAttendee.makeAttendees(from: self)
        return EventEditAttendee.deduplicated(of: attendees).compactMap({ $0.getPBModel() })
    }
}

// MARK: check webinar vc setting
extension EventEditViewModel {
    private func checkWebinarVCSetting(with context: PBEventSaveContext) -> RxSaveStage<Void> {
        guard input.isWebinarScene else { return .complete() }
        return .create { [weak self] forwarder in
            if let result = self?.webinarDataGetter?() {
                switch result {
                case .success(let data):
                    context.webinarData = data.configJson
                    context.event.webinarInfo.conf.speakerCanInviteOthers = data.speakerCanInviteOthers
                    context.event.webinarInfo.conf.speakerCanSeeOtherSpeakers = data.speakerCanSeeOtherSpeakers
                    context.event.webinarInfo.conf.audienceCanInviteOthers = data.audienceCanInviteOthers
                    context.event.webinarInfo.conf.audienceCanSeeOtherSpeakers = data.audienceCanSeeOtherSpeakers
                    if let webinarData = data.configJson {
                        context.event.webinarInfo.webinarData = webinarData
                    }
                    forwarder.complete()
                case .failure(let reason):
                    forwarder.terminate(SaveTerminal.webinarVCSettingNotValid(reason))
                }
            }
            return Disposables.create()
        }
    }
}

// MARK: 增加通知日历助手的记忆能力
extension EventEditViewModel {
    
    enum CaseType {
        case p2pCase
        case newGroupCase
        case reuseGroupCase
    }
    
    private func getDefaultSelectType(caseType: CaseType, name: String) -> SelectConfirmType {
        let setting = self.setting.getPB()
        EventEdit.logger.info("calendarEventEditNotifyFavor of calendar setting is \(setting.calendarEventEditNotifyFavor)")
        let assistantNoMemory = FeatureGating.assistantNoMemory(userID: self.userResolver.userID)
        if assistantNoMemory {
            /// 无记忆能力
            return useGroupName(caseType: caseType, name: name)
        } else {
            /// 有记忆能力
            switch setting.calendarEventEditNotifyFavor {
            case .bot:
                /// 如果当前记忆为卡片
                return .calendarAssistant
            case .chat, .unknown:
                /// 如果当前记忆为群
                return useGroupName(caseType: caseType, name: name)
                /// 扩展状态，默认发群
            @unknown default:
                return useGroupName(caseType: caseType, name: name)
            }
        }
    }
    
    /// 封装使用群
    private func useGroupName(caseType: CaseType, name: String) -> SelectConfirmType {
        switch caseType {
        case .newGroupCase:
            return .newMeetingGroup
        case .p2pCase:
            return .p2pChatName(name: name)
        case .reuseGroupCase:
            return .reuseGroupName(name: name)
        }
    }
}
