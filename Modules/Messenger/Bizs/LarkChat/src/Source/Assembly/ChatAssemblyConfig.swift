//
//  ChatAssemblyConfig.swift
//  LarkChat
//
//  Created by wuwenjian.weston on 2020/3/17.
//

import Foundation

public protocol ChatAssemblyConfig {
    /// 是否支持扫码加群，如果关闭则不会注册对应路由
    var canJoinGroupByQRCode: Bool { get }
    /// 是否支持通过Body跳转到对应聊天，如果关闭不会注册对应路由，⚠️关闭前请确认没有聊天的相关功能
    var shouldRegisterChatBody: Bool { get }
}

public extension ChatAssemblyConfig {
    var canJoinGroupByQRCode: Bool { return true }
    var shouldRegisterChatBody: Bool { return true }
}
