//
//  LarkAppStateSDKAssembly.swift
//  LarkAppStateSDK
//
//  Created by Meng on 2020/11/25.
//

import Foundation
import Swinject
import LarkAssembler
import LarkOpenChat
import ECOInfra
import LarkOPInterface

public class LarkAppStateSDKAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        let userContainer = container.inObjectScope(OPUserScope.userScope)
        userContainer.register(BotLinkStateEventListener.self) { (r) -> BotLinkStateEventListener in
            return try BotLinkStateEventListenerImpl(resolver: r)
        }
        userContainer.register(AppStateService.self) { (r) -> AppStateService in
            return AppStateImpl(resolver: r)
        }
    }

    // 注册机器人不可用footer
    @_silgen_name("Lark.OpenChat.Messenger.LarkAppState")
    static public func openChatRegister() {
        ChatFooterModule.register(BotBanFooterModule.self)
    }
}
