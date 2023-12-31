//
//  MyAIToolsHandle.swift
//  LarkAI
//
//  Created by ByteDance on 2023/6/6.
//

import Foundation
import LarkMessengerInterface
import EENavigator
import LarkNavigator
import LarkContainer
import LarkUIKit

final class MyAIToolsHandler: UserTypedRouterHandler {

    func handle(_ body: MyAIToolsBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let toolsPanelService: MyAIToolsService = try userResolver.resolve(assert: MyAIToolsService.self)
        let panelConfig = MyAIToolsPanelConfig(selectedToolIds: body.selectedToolIds,
                                               scenario: body.scenario,
                                               completionHandle: body.completionHandle,
                                               closeHandler: body.closeHandler,
                                               maxSelectCount: body.maxSelectCount,
                                               aiChatModeId: body.aiChatModeId,
                                               myAIPageService: body.myAIPageService,
                                               extra: body.extra)
        let toosPanelVc = toolsPanelService.generateAIToosPanel(with: panelConfig, userResolver: userResolver, chat: body.chat)
        toosPanelVc.show(from: req.from.fromViewController)
        res.end(resource: toosPanelVc)
    }
}

final class MyAIToolsSelectedHandler: UserTypedRouterHandler {

    func handle(_ body: MyAIToolsSelectedBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let toolsPanelService: MyAIToolsService = try userResolver.resolve(assert: MyAIToolsService.self)
        let panelConfig = MyAIToolsSelectedPanelConfig(userResolver: userResolver,
                                                       toolItems: body.toolItems,
                                                       toolIds: body.toolIds,
                                                       aiChatModeId: body.aiChatModeId,
                                                       myAIPageService: body.myAIPageService,
                                                       extra: body.extra,
                                                       startNewTopicHandler: body.startNewTopicHandler)
        let toosSelectedPanelVc = toolsPanelService.generateAIToosSelectedPanel(with: panelConfig, userResolver: userResolver, chat: body.chat)
        toosSelectedPanelVc.show(from: req.from.fromViewController)
        res.end(resource: toosSelectedPanelVc)
    }
}

final class MyAIToolsDetailHandler: UserTypedRouterHandler {
    func handle(_ body: MyAIToolsDetailBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let toolsDetailVc = MyAIToolsDetailViewController(toolItem: body.toolItem,
                                                          isSingleSelect: body.isSingleSelect,
                                                          userResolver: userResolver,
                                                          chat: body.chat,
                                                          myAIPageService: body.myAIPageService,
                                                          extra: body.extra,
                                                          addToolHandler: body.addToolHandler)
        res.end(resource: toolsDetailVc)
    }
}
