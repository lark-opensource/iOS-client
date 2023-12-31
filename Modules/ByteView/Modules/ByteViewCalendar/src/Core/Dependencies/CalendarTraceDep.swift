//
//  CalendarTraceDep.swift
//  ByteViewMod
//
//  Created by tuwenbo on 2022/9/28.
//

import Foundation
import Calendar
import LarkContainer
import LKCommonsTracker
import LKCommonsLogging

final class CalendarTraceDep {
    private lazy var calendarInterface: CalendarInterface? = {
        try? userResolver.resolve(assert: CalendarInterface.self)
    }()

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func traceEventDetailVideoMeetingShowIfNeed(event: Rust.CalendarEvent, with isInMeeting: Bool) {
        calendarInterface?.traceEventDetailVideoMeetingShowIfNeed(event: event, with: isInMeeting)
    }

    func traceEventDetailVideoMeetingClick(event: Rust.CalendarEvent, click: String, target: String = "none") {
        calendarInterface?.traceEventDetailVideoMeetingClick(event: event, click: click, target: target)
    }

    func traceEventDetailOpenVideoMeeting(event: Rust.CalendarEvent) {
        calendarInterface?.traceEventDetailOpenVideoMeeting(event: event)
    }

    func traceEventDetailJoinVideoMeeting(event: Rust.CalendarEvent) {
        calendarInterface?.traceEventDetailJoinVideoMeeting(event: event)
    }

    func traceEventDetailCopyVideoMeeting(event: Rust.CalendarEvent) {
        calendarInterface?.traceEventDetailCopyVideoMeeting(event: event)
    }

    func traceEventDetailVCSetting() {
        calendarInterface?.traceEventDetailVCSetting()
    }

    func reciableTraceEventDetailStartEnterMeeting() {
        calendarInterface?.reciableTraceEventDetailStartEnterMeeting()
    }

    func reciableTraceEventDetailEndEnterMeeting() {
        calendarInterface?.reciableTraceEventDetailEndEnterMeeting()
    }

    func reciableTraceEventDetailEnterMeetingFailed(errorCode: Int, errorMessage: String) {
        calendarInterface?.reciableTraceEventDetailEnterMeetingFailed(errorCode: errorCode, errorMessage: errorMessage)
    }
}
