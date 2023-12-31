//
//  MessengerAssemblyConfig.swift
//  LarkMessenger
//
//  Created by wuwenjian.weston on 2020/3/17.
//

import Foundation
import LarkChat
import LarkContact
import LarkUrgent

/// 这个config是为了解决不同app内，LarkMessenger 需要剪裁一些 feature 而配置，默认值为 Lark 内的行为
public typealias MessengerAssemblyConfig = ChatAssemblyConfig
    & ContactAssemblyConfig
    & UrgentAssemblyConfig
    & NewChatAssemblyConfig

public struct MessengerAssemblyDefaultConfig: MessengerAssemblyConfig {
    public init() {}
}
