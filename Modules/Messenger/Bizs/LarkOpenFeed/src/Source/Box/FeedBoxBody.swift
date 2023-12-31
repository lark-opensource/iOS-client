//
//  FeedBoxBody.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2023/4/3.
//

import Foundation
import EENavigator

// 会话盒子
public struct ChatBoxBody: CodablePlainBody {
    public static let pattern = "//client/feed/chatBox"
    public let chatBoxId: String

    public init(chatBoxId: String) {
        self.chatBoxId = chatBoxId
    }
}
