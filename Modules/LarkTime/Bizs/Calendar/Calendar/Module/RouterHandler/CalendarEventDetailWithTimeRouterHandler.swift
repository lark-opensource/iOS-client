//
//  CalendarEventDetailWithTimeRouterHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/9.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator
import LarkUIKit

final class CalendarEventDetailWithTimeRouterHandler: UserTypedRouterHandler {

    func handle(_ body: CalendarEventDetailWithTimeBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let resolver = self.userResolver
        let interface = try resolver.resolve(assert: CalendarInterface.self)
        let calendarVC = interface.getEventContentController(
            with: body.eventKey,
            calendarId: body.calendarId,
            originalTime: body.originalTime,
            startTime: body.startTime,
            endTime: body.endTime,
            instanceScore: "",
            isFromChat: false,
            isFromNotification: false,
            isFromMail: false,
            isFromTransferEvent: false,
            isFromInviteEvent: false,
            scene: .url)
        if Display.pad {
            let nav = LkNavigationController(rootViewController: calendarVC)
            nav.modalPresentationStyle = .formSheet
            nav.update(style: .default)
            res.end(resource: nav)
        } else {
            res.end(resource: calendarVC)
        }
    }

}
