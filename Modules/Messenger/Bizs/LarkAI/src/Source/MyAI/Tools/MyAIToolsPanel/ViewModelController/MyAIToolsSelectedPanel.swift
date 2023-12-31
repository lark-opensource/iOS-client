//
//  MyAIToolsPanel.swift
//  LarkIMMention
//
//  Created by ByteDance on 2023/5/22.
//

import UIKit
import Foundation
import RxSwift
import UniverseDesignActionPanel
import LarkAccountInterface
import LarkUIKit
import LarkContainer
import LarkModel
import LarkMessengerInterface

public final class MyAIToolsSelectedPanel: UDActionPanel, MyAIToolsPanelInterface {

    private var myAIToolsSelectedVC: MyAIToolsSelectedViewController

    public func show(from vc: UIViewController?) {
        myAIToolsSelectedVC.show(from: self)
        vc?.present(self, animated: true)
    }

    public init(panelConfig: MyAIToolsSelectedPanelConfig, chat: Chat) {
        self.myAIToolsSelectedVC = panelConfig.toolIds.isEmpty ?
        MyAIToolsSelectedViewController(toolItems: panelConfig.toolItems,
                                        userResolver: panelConfig.userResolver,
                                        chat: chat,
                                        aiChatModeId: panelConfig.aiChatModeId,
                                        myAIPageService: panelConfig.myAIPageService,
                                        extra: panelConfig.extra) :
        MyAIToolsSelectedViewController(toolIds: panelConfig.toolIds,
                                        userResolver: panelConfig.userResolver,
                                        chat: chat,
                                        aiChatModeId: panelConfig.aiChatModeId,
                                        myAIPageService: panelConfig.myAIPageService,
                                        extra: panelConfig.extra)
        self.myAIToolsSelectedVC.startNewTopicHandler = panelConfig.startNewTopicHandler
        let navigationVC = LkNavigationController(rootViewController: myAIToolsSelectedVC)
        var config = UDActionPanelUIConfig()
        config.originY = UIScreen.main.bounds.height * 0.5
        // 下拉组件自己实现
        config.canBeDragged = false
//        config.dismissByDrag = panelConfig.closeHandler
        super.init(customViewController: navigationVC, config: config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
