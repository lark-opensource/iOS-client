//
//  EventDeleteAble.swift
//  Calendar
//
//  Created by heng zhu on 2019/3/12.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import RustPB
import LarkContainer
import UniverseDesignToast

private enum DeleteAlertType {
    case deleteAllRepeatEvents
    case deleteConfirm
    case deleteAndLeaveGroupAlert
}

typealias DeleteEvent = (
    _ span: CalendarEvent.Span,
    _ notification: NotificationType,
    _ isUpgradeToChatinAlert: Bool?,
    _ isUpgradeToChatBeforeAlert: Bool?) -> Void

protocol EventDeleteAble: AnyObject, EventResponsible {
    var disposeBag: DisposeBag { get }
    var calendarApi: CalendarRustAPI? { get }
    var event: Rust.Event { get }
    var controller: UIViewController { get }
}

extension EventDeleteAble {
    fileprivate typealias ProcessSignalTuples = (type: DeleteAlertType, needNotification: Bool, span: Span, showMeetingMinuteWarning: Bool, isUpgradeToChatBeforeAlert: Bool?)
    func handleDeleteEvent(deleteModel: EventDeleteProtocol,
                           deleteEvent: @escaping DeleteEvent,
                           isFromDetail: Bool) {
        let processSignal = PublishSubject<ProcessSignalTuples>()

        processSignal
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (type: DeleteAlertType, needNotification: Bool, span: Span, showMeetingMinuteWarning: Bool, isUpgradeToChatBeforeAlert: Bool? ) in
                ReciableTracer.shared.recStartDelEvent()
                let doAlertDelete = { (showDeleteMeetingSummaryWarning: Bool) in
                    if deleteModel.attendeeUnableDelete {
                        // 参与人不可退出，直接弹toast不弹窗
                        UDToast().showTips(with: I18n.Calendar_NoKeyNoRemove_Toast, on: self?.controller.view ?? UIView())
                        return
                    }

                    self?.deleteWithAlert(alertType: type,
                                          showConfirmAlert: !(deleteModel.isRecurrence || deleteModel.isException),
                                          showDeleteMeetingSummaryWarning: showDeleteMeetingSummaryWarning,
                                          isMeetingLiving: deleteModel.isMeetingLiving,
                                          doDeleteEvent: { isUpgradeToChatinAlert in
                                            deleteEvent(span, deleteModel.notificationType, isUpgradeToChatinAlert, isUpgradeToChatBeforeAlert)
                                            CalendarTracerV2.EventDeleteConfirm.traceClick {
                                                let is_group_remain = "true"
                                                let click: String
                                                switch span {
                                                case .thisEvent: click = "yes_only"
                                                case .futureEvents: click = "yes_after"
                                                case .allEvents: click = "yes_all"
                                                @unknown default: click = "yes"
                                                }
                                                $0.click(click).target("none")
                                                    .mergeEventCommonParams(commonParam: CommonParamData(event: self?.event, startTime: deleteModel.startTime))
                                                $0.is_group_remain = is_group_remain
                                                $0.delete_or_exit = deleteModel.canDeleteAll ? "delete" : "exit"
                                            }
                                          })
                    let actionSource: CalendarTracer.CalDeleteEventParam.ActionSource =
                        isFromDetail ? .eventDetail : .fullEventEditor
                    let eventType: CalendarTracer.EventType = deleteModel.isMeeting ? .meeting : .event
                    var deleteType: CalendarTracer.CalDeleteEventParam.deleteType = .today
                    switch span {
                    case .thisEvent, .noneSpan:
                        deleteType = .today
                    case .futureEvents:
                        deleteType = .future
                    case .allEvents:
                        deleteType = .detele_all
                    @unknown default:
                        break
                    }

                    let viewMode = DayViewSwitcherMode(rawValue: KVValues.calendarDayViewMode)
                    let viewType = CalendarTracer.ViewType(mode: viewMode ?? .threeDay)
                    CalendarTracer.shareInstance.calDeleteEvent(actionSource: actionSource,
                                                                eventType: eventType,
                                                                notifyEventChanged: .init(deleteModel.notificationType),
                                                                viewType: viewType,
                                                                eventId: deleteModel.eventId,
                                                                isCrossTenant: deleteModel.isCrossTenant,
                                                                deleteType: deleteType,
                                                                meetingRoomCount: deleteModel.mtgroomCount,
                                                                thirdPartyAttendeeCount: deleteModel.thirdPartyAttendeeCount)
                }
                if needNotification {
                    // 会议正在进行时，先弹二次确认弹窗，再弹是不是要通知
                    if deleteModel.isMeetingLiving {
                        self?.deleteWithAlert(alertType: type,
                                              showConfirmAlert: !(deleteModel.isRecurrence || deleteModel.isException),
                                              showDeleteMeetingSummaryWarning: showMeetingMinuteWarning,
                                              isMeetingLiving: deleteModel.isMeetingLiving,
                                              doDeleteEvent: { _ in
                            self?.deleteWithNotification(
                                span: span,
                                startTime: deleteModel.startTime,
                                showDeleteMeetingMinuteWarning: showMeetingMinuteWarning,
                                isFromDetail: isFromDetail,
                                alertDelete: {
                                    if deleteModel.attendeeUnableDelete {
                                        UDToast().showTips(with: I18n.Calendar_NoKeyNoOperate_Toast, on: self?.controller.view ?? UIView())
                                    } else {
                                        // 这里直接删除，因为前面已经弹确认弹窗了
                                        deleteEvent(span, $0, $1, isUpgradeToChatBeforeAlert)
                                    }
                                },
                                directDelete: { deleteEvent(span, $0, $1, isUpgradeToChatBeforeAlert) })
                        })
                    } else {
                        self?.deleteWithNotification(
                            span: span,
                            startTime: deleteModel.startTime,
                            showDeleteMeetingMinuteWarning: showMeetingMinuteWarning,
                            isFromDetail: isFromDetail,
                            alertDelete: { (_, _) in
                                if deleteModel.attendeeUnableDelete {
                                    UDToast().showTips(with: I18n.Calendar_NoKeyNoOperate_Toast, on: self?.controller.view ?? UIView())
                                } else {
                                    doAlertDelete(showMeetingMinuteWarning)
                                }
                            },
                            directDelete: { deleteEvent(span, $0, $1, isUpgradeToChatBeforeAlert) })
                    }
                } else {
                    doAlertDelete(showMeetingMinuteWarning)
                }
                ReciableTracer.shared.recEndDelEvent()
            }).disposed(by: disposeBag)

        let showMeetingMinuteWarning = false
        if deleteModel.isRecurrence || deleteModel.isException {
            handleDeleteRecurrenceEvent(deleteModel: deleteModel,
                                        processSignal: processSignal)
        } else {
            let result = self.deleteNormalEvent(deleteModel: deleteModel)
            processSignal.onNext((type: result.type, needNotification: result.needNotification, span: .noneSpan, showMeetingMinuteWarning: showMeetingMinuteWarning, isUpgradeToChatBeforeAlert: nil))
        }
    }

    private func handleDeleteRecurrenceEvent(deleteModel: EventDeleteProtocol,
                                             processSignal: PublishSubject<ProcessSignalTuples>) {
        if deleteModel.attendeeUnableDelete {
            // 参与人不可退出，直接弹toast不弹窗
            UDToast().showTips(with: I18n.Calendar_NoKeyNoRemove_Toast, on: self.controller.view ?? UIView())
            return
        }

        if deleteModel.organizerUnableDelete {
            EventAlert.showRecurrenceDeleteAllAlert(controller: self.controller) { () in
                let result = self.deleteRecurrenceEvent(deleteModel: deleteModel, span: .allEvents)
                processSignal.onNext((type: result.type,
                                      needNotification: result.needNotification,
                                      span: .allEvents,
                                      showMeetingMinuteWarning: false,
                                      isUpgradeToChatBeforeAlert: false))
            }
            return
        }

        if let span = deleteModel.span {
            let result = self.deleteRecurrenceEvent(deleteModel: deleteModel, span: span)
            let title: String
            let defaultSubtitle = deleteModel.isMeetingLiving ? I18n.Calendar_Event_DeleteOngoingExplain : ""
            let subTitle: String = (result.type == .deleteAndLeaveGroupAlert ? I18n.Calendar_Alert_DeleteAndLeaveGroupAlert : defaultSubtitle)
            switch span {
            case .thisEvent, .noneSpan:
                title = deleteModel.canDeleteAll ? I18n.Calendar_Event_DeleteThisEvent : I18n.Calendar_Event_RemoveThisEvent
            case .futureEvents:
                title = deleteModel.canDeleteAll ? I18n.Calendar_Event_DeleteThisAndEvent : I18n.Calendar_Event_RemoveThisAndEvent
            case .allEvents:
                title = deleteModel.canDeleteAll ? I18n.Calendar_Event_DeleteAllEvent : I18n.Calendar_Event_RemoveAllEvent
            @unknown default:
                title = ""
            }

            let confirmAction = { (_: Bool?) -> Void in
                processSignal.onNext((type: result.type,
                                      needNotification: result.needNotification,
                                      span: span,
                                      showMeetingMinuteWarning: false,
                                      isUpgradeToChatBeforeAlert: nil))
            }

            EventAlert.showDeleteEventCalendarAlert(title: title,
                                                    message: subTitle,
                                                    controller: controller,
                                                    confirmAction: confirmAction,
                                                    cancelAction: nil,
                                                    isOrganizer: deleteModel.canDeleteAll)
        } else {
            calendarApi?.getHasMeetingEvent(calendarId: deleteModel.calendarId, key: deleteModel.key)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (hasMeetingEvent) in
                    guard let `self` = self else { return }
                    let subMessage = self.getSubMessage(canDeleteAll: deleteModel.canDeleteAll,
                                                        isMeeting: hasMeetingEvent,
                                                        hasMeetingUrl: deleteModel.hasMeetingMinuteUrl,
                                                        isRecurrence: deleteModel.isRecurrence)
                    let isOrganizer = deleteModel.canDeleteAll

                    if deleteModel.isRecurrence {
                        let doDeleteRecurrence: (Span, _ isUpgradeToChatBeforeAlert: Bool?) -> Void = { [weak self] (span, _ isUpgradeToChatBeforeAlert: Bool?) in
                            guard let self = self else {
                                return
                            }

                            let result = self.deleteRecurrenceEvent(deleteModel: deleteModel, span: span)
                            if deleteModel.isMeetingLiving {
                                let title: String
                                let subTitle: String = deleteModel.isMeetingLiving ? I18n.Calendar_Event_DeleteOngoingExplain : ""
                                switch span {
                                case .thisEvent, .noneSpan:
                                    title = deleteModel.canDeleteAll ? I18n.Calendar_Event_DeleteThisEvent : I18n.Calendar_Event_RemoveThisEvent
                                case .futureEvents:
                                    title = deleteModel.canDeleteAll ? I18n.Calendar_Event_DeleteThisAndEvent : I18n.Calendar_Event_RemoveThisAndEvent
                                case .allEvents:
                                    title = deleteModel.canDeleteAll ? I18n.Calendar_Event_DeleteAllEvent : I18n.Calendar_Event_RemoveAllEvent
                                @unknown default:
                                    title = ""
                                }

                                let confirmAction = { (_: Bool?) -> Void in
                                    processSignal.onNext((type: result.type,
                                                          needNotification: result.needNotification,
                                                          span: span,
                                                          showMeetingMinuteWarning: false,
                                                          isUpgradeToChatBeforeAlert: isUpgradeToChatBeforeAlert))
                                }

                                EventAlert.showDeleteEventCalendarAlert(title: title,
                                                                        message: subTitle,
                                                                        controller: self.controller,
                                                                        confirmAction: confirmAction,
                                                                        cancelAction: nil,
                                                                        isOrganizer: deleteModel.canDeleteAll)
                            } else {
                                processSignal.onNext((type: result.type,
                                                      needNotification: result.needNotification,
                                                      span: span,
                                                      showMeetingMinuteWarning: false,
                                                      isUpgradeToChatBeforeAlert: isUpgradeToChatBeforeAlert))
                            }
                        }
                        EventAlert.showDeleteRecurrenceSheet(canDeleteAll: deleteModel.canDeleteAll,
                                                             isLocalEvent: deleteModel.isLocalEvent,
                                                             subMessage: subMessage,
                                                             controller: self.controller,
                                                             isOrganizer: isOrganizer,
                                                             update: doDeleteRecurrence)
                        CalendarTracerV2.EventDeleteConfirm.traceView {
                            $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.event, startTime: deleteModel.startTime))
                            $0.delete_or_exit = deleteModel.canDeleteAll ? "delete" : "exit"
                        }
                    } else if deleteModel.isException {
                        let scroll = UIScrollView()
                        scroll.keyboardDismissMode = .interactive
                        EventAlert.showDeleteExceptionSheet(isLocalEvent: deleteModel.isLocalEvent,
                                                            subMessage: subMessage,
                                                            controller: self.controller,
                                                            isOrganizer: isOrganizer,
                                                            calendarApi: self.calendarApi,
                                                            calendarId: deleteModel.calendarId,
                                                            key: deleteModel.key) { [weak self] (span, _ isUpgradeToChatBeforeAlert: Bool?) in
                            guard let self = self else {
                                return
                            }
                            CalendarTracerV2.EventDeleteConfirm.traceClick {
                                let is_group_remain = "true"
                                let click: String
                                switch span {
                                case .thisEvent: click = "yes_only"
                                case .futureEvents: click = "yes_after"
                                case .allEvents: click = "yes_all"
                                @unknown default: click = "yes"
                                }
                                $0.click(click).target("none")
                                $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.event, startTime: deleteModel.startTime))
                                $0.is_group_remain = is_group_remain
                                $0.delete_or_exit = deleteModel.canDeleteAll ? "delete" : "exit"
                            }
                            let result = self.deleteExceptionEvent(deleteModel: deleteModel, span: span)
                            if deleteModel.isMeetingLiving {
                                let title: String
                                let subTitle: String = deleteModel.isMeetingLiving ? I18n.Calendar_Event_DeleteOngoingExplain : ""
                                switch span {
                                case .thisEvent, .noneSpan:
                                    title = deleteModel.canDeleteAll ? I18n.Calendar_Event_DeleteThisEvent : I18n.Calendar_Event_RemoveThisEvent
                                case .futureEvents:
                                    title = deleteModel.canDeleteAll ? I18n.Calendar_Event_DeleteThisAndEvent : I18n.Calendar_Event_RemoveThisAndEvent
                                case .allEvents:
                                    title = deleteModel.canDeleteAll ? I18n.Calendar_Event_DeleteAllEvent : I18n.Calendar_Event_RemoveAllEvent
                                @unknown default:
                                    title = ""
                                }

                                let confirmAction = { (_: Bool?) -> Void in
                                    processSignal.onNext((type: result.type,
                                                          needNotification: result.needNotification,
                                                          span: span,
                                                          showMeetingMinuteWarning: false,
                                                          isUpgradeToChatBeforeAlert: isUpgradeToChatBeforeAlert))
                                }

                                EventAlert.showDeleteEventCalendarAlert(title: title,
                                                                        message: subTitle,
                                                                        controller: self.controller,
                                                                        confirmAction: confirmAction,
                                                                        cancelAction: nil,
                                                                        isOrganizer: deleteModel.canDeleteAll)
                            } else {
                                processSignal.onNext((type: result.type,
                                                      needNotification: result.needNotification,
                                                      span: span,
                                                      showMeetingMinuteWarning: false,
                                                      isUpgradeToChatBeforeAlert: isUpgradeToChatBeforeAlert))
                            }
                        }
                        CalendarTracerV2.EventDeleteConfirm.traceView {
                            $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.event, startTime: deleteModel.startTime))
                            $0.delete_or_exit = deleteModel.canDeleteAll ? "delete" : "exit"
                        }
                    }
                }).disposed(by: self.disposeBag)
        }
    }

    private func deleteExceptionEvent(deleteModel: EventDeleteProtocol, span: CalendarEvent.Span) -> (type: DeleteAlertType, needNotification: Bool) {
        let type: DeleteAlertType = .deleteConfirm

        var needNotification: Bool = false
        if deleteModel.canDeleteAll {
            needNotification = true
        }

        return (type: type, needNotification: needNotification)
    }

    private func getSubMessage(canDeleteAll: Bool,
                               isMeeting: Bool,
                               hasMeetingUrl: Bool,
                               isRecurrence: Bool) -> String? {
        var result: String = ""

        if isMeeting && !canDeleteAll {
            result += BundleI18n.Calendar.Calendar_Alert_DeleteAllAndExitMeeting
            return result
        }
        if result.isEmpty {
            return nil
        }
        return result
    }

    private func deleteNormalEvent(deleteModel: EventDeleteProtocol) -> (type: DeleteAlertType, needNotification: Bool) {
        var type: DeleteAlertType = .deleteConfirm
        var needNotification: Bool = false

        if deleteModel.canDeleteAll {
            needNotification = true
        }

        if deleteModel.isMeeting, !needNotification {
            type = .deleteAndLeaveGroupAlert
        } else {
            type = .deleteConfirm
        }
        return (type: type, needNotification: needNotification)
    }

    private func deleteRecurrenceEvent(deleteModel: EventDeleteProtocol, span: CalendarEvent.Span) -> (type: DeleteAlertType, needNotification: Bool) {

        var type: DeleteAlertType = .deleteConfirm
        var needNotification: Bool = false

        if deleteModel.canDeleteAll {
            needNotification = true
        }

        if deleteModel.isMeeting, span == .allEvents, !needNotification {
            type = .deleteAndLeaveGroupAlert
        } else {
            type = .deleteConfirm
        }

        return (type: type, needNotification: needNotification)
    }

    private func deleteWithAlert(alertType: DeleteAlertType,
                                 showConfirmAlert: Bool,
                                 showDeleteMeetingSummaryWarning: Bool,
                                 isMeetingLiving: Bool,
                                 doDeleteEvent: @escaping (_ isUpgradeToChatinAlert: Bool?) -> Void) {
        if !showConfirmAlert {
            doDeleteEvent(nil)
            return
        }
        var title: String
        var subTitle: String
        let isOrganizer = self.event.isDeletable == .all
        switch alertType {
        case .deleteAllRepeatEvents:
            title = BundleI18n.Calendar.Calendar_Meeting_DeleteEventConfirm
            subTitle = BundleI18n.Calendar.Calendar_Meeting_DeleteAllRepeatEvents
        case .deleteConfirm:
            let organizerTitle = isMeetingLiving ? BundleI18n.Calendar.Calendar_Event_DeleteOngoingPop :
                BundleI18n.Calendar.Calendar_Event_SureCancelEvent
            title = isOrganizer ? organizerTitle : BundleI18n.Calendar.Calendar_Event_DeletedEventDesc
            subTitle = ""
        case .deleteAndLeaveGroupAlert:
            title = isOrganizer ? BundleI18n.Calendar.Calendar_Event_SureCancelEvent : BundleI18n.Calendar.Calendar_Event_DeletedEventDesc
            subTitle = BundleI18n.Calendar.Calendar_Alert_DeleteAndLeaveGroupAlert
        }
        if showDeleteMeetingSummaryWarning {
            subTitle += BundleI18n.Calendar.Calendar_MeetingMinutes_PopUpWindow
        }
        EventAlert.showDeleteEventCalendarAlert(title: title,
                                                message: subTitle,
                                                controller: controller,
                                                confirmAction: doDeleteEvent,
                                                cancelAction: nil,
                                                isOrganizer: isOrganizer)
        /// 非重复性日程弹窗埋点
        CalendarTracerV2.EventDeleteConfirm.traceView {
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.event))
            $0.delete_or_exit = isOrganizer ? "delete" : "exit"
        }
    }

    private func deleteWithNotification(span: CalendarEvent.Span,
                                        startTime: Int64,
                                        showDeleteMeetingMinuteWarning: Bool,
                                        isFromDetail: Bool = true,
                                        alertDelete: @escaping (NotificationType, _ isUpgradeToChatinAlert: Bool?) -> Void,
                                        directDelete: @escaping (NotificationType, _ isUpgradeToChatinAlert: Bool?) -> Void) {
        NotificationAlert.showDeleteNotification(controller: controller,
                                                 event: event,
                                                 span: span,
                                                 instanceStartTime: startTime,
                                                 isFromDetail: isFromDetail,
                                                 notificationBoxTypeGetter: calendarApi?.judgeNotificationBoxType) { (isUpgradeToChatinAlert, notificationOption) in
                if case let .notificationType(type) = notificationOption {
                    if type == .defaultNotificationType { // 走老逻辑
                        alertDelete(type, isUpgradeToChatinAlert)
                    } else {
                        CalendarTracerV2.EventDeleteNotification.traceClick {
                            let click = (type == .sendNotification) ? "send" : "not_send"
                            $0.click(click).target("none")
                            $0.is_group_remain = "true"
                            $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.event))
                        }
                        directDelete(type, isUpgradeToChatinAlert)
                    }
                }
        }

    }

}
