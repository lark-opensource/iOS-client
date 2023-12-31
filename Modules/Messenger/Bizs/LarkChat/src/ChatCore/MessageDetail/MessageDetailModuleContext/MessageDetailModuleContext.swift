//
//  MessageDetailModuleContext.swift
//  LarkChat
//
//  Created by zhaojiachen on 2021/12/27.
//

import Foundation
import Swinject
import LarkOpenChat
import LarkOpenIM
import LarkMessageBase
import AppContainer
import LarkFoundation
import LarkMessageCore
import LarkContainer

/// 该Context具备所有ModuleContext需要的能力
final class MessageDetailModuleContext: UserResolverWrapper {
    /// ChatVC域Resolver
    let userResolver: UserResolver
    /// ChatVC域Container
    let container: Container
    /// Menu
    /// iPad拖拽
    private let dragManager: DragInteractionManager
    /// ModelSummerizeFactory
    private let modelSummerizeFactory: MetaModelSummerizeFactory

    /// get ChatContext
    var messageDetailContext: MessageDetailContext { return self._messageDetailContext.wrappedValue }
    private var _messageDetailContext: ThreadSafeLazy<MessageDetailContext>!

    var keyboardContext: ChatKeyboardContext { return self._keyboardContext.wrappedValue }
    private var _keyboardContext: ThreadSafeLazy<ChatKeyboardContext>!

    /// 长按消息菜单Action
    var messageActionContext: MessageActionContext {
        return self ._messageActionContext.wrappedValue
    }
    private var _messageActionContext: ThreadSafeLazy<MessageActionContext>!

    init(userStorage: UserStorage, dragManager: DragInteractionManager, modelSummerizeFactory: MetaModelSummerizeFactory) {
        let container = Container(parent: BootLoader.container)
        let userResolver = container.getUserResolver(storage: userStorage, compatibleMode: M.userScopeCompatibleMode)
        self.container = container
        self.userResolver = userResolver
        self.dragManager = dragManager
        self.modelSummerizeFactory = modelSummerizeFactory

        // 使用ThreadSafeLazy，防止lazy多线程安全问题
        self._messageDetailContext = ThreadSafeLazy<MessageDetailContext>(value: {
            return MessageDetailContext(resolver: userResolver,
                                        dragManager: dragManager,
                                        defaulModelSummerizeFactory: modelSummerizeFactory)
        })
        self._keyboardContext = ThreadSafeLazy<ChatKeyboardContext>(value: {
            return ChatKeyboardContext(parent: container, store: Store(),
                                       userStorage: userResolver.storage,
                                       compatibleMode: userResolver.compatibleMode,
                                       disableMyAI: true)
        })
        self._messageActionContext = ThreadSafeLazy<MessageActionContext>(value: {
            return MessageActionContext(parent: container,
                                        store: Store(),
                                        interceptor: IMMessageActionInterceptor(),
                                        userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode)
        })
    }
}
