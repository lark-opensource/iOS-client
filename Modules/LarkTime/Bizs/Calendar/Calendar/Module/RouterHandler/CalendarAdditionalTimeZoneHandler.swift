//
//  CalendarAdditionalTimeZoneHandler.swift
//  Calendar
//
//  Created by chaishenghua on 2023/11/20.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator
import CTFoundation

class CalendarAdditionalTimeZoneHandler: UserTypedRouterHandler {
    func handle(_ body: CalendarAdditionalTimeZoneBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let viewModel = AdditionalTimeZoneViewModel(userResolver: userResolver, activateDay: body.activateDay)
        let vc = AdditionalTimeZoneViewController(userResolver: userResolver, viewModel: viewModel)
        res.end(resource: PopupViewController(rootViewController: vc))
    }
}
