//
//  SeizeMeetingroomRouterHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/9.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator

final class SeizeMeetingroomRouterHandler: UserRouterHandler {

    func handle(req: EENavigator.Request, res: EENavigator.Response) throws {
        let resolver = self.userResolver
        let interface = try resolver.resolve(assert: CalendarInterface.self)
        let token = req.parameters["resource_token"] as? String ?? ""
        let calendarVC = interface.getSeizeMeetingroomController(token: token)
        res.end(resource: calendarVC)
    }

}
