//
//  EventDetailNavigationBarViewModel+Delete.swift
//  Calendar
//
//  Created by Rico on 2021/4/13.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import EventKit
import RxRelay
import AppReciableSDK
import CalendarFoundation

extension EventDetailNavigationBarViewModel {
    func delete() {

        CalendarTracerV2.EventMore.traceClick {
            $0
                .click("delete")
                .target(.none)
                .mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
        }

        CalendarTracerV2.EventDetail.traceClick {
            $0.click("delete_event").target(.none)
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
            $0.event_type = model.isWebinar ? "webinar" : "normal"
        }

        if let schemaLink = model.event?.dt.schemaLink(key: .delete) {
            rxRoute.accept(.url(url: schemaLink))
            return
        }

        let deleteModel = getDeleteModel()
        self.handleDeleteEvent(deleteModel: deleteModel,
                               deleteEvent: { [weak self] (span,
                                                           notification,
                                                           isUpgradeToChatinAlert,
                                                           isUpgradeToChatBeforeAlert) in
                                EventDetail.logInfo("handle delete. options: [span: \(span), notification: \(notification), isUpgradeToChatinAlert: \(String(describing: isUpgradeToChatinAlert)), isUpgradeToChatBeforeAlert: \(String(describing: isUpgradeToChatBeforeAlert))")
                                self?.removeCallBack(span, notification, isUpgradeToChatinAlert, isUpgradeToChatBeforeAlert)
                               }, isFromDetail: true)
    }
}

// MARK: - 使用重构前删除逻辑

// 删除流程过于复杂，重构暂时使用老删除逻辑，之后和编辑页逻辑一起重构
extension EventDetailNavigationBarViewModel: EventDeleteAble {

    var controller: UIViewController {
        guard let controller = self.getControllerForDelete?() else {
            assertionFailure("EventDetailNavigationComponent's Controller is nil")
            return UIViewController()
        }
        return controller
    }

    var event: Rust.Event {
        guard let event = model.event else {
            assertionFailure()
            EventDetail.logError("event for delete cannot found")
            return Rust.Event()
        }
        return event
    }
}

extension EventDetailNavigationBarViewModel {

    /// 兼容旧逻辑，使用对PB的包装
    func makeDeleteEntities() -> (event: CalendarEventEntity, instance: CalendarEventInstanceEntity) {
        switch model {
        case .local(let ekEvent):
            let eventEntity = CalendarEventEntityFromLocal(event: ekEvent)
            let instanceEntity = CalendarEventInstanceEntityFromLocal(event: ekEvent)
            return (eventEntity, instanceEntity)
        case .pb(let pbEvent, let pbInstance):
            let eventEntity = PBCalendarEventEntity(pb: pbEvent)
            let instanceEntity = CalendarEventInstanceEntityFromPB(withInstance: pbInstance)
            return (eventEntity, instanceEntity)
        case .meetingRoomLimit:
            assertionFailure("会议室无权限日程不能走到这个逻辑")
            let event = EKEvent()
            return (CalendarEventEntityFromLocal(event: event), CalendarEventInstanceEntityFromLocal(event: event))
        }
    }

    func getDeleteModel() -> EventDeleteProtocol {
        let entities = makeDeleteEntities()
        let isMeetingLiving = context.state.isVideoMeetingLiving
        return EventDeleteModel.eventDeleteModel(
            event: entities.event,
            instance: entities.instance,
            isException: entities.event.isException(),
            isMeeting: entities.event.type == .meeting,
            isMeetingLiving: isMeetingLiving
        )
    }
}

extension EventDetailNavigationBarViewModel {
    func removeCallBack(_ span: CalendarEvent.Span, _ notificationType: NotificationType, _ isUpgradeToChatinAlert: Bool?, _ isUpgradeToChatBeforeAlert: Bool?) {
        let instance = makeDeleteEntities().instance
        self.removeEvent(instance: instance,
                         event: makeDeleteEntities().event,
                         span: span,
                         isUpgradeToChatinAlert: isUpgradeToChatinAlert,
                         isUpgradeToChatBeforeAlert: isUpgradeToChatBeforeAlert,
                         canDeleteAll: model.canDeleteAll,
                         notificationType: notificationType)
    }

    private func removeEvent(
        instance: CalendarEventInstanceEntity,
        event: CalendarEventEntity,
        span: CalendarEvent.Span,
        isUpgradeToChatinAlert: Bool? = nil,
        isUpgradeToChatBeforeAlert: Bool? = nil,
        canDeleteAll: Bool,
        notificationType: NotificationType
    ) {
        if isUpgradeToChatBeforeAlert ?? (isUpgradeToChatinAlert ?? true) {
            CalendarTracer.shareInstance.calTransformWhenRemoveEvent(isWebinar: event.category == .webinar)
        }

        if canDeleteAll {//创建者删除
            var event = event
            event.notificationType = notificationType
            let dissolveMeeting = !(isUpgradeToChatBeforeAlert ?? (isUpgradeToChatinAlert ?? true))
            self.deleteEvent(
                span: span,
                event: event,
                instance: instance,
                dissolveMeeting: dissolveMeeting
            )
        } else {
            CalendarMonitorUtil.startExitEventTime(calEventID: instance.eventServerId, originalTime: instance.originalTime, uid: instance.key)
            self.deleteInvitedEvent(
                span: span,
                event: event,
                instance: instance
            )
        }
    }

    private func deleteEvent(
        span: CalendarEvent.Span,
        event: CalendarEventEntity,
        instance: CalendarEventInstanceEntity,
        dissolveMeeting: Bool
    ) {
        EventDetail.logDebug("delete event start")
        if !dissolveMeeting {
            CalendarTracer.shareInstance.calTransformWhenRemoveEvent(isWebinar: event.category == .webinar)
        }
        monitor.track(.start(.delete))
        calendarApi?.removeEvent(
            event,
            instance: instance,
            span: span,
            scenarioToken: .deleteEventOnEventDetailView,
            dissolveMeeting: dissolveMeeting
        )
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    guard let self = self else { return }
                    EventDetail.logInfo("delete event success")
                    self.monitor.track(.success(.delete, self.model, [.deleteType: "remove", .span: span]))
                    self.removeEventSuccess(event)
                },
                onError: { [weak self] error in
                    guard let self = self else { return }
                    EventDetail.logInfo("delete event error: \(error)")
                    self.monitor.track(.failure(.delete, self.model, error, [.deleteType: "remove", .span: span]))
                    self.rxToast.accept(.failure(error.getTitle() ?? I18n.Calendar_Common_DeleteFailedTip))
                    ReciableTracer.shared.recTracerError(errorType: ErrorType.Unknown,
                                                         scene: Scene.CalEventDetail,
                                                         event: .deleteEvent,
                                                         userAction: "cal_delete_event",
                                                         page: "cal_event_detail",
                                                         errorCode: Int(error.errorCode() ?? 0),
                                                         errorMessage: error.getMessage() ?? "")
                }
            )
        .disposed(by: self.disposeBag)
    }

    private func deleteInvitedEvent(
        span: CalendarEvent.Span,
        event: CalendarEventEntity,
        instance: CalendarEventInstanceEntity
    ) {
        EventDetail.logDebug("delete invited start")
        monitor.track(.start(.delete))
        self.responseToEvent(
            withstatus: .removed,
            span: span,
            event: event,
            instance: instance,
            calendarApi: calendarApi,
            messageId: nil
        )
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] (isRemoved, _, errorCodes) in
                    guard let self = self else { return }
                    EventDetail.logInfo("delete invited on next: \(isRemoved)")
                    if isRemoved {
                        self.removeEventSuccess(event)
                        self.monitor.track(.success(.delete, self.model, [.deleteType: "exit", .span: span]))
                        CalendarMonitorUtil.endExitEventTime(isSuccess: true, errorCode: "")
                    } else {
                        self.rxToast.accept(.failure(I18n.Calendar_Common_DeleteFailedTip))
                        CalendarMonitorUtil.endExitEventTime(isSuccess: false, errorCode: "\(errorCodes.description)")
                    }
                    if errorCodes.contains(where: { ErrorType(rawValue: $0) == .invalidCipherFailedToSendMessage }) {
                        self.rxToast.accept(.failure(I18n.Calendar_KeyNoToast_CannoReply_Pop))
                    }
                },
                onError: { [weak self] error in
                    if let self = self {
                        EventDetail.logInfo("delete invite event error: \(error)")
                        self.monitor.track(.failure(.delete, self.model, error, [.deleteType: "exit", .span: span]))
                        self.rxToast.accept(.failure(error.getTitle() ?? I18n.Calendar_Common_DeleteFailedTip))
                        ReciableTracer.shared.recTracerError(errorType: ErrorType.Unknown,
                                                             scene: Scene.CalEventDetail,
                                                             event: .deleteEvent,
                                                             userAction: "cal_delete_event",
                                                             page: "cal_event_detail",
                                                             errorCode: Int(error.errorCode() ?? 0),
                                                             errorMessage: error.getMessage() ?? "")
                        CalendarMonitorUtil.endExitEventTime(isSuccess: false, errorCode: "\(error.errorCode())")
                    }
                }
            )
            .disposed(by: self.disposeBag)
    }

    private func removeEventSuccess(_ event: CalendarEventEntity) {
        EventDetail.logInfo("remove Event Success")
        rxRoute.accept(.dismiss)
        localRefreshService?.rxEventNeedRefresh.onNext(())
        localRefreshService?.rxCalendarDetailDismiss.onNext(())
    }
}
