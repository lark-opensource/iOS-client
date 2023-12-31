//
//  EventEditCoordinator+MeetingRoom.swift
//  Calendar
//
//  Created by 张威 on 2020/4/13.
//

import Foundation
import UniverseDesignToast

/// 编辑日程会议室

// MARK: EventEditMeetingRoomDelegate

extension EventEditCoordinator: EventEditMeetingRoomDelegate {

    func selectMeetingRoom(from fromVC: EventEditViewController) {
        guard let navigationController = navigationController,
              let eventModel = fromVC.viewModel.eventModel?.rxModel?.value else {
            assertionFailure()
            return
        }
        let selectedMeetingoms = eventModel.meetingRooms.filter { $0.status != .removed }
        let span = fromVC.viewModel.eventModel?.rxModel?.value.span ?? .noneSpan
        if let toast = checkMeetingRoomAddable(
            hasMeetingRoom: !selectedMeetingoms.isEmpty,
            isRepeatEvent: span != .noneSpan || eventModel.rrule != nil,
            overUsageLimit: eventViewController?.viewModel.rxOverUsageLimit.value ?? false) {
            UDToast.showTips(with: toast, on: fromVC.view)
            return
        }

        let eventConditions = { (event: EventEditModel) -> (approveDisabled: Bool, formDisabled: Bool) in
            let approveDisabled = !event.rrule.isNil
            let formDisabled = [.thisEvent, .futureEvents].contains(event.span) && event.getPBModel().originalTime == 0
            return (approveDisabled, formDisabled)
        }
        let meetingRoomWithFormUnAvailableReason = { (event: EventEditModel) -> String in
            switch event.span {
            case .thisEvent:
                return I18n.Calendar_EditThisNoReserveForm_Toast
            case .futureEvents:
                return I18n.Calendar_EditLaterNoReserveForm_Toast
            @unknown default:
                return ""
            }
        }

        let meetingRoomCoordinator = EventMeetingRoomCoordinator(
            userResolver: self.userResolver,
            navigationController: navigationController,
            dependency: .init(
                eventModel: eventModel,
                selectedMeetingRooms: selectedMeetingoms,
                startDate: eventModel.startDate,
                endDate: eventModel.endDate,
                timeZoneId: eventModel.timeZone.identifier,
                rrule: eventModel.rrule,
                eventConditions: eventConditions(eventModel),
                meetingRoomWithFormUnAvailableReason: meetingRoomWithFormUnAvailableReason(eventModel),
                meetingRoomApi: dependency.calendarApi,
                tenantId: dependency.currentUser?.tenantId ?? "",
                endDateEditable: fromVC.isEndDateEditable
            ))
        meetingRoomCoordinator.editType = fromVC.editType
        meetingRoomCoordinator.delegate = self
        children[.meetingRoom] = meetingRoomCoordinator
        meetingRoomCoordinator.start()
    }

    // MARK: Check toast before adding meetingRoom
    private func checkMeetingRoomAddable(hasMeetingRoom: Bool, isRepeatEvent: Bool, overUsageLimit: Bool) -> String? {
        let resourceCondition = SettingService.shared().tenantSetting?.resourceSubscribeCondition ?? SettingService.defaultTenantSetting.resourceSubscribeCondition
        /// Hints sorted by priority.
        var toast: String?
        // 重复性不支持预定
        if resourceCondition.forbidInRecursiveEvent && isRepeatEvent {
            toast = BundleI18n.Calendar.Calendar_MeetingView_RecurringNoReserve
            CalendarTracerV2.FullCreateRoomsReservePopView.traceView { $0.content = "rrule_event_reason" }
            return toast
        }

        // 仅支持预定一个会议室
        if resourceCondition.oneMostPerEvent && hasMeetingRoom {
            toast = BundleI18n.Calendar.Calendar_MeetingView_OnlyOneCanReserve
            CalendarTracerV2.FullCreateRoomsReservePopView.traceView { $0.content = "only_one_room" }
            return toast
        }

        // 用量超限
        if resourceCondition.limitPerDay != 0 && overUsageLimit {
            toast = BundleI18n.Calendar.Calendar_MeetingView_MaxReserveOnePersonPerDay(number: resourceCondition.limitPerDay)
            CalendarTracerV2.FullCreateRoomsReservePopView.traceView { $0.content = "limit_reached" }
        }
        return toast
    }
}

// MARK: EventMeetingRoomCoordinatorDelegate

extension EventEditCoordinator: EventMeetingRoomCoordinatorDelegate {

    /// 选中某些会议室
    func coordinator(
        _ coordinator: EventMeetingRoomCoordinator,
        didSelectMeetingRooms meetingRooms: [CalendarMeetingRoom]
    ) {
        guard let eventViewModel = eventViewController?.viewModel else {
            assertionFailure()
            return
        }
        eventViewModel.addMeetingRooms(meetingRooms)
    }

    // 取消会议室可能需要的确认弹窗
    func coordinator(
        _ coordinator: EventMeetingRoomCoordinator,
        confirmAlertTextsForDeselectingMeetingRoom meetingRoom: CalendarMeetingRoom
    ) -> EventEditConfirmAlertTexts? {
        return eventViewController?.viewModel.confirmAlertTextsForDeletingMeetingRoom(meetingRoom)
    }

    /// 取消某个会议室
    func coordinator(
        _ coordinator: EventMeetingRoomCoordinator,
        didDeselectMeetingRoom meetingRoom: CalendarMeetingRoom
    ) {
        guard let eventViewModel = eventViewController?.viewModel else {
            assertionFailure()
            return
        }
        _ = eventViewModel.deleteMeetingRoom(byId: meetingRoom.uniqueId)
    }

    func coordinatorDidFinish(_ coordinator: EventMeetingRoomCoordinator) {
        children.removeValue(forKey: .meetingRoom)
    }
    
    // 一键调整被点击
    func autoJustTimeTapped(needRenewalReminder: Bool, rrule: EventRecurrenceRule?) {
        guard let eventViewModel = eventViewController?.viewModel else {
            assertionFailure()
            return
        }
        eventViewModel.autoJustTimeTapped(needRenewalReminder: needRenewalReminder, rrule: rrule)
    }

}
