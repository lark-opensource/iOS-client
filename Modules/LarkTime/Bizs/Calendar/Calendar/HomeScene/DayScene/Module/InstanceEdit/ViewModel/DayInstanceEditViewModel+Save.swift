//
//  DayInstanceEditViewModel+Save.swift
//  Calendar
//
//  Created by 张威 on 2020/9/8.
//

import UIKit
import RxSwift
import LarkUIKit
import LarkContainer
import CalendarFoundation
import LarkTimeFormatUtils
import UniverseDesignDialog

/// DayScene - InstanceEdit - ViewModel: SaveEvent

// MARK: - Types

extension DayInstanceEditViewModel {

    typealias Stage<State> = RxStage<State, SaveViewMessage>
    typealias Forwarder<State> = StageForwarder<State, SaveViewMessage>

    enum SaveViewMessage {
        // swiftlint:disable nesting
        struct ActionItem {
            var title: String
            var titleColor: UIColor = UIColor.ud.textTitle
            var handler: () -> Void
        }

        struct Alert {
            var title: String?
            var message: String?
            var actions: [ActionItem] = []
        }

        // 会议室存在预订失败弹窗
        struct MeetingRoomReservationAlert {
            let title = BundleI18n.Calendar.Calendar_Room_SomeNoReserveConfirm_Pop
            var actions: [ActionItem]
        }

        // 通用的会议室信息弹窗
        struct GeneralMeetingRoomInfoAlert {
            var title: String
            var itemInfos: [(title: String, trigger: Int64?)]
            var actions: [ActionItem] = []
        }

        // 会议室审批弹窗
        struct MeetingRoomApprovalAlert {
            var title: String
            var itemInfos: [(title: String, trigger: Int64?)]
            var confirmHandler: (_ message: String) -> Void
            var cancelHandler: () -> Void
        }

        // 通知弹窗
        struct NotiOptionAlert {
            var title: String
            var subtitle: String?
            var checkBoxTitle: String?
            var actions: [ActionItem] = []
        }
        // swiftlint:enable nesting

        case alert(Alert)
        // 会议室存在预订失败
        case meetingRoomReservationAlert(MeetingRoomReservationAlert)
        // 通用的会议室信息弹窗
        case generalMeetingRoomInfoAlert(GeneralMeetingRoomInfoAlert)
        // 会议室审批弹窗
        case meetingRoomApprovalAlert(MeetingRoomApprovalAlert)
        // 日程通知弹窗
        case notiOptionAlert(NotiOptionAlert)
        // present UIViewController
        case present(UIViewController)
        case successToast(_ text: String)
    }

    enum SaveTerminal: Error {
        case cancelledByUser
        case rustSdkError(Error)
        case localError(Error)
    }

}

// MARK: - Save To Local

extension DayInstanceEditViewModel {

    private final class LocalEventSaveContext {
        var event: Local.Event
        var span = Span.noneSpan
        let dates: (startDate: Date, endDate: Date)

        init(event: Local.Event, dates: (startDate: Date, endDate: Date)) {
            self.event = event
            self.dates = dates
        }
    }

    func rxSaveToLocal(
        _ instance: Local.Instance,
        with newDates: (startDate: Date, endDate: Date)
    ) -> Stage<Void> {
        let saveContext = LocalEventSaveContext(event: instance, dates: newDates)
        let rxStart = Stage<Void>.complete()
        return rxStart
            .joinStage { [weak self] _ -> Stage<Void> in
                return self?.updateEventDates(with: saveContext) ?? .empty()
            }
            .joinStage { [weak self] _ -> Stage<Void> in
                return self?.checkSpan(with: saveContext) ?? .empty()
            }
            .joinStage { [weak self] _ -> Stage<Void> in
                return self?.saveToLocal(with: saveContext) ?? .empty()
            }
    }

    // 更新 event 的 dates
    private func updateEventDates(with context: LocalEventSaveContext) -> Stage<Void> {
        context.event.startDate = context.dates.startDate
        context.event.endDate = context.dates.endDate
        return .complete()
    }

    private func checkSpan(with context: LocalEventSaveContext) -> Stage<Void> {
        if context.event.hasRecurrenceRules {
            context.span = .thisEvent
        } else {
            context.span = .noneSpan
        }
        return .complete()
    }

    private func saveToLocal(with context: LocalEventSaveContext) -> Stage<Void> {
        let token = SensitivityControlToken.instantSaveEventOnDayScene
        do {
            let entity = CalendarEventEntityFromLocal(event: context.event)
            try LocalCalendarManager.saveEvent(for: token, event: entity, span: context.span)
            return .complete()
        } catch {
            SensitivityControlToken.logFailure("save local event failed, may because sensitivity control for :\(token),  error: \(error)")
            DayScene.logger.error("save local event failed. \(error)")
            return .terminate(SaveTerminal.localError(error))
        }
    }

}

// MARK: - Save To Rust

extension DayInstanceEditViewModel {

    private final class RustEventSaveContext {
        let originalInstance: Rust.Instance
        var event = Rust.Event()
        var originalEvent = Rust.Event()
        var span = Span.noneSpan
        let dates: (startDate: Date, endDate: Date)
        let needRenewalReminder: Bool

        init(originalInstance: Rust.Instance,
             dates: (startDate: Date, endDate: Date),
             needRenewalReminder: Bool = false) {
            self.originalInstance = originalInstance
            self.dates = dates
            self.needRenewalReminder = needRenewalReminder
        }
    }
    
    func saveTimeBlock(
        model: TimeBlockModel,
        with newDates: (startDate: Date, endDate: Date),
        actionType: UpdateTimeBlockActionType,
        is12HourStyle: Bool
    ) -> Stage<Void> {
        // 拖拽和移动虽然调用的同一个接口，但产品交互不同，因此这里区分处理
        switch actionType {
        case .drag:
            return processDrag()
        case .move:
            return processMove()
        case .unknown:
            return .complete()
        @unknown default:
            return .complete()
        }
        func processDrag() -> Stage<Void> {
            return Stage<Void>.create { forwarder in
                let config = UDDialogUIConfig()
                config.style = .horizontal
                let dialog = UDDialog(config: config)
                dialog.setTitle(text: I18n.Calendar_G_ConfirmUpdateTaskInfo_Title)
                var options = LarkTimeFormatUtils.Options()
                options.timePrecisionType = .minute
                options.timeFormatType = .short
                // 使用设备时区
                let customOptions = Options(
                    timeZone: TimeZone.current,
                    is12HourStyle: is12HourStyle,
                    timePrecisionType: .minute,
                    datePrecisionType: .day,
                    dateStatusType: .absolute,
                    shouldRemoveTrailingZeros: false
                )
                let startTimeDesc = CalendarTimeFormatter.formatFullDateTimeRange(
                    startFrom: newDates.startDate,
                    endAt: newDates.endDate,
                    isAllDayEvent: model.isAllDay,
                    with: customOptions
                )
                dialog.setContent(text: I18n.Calendar_G_ConfirmUpdateTaskInfo_Desc(time1: startTimeDesc))
                dialog.addCancelButton(dismissCompletion:  {
                    CalendarTracerV2.ChangeTaskConfirm.normalTrackClick {
                        var map = [String: Any]()
                        map["task_id"] = model.taskId
                        map["click"] = "cancel"
                        return map
                    }
                    forwarder.complete()
                })
                dialog.addPrimaryButton(text: I18n.Calendar_G_ConfirmUpdateTaskInfo_Button, dismissCompletion:  { [weak self] in
                    guard let self = self else { return }
                    CalendarTracerV2.ChangeTaskConfirm.normalTrackClick {
                        var map = [String: Any]()
                        map["task_id"] = model.taskId
                        map["click"] = "confirm"
                        return map
                    }
                    guard checkIsChange() else {
                        forwarder.terminate(SaveTerminal.cancelledByUser)
                        return
                    }
                    self.timeBlockSaveToRust(model: model, with: newDates, actionType: actionType)
                        .subscribe(onNext: { _ in
                            forwarder.complete()
                        }, onError: { error in
                            forwarder.terminate(error)
                        }).disposed(by: self.disposeBag)
                })
                CalendarTracerV2.ChangeTaskConfirm.normalTrackView {
                    var map = [String: Any]()
                    map["task_id"] = model.taskId
                    return map
                }
                forwarder.deliver(.present(dialog))
                return Disposables.create()
            }
        }
        
        func processMove() -> Stage<Void> {
            guard checkIsChange() else { return .terminate(SaveTerminal.cancelledByUser) }
            return self.timeBlockSaveToRust(model: model, with: newDates, actionType: actionType)
                .asStage { Stage.Element.state($0) }
                .joinStage { _ -> Stage<Void> in
                    return .create { forwarder in
                        forwarder.deliver(.successToast(I18n.Calendar_MV_TaskTimeUpdated_Toast))
                        forwarder.complete()
                        return Disposables.create()
                    }
                }
                .catchError { error, forwarder in
                    forwarder.terminate(error)
                    return Disposables.create()
                }
        }
        
        func checkIsChange() -> Bool {
            let newStartTime = Int64(newDates.startDate.timeIntervalSince1970)
            let newEndTime = Int64(newDates.endDate.timeIntervalSince1970)
            return (model.startTime != newStartTime) || (model.endTime != newEndTime)
        }
    }

    func timeBlockSaveToRust(
        model: TimeBlockModel,
        with newDates: (startDate: Date, endDate: Date),
        actionType: UpdateTimeBlockActionType) -> Observable<Void> {
        let startTime = Int64(newDates.startDate.timeIntervalSince1970)
        let endTime = Int64(newDates.endDate.timeIntervalSince1970)
        guard let timeDataService = self.timeDataService else { return .empty() }
        return timeDataService.patchTimeBlock(id: model.id,
                                              containerIDOnDisplay: model.containerIDOnDisplay,
                                              startTime: startTime,
                                              endTime: endTime,
                                              actionType: actionType)
    }

    func rxSaveToRust(
        _ instance: Rust.Instance,
        with newDates: (startDate: Date, endDate: Date)
    ) -> Stage<Void> {
        let saveContext = RustEventSaveContext(originalInstance: instance,
                                               dates: newDates,
                                               // 这里只可能是false
                                               needRenewalReminder: false)
        let rxStart = Stage<Void>.complete()
        return rxStart
            .joinStage { [weak self] _ -> Stage<Void> in
                return self?.getRustEvent(with: saveContext) ?? .complete()
            }
            .joinStage { [weak self] _ -> Stage<Void> in
                return self?.checkReachAttendeeCountControlLimit(with: saveContext) ?? .complete()
            }
            .joinStage { [weak self] _ -> Stage<Void> in
                return self?.updateEventDates(with: saveContext) ?? .complete()
            }
            .joinStage { [weak self] _ -> Stage<Void> in
                return self?.checkSpan(with: saveContext) ?? .complete()
            }
            .joinStage { [weak self] _ -> Stage<Void> in
                return self?.checkConflictMeetingRoomAndRrule(with: saveContext) ?? .complete()
            }
            .joinStage { [weak self] _ -> Stage<Void> in
                return self?.checkConditionalApprovalMeetingRoomRemoved(with: saveContext) ?? .complete()
            }
            .joinStage { [weak self] _ -> Stage<Void> in
                return self?.checkMeetingRoomReservation(with: saveContext) ?? .complete()
            }
            .joinStage { [weak self] _ -> Stage<Void> in
                return self?.checkMeetingRoomApprovalReason(with: saveContext) ?? .complete()
            }
            .joinStage { [weak self] _ -> Stage<Void> in
                return self?.checkNoti(with: saveContext) ?? .complete()
            }
            .joinStage { [weak self] _ -> Stage<Void> in
                return self?.saveToRust(with: saveContext) ?? .complete()
            }
    }

    // 根据 instance 获取 event
    private func getRustEvent(with context: RustEventSaveContext) -> Stage<Void> {
        guard let calendarApi = self.calendarApi else { return Stage<Void>.complete() }
        return calendarApi.getEvent(
            calendarId: context.originalInstance.calendarID,
            key: context.originalInstance.key,
            originalTime: context.originalInstance.originalTime
        ).flatMapLatest({ [weak self] (localEntity) -> Observable<CalendarEventEntity> in
            guard let self = self, let calendarApi = self.calendarApi else { return .just(localEntity) }
            return calendarApi.getServerEvent(serverId: localEntity.serverID, refidCalendarMap: [localEntity.serverID: localEntity.calendarId])
                .map({serverEntity in serverEntity ?? localEntity })
                .catchErrorJustReturn(localEntity)
        })
        .asStage { Stage.Element.state($0) }
        .joinStage { eventEntity in
            context.originalEvent = eventEntity.getPBModel()
            context.event = eventEntity.getPBModel()
            return .complete()
        }
    }

    // 检查日程是否超出大人数日程管控上限
    private func checkReachAttendeeCountControlLimit(with context: RustEventSaveContext) -> Stage<Void> {
        guard let calendarApi = self.calendarApi, let calendarManager = self.calendarManager else { return Stage<Void>.complete() }
        let userResolver = self.userResolver
        return calendarApi.getEventApprovalStatus(key: context.originalInstance.key)
            .asStage { Stage.Element.state($0) }
            .joinStage { approved in
                let count = Int(context.originalEvent.attendeeInfo.totalNo)
                let calendar = calendarManager.calendar(with: context.originalEvent.calendarID).map({ $0.toEventEditCalendar() })
                let isEventCreator = context.originalEvent.creatorCalendarID == calendarManager.primaryCalendarID
                let isRecurEvent = !context.originalEvent.rrule.isEmpty || context.originalInstance.originalTime != 0
                let isExceptEvent = context.originalInstance.originalTime != 0

                guard let reason = EventEditAttendeeManager.attendeesUpperLimitReason(
                    count: count,
                    calendar: calendar,
                    attendeeMaxCountControlled: !approved,
                    isEventCreator: isEventCreator,
                    isRecurEvent: isRecurEvent
                ) else { return .complete() }

                let title: String
                let message: String
                let makeActions: ((Forwarder<Void>) -> [SaveViewMessage.ActionItem])
                switch reason {
                case .reachControlLimit(let limit):
                    title = I18n.Calendar_G_GuestLimitReached(number: limit)
                    message = I18n.Calendar_G_MoreGuestGoRequest
                    makeActions = { forwarder in
                        [
                            SaveViewMessage.ActionItem(
                                title: I18n.Calendar_G_ContinueSave_Button,
                                handler: { forwarder.complete() }
                            ),
                            SaveViewMessage.ActionItem(
                                title: I18n.Calendar_G_RequestPermission_Button,
                                titleColor: UIColor.ud.primaryContentDefault,
                                handler: {
                                    let approveVM = EventAttendeeLimitApproveViewModel(userResolver: userResolver,
                                                                                       calendarId: context.originalEvent.calendarID,
                                                                                       key: context.originalEvent.key,
                                                                                       originalTime: context.originalEvent.originalTime)
                                    approveVM.approveCommitSucceedHandler = {
                                        forwarder.complete()
                                    }
                                    approveVM.cancelCommitHandler = {
                                        forwarder.terminate(SaveTerminal.cancelledByUser)
                                    }
                                    let approveVC = EventAttendeeLimitApproveViewController(viewModel: approveVM)
                                    let naviController = LkNavigationController(rootViewController: approveVC)
                                    forwarder.deliver(.present(naviController))
                                }
                            )
                        ]
                    }

                case .reachRecurEventLimit(let limit):
                    // 例外日程拖动不会生成新的日程，允许保存
                    if isExceptEvent {
                        return .complete()
                    }
                    title = I18n.Calendar_G_GuestLimitReached(number: limit)
                    message = I18n.Calendar_G_GuestRecurNoExceedLimit(number: limit)
                    makeActions = { forwarder in
                        [
                            SaveViewMessage.ActionItem(
                                title: I18n.Calendar_Common_GotIt,
                                handler: { forwarder.terminate(SaveTerminal.cancelledByUser) }
                            )
                        ]
                    }
                    let event = context.event
                    CalendarTracerV2.RepeatedEventReachLimit.traceView {
                        $0.mergeEventCommonParams(commonParam: .init(event: event))
                        $0.is_new_create = "false"
                        $0.limit_number = limit
                    }
                default:
                    return .complete()

                }

                return .create { forwarder -> Disposable in
                    let alert = SaveViewMessage.Alert(
                        title: title,
                        message: message,
                        actions: makeActions(forwarder))
                    forwarder.deliver(.alert(alert))
                    return Disposables.create()
                }
            }
    }

    // 更新 event 的 dates
    private func updateEventDates(with context: RustEventSaveContext) -> Stage<Void> {
        context.event.startTime = Int64(context.dates.startDate.timeIntervalSince1970)
        context.event.endTime = Int64(context.dates.endDate.timeIntervalSince1970)
        let dateChanged = context.originalInstance.startTime != context.event.startTime
                || context.originalInstance.endTime != context.event.endTime
        guard dateChanged else { return .terminate(SaveTerminal.cancelledByUser) }
        return .complete()
    }

    // 检查全量审批会议室与rrule是否冲突
    private func checkConflictMeetingRoomAndRrule(with context: RustEventSaveContext) -> Stage<Void> {
        let dateChanged = context.originalInstance.startTime != context.event.startTime
                || context.originalInstance.endTime != context.event.endTime
        guard dateChanged else { return .complete() }

        let originalApprovalMeetingRooms = context.event.attendees.filter { attendee in
            if attendee.category == .resource && attendee.status != .removed {
                return attendee.attendeeSchema.hasApprovalKey
            }
            return false
        }
        if !originalApprovalMeetingRooms.isEmpty && !context.originalEvent.rrule.isEmpty {
            return .create { forwarder in
                let alert = SaveViewMessage.Alert(
                    title: I18n.Calendar_Rooms_EventTimeNoChangeSwitchRoom,
                    message: nil,
                    actions: [
                        SaveViewMessage.ActionItem(
                            title: I18n.Calendar_Common_GotIt,
                            handler: {
                                forwarder.terminate(SaveTerminal.cancelledByUser)
                            }
                        )
                    ])
                forwarder.deliver(.alert(alert))
                return Disposables.create()
            }
        } else {
            return .complete()
        }
    }

    // 检查是否有条件审批会议室从有到无
    private func checkConditionalApprovalMeetingRoomRemoved(with context: RustEventSaveContext) -> Stage<Void> {
        let originalDuration = context.originalInstance.endTime - context.originalInstance.startTime
        let duration = context.event.endTime - context.event.startTime

        // 如果是增加日程时长 直接忽略
        guard duration < originalDuration else { return .complete() }

        let removedMeetingRooms = context.event.attendees.filter { attendee in
            if attendee.category == .resource && attendee.status != .removed && attendee.status != .accept {
                return attendee.attendeeSchema.hasConditionalApprovalKey &&
                attendee.schemaExtraData.cd.approvalType.shouldTriggerApprovalOff(duration: originalDuration) &&
                !attendee.schemaExtraData.cd.approvalType.shouldTriggerApprovalOff(duration: duration)
            }
            return false
        }

        // 如果旧的会议室都包含在新的里面 说明没有因为时长变短而不再满足条件的会议室
        if removedMeetingRooms.isEmpty {
            return .complete()
        } else {
            return .create { forwarder in
                let itemInfos: [(title: String, trigger: Int64?)] = removedMeetingRooms.map { ($0.displayName, $0.schemaExtraData.cd.approvalType.conditionalApprovalTriggerDuration) }
                let actions: [DayInstanceEditViewModel.SaveViewMessage.ActionItem] = [
                    SaveViewMessage.ActionItem(title: BundleI18n.Calendar.Calendar_Common_Confirm) {
                        DayScene.logger.info("reduce condition meeting room confirmed")
                        forwarder.complete()
                    },
                    SaveViewMessage.ActionItem(title: BundleI18n.Calendar.Calendar_Common_Cancel) {
                        DayScene.logger.info("reduce condition meeting room cancelled")
                        forwarder.terminate(SaveTerminal.cancelledByUser)
                    }
                ]

                let alert = SaveViewMessage
                    .GeneralMeetingRoomInfoAlert(title: BundleI18n.Calendar.Calendar_Rooms_ChangeTimeDesc,
                                                 itemInfos: itemInfos,
                                                 actions: actions)
                forwarder.deliver(.generalMeetingRoomInfoAlert(alert))
                return Disposables.create()
            }
        }
    }

    // Check 会议室限制条件
    private func checkMeetingRoomReservation(with context: RustEventSaveContext) -> Stage<Void> {
        let dateChanged = context.originalInstance.startTime != context.event.startTime
        || context.originalInstance.endTime != context.event.endTime
        guard dateChanged else { return .complete() }

        let resourceStatusInfoArray = context.originalEvent.attendees
            .filter { $0.category == .resource && $0.status != .removed }
            .map { (resource) -> Rust.ResourceStatusInfo in
                var info = Rust.ResourceStatusInfo()
                info.calendarID = resource.attendeeCalendarID
                if let resourceStrategy = resource.schemaExtraData.cd.resourceStrategy {
                    info.resourceStrategy = resourceStrategy
                }
                if let resourceRequisition = resource.schemaExtraData.cd.resourceRequisition {
                    info.resourceRequisition = resourceRequisition
                }
                if let resourceApprovalInfo = resource.schemaExtraData.cd.resourceApprovalInfo {
                    info.resourceApproval = resourceApprovalInfo
                }
                return info
            }
        let eventPB = context.event
        let startDate = Date(timeIntervalSince1970: TimeInterval(eventPB.startTime))
        let endDate = Date(timeIntervalSince1970: TimeInterval(eventPB.endTime))

        var uniqueFields = Server.CalendarEventUniqueField()
        uniqueFields.calendarID = eventPB.calendarID
        uniqueFields.originalTime = String(eventPB.originalTime)
        uniqueFields.key = eventPB.key

        /* 实现效果 - aligned with @孙强 @蒋雨（PM）
         Server 和 SDK 请求同时发出，SDK 先返回
         1. SDK 本地计算，对返回结果 unusableReasonsMap 判空，若会预订失败则直接弹窗；反之，等 Server 结论
         2. Server 服务端计算，将返回会议室状态结果 map 为是否弹窗(Bool), keep going
         3. Server 请求 500ms 超时，认为不会失败，keep going
         note - 有任何 error 一律认为不会失败
        */
        guard let calendarApi = self.calendarApi else { return Stage<Void>.complete() }
        let sdkResponse = calendarApi.getUnusableMeetingRooms(
            startDate: startDate,
            endDate: endDate,
            eventRRule: eventPB.rrule,
            eventOriginTime: eventPB.originalTime,
            resourceStatusInfoArray: resourceStatusInfoArray
        ).map { !$0.isEmpty }.filter { inValid in
            inValid // SDK 说不会失败没用，要等 server
        }.catchErrorJustReturn(false)

        let serverResponse = calendarApi.getMeetingRoomReserveStatusFromServer(
            startTime: startDate, endTime: endDate,
            eventRrule: "", startTimezone: eventPB.startTimezone,
            roomCalendarIDs: resourceStatusInfoArray.map(\.calendarID),
            eventUniqueFields: uniqueFields
        ).map { statusInformationDic in
            statusInformationDic.mapValues(\.isFree).values.contains(false)
        }.catchErrorJustReturn(false)

        let defaultWhenTimeout = Observable.deferred {
            return .just(false)
                .delay(.milliseconds(500), scheduler: MainScheduler.instance)
        }

        return Observable.merge(sdkResponse, serverResponse, defaultWhenTimeout).take(1)
            .asStage { Stage.Element.state($0) }
            .joinStage { (show, forwarder: Forwarder<Void>) in
                guard show else {
                    forwarder.complete()
                    return
                }
                let actions: [DayInstanceEditViewModel.SaveViewMessage.ActionItem] = [
                    .init(title: BundleI18n.Calendar.Calendar_Common_Cancel) {
                        DayScene.logger.info("checked by user: not change")
                        CalendarTracerV2.RoomNoReserveConfirm.traceClick {
                            $0.click("cancel").target("cal_calendar_main_view")
                        }
                        forwarder.terminate(SaveTerminal.cancelledByUser)
                    },
                    .init(title: BundleI18n.Calendar.Calendar_Common_Save, titleColor: UIColor.ud.primaryContentDefault) {
                        DayScene.logger.info("checked by user: change")
                        CalendarTracerV2.RoomNoReserveConfirm.traceClick {
                            $0.click("save").target("cal_event_full_create_view")
                        }
                        forwarder.complete()
                    }
                ]
                forwarder.deliver(.meetingRoomReservationAlert(.init(actions: actions)))
            }
    }

    // 添加会议室审批理由
    private func checkMeetingRoomApprovalReason(with context: RustEventSaveContext) -> Stage<Void> {
        let dateChanged = context.originalInstance.startTime != context.event.startTime
            || context.originalInstance.endTime != context.event.endTime
        // 时间没有变
        guard dateChanged else { return .complete() }

        // 过滤出所有审批类会议室
        let approvalMeetingRooms = context.event.attendees.filter {
            if $0.category == .resource && $0.status != .removed {
                let approvalType = $0.schemaExtraData.cd.approvalType
                let needApproval = $0.attendeeSchema.hasApprovalKey || approvalType.shouldTriggerApprovalOff(duration: context.event.endTime - context.event.startTime)
                return needApproval
            }
            return false
        }
        // 没有会议室a
        guard !approvalMeetingRooms.isEmpty else { return .complete() }

        let itemInfos = approvalMeetingRooms.map { ($0.displayName, $0.schemaExtraData.cd.approvalType.conditionalApprovalTriggerDuration) }

        let title: String
        if approvalMeetingRooms.allSatisfy({ $0.status == .needsAction }) {
            title = I18n.Calendar_Rooms_ReservedCanceledDialog
        } else if approvalMeetingRooms.allSatisfy({ $0.attendeeSchema.hasConditionalApprovalKey && $0.schemaExtraData.cd.approvalRequest == nil }) {
            title = I18n.Calendar_Approval_PopUpTitle
        } else {
            title = I18n.Calendar_Approval_DragChange
        }

        // 添加审批 reason
        let addApprovalMessage = { [weak context] (reason: String) in
            guard let context = context else { return }

            let ids = Set(approvalMeetingRooms.map(\.attendeeCalendarID))
            for i in 0..<context.event.attendees.count
                where context.event.attendees[i].category == .resource
                    && ids.contains(context.event.attendees[i].attendeeCalendarID) {
                var request = Rust.SchemaExtraData.ApprovalRequest()
                request.reason = reason
                var bizData = Rust.SchemaExtraData.BizData()
                bizData.type = .approvalRequest
                bizData.approvalRequest = request
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
            let approvalAlert = SaveViewMessage.MeetingRoomApprovalAlert(
                title: title,
                itemInfos: itemInfos,
                confirmHandler: { reason in
                    let reason = reason.trimmingCharacters(in: .whitespaces)
                    DayScene.assert(!reason.isEmpty)
                    addApprovalMessage(reason)
                    DayScene.logger.info("check reason of approval meetingRooms")
                    forwarder.complete()
                },
                cancelHandler: {
                    DayScene.logger.info("cancelledByUser")
                    forwarder.terminate(SaveTerminal.cancelledByUser)
                }
            )
            forwarder.deliver(.meetingRoomApprovalAlert(approvalAlert))
            return Disposables.create()
        }
    }

    private func checkSpan(with context: RustEventSaveContext) -> Stage<Void> {
        if context.originalEvent.rrule.isEmpty {
            context.span = .noneSpan
        } else {
            context.span = .thisEvent
        }
        return .complete()
    }

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

    private func notiAlertSubtitle(from notiBoxParams: NotificationBoxParam) -> String? {
        switch notiBoxParams.meetingRule {
        case .addAllAttendeesEnterNewMeetingGroupSubtitle, .popAllAttendeesEnterNewMeetingGroupBox:
            return BundleI18n.Calendar.Calendar_Meeting_NewMeeting
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

    private func publishNotiAlert(
        byForwarder forwarder: Forwarder<Void>,
        withParams notiBoxParams: NotificationBoxParam,
        context: RustEventSaveContext
    ) {
        guard let alertTitle = titleForNotiBoxType(notiBoxParams.notificationInfos.type) else {
            context.event.notificationType = .defaultNotificationType
            forwarder.complete()
            return
        }

        // 新通知逻辑下视图页面日程修改 统一弹窗
        if FG.rsvpNoticeOffline {
            var alert = SaveViewMessage.Alert(title: I18n.Calendar_G_ConfirmToEditPop)
            alert.actions = [
                SaveViewMessage.ActionItem(title: BundleI18n.Calendar.Calendar_Common_Cancel) {
                    forwarder.terminate(SaveTerminal.cancelledByUser)
                    CalendarTracerV2.EventCreateConfirm.traceClick {
                        $0.click("cancel")
                        $0.view_type = "save_change"
                    }
                },
                SaveViewMessage.ActionItem(title: BundleI18n.Calendar.Calendar_Common_Confirm, titleColor: .ud.primaryContentDefault) {
                    context.event.notificationType = .sendNotification
                    forwarder.complete()
                    CalendarTracerV2.EventCreateConfirm.traceClick {
                        $0.click("confirm")
                        $0.view_type = "save_change"
                    }
                }
            ]
            forwarder.deliver(.alert(alert))
            CalendarTracerV2.EventCreateConfirm.traceView { $0.view_type = "save_change" }
            return
        }

        if notiBoxParams.meetingRule == .popAllAttendeesEnterNewMeetingGroupBox {
            // 单独处理
            var alertContext = SaveViewMessage.Alert()
            alertContext.message = alertTitle
            alertContext.actions = [
                .init(title: BundleI18n.Calendar.Calendar_Common_Confirm) { [weak context] in
                    context?.event.notificationType = .defaultNotificationType
                    forwarder.complete()
                },
                .init(title: BundleI18n.Calendar.Calendar_Common_Cancel) {
                    forwarder.terminate(SaveTerminal.cancelledByUser)
                }
            ]
            forwarder.deliver(.alert(alertContext))
            return
        }
        var alert = SaveViewMessage.NotiOptionAlert(title: alertTitle)
        alert.subtitle = notiAlertSubtitle(from: notiBoxParams)
        alert.actions = [
            .init(title: BundleI18n.Calendar.Calendar_Detail_Send, titleColor: UIColor.ud.primaryContentDefault) {
                context.event.notificationType = .sendNotification
                forwarder.complete()
                EventEdit.logger.info("check notification. type: sendNotification")
            },
            .init(title: BundleI18n.Calendar.Calendar_Detail_DontSend) {
                context.event.notificationType = .noNotification
                forwarder.complete()
                EventEdit.logger.info("check notification. type: noNotification")
            },
            .init(title: BundleI18n.Calendar.Calendar_Detail_CancelEdit) {
                forwarder.terminate(SaveTerminal.cancelledByUser)
                EventEdit.logger.info("check notification. cancelEdit")
            }
        ]
        forwarder.deliver(.notiOptionAlert(alert))
    }

    private func checkNoti(with context: RustEventSaveContext) -> Stage<Void> {
        guard let calendarApi = self.calendarApi else { return Stage<Void>.complete() }
        let apiRequest = calendarApi.judgeNotificationBoxType(
            operationType: .opEditEvent,
            span: context.span,
            event: context.event,
            originalEvent: context.originalEvent,
            instanceStartTime: context.originalInstance.startTime,
            newSimpleAttendees: context.event.attendees.toEventSimpleAttendee(),
            originalSimpleAttendees: context.originalEvent.attendees.toEventSimpleAttendee()
        )
        DayScene.logger.info("check api: judgeNotificationBoxType")
        return apiRequest
            .asStage { Stage.Element.state($0) }
            .joinStage { [weak self] (params, forwarder: Forwarder<Void>) in
                DayScene.logger.info("publishNotiAlert")
                guard let self = self else {
                    forwarder.complete()
                    return
                }
                self.publishNotiAlert(byForwarder: forwarder, withParams: params, context: context)
            }
            .catchError { (error, forwarder) -> Disposable in
                // 兜底网络问题，避免保存失败
                DayScene.logger.error("judgeNotificationBoxType failed: \(error)")
                context.event.notificationType = .defaultNotificationType
                guard let terminalError = error as? SaveTerminal else {
                    assertionFailure("judgeNotificationBoxType failed: \(error)")
                    forwarder.complete()
                    return Disposables.create()
                }
                forwarder.terminate(terminalError)
                return Disposables.create()
            }
    }

    private func saveToRust(with context: RustEventSaveContext) -> Stage<Void> {
        guard let calendarApi = self.calendarApi else { return Stage<Void>.complete() }
        return calendarApi.saveEvent(
            event: context.event,
            originalEvent: context.originalEvent,
            instance: context.originalInstance,
            span: context.span,
            shareToChatId: nil,
            newSimpleAttendees: context.event.attendees.toEventSimpleAttendee(),
            originalSimpleAttendees: context.originalEvent.attendees.toEventSimpleAttendee(),
            groupSimpleMembers: nil,
            rejectedUserMap: [:],
            needRenewalReminder: context.needRenewalReminder
        )
        .asStage { _ in Stage<Void>.Element.state(()) }
    }

}
