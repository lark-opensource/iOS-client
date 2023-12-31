//
//  ContactAssemblyConfig.swift
//  LarkContact
//
//  Created by wuwenjian.weston on 2020/3/17.
//

import Foundation

public protocol ContactAssemblyConfig {
    /// 是否启用加好友的功能，如果不启用，assemble 时不会注册相关路由
    var canAddFriend: Bool { get }
}

public extension ContactAssemblyConfig {
    var canAddFriend: Bool { return true }
}
