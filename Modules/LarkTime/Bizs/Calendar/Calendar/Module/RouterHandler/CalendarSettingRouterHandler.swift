//
//  CalendarSettingRouterHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/9.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator

final class CalendarSettingRouterHandler: UserTypedRouterHandler {

    func handle(_ body: CalendarSettingBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let resolver = self.userResolver
        let interface = try resolver.resolve(assert: CalendarInterface.self)
        let vc = interface.getSettingsController(fromWhere: body.fromWhere)
        res.end(resource: vc)
    }
}
