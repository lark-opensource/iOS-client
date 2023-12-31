//
//  CalendarEventSubSearchRouterHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/9.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator

final class CalendarEventSubSearchRouterHandler: UserTypedRouterHandler {

    func handle(_ body: CalendarEventSubSearch, req: EENavigator.Request, res: EENavigator.Response) throws {
        let resolver = self.userResolver
        let interface = try resolver.resolve(assert: CalendarInterface.self)
        let calendarSearchVC = interface.getSearchController(query: body.query)
        res.end(resource: calendarSearchVC)
    }

}
