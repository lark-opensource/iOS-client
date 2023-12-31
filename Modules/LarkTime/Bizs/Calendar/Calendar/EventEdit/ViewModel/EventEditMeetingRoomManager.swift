//
//  EventEditMeetingRoomManager.swift
//  Calendar
//
//  Created by 张威 on 2020/4/17.
//

import RxCocoa
import RxSwift
import LarkContainer
/// 日程编辑 - 会议室管理

final class EventEditMeetingRoomManager: EventEditModelManager<[CalendarMeetingRoom]> {

    @ScopedInjectedLazy var calendarAPI: CalendarRustAPI?

    // 日程会议室（包括 removed 的，已去重）
    let rxMeetingRooms: BehaviorRelay<[CalendarMeetingRoom]>

    private let initialMeetingRooms: [CalendarMeetingRoom]

    var originalEvent: EventEditModel?

    init(userResolver: UserResolver, input: EventEditInput, identifier: String) {
        let meetingRooms: [CalendarMeetingRoom]
        switch input {
        case .createWithContext(let context) where !context.meetingRooms.isEmpty:
            meetingRooms = context.meetingRooms.map(CalendarMeetingRoom.makeMeetingRoom(fromResource:buildingName:tenantId:))
            // 执行特殊的初始化逻辑 认为通过context创建的会议室是后续添加进来的 避免出现删除审批会议室时弹窗提示撤回申请
            self.rxMeetingRooms = BehaviorRelay(value: meetingRooms)
            initialMeetingRooms = []
            super.init(userResolver: userResolver, identifier: identifier, rxModel: rxMeetingRooms)
            return
        case .editFrom(let pbEvent, let pbInstance), .editWebinar(let pbEvent, let pbInstance):
            meetingRooms = pbEvent.attendees
                .filter { $0.category == .resource }
                .map { CalendarMeetingRoom(from: $0) }
            originalEvent = EventEditModel(from: pbEvent, instance: pbInstance)
        default:
            meetingRooms = []
        }
        self.initialMeetingRooms = Self.deduplicated(of: meetingRooms)
        self.rxMeetingRooms = BehaviorRelay(value: self.initialMeetingRooms)
        super.init(userResolver: userResolver, identifier: identifier, rxModel: rxMeetingRooms)
    }

    // 根据 id 去重，如果有相同的，则以最后一个为准
    private static func deduplicated(of meetingRooms: [CalendarMeetingRoom])
        -> [CalendarMeetingRoom] {
        var idSet = Set<String>()
        var deduplicated = [CalendarMeetingRoom]()
        for meetingRoom in meetingRooms.reversed() {
            if idSet.contains(meetingRoom.uniqueId) {
                continue
            }
            idSet.insert(meetingRoom.uniqueId)
            deduplicated.append(meetingRoom)
        }
        return deduplicated.reversed()
    }

    /// 所有可见会议室
    func visibleMeetingRooms() -> [CalendarMeetingRoom] {
        return rxMeetingRooms.value.filter { $0.status != .removed }
    }

    /// 第 index 个可见会议室
    func visibleMeetingRoom(at index: Int) -> CalendarMeetingRoom? {
        let meetingRooms = rxMeetingRooms.value.filter { $0.status != .removed }
        guard index >= 0 && index < meetingRooms.count else { return nil }
        return meetingRooms[index]
    }

    /// 清空会议室
    func clearMeetingRooms() {
        guard !rxMeetingRooms.value.isEmpty else { return }
        let meetingRooms: [CalendarMeetingRoom] = initialMeetingRooms.map {
            var new = $0
            new.status = .removed
            return new
        }
        rxMeetingRooms.accept(meetingRooms)
    }

    /// 新增会议室
    func addMeetingRooms(_ appendedRooms: [CalendarMeetingRoom], isAIAppend: Bool = false) {
        assert(appendedRooms.allSatisfy { $0.permission.isEditable })
        var meetingRooms = rxMeetingRooms.value
        if isAIAppend {
            meetingRooms.insert(contentsOf: appendedRooms, at: 0)
        } else {
            meetingRooms.append(contentsOf: appendedRooms)
        }
        rxMeetingRooms.accept(Self.deduplicated(of: meetingRooms))
    }
    
    /// 重置会议室
    func resetMeetingRooms(_ newMeetingRooms: [CalendarMeetingRoom]) {
        assert(newMeetingRooms.allSatisfy { $0.permission.isEditable })
        var meetingRooms = rxMeetingRooms.value
        meetingRooms = newMeetingRooms
        rxMeetingRooms.accept(Self.deduplicated(of: meetingRooms))
    }

    /// 移除自定位置的可见会议室
    func removeVisibleMeetingRoom(at index: Int) {
        let meetingRooms = visibleMeetingRooms()
        guard index >= 0 && index < meetingRooms.count else {
            assertionFailure()
            return
        }
        removeMeetingRoom(byId: meetingRooms[index].uniqueId)
    }

    func meetingRoomForm(index: Int) -> Rust.ResourceCustomization? {
        visibleMeetingRooms()[index].resourceCustomization
    }

    func updateForm(index: Int, newForm: Rust.ResourceCustomization) {
        var meetingRooms = visibleMeetingRooms()
        var targetMeetingRoom = meetingRooms[index]
        targetMeetingRoom.resourceCustomization = newForm
        targetMeetingRoom.formCompleted = true
        meetingRooms[index] = targetMeetingRoom
        rxMeetingRooms.accept(meetingRooms)
    }

    func updateIncompletedForms(IDs: [String]) {
        var meetingRooms = visibleMeetingRooms()
        IDs.forEach { id in
            if let index = meetingRooms.firstIndex(where: { $0.uniqueId == id }) {
                meetingRooms[index].formCompleted = false
            }
        }
        rxMeetingRooms.accept(meetingRooms)
    }

    /// 根据 id 移除会议室
    func removeMeetingRoom(byId uniqueId: String) {
        var meetingRooms = rxMeetingRooms.value
        if initialMeetingRooms.contains(where: { $0.uniqueId == uniqueId }) {
            for i in 0 ..< meetingRooms.count where meetingRooms[i].uniqueId == uniqueId {
                var needRemove = meetingRooms[i]
                needRemove.status = .removed
                meetingRooms[i] = needRemove
            }
        } else {
            meetingRooms = meetingRooms.filter { $0.uniqueId != uniqueId }
        }
        rxMeetingRooms.accept(meetingRooms)
    }

    /// 移除 meetingRoom 的 alert message
    func alertMessageForRemovingMeetingRoom(_ meetingRoom: CalendarMeetingRoom) -> String? {
        guard meetingRoom.hasApprovalRequest,
            meetingRoom.status != .removed,
            meetingRoom.status != .decline,
            initialMeetingRooms.contains(where: { $0.uniqueId == meetingRoom.uniqueId }) else {
            return nil
        }
        if meetingRoom.status == .accept {
            return BundleI18n.Calendar.Calendar_Approval_DeleteSucceed
        } else {
            return BundleI18n.Calendar.Calendar_Approval_DeleteInReview
        }
    }
}

extension EventEditMeetingRoomManager {

    // 获取会议室预定失败的原因
    func confirmMessagesForMeetingRoomReservation(
        startDate: Date, endDate: Date, originalTime: Int64,
        rrule: String, isAllDay: Bool, is12HourStyle: Bool, timeZone: TimeZone
    ) -> Observable<[ScrollableAlertMessage]?> {
        let meetingRooms = self.visibleMeetingRooms()
        guard !meetingRooms.isEmpty else { return .just(nil) }

        let resourceStatusInfoArray = meetingRooms.map { (resource) -> Rust.ResourceStatusInfo in
            var info = Rust.ResourceStatusInfo()
            info.calendarID = resource.uniqueId
            if let resourceStrategy = resource.resourceStrategy {
                info.resourceStrategy = resourceStrategy
            }
            if let resourceRequisition = resource.resourceRequisition {
                info.resourceRequisition = resourceRequisition
            }
            if let resourceApprovalInfo = resource.getPBModel().schemaExtraData.cd.resourceApprovalInfo {
                info.resourceApproval = resourceApprovalInfo
            }
            return info
        }

        if resourceStatusInfoArray.isEmpty { return .just(nil) }

        guard let rustApi = self.calendarAPI else { return .just(nil) }

        return rustApi.getUnusableMeetingRooms(
            startDate: startDate,
            endDate: endDate,
            eventRRule: rrule,
            eventOriginTime: originalTime,
            resourceStatusInfoArray: resourceStatusInfoArray
        ).observeOn(MainScheduler.instance)
            .subscribeOn(rustApi.requestScheduler)
            .map({ (unusableReasonMap) -> [ScrollableAlertMessage]? in
                guard !unusableReasonMap.isEmpty else { return nil }
                let alertMessages = ScrollableAlertMessage.create(
                    from: unusableReasonMap,
                    with: meetingRooms,
                    startDate: startDate,
                    endDate: endDate,
                    is12HourStyle: is12HourStyle,
                    timeZone: timeZone
                )
                return alertMessages.isEmpty ? nil : alertMessages
            })
    }

    // 获取需要重新审批的会议室
    func changedMeetingRoomsWithConfirmAlertTitle(duration: Int64) -> (meetingRooms: [CalendarMeetingRoom], alertTitle: String?) {
        let meetingRooms = self.visibleMeetingRooms()
        guard !meetingRooms.isEmpty else { return ([], nil) }
        guard nil != originalEvent else { return ([], nil) }

        let approvalMeetingRooms = meetingRooms.filter({ $0.hasApprovalRequest })

        if approvalMeetingRooms.allSatisfy({ $0.needsConditionalApproval && !$0.shouldTriggerApproval(duration: duration) }) {
            // 条件审批会议室更改时间后不再需要审批场景
            if !approvalMeetingRooms.allSatisfy({ $0.status == .accept }) {
                return (approvalMeetingRooms, I18n.Calendar_Rooms_ChangeTimeDesc)
            } else {
                return ([], nil)
            }
        }

        if approvalMeetingRooms.allSatisfy({ $0.status == .needsAction  }) {
            return (approvalMeetingRooms, I18n.Calendar_Rooms_ReservedCanceledDialog)
        } else {
            return (approvalMeetingRooms, I18n.Calendar_Approval_DragChange)
        }
    }
}
