//
//  CardDependency.swift
//  UniversalCardInterface
//
//  Created by ByteDance on 2023/8/7.
//

import Foundation
import LarkContainer

public protocol UniversalCardDependencyProtocol {
    var userResolver: UserResolver? { get }
    // 复制用key, 卡片内部 text 复制时需要指定不同的 key 来标识复制内容, 这里需要传入一个统一前缀.
    var copyableKeyPrefix: String { get }
    var actionService: UniversalCardActionServiceProtocol? { get }
}
