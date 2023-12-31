//
//  EmojiDataDependency.swift
//  ByteView
//
//  Created by lutingting on 2023/9/19.
//

import Foundation
import ByteViewNetwork


public protocol EmojiDataDependency {
    /// 根据类型获取用户的Reactions：最近使用/最常使用
    func getUserReactionsByType() -> [ReactionEntity]

    /// 获取所有表情分类: 包含默认和企业自定义
    func getAllReactions() -> [ReactionGroup]

    /// 获取企业自定义表情分类
    func getCustomReactions() -> [ReactionGroup]
}

public struct ReactionEntity {
    public let key: String
    public let selectSkinKey: String
    public let skinKeys: [String]
    public let size: CGSize

    public init(key: String, selectSkinKey: String, skinKeys: [String], size: CGSize) {
        self.key = key
        self.selectSkinKey = selectSkinKey
        self.skinKeys = skinKeys
        self.size = size
    }
}

public struct ReactionGroup {
    public let type: EmojiPanel.EmojiPanelType
    public let iconKey: String
    public let title: String
    public let source: String
    public let entities: [ReactionEntity]

    public init(type: EmojiPanel.EmojiPanelType, iconKey: String, title: String, source: String, entities: [ReactionEntity]) {
        self.type = type
        self.iconKey = iconKey
        self.title = title
        self.source = source
        self.entities = entities
    }
}
