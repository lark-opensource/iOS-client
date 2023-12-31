//
//  CalendarFreeBusyBodyRouterHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/9.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator

final class CalendarFreeBusyBodyRouterHandler: UserTypedRouterHandler {

    func handle(_ body: CalendarFreeBusyBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let resolver = self.userResolver
        let interface = try resolver.resolve(assert: CalendarInterface.self)
        if FG.freebusyOpt {
            let freBusyVC = interface.getFreeBusyController(body: body)
            res.end(resource: freBusyVC)
        } else {
            let freBusyVC = interface.getOldFreeBusyController(userId: body.uid, isFromProfile: body.isFromProfile)
            res.end(resource: freBusyVC)
        }
    }

}
