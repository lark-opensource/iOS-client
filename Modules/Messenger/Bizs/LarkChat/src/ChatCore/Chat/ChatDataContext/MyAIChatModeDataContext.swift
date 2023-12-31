//
//  MyAIChatModeDataContext.swift
//  LarkChat
//
//  Created by ByteDance on 2023/10/16.
//

import Foundation
import LarkMessengerInterface
import LarkModel
import RustPB
import LarkSDKInterface

class MyAIChatModeDataContext: ChatDataContextProtocol {
    let identify = "MyAIChatModeDataContext"

    /// MyAI分会场场景，根消息的position为-1，所以这里我们设置为-2，不然ChatMessagesDatasource-checkVisible逻辑会把根消息过滤掉
    private let firstThreadPositionBound: Int32 = -2

    private let myAIPageService: MyAIPageService
    private var threadMessage: ThreadMessage? {
        return myAIPageService.chatModeThreadMessage
    }
    private var thread: RustPB.Basic_V1_Thread? {
        return threadMessage?.thread
    }
    var firstMessagePosition: Int32 {
        return self.firstThreadPositionBound
    }

    var lastMessagePosition: Int32 {
        return self.thread?.lastMessagePosition ?? 0
    }

    var lastVisibleMessagePosition: Int32 {
        return self.thread?.lastVisibleMessagePosition ?? 0
    }

    var readPositionBadgeCount: Int32 {
        return self.thread?.readPositionBadgeCount ?? 0
    }

    var readPosition: Int32 {
        return self.thread?.readPosition ?? 0
    }

    var lastReadPosition: Int32 {
        //分会话预期不会访问这个属性
        assertionFailure("not implemented")
        return 0
    }

    init(myAIPageService: MyAIPageService) {
        self.myAIPageService = myAIPageService
    }
}
