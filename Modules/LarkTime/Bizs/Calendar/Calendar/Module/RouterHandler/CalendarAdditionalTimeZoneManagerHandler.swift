//
//  CalendarAdditionalTimeZoneManagerHandler.swift
//  Calendar
//
//  Created by chaishenghua on 2023/11/23.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator

class CalendarAdditionalTimeZoneManagerHandler: UserTypedRouterHandler {
    func handle(_ body: CalendarAdditionalTimeZoneManagerBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let viewModel = AdditionalTimeZoneManagerViewModel(body.provider, userResolver: self.userResolver)
        let vc = AdditionalTimeZoneManagerViewController(viewModel: viewModel, userResolver: self.userResolver)
        res.end(resource: vc)
    }
}
