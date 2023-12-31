//
//  EventEditViewModel+WebinarAttendee.swift
//  Calendar
//
//  Created by ByteDance on 2023/1/16.
//

import Foundation
import CalendarFoundation

// MARK: Webinar Attendee
extension EventEditViewModel {

    var webinarAttendeeModel: WebinarEventEditAttendeeManager? {
        self.models[.webinarAttendees] as? WebinarEventEditAttendeeManager
    }

    func makeWebinarAttendeeModel() -> WebinarEventEditAttendeeManager {
        let webinarModel = WebinarEventEditAttendeeManager(
            identifier: EventEditModelType.webinarAttendees.rawValue, input: input, userResolver: self.userResolver)
        webinarModel.eventDelegate = self
        webinarModel.relyModel = [EventEditModelType.calendar.rawValue]
        webinarModel.initMethod = { [weak self, weak webinarModel] observer in
            guard let self = self, let rustAPI = self.calendarApi, let attendee_model = webinarModel else {
                assertionFailureLog()
                return
            }
            attendee_model.startInit(with: self.calendarModel?.rxModel?.value.current)
            if case let .editWebinar(pbEvent, _) = self.input {
                // 如果是编辑日程，需要判断日程参与者人数是否被管控
                rustAPI.getEventApprovalStatus(key: pbEvent.key)
                    .subscribe(onNext: {
                        attendee_model.attendeeMaxCountControlled = !$0
                        observer.onCompleted()
                    }).disposed(by: self.disposeBag)
            } else {
                observer.onCompleted()
            }
        }
        webinarModel.initLater = { [weak self, weak webinarModel] in
            guard let self = self,
                  let webinarModel = webinarModel,
                  let rxAttendee = webinarModel.rxModel else { return }
            self.calendarModel?.rxModel?.subscribe { [weak self, weak webinarModel] (pre, current) in
                guard let pre = pre, let current = current, let webinarModel = webinarModel else { return }
                webinarModel.calendar = current
            }.disposed(by: self.disposeBag)
        }
        return webinarModel
    }
}
