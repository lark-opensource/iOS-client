//
//  NameCardEditHandler.swift
//  LarkContact
//
//  Created by 夏汝震 on 2021/4/13.
//

import Foundation
import LarkMessengerInterface
import Swinject
import EENavigator
import LarkSDKInterface
import LarkNavigator

final class NameCardEditHandler: UserTypedRouterHandler {

    func handle(_ body: NameCardEditBody, req: EENavigator.Request, res: Response) throws {
        let namecardAPI = try self.userResolver.resolve(assert: NamecardAPI.self)
        let namecardAPIProvider = { namecardAPI }
        let dependency = NameCardEditDependencyImpl(namecardAPIProvider: namecardAPIProvider)
        let viewModel = try NameCardEditViewModel(
            id: body.id,
            email: body.email,
            name: body.name,
            source: body.source,
            accountID: body.accountID,
            accountList: body.accountList,
            callback: body.callback,
            pushCenter: try userResolver.userPushCenter,
            dependency: dependency,
            resolver: userResolver
        )
        let vc = NameCardEditViewController(viewModel: viewModel, resolver: userResolver)
        res.end(resource: vc)
    }
}
