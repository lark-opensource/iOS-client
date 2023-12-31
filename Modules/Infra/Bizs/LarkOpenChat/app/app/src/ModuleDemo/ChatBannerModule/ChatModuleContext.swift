//
//  ChatModuleContext.swift
//  LarkOpenChatDev
//
//  Created by 李勇 on 2020/12/21.
//

import Foundation
import LarkOpenChat
import Swinject

class ChatModuleContext {
    /// KV存储
    private let store = Store()
    /// ChatVC域Resolver
    private let resolver: Resolver
    /// ChatVC域Container
    let container: Container
    /// 事件监听
    private let signaleTrap = SignalTrap()

    init(parent: Container) {
        self.container = Container(parent: parent)
        self.resolver = self.container
    }

    /// get ChatBannerContext
    lazy var bannerContext: ChatBannerContext = {
        return ChatBannerContext(parent: self.container, store: self.store)
    }()
}
