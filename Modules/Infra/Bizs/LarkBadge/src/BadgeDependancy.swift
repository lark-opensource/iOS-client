//
//  BadgeDependancy.swift
//  Kingfisher
//
//  Created by KT on 2019/4/23.
//

import Foundation

/// Badge外部依赖
public protocol BadgeDependancy {

    /// 有效Badge节点名称 - 规则：完全匹配
    var whiteLists: [NodeName] { get }

    /// 有效前缀 e.g. ["chat_id"] 匹配 "chat_id12345"
    var prefixWhiteLists: [NodeName] { get }
}
