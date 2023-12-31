//
//  EventEditViewModel+MeetingRoom.swift
//  Calendar
//
//  Created by ByteDance on 2023/1/16.
//

import Foundation
import RxSwift

// MARK: Setup MeetingRoom
extension EventEditViewModel {

    var meetingRoomModel: EventEditMeetingRoomManager? {
        self.models[EventEditModelType.meetingRooms] as? EventEditMeetingRoomManager
    }
    
    func makeMeetingRoomModel() -> EventEditMeetingRoomManager {
        let meetingRoom_model = EventEditMeetingRoomManager(userResolver: self.userResolver,
                                                            input: self.input,
                                                            identifier: EventEditModelType.meetingRooms.rawValue)
        meetingRoom_model.initLater = { [weak self, weak meetingRoom_model] in
            guard let self = self, let meetingRoom_model = meetingRoom_model else { return }
            self.calendarModel?.rxModel?.subscribe { [weak meetingRoom_model] (pre, current) in
                guard let pre = pre,
                      let current = current,
                      let meetingRoom_model = meetingRoom_model else { return }
                switch (pre.source, current.source) {
                case (.lark, .google), (.exchange, .google), (.google, .lark), (.exchange, .lark), (.lark, .exchange), (.google, .exchange):
                    meetingRoom_model.clearMeetingRooms()
                default: break
                }
            }.disposed(by: self.disposeBag)

            // 预定次数限制
            if SettingService.shared().tenantSetting?.resourceSubscribeCondition.limitPerDay != 0 {
                guard let rxEventModel = self.eventModel?.rxModel else { return }
                let _ = rxEventModel.distinctUntilChanged {
                    $0.startDate != $1.startDate && $0.endDate != $0.endDate
                }.flatMapLatest { [weak self] eventModel -> Observable<Bool> in
                    guard let self = self else { return .empty() }
                    return self.calendarApi?.getResourceSubscribeUsage(
                        startTime: eventModel.startDate,
                        endTime: eventModel.endDate,
                        rrule: eventModel.getPBModel().rrule,
                        key: eventModel.getPBModel().key,
                        originalTime: eventModel.getPBModel().originalTime
                    ).catchError { _ in return .empty() } ?? .empty()
                }.bind(to: self.rxOverUsageLimit)
            }
        }
        return meetingRoom_model
    }
}
