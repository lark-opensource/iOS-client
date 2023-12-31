//
//  EventDetailBottomActionViewModel+RSVP.swift
//  Calendar
//
//  Created by Rico on 2021/10/19.
//

import Foundation
import RxRelay
import RxSwift
import AppReciableSDK
import CalendarFoundation

extension EventDetailBottomActionViewModel {

    func tapStatus(_ status: CalendarEventAttendee.Status) {

        let confirm = { [weak self] (span: CalendarEventEntity.Span) -> Void in
            self?.changeTo(status: status, span: span)
        }

        if model.isRecurrence {
            route.send(.replyEventSheet(status: status, spanConfirm: confirm))
        } else if model.isException {
            // 例外日程需判断是否在重复性序列里，在则提供 span 选择，不在则默认 span = thisEvent
            calendarApi?.getEvent(calendarId: model.calendarId,
                                 key: model.key,
                                 originalTime: 0).map({ $0.selfAttendeeStatus != .removed })
                .catchErrorJustReturn(false)
                .subscribe(onNext: { [weak self] isExist in
                    guard let self = self else { return }
                    if !isExist {
                        self.changeTo(status: status, span: .thisEvent)
                        return
                    }
                    self.route.send(.replyEventSheet(status: status, spanConfirm: confirm))
                }).disposed(by: disposeBag)
        } else {
            self.changeTo(status: status, span: .noneSpan)
        }

        CalendarTracerV2.EventDetail.traceClick {
            let click: String
            switch status {
            case .accept: click = "accept"
            case .decline: click = "reject"
            case .tentative: click = "not_determined"
            @unknown default: click = "none"
            }
            $0
                .click(click)
                .target("none")
            $0.event_type = model.isWebinar ? "webinar" : "normal"
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
        }
    }

    private func changeTo(status: CalendarEventAttendee.Status,
                          span: CalendarEvent.Span) {
        EventDetail.logInfo("rsvp attempt to change: \(status)")
        ReciableTracer.shared.recStartDetailRSVP()
        monitor.track(.start(.rsvp))
        rxToast.accept(.loading(info: I18n.Calendar_Toast_ReplyingMobile, disableUserInteraction: true))

        /// 只有当前 span 为 thisEvent 且 originalTime 为 0 才能确定该日程是重复性日程中的例外日程
        /// 只有例外日程才需要更改 originalTime 否则传回原值
        let originalTime = (span == .thisEvent && model.originalTime == 0) ? model.startTime : model.originalTime
        CalendarMonitorUtil.startTrackRsvpEventDetailTime(calEventId: model.event?.serverID, originalTime: originalTime, uid: model.key)

        calendarApi?.replyCalendarEventInvitationWithSpan(calendarId: model.calendarId,
                                                         key: model.key,
                                                         originalTime: originalTime,
                                                         comment: "",
                                                         inviteOperatorID: "",
                                                         replyStatus: status,
                                                         span: span,
                                                         messageId: nil)
            .map { (entity, _, errorCodes) -> (Bool, EventDetail.Event, [Int32]) in
                return (entity.selfAttendeeStatus == status ? true : false, entity.getPBModel(), errorCodes)
            }.subscribe { [weak self] result, event, errorCodes in
                guard let self = self else { return }
                EventDetail.logInfo("rsvp api success")
                ReciableTracer.shared.recEndDetailRSVP()
                if result {
                    EventDetail.logInfo("rsvp change success")
                    self.monitor.track(.success(.rsvp, self.model, [.toRSVP: status, .span: span]))
                    self.refreshHandle.refresh(newEvent: event)
                    self.rxToast.accept(.remove)
                    self.rxToast.accept(.success(status.rsvpSelectedToast))
                    self.localRefresh?.rxEventNeedRefresh.onNext(())
                } else {
                    EventDetail.logError("rsvp change failed")
                    self.rxToast.accept(.remove)
                    self.rxToast.accept(.failure(I18n.Calendar_Detail_ResponseFailed))
                }
                if errorCodes.contains(where: { ErrorType(rawValue: $0) == .invalidCipherFailedToSendMessage }) {
                    self.rxToast.accept(.failure(I18n.Calendar_KeyNoToast_CannoReply_Pop))
                }
                CalendarMonitorUtil.endTrackRsvpEventDetailTime()
            } onError: { [weak self] error in
                guard let self = self else { return }
                EventDetail.logError("rsvp api error: \(error)")
                self.monitor.track(.failure(.rsvp, self.model, error, [.toRSVP: status, .span: span]))
                self.rxToast.accept(.failure(error.getTitle() ?? I18n.Calendar_Detail_ResponseFailed))
                ReciableTracer.shared.recTracerError(errorType: ErrorType.Network,
                                                     scene: Scene.CalEventDetail,
                                                     event: .replyRsvp,
                                                     userAction: "cal_reply_rsvp",
                                                     page: "cal_event_detail",
                                                     errorCode: Int(error.errorCode() ?? 0),
                                                     errorMessage: error.getMessage() ?? "")
            }.disposed(by: disposeBag)
    }

}
