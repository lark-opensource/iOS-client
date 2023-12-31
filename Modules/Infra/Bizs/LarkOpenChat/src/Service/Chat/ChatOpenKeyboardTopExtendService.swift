//
//  ChatOpenKeyboardTopExtendService.swift
//  LarkOpenChat
//
//  Created by zc09v on 2022/1/12.
//

import Foundation

public protocol ChatOpenKeyboardTopExtendService: AnyObject {
    /// 刷新键盘上方扩展区域
    func refresh()
}

public final class DefaultChatOpenKeyboardTopExtendService: ChatOpenKeyboardTopExtendService {
    public init() {}
    public func refresh() {}
}
