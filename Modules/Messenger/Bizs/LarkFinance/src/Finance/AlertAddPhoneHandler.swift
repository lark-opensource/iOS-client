//
//  AlertAddPhoneHandler.swift
//  LarkFinance
//
//  Created by 李晨 on 2020/1/15.
//

import Foundation
import EENavigator
import LarkMessengerInterface
import LarkNavigator

final class AlertAddPhoneHandler: UserTypedRouterHandler {
    func handle(_ body: AlertAddPhoneBody, req: EENavigator.Request, res: Response) throws {
        res.end(resource: AlertAddPhoneController(userResolver: userResolver, content: body.content))
    }
}
