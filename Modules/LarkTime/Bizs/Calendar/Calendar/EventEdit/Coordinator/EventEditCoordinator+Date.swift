//
//  EventEditCoordinator+Date.swift
//  Calendar
//
//  Created by 张威 on 2020/4/13.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import LarkUIKit
import CTFoundation
import CalendarFoundation
import UniverseDesignToast
import EventKit
import LarkAlertController

/// 编辑日程时间

extension EventEditCoordinator: EventEditDateDelegate,
    EventPickDateViewControllerDelegate {

    // MARK: EventEditDateDelegate

    func pickDate(from fromVC: EventEditViewController, selectStart: Bool) {
        let eventViewModel = fromVC.viewModel
        guard let eventModel = eventViewModel.eventModel?.rxModel?.value,
              let calendarApi = eventViewModel.calendarApi
        else {
            assertionFailure()
            return
        }
        let userAttendees: [UserAttendeeBaseDisplayInfo]
        if eventViewModel.input.isWebinarScene {
            userAttendees = EventEditAttendee.allUserAttendees(of: eventModel.speakers + eventModel.audiences)
        } else {
            userAttendees = EventEditAttendee.allUserAttendees(of: eventModel.attendees)
        }
        let viewModel = EventPickDateViewModel(
            editItem: .init(
                dateRange: (eventModel.startDate, eventModel.endDate),
                rrule: eventModel.rrule?.iCalendarString() ?? "",
                isAllDay: eventModel.isAllDay,
                timeZone: eventModel.timeZone,
                originalTime: eventModel.getPBModel().originalTime
            ),
            calendarApi: calendarApi,
            attendees: userAttendees,
            meetingRooms: eventViewModel.selectedMeetingRooms,
            originalEvent: eventViewController?.viewModel.originalEvent,
            is12HourStyle: dependency.is12HourStyle ?? .init(value: true),
            rxTimezoneDisplayType: eventViewModel.rxTimezoneDisplayType,
            startSelected: selectStart,
            isWebinarScene: eventViewModel.input.isWebinarScene
        )
        let pickDateVC = EventPickDateViewController(viewModel: viewModel, userResolver: self.userResolver)
        pickDateVC.delegate = self
        fromVC.navigationController?.pushViewController(pickDateVC, animated: true)
    }

    func arrangeDate(from fromVC: EventEditViewController) {
        let arrangeDateContext = fromVC.viewModel.contextForArrangingDate()
        let filertParam: FilterParam = (
            serverId: arrangeDateContext.eventServerId,
            key: arrangeDateContext.eventKey,
            originalTime: arrangeDateContext.eventOriginalTimestamp
        )
        
        let dataSource = ArrangementDataSource(
            attendees: arrangeDateContext.attendeeEntities,
            startTime: arrangeDateContext.startDate,
            endTime: arrangeDateContext.endDate,
            organizerCalendarId: arrangeDateContext.organizerCalendarId,
            rxTimezoneDisplayType: arrangeDateContext.rxTimezoneDisplayType,
            timeZoneId: arrangeDateContext.timeZoneId,
            filterParam: filertParam
        )
        
        if FG.freebusyOpt {
            let toVC = getArrangementController(dataSource)
            toVC.didSelectedTimes = { [weak fromVC] (startDate, endDate, timeZoneId) in
                guard let fromVC = fromVC,
                      let isAllDay = fromVC.viewModel.eventModel?.rxModel?.value.isAllDay else { return }
                let timeZone = TimeZone(identifier: timeZoneId) ?? TimeZone.current
                fromVC.viewModel.updateDateComponents(
                    startDate: startDate,
                    endDate: endDate,
                    isAllDay: isAllDay,
                    timeZone: timeZone
                )
            }
            toVC.modalPresentationStyle = .formSheet
            fromVC.present(toVC, animated: true)
        } else {
            let toVC = getOldArrangementController(
                attendees: arrangeDateContext.attendeeEntities,
                startTime: arrangeDateContext.startDate,
                endTime: arrangeDateContext.endDate,
                organizerId: arrangeDateContext.organizerCalendarId,
                filterParam: filertParam,
                rxTimezoneDisplayType: arrangeDateContext.rxTimezoneDisplayType,
                timeZoneId: arrangeDateContext.timeZoneId
            )
            toVC.didSelectedTimes = { [weak fromVC] (startDate, endDate, timeZoneId) in
                guard let fromVC = fromVC,
                      let isAllDay = fromVC.viewModel.eventModel?.rxModel?.value.isAllDay else { return }
                let timeZone = TimeZone(identifier: timeZoneId) ?? TimeZone.current
                fromVC.viewModel.updateDateComponents(
                    startDate: startDate,
                    endDate: endDate,
                    isAllDay: isAllDay,
                    timeZone: timeZone
                )
            }
            toVC.modalPresentationStyle = .formSheet
            fromVC.present(toVC, animated: true)
        }
    }

    func getOldArrangementController(attendees: [UserAttendeeBaseDisplayInfo],
                                  startTime: Date,
                                  endTime: Date,
                                  organizerId: String,
                                  filterParam: FilterParam,
                                  rxTimezoneDisplayType: BehaviorRelay<TimezoneDisplayType>,
                                  timeZoneId: String = TimeZone.current.identifier) -> OldArrangementController {

        let arrangementLoader = ArrangementLoader(
            userResolver: self.userResolver,
            organizerCalendarId: organizerId,
            filterParam: filterParam
        )
        let controller = OldArrangementController(
            userResolver: self.userResolver,
            dataLoader: arrangementLoader,
            attendees: attendees,
            startTime: startTime,
            endTime: endTime,
            is12HourStyle: self.calendarDependency?.is12HourStyle.value ?? true,
            currentUserCalendarId: self.dependency.calendarManager?.primaryCalendarID ?? "",
            organizerCalendarId: organizerId,
            rxTimezoneDisplayType: rxTimezoneDisplayType,
            timeZoneId: timeZoneId
        )
        return controller
    }

    
    func getArrangementController(_ model: ArrangementDataSource) -> ArrangementController {
        let vm = ArrangementViewModel(userResolver: self.userResolver,
                                      dataSource: model)
        let controller = ArrangementController(viewModel: vm)
        return controller
    }
    // MARK: EventPickDateViewControllerDelegate

    func selectTimeZone(from fromVC: EventPickDateViewController, with anchorDate: Date) {
        EventEdit.logger.info("selectTimeZone \(fromVC.viewModel.rxTimeZoneModel.value)")
        guard let service = dependency.timeZoneSelectService else { return }
        let toVC = getPopupTimeZoneSelectViewController(
            with: service,
            selectedTimeZone: fromVC.viewModel.rxTimeZoneModel,
            anchorDate: anchorDate,
            onTimeZoneSelect: { [weak fromVC] timeZone in
                fromVC?.viewModel.updateTimeZone(timeZone)
            }
        )
        fromVC.present(toVC, animated: true)
    }

    func didCancelEdit(from viewController: EventPickDateViewController) {
        let viewModel = viewController.viewModel
        let model = self.eventViewController?.viewModel.eventModel?.rxModel?.value
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("save_time")
            $0.is_time_alias = "false"
            $0.event_type = viewModel.isWebinarScene ? "webinar" : "normal"
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: model?.getPBModel(), startTime: Int64(model?.startDate.timeIntervalSince1970 ?? 0)))
        }
        viewController.navigationController?.popViewController(animated: true)
    }

    typealias MeetingRoomMessage = EventPickDateViewController.MeetingRoomMessage
    private func confirmMessageForMeetingRoomReservation(eventPickDateViewController vc: EventPickDateViewController) -> RxStage<Void, MeetingRoomMessage> {
        return .create { [weak self] forwarder in
            let editItem = vc.viewModel.editItem
            self?.eventViewController?.viewModel.meetingRoomModel?.confirmMessagesForMeetingRoomReservation(
                startDate: editItem.dateRange.start,
                endDate: editItem.dateRange.end,
                originalTime: editItem.originalTime,
                rrule: editItem.rrule,
                isAllDay: vc.viewModel.rxIsAllDay.value,
                is12HourStyle: vc.viewModel.rxIs12HourStyle.value,
                timeZone: vc.viewModel.rxTimeZone.value)
                .subscribe(onNext: { alertMessages in
                    guard let alertMessages = alertMessages else {
                        forwarder.complete()
                        return
                    }
                    let reservationAlertContext = EventPickDateViewController.MeetingRoomMessage.ReservaionAlertContext(
                        contents: alertMessages,
                        confirmHandler: { forwarder.complete() },
                        cancelHandler: { forwarder.terminate(EventPickDateViewController.MeetingRoomError.undo) })
                    forwarder.deliver(.reservationAlert(reservationAlertContext))
                }).disposed(by: vc.disposeBag)
            return Disposables.create()
        }
    }

    private func changedMeetingRoomsWithConfirmAlertTitle(duration: Int64) -> RxStage<Void, MeetingRoomMessage> {
        let (alertMeetingRooms, alertTitle) = self.eventViewController?.viewModel.meetingRoomModel?.changedMeetingRoomsWithConfirmAlertTitle(duration: duration) ?? ([], nil)
        guard !alertMeetingRooms.isEmpty else { return .complete() }
        return .create { forwarder in
            let actions: [DayInstanceEditViewModel.SaveViewMessage.ActionItem] = [
                .init(title: BundleI18n.Calendar.Calendar_Common_Cancel) {
                    DayScene.logger.info("reduce condition meeting room cancelled")
                    forwarder.terminate(EventPickDateViewController.MeetingRoomError.undo)
                },
                .init(title: BundleI18n.Calendar.Calendar_Common_Confirm, titleColor: UIColor.ud.primaryContentDefault) {
                    DayScene.logger.info("reduce condition meeting room confirmed")
                    forwarder.complete()
                }
            ]
            forwarder.deliver(.approvalAlert(meetingRooms: alertMeetingRooms, alertTitle: alertTitle, actions: actions))
            return Disposables.create()
        }
    }

    private func checkRoomRemainedUsageToast(eventStart: Int64, duration: Int64) {
        guard let rooms = self.eventViewController?.viewModel.meetingRoomModel?.rxMeetingRooms.value,
              let overUsageLimit = self.eventViewController?.viewModel.rxOverUsageLimit.value,
              let view = self.eventViewController?.view else { return }
        /*
         审批会议室不会消耗额度，故此处 allSatisfy 并不会 toast 提示
         note - 但 额度已满时，审批会议室并无法添加（所有添加会议室入口均被禁），不是 bug - by PM @蒋雨
         */
        let allNeedsApprove = rooms.allSatisfy { $0.needsApproval || $0.shouldTriggerApproval(duration: duration) }

        let isRecurEvent =  self.eventViewController?.viewModel.eventModel?.rxModel?.value.isRecurEvent ?? false
        if !allNeedsApprove {
            let currentUID = self.userResolver.userID
            // 修改到临近时间，需要消耗用量-惩罚机制
            var countRefundTime = 4 * 3600 // 默认4h

            if let tenantSetting = SettingService.shared().tenantSetting, tenantSetting.hasResourceSubscribeCondition {
                countRefundTime = Int(tenantSetting.resourceSubscribeCondition.countRefundTime)
            }

            let range = 0..<Double(countRefundTime)
            let lessRefundTime = range ~= Double(eventStart) - Date().timeIntervalSince1970
            // 只要有不是自己的，就会重新预订并消耗用量
            let reserverChanged = !rooms.allSatisfy { $0.getPBModel().resource.bookerID == currentUID }

            let needPayOff = lessRefundTime || reserverChanged
            if needPayOff && !overUsageLimit && !isRecurEvent {
                UDToast.showTips(with: BundleI18n.Calendar.Calendar_MeetingView_EditHasQuotaNote, on: view)
            }
        }
    }

    func didFinishEdit(from viewController: EventPickDateViewController) {
        let editItem = viewController.viewModel.editItem
        let duration = Int64(editItem.dateRange.end.timeIntervalSince(editItem.dateRange.start))
        let rxStart = RxStage<Void, MeetingRoomMessage>.complete()
        rxStart
            .joinStage { [weak self] _ -> RxStage<Void, MeetingRoomMessage> in
                self?.confirmMessageForMeetingRoomReservation(eventPickDateViewController: viewController) ?? .empty()
            }
            .joinStage { [weak self] _ -> RxStage<Void, MeetingRoomMessage> in
                guard editItem.rrule.isEmpty else {
                    return .complete()
                }
                return self?.changedMeetingRoomsWithConfirmAlertTitle(duration: duration) ?? .empty()
            }
            .joinStage { [weak self] _ -> RxStage<Void, MeetingRoomMessage> in
                guard let self = self else { return .empty() }
                self.eventViewController?.viewModel.updateDateComponents(
                    startDate: editItem.dateRange.start,
                    endDate: editItem.dateRange.end,
                    isAllDay: editItem.isAllDay,
                    timeZone: editItem.timeZone
                )
                viewController.navigationController?.popViewController(animated: true)
                if let eventStart = self.eventViewController?.event.startTime {
                    self.checkRoomRemainedUsageToast(eventStart: eventStart, duration: duration)
                }
                return .complete()
            }.subscribe(onMessage: { message in
                viewController.handleMeetingRoomMessage(message)
            }, onTerminate: { error in
                guard let error = error as? EventPickDateViewController.MeetingRoomError else { return }
                viewController.handleMeetingRoomError(error)
            }).disposed(by: viewController.disposeBag)
    }

}

extension EventPickDateViewController {

    enum MeetingRoomMessage {
        struct ReservaionAlertContext {
            var contents: [ScrollableAlertMessage]
            var confirmHandler: AlertActionHandler?
            var cancelHandler: AlertActionHandler?
        }
        case reservationAlert(ReservaionAlertContext)
        case approvalAlert(meetingRooms: [CalendarMeetingRoom], alertTitle: String?, actions: [DayInstanceEditViewModel.SaveViewMessage.ActionItem])
    }

    enum MeetingRoomError: Error {
        case undo
        case cancel
    }

    func handleMeetingRoomMessage(_ message: MeetingRoomMessage) {
        switch message {
        case .reservationAlert(let context):
            self.showConfirmAlertScrollView(
                    title: BundleI18n.Calendar.Calendar_Edit_ChangeReserveTimeTitle,
                    subtitle: BundleI18n.Calendar.Calendar_Edit_ChangeReserveTimeContent,
                    contents: context.contents,
                    confirmText: BundleI18n.Calendar.Calendar_Common_Change,
                    cancelText: BundleI18n.Calendar.Calendar_Common_Cancel,
                    confirmHandler: context.confirmHandler,
                    cancelHandler: context.cancelHandler)
        case .approvalAlert(let alertMeetingRooms, let alertTitle, let actions):
            let alert = LarkAlertController.generalMeetingRoomAlert(
                title: alertTitle ?? BundleI18n.Calendar.Calendar_Rooms_ChangeTimeDesc,
                itemInfos: alertMeetingRooms.map {
                    ($0.getPBModel().displayName, $0.getPBModel().schemaExtraData.cd.approvalType.conditionalApprovalTriggerDuration)
                })
            actions.forEach { item in
                alert.addButton(text: item.title, color: item.titleColor, dismissCompletion: {
                    item.handler()
                })
            }
            self.present(alert, animated: true)
        }
    }

    func handleMeetingRoomError(_ error: MeetingRoomError) {
        switch error {
        case .undo:
            self.didUndoEdit()
        case .cancel:
            // Do nothing
            return
        }
    }
}
