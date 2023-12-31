//
//  CalendarEventDetailRouterHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/9.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator

final class CalendarEventDetailRouterHandler: UserTypedRouterHandler {

    func handle(_ body: CalendarEventDetailBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let resolver = self.userResolver
        let interface = try resolver.resolve(assert: CalendarInterface.self)
        if body.sysEventIdentifier.isEmpty {
            let controller = interface.applinkEventDetailController(key: body.eventKey,
                                                                    calendarId: body.calendarId,
                                                                    source: CalendarAssembly.AppLinkUniqueFields,
                                                                    token: nil,
                                                                    originalTime: body.originalTime,
                                                                    startTime: body.startTime,
                                                                    endTime: nil,
                                                                    isFromAPNS: body.isFromAPNS)
            res.end(resource: controller)
        } else {
            let calendarVC = interface.getLocalDetailController(identifier: body.sysEventIdentifier)
            res.end(resource: calendarVC)
        }
    }

}
