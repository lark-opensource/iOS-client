//
//  MyAIPageServiceImpl+Extension.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/13.
//

import Foundation
import RxSwift
import LarkModel
import LarkUIKit
import LarkStorage
import LarkSDKInterface
import LarkMessengerInterface

/// 插件相关逻辑放这里
public extension MyAIPageServiceImpl {
    /// 处理 AIExtensionConfig信息
    func handleAIExtensionConfig(aiExtensionConfig: AIExtensionConfig) {
        MyAIPageServiceImpl.logger.info("my ai pull extension config maxNum: \(aiExtensionConfig.maxNum)")
        if let userStore = self.userStore {
            let isSingleExtensionModeLocal = userStore[KVKeys.MyAITool.myAIModelType]
            let isSingleExtensionModeService = aiExtensionConfig.maxNum == 1 ? true : false
            guard isSingleExtensionModeLocal != isSingleExtensionModeService else { return }
            userStore[KVKeys.MyAITool.myAIModelType] = aiExtensionConfig.maxNum == 1 ? true : false
        }
        self.aiExtensionConfig.accept(aiExtensionConfig)
    }

    /// 处理 AISessionInfo信息
    func handleAISessionInfo(aiSessionInfo: AISessionInfo) {
        MyAIPageServiceImpl.logger.info("my ai pull last session info lastNewTopicSystemPosition: \(aiSessionInfo.lastNewTopicSystemMsgPosition)")
        self.aiSessionInfo.accept(aiSessionInfo)
    }

    private func didClickExtension(isAllowSelect: Bool, toolIds: [String], extra: [AnyHashable: Any], chat: Chat, from: UIViewController) {
        guard let userResolver = self.userResolver else { return }
        let myAIPageService = self
        let aiChatModeId = myAIPageService.chatModeConfig.aiChatModeId
        if isAllowSelect {
            let body = MyAIToolsBody(chat: chat,
                                     scenario: myAIPageService.chatModeConfig.objectType.getScenarioID(),
                                     selectedToolIds: toolIds,
                                     aiChatModeId: aiChatModeId,
                                     myAIPageService: myAIPageService,
                                     extra: extra)
            userResolver.navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: from
            )
        } else {
            //当前extension 已产生过会话，不可以修改了，只可查看详情
            let myAIToolsService = try? userResolver.resolve(assert: MyAIToolsService.self)
            let toolsSelectedPanel = myAIToolsService?.generateAIToolSelectedUDPanel(panelConfig: MyAIToolsSelectedPanelConfig(userResolver: userResolver,
                                                                                                                               toolIds: toolIds,
                                                                                                                               aiChatModeId: aiChatModeId,
                                                                                                                               myAIPageService: myAIPageService,
                                                                                                                               extra: extra),
                                                                                     chat: chat)
            toolsSelectedPanel?.show(from: from)
        }
    }

    /// 点击了卡片中的选择插件，调起选择插件面板
    func handleExtensionCardApplink(messageId: String, chat: Chat, from: UIViewController) {
        self.messageAPI?.fetchMessage(id: messageId).observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (message) in
                MyAIPageServiceImpl.logger.info("extension card applink get local message success:\(message.id)")
                guard let `self` = self else { return }
                self.extensionTapAction(by: message, chat: chat, from: from)
            }, onError: { (error) in
                MyAIPageServiceImpl.logger.info("extension card applink get local message failure \(error)")
            }).disposed(by: self.disposeBag)
    }

    /// 插件卡片消息点击
    private func extensionTapAction(by message: Message?, chat: Chat, from: UIViewController) {
        MyAIPageServiceImpl.logger.info("extension card tap select")
        guard let message = message, chat.isP2PAi else {
            MyAIPageServiceImpl.logger.info("extensionTapAction myAIPageService nil")
            // UX 说这种case就先点击无反应
            return
        }
        // myAI分会场
        let myAIPageService = self
        let isMyAIChatMode = myAIPageService.chatMode
        let aiRoundInfo = myAIPageService.aiRoundInfo.value
        let aiChatModeId = myAIPageService.chatModeConfig.aiChatModeId
        let extra = ["messageId": message.id, "chatId": chat.id]
        // 判断是在同一主、分会场内点击
        guard aiChatModeId == message.aiChatModeID else {
            return
        }
        // 判断是否在最后一轮会话点击
        if (aiRoundInfo.roundLastPosition > message.position && !isMyAIChatMode) ||
            (aiRoundInfo.roundLastPosition > message.threadPosition && isMyAIChatMode) {
            MyAIPageServiceImpl.logger.info("cannot select extension messageId:\(message.id) aiChatModeId:\(aiChatModeId)")
            //当前extension 已产生过会话，不可以修改了，只可查看详情
            self.didClickExtension(isAllowSelect: false, toolIds: [], extra: extra, chat: chat, from: from)
        } else {
            MyAIPageServiceImpl.logger.info("select extension messageId:\(message.id)")
            self.didClickExtension(isAllowSelect: true, toolIds: [], extra: extra, chat: chat, from: from)
        }
    }
}
