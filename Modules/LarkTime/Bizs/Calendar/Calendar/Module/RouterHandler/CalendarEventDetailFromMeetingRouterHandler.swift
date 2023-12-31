//
//  CalendarEventDetailFromMeetingRouterHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/9.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator

final class CalendarEventDetailFromMeetingRouterHandler: UserTypedRouterHandler {

    func handle(_ body: CalendarEeventDetailFromMeeting, req: EENavigator.Request, res: EENavigator.Response) throws {
        let resolver = self.userResolver
        let interface = try resolver.resolve(assert: CalendarInterface.self)
        let calendarVC = interface.getEventContentController(with: body.chatId, isFromChat: true)
        res.end(resource: calendarVC)
    }

}
