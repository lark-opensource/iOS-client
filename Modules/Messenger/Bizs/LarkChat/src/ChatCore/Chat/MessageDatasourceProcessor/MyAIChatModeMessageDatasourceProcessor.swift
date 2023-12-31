//
//  MyAIChatModeMessageDatasourceProcessor.swift
//  LarkChat
//
//  Created by ByteDance on 2023/10/18.
//

import Foundation
import LarkModel
import LarkMessengerInterface

class MyAIChatModeMessageDatasourceProcessor: BaseChatMessageDatasourceProcessor {
    let myAIPageService: MyAIPageService

    init(myAIPageService: MyAIPageService,
         isNewRecalledEnable: Bool) {
        self.myAIPageService = myAIPageService
        super.init(isNewRecalledEnable: isNewRecalledEnable)
    }

    override func processBeforFirst(message: Message) -> [CellVMType] {
        var types: [CellVMType] = self.getStickToTopCellVMType()
        types.append(generateCellVMTypeForMessage(prev: nil, cur: message, mustBeSingle: true))
        return types
    }

    override func process(prev: Message, cur: Message) -> [CellVMType] {
        var types: [CellVMType] = []
        types.append(generateCellVMTypeForMessage(prev: prev, cur: cur, mustBeSingle: false))
        return types
    }

    override func getStickToTopCellVMType() -> [CellVMType] {
        var types: [CellVMType] = []
        // 「协作记录」系统消息
        if dependency?.container?.userResolver.fg.dynamicFeatureGatingValue(with: "lark.my_ai.card_swich_extension") != true {
            //当fg"lark.my_ai.card_swich_extension"为true时，不展示“你发起了协作”系统消息
            let greetingMessageType = myAIPageService.chatModeConfig.greetingMessageType
            types.append(.mockSystemMessage(greetingMessageType.toMyAIMockSystemCellConfigType()))
        }
        // 业务方传入的默认插件
        let toolIds = myAIPageService.chatModeConfig.toolIds
        if !toolIds.isEmpty { types.append(.mockToolSystemMessage(toolIds: toolIds)) }
        types.append(contentsOf: super.getStickToTopCellVMType())
        return types
    }
}
