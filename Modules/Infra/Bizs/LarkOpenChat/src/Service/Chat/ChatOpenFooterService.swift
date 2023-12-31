//
//  ChatOpenFooterService.swift
//  LarkOpenChat
//
//  Created by Zigeng on 2022/7/7.
//

import Foundation

public protocol ChatOpenFooterService: AnyObject {
    /// footer区域是否展示
    var isDisplay: Bool { get }
    /// 刷新 Footer 区域
    func refresh()
    /// 重新加载 Footer 区域
    func reload()
}

public final class DefaultChatOpenFooterService: ChatOpenFooterService {
    public var isDisplay: Bool {
        return false
    }
    public init() {}
    public func refresh() {}
    public func reload() {}
}
