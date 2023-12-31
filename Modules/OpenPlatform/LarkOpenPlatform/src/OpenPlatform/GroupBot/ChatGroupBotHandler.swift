//
//  ChatGroupBotHandler.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/22.
//

import Foundation
import LarkContainer
import RxSwift
import LarkUIKit
import LKCommonsLogging
import EENavigator
import Swinject
import RoundedHUD
import LarkModel
import LarkAccountInterface
import LarkSDKInterface
import LarkOPInterface
import LarkNavigator

/// 群机器人页面路由
final class ChatGroupBotHandler: UserTypedRouterHandler {
    private let disposeBag = DisposeBag()

    func handle(_ body: ChatGroupBotBody, req: EENavigator.Request, res: Response) {
        guard !body.chatId.isEmpty else {
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }
        let vc = GroupBotListViewController(resolver: userResolver, chatID: body.chatId, isCrossTenant: body.isCrossTenant)
        res.end(resource: vc)
    }
}
