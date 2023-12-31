//
//  CalendarShareRouterHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/25.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator

final class EventShareRouterHandler: UserRouterHandler {

    func handle(req: EENavigator.Request, res: EENavigator.Response) throws {
        let token = req.parameters["token"] as? String ?? ""
        let controller = EventDetailBuilder.build(userResolver: self.userResolver,
                                                  key: "",
                                                  calendarID: "",
                                                  originalTime: 0,
                                                  token: token,
                                                  messageId: "",
                                                  isFromAPNS: false,
                                                  scene: .url)
        if let from = req.context.from() {
            userResolver.navigator.push(controller, from: from)
        }
        res.end(resource: EmptyResource())
    }

}
