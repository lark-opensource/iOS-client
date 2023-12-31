//
//  NewChatAssemblyConfig.swift
//  LarkChat
//
//  Created by wuwenjian.weston on 2020/3/18.
//

import Foundation

public protocol NewChatAssemblyConfig {
    // 是否支持从外部URL（如点击推送）跳转到聊天页面，关闭则不进行处理
    var canGoToChatByExternalURL: Bool { get }
}

public extension NewChatAssemblyConfig {
    var canGoToChatByExternalURL: Bool { return true }
}
