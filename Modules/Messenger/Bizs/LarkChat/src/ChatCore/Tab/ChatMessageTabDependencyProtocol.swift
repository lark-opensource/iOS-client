//
//  ChatMessageTabDependencyProtocol.swift
//  LarkChat
//
//  Created by 赵家琛 on 2021/7/13.
//

import Foundation
import LarkMessengerInterface
import LarkMessageCore
import LarkMessageBase
import LarkSDKInterface
import RxSwift
import RxCocoa
import LarkOpenChat
import LarkChatOpenKeyboard
import LarkContainer

/// message 业务初始化需要的依赖
protocol ChatMessageTabDependencyProtocol {
    var positionStrategy: ChatMessagePositionStrategy? { get }
    var moduleContext: ChatModuleContext { get }
    var keyboardStartState: KeyboardStartupState { get }
    var chatKeyPointTracker: ChatKeyPointTracker { get }
    var dragManager: DragInteractionManager { get }
    var getChatMessagesResultObservable: Observable<GetChatMessagesResult> { get }
    var getBufferPushMessages: GetBufferPushMessagesHandler { get }
    var isMessagePicker: Bool { get }
    var ignoreDocAuth: Bool { get }
    var messagePickerCancelHandler: ChatMessagePickerCancelHandler { get }
    var messagePickerFinishHandler: ChatMessagePickerFinishHandler { get }
    var componentGenerator: ChatViewControllerComponentGeneratorProtocol { get }
    var router: ChatControllerRouter { get }
    var dependency: ChatControllerDependency { get }
    var chatFromWhere: ChatFromWhere { get }
    var controllerService: ChatViewControllerService? { get }
}

final class ChatMessageTabDependency: ChatMessageTabDependencyProtocol {
    let positionStrategy: ChatMessagePositionStrategy?
    let keyboardStartState: KeyboardStartupState
    let chatKeyPointTracker: ChatKeyPointTracker
    let dragManager: DragInteractionManager
    let getChatMessagesResultObservable: Observable<GetChatMessagesResult>
    let getBufferPushMessages: GetBufferPushMessagesHandler
    weak var _moduleContext: ChatModuleContext?
    var moduleContext: ChatModuleContext {
        return _moduleContext ?? ChatModuleContext(
            userStorage: userResolver.storage,
            dragManager: DragInteractionManager(),
            modelSummerizeFactory: DefaultMesageSummerizeFactory(userResolver: userResolver)
        )
    }

    let componentGenerator: ChatViewControllerComponentGeneratorProtocol
    let router: ChatControllerRouter
    let dependency: ChatControllerDependency
    let messagePickerCancelHandler: ChatMessagePickerCancelHandler
    let messagePickerFinishHandler: ChatMessagePickerFinishHandler
    let isMessagePicker: Bool
    let ignoreDocAuth: Bool
    let chatFromWhere: ChatFromWhere
    let controllerService: ChatViewControllerService?
    let userResolver: UserResolver
    init(positionStrategy: ChatMessagePositionStrategy?,
         keyboardStartState: KeyboardStartupState,
         chatKeyPointTracker: ChatKeyPointTracker,
         dragManager: DragInteractionManager,
         getChatMessagesResultObservable: Observable<GetChatMessagesResult>,
         getBufferPushMessages: @escaping GetBufferPushMessagesHandler,
         moduleContext: ChatModuleContext,
         componentGenerator: ChatViewControllerComponentGeneratorProtocol,
         router: ChatControllerRouter,
         dependency: ChatControllerDependency,
         isMessagePicker: Bool,
         ignoreDocAuth: Bool,
         messagePickerCancelHandler: ChatMessagePickerCancelHandler,
         messagePickerFinishHandler: ChatMessagePickerFinishHandler,
         chatFromWhere: ChatFromWhere,
         controllerService: ChatViewControllerService?,
         userResolver: UserResolver) {
        self.positionStrategy = positionStrategy
        self.keyboardStartState = keyboardStartState
        self.chatKeyPointTracker = chatKeyPointTracker
        self.dragManager = dragManager
        self.getChatMessagesResultObservable = getChatMessagesResultObservable
        self.getBufferPushMessages = getBufferPushMessages
        self._moduleContext = moduleContext
        self.componentGenerator = componentGenerator
        self.isMessagePicker = isMessagePicker
        self.ignoreDocAuth = ignoreDocAuth
        self.router = router
        self.dependency = dependency
        self.messagePickerCancelHandler = messagePickerCancelHandler
        self.messagePickerFinishHandler = messagePickerFinishHandler
        self.chatFromWhere = chatFromWhere
        self.controllerService = controllerService
        self.userResolver = userResolver
    }

    deinit {
        print("deinit ChatMessageTabDependency")
    }
}
