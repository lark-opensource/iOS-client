//
//  CalendarShareRouterHandler.swift
//  Calendar
//
//  Created by Hongbin Liang on 6/6/23.
//

import Foundation
import LarkUIKit
import LarkContainer
import LarkNavigator
import EENavigator

final class CalendarShareRouterHandler: UserRouterHandler {

    func handle(req: EENavigator.Request, res: EENavigator.Response) throws {
        let token = req.parameters["token"] as? String ?? ""
        let vc: UIViewController
        if FG.optimizeCalendar {
            let vm = CalendarDetailCardViewModel(withToken: token, userResolver: userResolver)
            vc = CalendarDetailCardViewController(viewModel: vm)
        } else {
            let viewModel = LegacyCalendarDetailViewModel(param: .token(token), userResolver: self.userResolver)
            let legacyDetailVC = LegacyCalendarDetailController(viewModel: viewModel, userResolver: self.userResolver)
            let naviVC = LkNavigationController(rootViewController: legacyDetailVC)
            naviVC.update(style: .default)
            vc = naviVC
        }

        if Display.pad {
            vc.modalPresentationStyle = .formSheet
        } else {
            vc.modalPresentationStyle = .fullScreen
        }
        if let from = req.context.from() {
            userResolver.navigator.present(vc, from: from)
        }
        res.end(resource: EmptyResource())
    }

}
