//
//  PhoneQueryLimitControllerHandler.swift
//  LarkChat
//
//  Created by 李勇 on 2019/4/28.
//

import Foundation
import Swinject
import EENavigator
import LarkSDKInterface
import LarkSendMessage
import LarkMessengerInterface
import LarkNavigator

final class PhoneQueryLimitControllerHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    func handle(_ body: PhoneQueryLimitBody, req: EENavigator.Request, res: Response) throws {
        let viewModel: PhoneQueryLimitViewModel = PhoneQueryLimitViewModel(
            userResolver: userResolver,
            queryQuota: body.queryQuota,
            chatterId: body.chatterId,
            chatId: body.chatId,
            deniedAlertDisplayName: body.deniedAlertDisplayName,
            byteViewDependency: try resolver.resolve(assert: ChatByteViewDependency.self),
            chatterAPI: try resolver.resolve(assert: ChatterAPI.self),
            userAppConfig: try resolver.resolve(assert: UserAppConfig.self),
            sendMessageAPI: try resolver.resolve(assert: SendMessageAPI.self),
            chatService: try resolver.resolve(assert: LarkSDKInterface.ChatService.self))
        let vc = PhoneQueryLimitController(viewModel: viewModel)
        res.end(resource: vc)
    }
}
