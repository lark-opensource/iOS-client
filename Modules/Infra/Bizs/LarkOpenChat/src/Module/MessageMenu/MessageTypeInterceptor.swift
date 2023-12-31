//
//  MessageActionTypeInterceptor.swift
//  LarkOpenChat
//
//  Created by Zigeng on 2023/2/17.
//

import Foundation
import LarkMessageBase
import LarkModel

/// 开放给各消息类型业务方的类型拦截器,可拦截各业务方自己实现的消息类型上期望拒绝的功能
public final class OpenMessageTypeActionInterceptor: MessageActioSubnInterceptor {
    public required init() { }
    public static var subType: MessageActionSubInterceptorType { return .messageType }
    /// 消息类型拦截器字典
    public static var subInterceptors: [Message.TypeEnum: OpenMessageTypeActionSubInterceptor.Type] = [:]
    /// 注册消息类型期望拒绝的所有Action
    public static func register(_ subInterceptor: OpenMessageTypeActionSubInterceptor.Type) {
        Self.subInterceptors.updateValue(subInterceptor, forKey: subInterceptor.messageType)
    }
    public func intercept(context: MessageActionInterceptorContext) -> [MessageActionType : MessageActionInterceptedType] {
        var interceptedList: [MessageActionType : MessageActionInterceptedType] = [:]
        Self.subInterceptors[context.message.type]?.interceptedSet.forEach {
            interceptedList.updateValue(.hidden, forKey: $0)
        }
        return interceptedList
    }
}

public protocol OpenMessageTypeActionSubInterceptor {
    static var messageType: Message.TypeEnum { get }
    /// 返回对应消息类型拒绝的Action
    static var interceptedSet: Set<MessageActionType> { get }
}
