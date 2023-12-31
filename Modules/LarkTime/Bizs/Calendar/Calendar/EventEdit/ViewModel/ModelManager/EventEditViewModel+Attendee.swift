//
//  attendee.swift
//  Calendar
//
//  Created by ByteDance on 2023/1/16.
//

import Foundation
import CalendarFoundation

extension EventEditViewModel {

    var attendeeModel: EventEditAttendeeManager? {
        self.models[EventEditModelType.attendees] as? EventEditAttendeeManager
    }
    
    func makeAttendeeModel() -> EventEditAttendeeManager {
        let attendee_model = EventEditAttendeeManager(identifier: EventEditModelType.attendees.rawValue,
                                                      input: self.input,
                                                      userResolver: self.userResolver)
        attendee_model.eventDelegate = self
        attendee_model.relyModel = [EventEditModelType.calendar.rawValue]
        attendee_model.initMethod = { [weak self, weak attendee_model] observer in
            guard let self = self, let rustAPI = self.calendarApi, let attendee_model = attendee_model else {
                assertionFailureLog()
                return
            }
            attendee_model.initMethod(with: self.calendarModel?.rxModel?.value.current)
            if case let .editFrom(pbEvent, _) = self.input {
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
        attendee_model.initLater = { [weak self, weak attendee_model] in
            guard let self = self,
                  let attendee_model = attendee_model,
                  let rxAttendee = attendee_model.rxModel else { return }
            self.calendarModel?.rxModel?.subscribe { [weak self, weak attendee_model] (pre, current) in
                guard let pre = pre, let current = current, let attendee_model = attendee_model else { return }
                switch (pre.source, current.source) {
                case (.lark, .google), (.exchange, .google), (.google, .lark), (.exchange, .lark), (.lark, .exchange), (.google, .exchange):
                    attendee_model.clearAttendees()
                default: break
                }
                attendee_model.updateAttendeeIfNeeded(forCalendarChanged: current)
                // 编辑场景，如果切换了日历，根据需要，将日历的 owner 加为参与人，需满足如下条件：
                //  - 目标日历是他人的主日历
                //  - 有会议室或者参与人
                //  - 当前可见参与人中没有该参与人
                if case .editFrom(let pbEvent, _) = attendee_model.input,
                   pbEvent.calendarID != current.id,
                   current.userChatterId != pbEvent.organizer.user.userID,
                   current.isPrimary {
                    let attendees = rxAttendee.value
                    let containsFunc = { (attendee: EventEditAttendee) -> Bool in
                        guard case .user(let userAttendee) = attendee else {
                            return false
                        }
                        return userAttendee.status != .removed && userAttendee.chatterId == current.userChatterId
                    }
                    let hasMeetingRoom = self?.meetingRoomModel?.rxModel?.value.contains(where: { $0.status != .removed }) ?? false
                    if (!attendees.isEmpty || hasMeetingRoom) && !attendees.contains(where: containsFunc) {
                        attendee_model.addAttendees(withSeeds: [.user(chatterId: current.userChatterId)])
                    }
                }
            }.disposed(by: self.disposeBag)
        }
        return attendee_model
    }

    var hasAllAttendee: Bool {
        attendeeModel?.haveAllAttendee ?? true
    }
}
