//
//  CalendarCheckInRouterHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/9.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator
import LarkUIKit

final class CalendarCheckInRouterHandler: UserRouterHandler {

    func handle(req: EENavigator.Request, res: EENavigator.Response) throws {
        let token = req.parameters["resource_token"] as? String ?? ""

        let viewModel = MeetingRoomOrderViewModel(token: token, userResolver: self.userResolver)
        let vc = MeetingRoomOrderViewController(viewModel: viewModel, originalURL: req.url, userResolver: self.userResolver)
        let navi = LkNavigationController(rootViewController: vc)

        if Display.pad {
            navi.modalPresentationStyle = .formSheet
        } else {
            navi.modalPresentationStyle = .fullScreen
        }

        if let from = req.context.from() {
            self.userResolver.navigator.present(navi, from: from)
        }
        res.end(resource: EmptyResource())
    }

}

