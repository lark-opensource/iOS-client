//
//  NameCardListHandler.swift
//  LarkContact
//
//  Created by Aslan on 2021/4/18.
//

import Foundation
import LarkMessengerInterface
import Swinject
import EENavigator
import LarkSDKInterface
import LarkNavigator

final class NameCardListHandler: UserTypedRouterHandler {

    func handle(_ body: NameCardListBody, req: EENavigator.Request, res: Response) throws {
        let vc = try userResolver.resolve(assert: NameCardWrapperViewController.self)
        res.end(resource: vc)
    }
}
