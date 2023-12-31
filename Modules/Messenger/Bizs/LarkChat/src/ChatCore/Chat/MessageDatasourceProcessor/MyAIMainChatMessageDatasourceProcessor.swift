//
//  MyAIMainChatMessageDatasourceProcessor.swift
//  LarkChat
//
//  Created by ByteDance on 2023/10/18.
//

import Foundation
import LarkModel
import ThreadSafeDataStructure
import LarkContainer

class MyAIMainChatMessageDatasourceProcessor: BaseChatMessageDatasourceProcessor {
    //展开的myAI分会场消息。不在字典里的说明是折叠的。
    //key：myAIChatModeID；  value:最多展示的条数（超出的话展示load more）
    private(set) var unfoldedMyAIChatModeThread: SafeDictionary<Int64, MyAIChatModeThreadInfo> = [:] + .readWriteLock

    var userResolver: UserResolver
    init(userResolver: UserResolver, isNewRecalledEnable: Bool) {
        self.userResolver = userResolver
        super.init(isNewRecalledEnable: isNewRecalledEnable)
    }

    override func processBeforFirst(message: Message) -> [CellVMType] {
        var types: [CellVMType] = self.getStickToTopCellVMType()

        var hideMessage = false

        if message.aiChatModeID > 0 && message.threadPosition == -1 { // my ai分会场根消息
            if message.thread != nil {
                types.append(.aiChatModeFoldMessage(rootMessage: message))
            } else {
                assertionFailure("no thread on curMessage")
            }
            // 如果用户没有展开此分会场消息，则不展示根消息，只展示上方的.aiChatModeFoldMessage
            hideMessage = unfoldedMyAIChatModeThread[message.aiChatModeID]?.unfoldedMaxPosition ?? 0 <= 0
        }

        if !hideMessage {
            types.append(generateCellVMTypeForMessage(prev: nil, cur: message, mustBeSingle: true))
        }
        return types
    }

    override func process(prev: Message, cur: Message) -> [CellVMType] {
        var types: [CellVMType] = []
        var mustBeSingle = false
        var hideMessage: Bool = false

        if cur.aiChatModeID > 0 && cur.threadPosition == -1 { // my ai分会场根消息
            if cur.thread != nil {
                types.append(.aiChatModeFoldMessage(rootMessage: cur))
            } else {
                assertionFailure("no thread on curMessage")
            }
            // 如果用户没有展开此分会场消息，则不展示根消息，只展示上方的.aiChatModeFoldMessage
            hideMessage = unfoldedMyAIChatModeThread[cur.aiChatModeID]?.unfoldedMaxPosition ?? 0 <= 0
            mustBeSingle = true
        }

        // 如果是自己发送的新话题消息，需要在消息上方展示一个mock的系统消息。
        if cur.isAiSessionFirstMsg, cur.isMeSend(userId: userResolver.userID) {
            types.append(.mockSystemMessage(.textWithLine(BundleI18n.AI.Lark_MyAI_IM_Server_StartNewTopic_Text)))
            mustBeSingle = true
        }

        if !hideMessage {
            types.append(generateCellVMTypeForMessage(prev: prev, cur: cur, mustBeSingle: mustBeSingle))
        }
        return types
    }

    override func isMessagesInSameGroup(prev: Message, cur: Message) -> Bool {
        //两个消息来自不同的my ai分会话（或一个来自my ai分会话 另一个来自my ai主会话），则不吸附
        if prev.aiChatModeID != cur.aiChatModeID {
            return false
        }
        return super.isMessagesInSameGroup(prev: prev, cur: cur)
    }
}

class MyAIChatModeThreadInfo {
    var unfoldedMaxPosition: Int32 = 0     //当前最多展开到哪个position之前。如果有大于等于这个position的消息则展示load more
    var rootMessagePosition: Int32 = -1 //根消息的position
    var currentMaxThreadPosition: Int32 = -2   //(该分会话的)展开且渲染了的消息中，最大的threadPosition
}
