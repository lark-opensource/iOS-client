//
//  MyAIMockToolSystemCellViewModel.swift
//  LarkAI
//
//  Created by ByteDance on 2023/7/3.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkMessengerInterface
import RustPB
import TangramService
import LarkContainer
import RichLabel
import LKCommonsLogging
import LarkUIKit

public class MyAIMockToolSystemCellViewModel<C: PageContext>: MyAIToolSystemCellViewModel<C> {
    private let logger = Logger.log(MyAIMockToolSystemCellViewModel.self, category: "MyAITool")
    public let toolIdList: [String]

    override var toolIds: [String] {
        return toolIdList
    }

    override var displayTopic: Bool {
        return false
    }

    public init(metaModel: CellMetaModel, context: C, toolIds: [String]) {
        self.toolIdList = toolIds
        super.init(metaModel: metaModel, context: context)
    }

    public override func tapAction(toolIds: [String]) {
        let aiChatModeId = self.context.myAIPageService?.chatModeConfig.aiChatModeId ?? 0
        let extra = ["messageId": "none", "chatId": chat.id, "source": "systemMessage"]
        self.logger.info("mock newTopicSelect toolIds: \(toolIdList) aiChatModeId:\(aiChatModeId)")
        let myAIToolsService = try? self.context.userResolver.resolve(assert: MyAIToolsService.self)
        let toolsSelectedPanel = myAIToolsService?.generateAIToolSelectedUDPanel(panelConfig: MyAIToolsSelectedPanelConfig(
            userResolver: self.context.userResolver,
            toolIds: toolIds,
            aiChatModeId: aiChatModeId,
            myAIPageService: self.context.myAIPageService,
            extra: extra),
                                                        chat: self.chat)
        toolsSelectedPanel?.show(from: context.targetVC)
    }

    override public var identifier: String {
        return "MyAIMockToolSystemCellViewModelIdentifier"
    }
}

public class MyAIMockToolMetaModel: CellMetaModel {
    public var message: Message {
        var pbModel = Message.PBModel()
        pbModel.type = .system
        return Message.transform(pb: pbModel)
    }
    public var getChat: () -> Chat
    public init(getChat: @escaping () -> Chat) {
        self.getChat = getChat
    }
}
