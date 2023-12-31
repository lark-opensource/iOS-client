//
//  CalendarEventDetailFromMailRouterHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/9.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator

final class CalendarEventDetailFromMailRouterHandler: UserTypedRouterHandler {

    func handle(_ body: CalendarEventDetailFromMail, req: EENavigator.Request, res: EENavigator.Response) throws {
        let resolver = self.userResolver
        let interface = try resolver.resolve(assert: CalendarInterface.self)
        let calendarVC = interface.getEventContentController(
            with: body.eventKey,
            calendarId: body.calendarId,
            originalTime: body.originalTime,
            startTime: nil,
            endTime: nil,
            instanceScore: "",
            isFromChat: false,
            isFromNotification: false,
            isFromMail: true,
            isFromTransferEvent: false,
            isFromInviteEvent: false,
            scene: .url
        )
        res.end(resource: calendarVC)
    }

}
