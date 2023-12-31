//
//  EventResponsible.swift
//  Calendar
//
//  Created by zhuchao on 2019/1/15.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import RustPB
import RxSwift
import LarkUIKit
import RoundedHUD
import AppReciableSDK

protocol EventResponsible {}
extension EventResponsible {

    func responseToEvent(withstatus status: CalendarEventAttendee.Status,
                         span: CalendarEvent.Span,
                         event: CalendarEventEntity,
                         instance: CalendarEventInstanceEntity?,
                         calendarApi: CalendarRustAPI?,
                         messageId: String?) -> Observable<(Bool, CalendarEventEntity?, [Int32])> {
        guard let api = calendarApi else { return .empty() }
        let originalTime = (span == .thisEvent) ?
            (event.originalTime == 0 ? (instance?.startTime ?? event.startTime) : event.originalTime) : 0

        return api.replyCalendarEventInvitationNew(
            calendarId: event.calendarId,
            key: event.key,
            originalTime: originalTime,
            comment: "",
            inviteOperatorID: "",
            replyStatus: status,
            messageId: messageId
        )
            .map({ (entity, _, errorCode) -> (Bool, CalendarEventEntity?, [Int32]) in
              return (entity.selfAttendeeStatus == status ? true : false, entity, errorCode)
            })
    }

}
