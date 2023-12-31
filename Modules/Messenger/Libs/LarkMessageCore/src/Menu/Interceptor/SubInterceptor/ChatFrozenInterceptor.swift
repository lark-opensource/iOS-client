//
//  ChatFrozenInterceptor.swift
//  LarkMessageCore
//
//  Created by zhaojiachen on 2023/2/28.
//

import Foundation
import LarkMessageBase

public class ChatFrozenInterceptor: MessageActioSubnInterceptor {
    public static var subType: MessageActionSubInterceptorType { .chatForzen }
    public required init() { }
    public func intercept(context: MessageActionInterceptorContext) -> [MessageActionType: MessageActionInterceptedType] {
        guard context.chat.isFrozen else { return [:] }
        let interceptList: [MessageActionType] = [.urgent, .createThread, .topMessage, .pin, .chatPin, .multiEdit, .restrict, .reply, .recall, .reaction]
        var interceptedActions: [MessageActionType: MessageActionInterceptedType] = [:]
        interceptList.forEach {
            interceptedActions[$0] = .hidden
        }
        return interceptedActions

    }
}
