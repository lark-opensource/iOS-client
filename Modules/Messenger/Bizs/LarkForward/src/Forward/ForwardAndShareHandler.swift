//
//  ForwardAndShareHandler.swift
//  Lark
//
//  Created by zc09v on 2018/5/29.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkCore
import LarkModel
import LarkMessengerInterface

public protocol ForwardAndShareHandler {
    func itemsToIds(_ items: [ForwardItem]) -> (chatIds: [String], userIds: [String], filterIds: [String])
}

extension ForwardAndShareHandler {

    public func itemsToIds(_ items: [ForwardItem]) -> (chatIds: [String], userIds: [String], filterIds: [String]) {
        var chatIds: [String] = []
        var userIds: [String] = []
        var filterIds: [String] = []
        items.forEach { (item) in
            switch item.type {
            case .chat:
                chatIds.append(item.id)
            case .user, .myAi:
                userIds.append(item.id)
            case .bot:
                userIds.append(item.id)
            case .generalFilter:
                filterIds.append(item.id)
            // 目前这一块不需要支持转发到帖子，因此不需要对.threadMessage作处理
            case .unknown, .threadMessage, .replyThreadMessage:
                break
            }
        }
        return (chatIds: chatIds, userIds: userIds, filterIds: filterIds)
    }
}
