//
//  LarkMyAIToolsPanelImp.swift
//  LarkIMMention
//
//  Created by ByteDance on 2023/5/22.
//

import Foundation
import UIKit
import LarkMessengerInterface
import LarkModel
import LarkContainer

final class MyAIToolsServiceImp: MyAIToolsService {
    func generateAIToosPanel(with panelCofig: MyAIToolsPanelConfig, userResolver: UserResolver, chat: Chat) -> MyAIToolsPanelInterface {
        let context = MyAIToolsContext(selectedToolIds: panelCofig.selectedToolIds,
                                       scenario: panelCofig.scenario,
                                       maxSelectCount: panelCofig.maxSelectCount,
                                       aiChatModeId: panelCofig.aiChatModeId,
                                       myAIPageService: panelCofig.myAIPageService,
                                       extra: panelCofig.extra)
        let myAIToolsVC = MyAIToolsViewController(context: context, userResolver: userResolver, chat: chat)
        myAIToolsVC.completionHandle = panelCofig.completionHandle
        myAIToolsVC.closeHandler = panelCofig.closeHandler
        return myAIToolsVC
    }

    func generateAIToosSelectedPanel(with panelCofig: MyAIToolsSelectedPanelConfig, userResolver: UserResolver, chat: Chat) -> MyAIToolsPanelInterface {
        let selectedVcFromToolItems = MyAIToolsSelectedViewController(toolItems: panelCofig.toolItems,
                                                                      userResolver: userResolver,
                                                                      chat: chat,
                                                                      aiChatModeId: panelCofig.aiChatModeId,
                                                                      myAIPageService: panelCofig.myAIPageService,
                                                                      extra: panelCofig.extra)
        let selectedVcFromToolIds = MyAIToolsSelectedViewController(toolIds: panelCofig.toolIds,
                                                                    userResolver: userResolver,
                                                                    chat: chat,
                                                                    aiChatModeId: panelCofig.aiChatModeId,
                                                                    myAIPageService: panelCofig.myAIPageService,
                                                                    extra: panelCofig.extra)
        let myAIToolsSelectedVc = panelCofig.toolIds.isEmpty ? selectedVcFromToolItems : selectedVcFromToolIds
        myAIToolsSelectedVc.startNewTopicHandler = panelCofig.startNewTopicHandler
        return myAIToolsSelectedVc
    }

    func generateAIToolSelectedUDPanel(panelConfig: MyAIToolsSelectedPanelConfig, chat: Chat) -> MyAIToolsPanelInterface {
        let toolsSelectedUDPanel = MyAIToolsSelectedPanel(panelConfig: panelConfig,
                                                        chat: chat)
        return toolsSelectedUDPanel
    }
}
