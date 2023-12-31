//
//  ReactionModel.swift
//  LarkReactionView
//
//  Created by 李晨 on 2019/6/5.
//

import UIKit
import Foundation
import LarkEmotion

public final class ReactionUser {
    public var id: String
    public var name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public final class ReactionInfo {
    public var reactionKey: String
    public var reactionSize: CGSize?
    public var users: [ReactionUser]

    public init(reactionKey: String, users: [ReactionUser]) {
        self.reactionKey = reactionKey
        self.reactionSize = EmotionResouce.shared.sizeBy(key: reactionKey)
        self.users = users
    }
}

public enum ReactionTapType {
    /// 点赞或者取消点赞
    case icon
    /// 点击了人名
    case name(_ id: String)
    /// 点击人名后面的等几人
    case more
}

struct ReactionOpenEntrance {
    static var reactionImage = Resources.reactionOpenEntrance
    static var reactionSize = CGSize(width: 15, height: 15)
    static var reactionKey = "EmojiOpenEntrance"
}
