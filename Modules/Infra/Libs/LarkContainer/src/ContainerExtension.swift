//
//  Container.swift
//  LarkContainer
//
//  Created by liuwanlin on 2018/4/18.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import Swinject
import EEAtomic

let pushNotificationCenter = PushNotificationCenter()

extension Resolver {
    /// 全局的pushCenter
    @available(*, deprecated, message: "use `globalPushCenter` or `userPushCenter` instead")
    public var pushCenter: PushNotificationCenter { pushNotificationCenter }
    /// 全局的pushCenter, 用于发送和接收用户无关的消息。该实例不会被销毁
    /// 通过改名来保证旧调用都被确认修改过了..
    public var globalPushCenter: PushNotificationCenter { pushNotificationCenter }
    /// 用户态的PushCenter，用于发送和接收用户相关的消息。出于方便考虑，该实例也可以接受全局消息
    /// NOTE: 用户消息，发送和接收需要是相同的实例
    /// 使用UserResolver时可能抛出异常..
    public var userPushCenter: PushNotificationCenter {
      get throws { try resolve(type: PushNotificationCenter.self) }
    }
}
