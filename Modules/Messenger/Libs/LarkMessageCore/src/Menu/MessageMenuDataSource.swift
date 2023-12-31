//
//  MessageMenuDataSource.swift
//  LarkChat
//
//  Created by 李晨 on 2019/1/30.
//

import Foundation
import LarkEmotion
import LarkMessageBase
import LarkMenuController
import LarkEmotionKeyboard
import LarkOpenChat

public enum ReactionActionType {
    /// 点赞或者取消点赞
    case icon

    /// 点击了人名
    case name(_ chatterId: String)

    /// 点击人名后面的等几人
    case more
}

enum ReactionActionSource {
    case ReactionView           // 从ReactionView（消息下面的小尾巴） 直接点击
    case ReactionBar            // 从ReactionBar（最常使用） 处点击
    case ReactionPanel(Int)     // 从ReactionPanel（更多表情面板） 第n个section处点击：目前都是all类型，不区分recently（下线）和mru了
}
