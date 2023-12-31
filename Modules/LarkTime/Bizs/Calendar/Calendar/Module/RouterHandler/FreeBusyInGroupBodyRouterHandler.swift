//
//  FreeBusyInGroupBodyRouterHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/9.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator

final class FreeBusyInGroupBodyRouterHandler: UserTypedRouterHandler {

    func handle(_ body: FreeBusyInGroupBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let resolver = self.userResolver
        let interface = try resolver.resolve(assert: CalendarInterface.self)
        if FG.freebusyOpt {
            let vc = interface.getGroupFreeBusyController(chatId: body.chatId, chatType: body.chatType, createEventBody: nil)
            res.end(resource: vc)
        } else {
            let vc = interface.getOldGroupFreeBusyController(chatId: body.chatId, chatType: body.chatType, createEventBody: nil)
            res.end(resource: vc)
        }

    }

}
