//
//  CalendarRouterHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/9.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator

final class CalendarRouterHandler: UserRouterHandler {

    func handle(req: EENavigator.Request, res: EENavigator.Response) throws {
        let resolver = self.userResolver
        let calendarHome = try resolver.resolve(assert: CalendarHome.self)
        let vc = calendarHome.controller
        res.end(resource: vc)
    }

}
