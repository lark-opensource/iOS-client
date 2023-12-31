//
//  PinListHandler.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/3/18.
//

import UIKit
import Foundation
import EENavigator
import LarkModel
import Swinject
import LarkCore
import LarkContainer
import LarkFeatureGating
import LarkMessageBase
import LarkMessageCore
import LarkActionSheet
import LarkSDKInterface
import LarkAccountInterface
import LarkMessengerInterface
import LarkGuide
import AsyncComponent
import LarkSearchCore
import LarkSceneManager
import LarkOpenChat
import class AppContainer.BootLoader
import LarkNavigator

final class PinListHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    func handle(_ body: PinListBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI: ChatAPI = try resolver.resolve(assert: ChatAPI.self)
        guard !body.chatId.isEmpty, let chat = chatAPI.getLocalChat(by: body.chatId) else {
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }
        let controller = try PinListFactory.generateNewPinList(chat: chat, resolver: self.userResolver)
        res.end(resource: controller)
    }
}

final class PinListFactory {
    class func generateNewPinList(chat: Chat, resolver: UserResolver) throws -> UIViewController {
        let enterCostInfo = EnterPinCostInfo()
        let dragManager = DragInteractionManager()
        dragManager.viewTagBlock = { return $0.getASComponentKey() ?? "" }
        let pinContext = PinContext(
            resolver: resolver,
            dragManager: dragManager,
            defaulModelSummerizeFactory: DefaultMesageSummerizeFactory(userResolver: resolver)
        )
        let pushCenter = try resolver.userPushCenter
        let deletePinPush = pushCenter.observable(for: PushDeletePinList.self).map({ (push) -> String in
            return push.pinId
        })
        let messagePush = pushCenter.observable(for: PushChannelMessage.self).map({ return $0.message })
        let currentChatterId = resolver.userID
        let is24HourTime = try resolver.resolve(assert: UserGeneralSettings.self).is24HourTime
        let pinBadgeEnable = resolver.fg.staticFeatureGatingValue(with: .init(key: .pinBadgeEnable))
        let dependency = PinListViewModelDependency(deletePinPush: deletePinPush,
                                                    messagePush: messagePush,
                                                    is24HourTime: is24HourTime,
                                                    pinReadStatus: pushCenter.observable(for: PushChatPinReadStatus.self),
                                                    pinAPI: try resolver.resolve(assert: PinAPI.self),
                                                    searchCache: try resolver.resolve(assert: SearchCache.self),
                                                    pinBadgeEnable: pinBadgeEnable,
                                                    searchAPI: try resolver.resolve(assert: SearchAPI.self),
                                                    currentChatterId: currentChatterId,
                                                    urlPreviewService: try resolver.resolve(assert: MessageURLPreviewService.self),
                                                    inlinePreviewVM: MessageInlineViewModel())
        let viewModel: PinListViewModel
        let controller: PinListViewController
        enterCostInfo.chat = chat
        viewModel = PinListViewModel(chat: chat, context: pinContext, dependency: dependency, enterCostInfo: enterCostInfo)
        let pushWrapper = try resolver.resolve(assert: ChatPushWrapper.self, argument: chat)
        let container = Container(parent: BootLoader.container)
        let actionContext = MessageActionContext(parent: container,
                                                 store: Store(),
                                                 interceptor: IMMessageActionInterceptor(),
                                                 userStorage: resolver.storage, compatibleMode: resolver.compatibleMode)
        PinListMessageActionModule.onLoad(context: actionContext)
        let actionModule = PinListMessageActionModule(context: actionContext)
        let pinMenuService = PinMenuServiceImp(actionModule)
        controller = PinListViewController(chat: chat,
                                              context: pinContext,
                                              viewModel: viewModel,
                                              guideService: try resolver.resolve(assert: GuideService.self),
                                              pinMenuService: pinMenuService,
                                              enterCostInfo: enterCostInfo)
        pinContext.dataSourceAPI = viewModel
        pinContext.pageAPI = controller
        pinContext.pageContainer.register(ChatScreenProtectService.self) { [weak pinContext] in
            return ChatScreenProtectService(chat: pushWrapper.chat,
                                            getTargetVC: { [weak pinContext] in return pinContext?.pageAPI },
                                            userResolver: resolver)
        }
        pinContext.pageContainer.register(PinMenuService.self) { [weak pinMenuService] in
            let service: PinMenuService = pinMenuService ?? DefaultPinMenuService()
            return service
        }
        container.register(ChatMessagesOpenService.self) { [weak controller] _ -> ChatMessagesOpenService in
            return controller ?? DefaultChatMessagesOpenService()
        }
        enterCostInfo.initViewStamp = CACurrentMediaTime()
        return controller
    }
}
