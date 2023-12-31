//
//  CleanedActionInterceptor.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/4/13.
//

import Foundation
import LarkModel
import LarkMessageBase

/// 服务端已将将消息物理清除,不展示菜单
public final class CleanedActionInterceptor: MessageActioSubnInterceptor {
    public required init() { }
    public static var subType: MessageActionSubInterceptorType { .cleaned }
    public func intercept(context: MessageActionInterceptorContext) -> [MessageActionType: MessageActionInterceptedType] {
        var interceptedActions: [MessageActionType: MessageActionInterceptedType] = [:]
        if context.message.isCleaned {
            MessageActionType.allCases.forEach { interceptedActions.updateValue(.hidden, forKey: $0) }
        }
        return interceptedActions
    }
}
