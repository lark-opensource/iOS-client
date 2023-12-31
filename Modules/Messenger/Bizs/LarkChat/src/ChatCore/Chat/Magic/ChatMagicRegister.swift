//
//  ChatMagicRegister.swift
//  LarkChat
//
//  Created by mochangxing on 2020/11/13.
//

import Foundation
import LarkContainer
import LarkFeatureGating
import LarkMagic
import LarkMessengerInterface

final class ChatMagicRegister {
    static let scenarioID = "chat"
    var magicInterceptor = ChatMagicInterceptor()
    private let larkMagicService: LarkMagicService

    init(userResolver: UserResolver, containerProvider: @escaping ContainerProvider) throws {
        larkMagicService = try userResolver.resolve(assert: LarkMagicService.self)
        larkMagicService.register(scenarioID: ChatMagicRegister.scenarioID,
                                  interceptor: magicInterceptor,
                                  containerProvider: containerProvider)
    }

    deinit {
        larkMagicService.unregister(scenarioID: ChatMagicRegister.scenarioID)
    }
}
