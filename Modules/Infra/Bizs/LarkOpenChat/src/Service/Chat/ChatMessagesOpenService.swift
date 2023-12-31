//
//  ChatMessagesOpenService.swift
//  LarkOpenChat
//
//  Created by Zigeng on 2023/2/17.
//

import Foundation
import LarkMessageBase
import LarkModel
import SnapKit

/// ChatMessagesVC对外暴露的能力
public protocol ChatMessagesOpenService: AnyObject {
    /// 获取当前页面UI数据源的所有消息
    func getUIMessages() -> [Message]
    /// 获取PageApi
    var pageAPI: PageAPI? { get }
    /// 页面内datasourceAPI
    var dataSource: DataSourceAPI? { get }
    /// 删除消息
    func delete(messageIds: [String], callback: ((Bool) -> Void)?)
}

public extension ChatMessagesOpenService {
    func getUIMessages() -> [Message] { return [] }
    func delete(messageIds: [String], callback: ((Bool) -> Void)?) { }
}

public class DefaultChatMessagesOpenService: ChatMessagesOpenService{
    public func getUIMessages() -> [Message] { return [] }
    public var pageAPI: PageAPI? { nil }
    public func delete(messageIds: [String], callback: ((Bool) -> Void)?) { }
    public var dataSource: DataSourceAPI? { nil }
    public init() { }
}
