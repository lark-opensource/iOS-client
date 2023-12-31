//
//  ChatModuleContext.swift
//  LarkChat
//
//  Created by 李勇 on 2020/12/8.
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
final class ChatModuleContext {
    /// ChatVC域子Resolver
    var resolver: Resolver { userResolver }
    let userResolver: UserResolver
    /// ChatVC域Container
    let container: Container
    /// 事件监听
    let signaleTrap = SignalTrap()
    /// iPad拖拽
    private let dragManager: DragInteractionManager
    /// ModelSummerizeFactory
    private let modelSummerizeFactory: MetaModelSummerizeFactory

    /// get ChatContext
    var chatContext: ChatContext { return self._chatContext.wrappedValue }
    private var _chatContext: ThreadSafeLazy<ChatContext>!

    /// get ChatBannerContext
    var bannerContext: ChatBannerContext { return self._bannerContext.wrappedValue }
    private var _bannerContext: ThreadSafeLazy<ChatBannerContext>!

    // 获取 ChatFooterContext
    var footerContext: ChatFooterContext { return self._footerContext.wrappedValue }
    private var _footerContext: ThreadSafeLazy<ChatFooterContext>!

    /// 长按消息菜单
    var messageActionContext: MessageActionContext {
        return self._messageActionContext.wrappedValue
    }
    private var _messageActionContext: ThreadSafeLazy<MessageActionContext>!

    /// get ChatTabContext
    var tabContext: ChatTabContext { return self._tabContext.wrappedValue }
    private var _tabContext: ThreadSafeLazy<ChatTabContext>!

    /// 群 widget
    var widgetContext: ChatWidgetContext { return self._widgetContext.wrappedValue }
    private var _widgetContext: ThreadSafeLazy<ChatWidgetContext>!

    var pinSummaryContext: ChatPinSummaryContext { return self._pinSummaryContext.wrappedValue }
    private var _pinSummaryContext: ThreadSafeLazy<ChatPinSummaryContext>!

    /// 键盘上方扩展区域context
    var keyBoardTopExtendContext: ChatKeyboardTopExtendContext { return self._keyBoardTopExtend.wrappedValue }
    private var _keyBoardTopExtend: ThreadSafeLazy<ChatKeyboardTopExtendContext>!

    var navigaionContext: ChatNavgationBarContext { return self._navigaionContext.wrappedValue }
    private var _navigaionContext: ThreadSafeLazy<ChatNavgationBarContext>!

    var keyboardContext: ChatKeyboardContext { return self._keyboardContext.wrappedValue }
    private var _keyboardContext: ThreadSafeLazy<ChatKeyboardContext>!

    init(userStorage: UserStorage, dragManager: DragInteractionManager, modelSummerizeFactory: MetaModelSummerizeFactory) {
        let container = Container(parent: BootLoader.container)
        let userResolver = container.getUserResolver(storage: userStorage, compatibleMode: M.userScopeCompatibleMode)
        self.container = container
        self.userResolver = userResolver
        self.dragManager = dragManager
        self.modelSummerizeFactory = modelSummerizeFactory

        // 使用ThreadSafeLazy，防止lazy多线程安全问题
        // 注意不要捕获self形成循环引用
        self._chatContext = ThreadSafeLazy<ChatContext>(value: {
            return ChatContext(resolver: userResolver,
                               dragManager: dragManager,
                               defaulModelSummerizeFactory: modelSummerizeFactory)
        })
        self._bannerContext = ThreadSafeLazy<ChatBannerContext>(value: {
            return ChatBannerContext(parent: container, store: Store(),
                                     userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode)
        })
        self._footerContext = ThreadSafeLazy<ChatFooterContext>(value: {
            return ChatFooterContext(parent: container, store: Store(),
                                     userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode)
        })
        self._tabContext = ThreadSafeLazy<ChatTabContext>(value: {
            return ChatTabContext(parent: container, store: Store(),
                                  userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode)
        })
        self._messageActionContext = ThreadSafeLazy<MessageActionContext>(value: {
            return MessageActionContext(parent: container,
                                        store: Store(),
                                        interceptor: IMMessageActionInterceptor(),
                                        userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode
            )
        })
        self._widgetContext = ThreadSafeLazy<ChatWidgetContext>(value: {
            return ChatWidgetContext(parent: container, store: Store(),
                                     userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode)
        })
        self._pinSummaryContext = ThreadSafeLazy<ChatPinSummaryContext>(value: {
            return ChatPinSummaryContext(parent: container, store: Store(),
                                         userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode)
        })
        self._keyBoardTopExtend = ThreadSafeLazy<ChatKeyboardTopExtendContext>(value: {
            return ChatKeyboardTopExtendContext(parent: container, store: Store(),
                                                userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode)
        })
        self._navigaionContext = ThreadSafeLazy<ChatNavgationBarContext>(value: {
            return ChatNavgationBarContext(parent: container,
                                           store: Store(),
                                           interceptor: IMMessageNavigationInterceptor(),
                                           userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode)
        })
        self._keyboardContext = ThreadSafeLazy<ChatKeyboardContext>(value: {
            return ChatKeyboardContext(parent: container, store: Store(),
                                       userStorage: userResolver.storage,
                                       compatibleMode: userResolver.compatibleMode,
                                       disableMyAI: false)
        })
    }
}
