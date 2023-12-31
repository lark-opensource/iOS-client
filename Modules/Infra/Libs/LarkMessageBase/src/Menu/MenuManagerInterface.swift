//
//  MenuManagerInterface.swift
//  LarkMessageBase
//
//  Created by Zigeng on 2023/1/20.
//

import Foundation
import LarkModel

public enum CopyMessageSelectedType {
    case all
    case range(NSRange)
    case from(Int)
    case to(Int)
    case richView(() -> (NSAttributedString, MessageSelectedType)?)
}

// 消息选中位置
public enum MessageSelectedType {
    case all // 全部选中
    case head // 选中头部
    case middle // 选中中间
    case tail // 选中尾部

    public static func transform(
        canSelectMoreAhead: Bool,
        canSelectMoreAftwards: Bool
    ) -> MessageSelectedType {
        if canSelectMoreAhead, !canSelectMoreAftwards { // 前面有更多，后面没有
            return .tail
        } else if !canSelectMoreAhead, canSelectMoreAftwards { // 后面有更多，前面没有
            return .head
        } else if canSelectMoreAhead, canSelectMoreAftwards { // 前后都有更多
            return .middle
        }
        return .all
    }
}

/// copy维度
public enum CopyMessageType {
    /// 消息
    case message
    /// 原文
    case origin
    /// 译文
    case translate
    /// 卡片
    case card((() -> NSAttributedString)?)
}
