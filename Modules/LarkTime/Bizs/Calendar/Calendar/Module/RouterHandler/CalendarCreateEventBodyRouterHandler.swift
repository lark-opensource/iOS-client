//
//  CalendarCreateEventBodyRouterHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/9.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator
import UniverseDesignToast

final class CalendarCreateEventBodyRouterHandler: UserTypedRouterHandler {

    func handle(_ body: CalendarCreateEventBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let resolver = self.userResolver
        let interface = try resolver.resolve(assert: CalendarInterface.self)
        let disableEncrypt = SettingService.shared().tenantSetting?.disableEncrypt ?? false
        let shouldCheckEncrypt: Bool
        switch body.perferredScene {
        case .webinar, .edit:
            shouldCheckEncrypt = true
        case .freebusy:
            shouldCheckEncrypt = false
        }
        if shouldCheckEncrypt && disableEncrypt {
            let view = resolver.navigator.navigation?.fromViewController?.view ?? UIView()
            UDToast().showTips(with: I18n.Calendar_NoKeyNoCreate_Toast, on: view)
        } else {
            let vc = interface.getCreateEventController(for: body)
            res.end(resource: vc)
        }
    }

}
