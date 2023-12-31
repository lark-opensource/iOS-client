//
//  FlodChatter.swift
//  LarkMessageCore
//
//  Created by Bytedance on 2022/9/23.
//

import Foundation

/// 每个Chatter模型，提供给FlodChatterLayout进行布局计算，提供给FlodChatterView进行渲染
public struct FlodChatter {
    /// 唯一标识
    let identifier: String
    /// 头像key
    let avatarKey: String
    /// 名字
    let name: String
    /// 聚合数量
    let number: UInt

    init (_ identifier: String, avatarKey: String, name: String, number: UInt = 0) {
        self.identifier = identifier
        self.avatarKey = avatarKey
        self.name = name
        self.number = number
    }
}
