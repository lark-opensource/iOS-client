//
//  MenuReactionItem.swift
//  LarkReactionPanel
//
//  Created by 王元洵 on 2021/2/8.
//

/// MenuReactionItem
public struct MenuReactionItem {
    /// ReactionKey
    public var type: String {
        return reactionEntity.selectSkinKey
    }

    public var subTypes: [String] {
        return reactionEntity.skinKeys
    }

    public let reactionEntity: ReactionEntity
    /// ClickAction
    public let action: (String) -> Void

    /// init
    public init(type: String,
                action: @escaping (String) -> Void) {
        self.reactionEntity = ReactionEntity(key: type, selectSkinKey: type, skinKeys: [])
        self.action = action
    }

    /// init
    public init(reactionEntity: ReactionEntity,
                action: @escaping (String) -> Void) {
        self.reactionEntity = reactionEntity
        self.action = action
    }
}
