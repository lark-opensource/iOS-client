//
//  EmojiDataSourceDependency.swift
//  LarkSDKInterface
//
//  Created by 李晨 on 2019/2/3.
//

import UIKit
import Foundation
import RustPB
import RxSwift

public struct ReactionEntity {
    public let key: String
    public let selectSkinKey: String
    public let skinKeys: [String]
    // emoji 原图的尺寸, 单位pt
    public let size: CGSize

    public init(key: String,
                selectSkinKey: String,
                skinKeys: [String],
                size: CGSize? = nil) {
        self.key = key
        self.selectSkinKey = selectSkinKey
        self.skinKeys = skinKeys
        self.size = size ?? .zero
    }
}

public struct ReactionGroup {
    public let type: Im_V1_EmojiPanel.TypeEnum
    // 分类的 icon
    public let iconKey: String
    // 分类的 title, 返回国际化
    public let title: String
    // hover 上去展示的文案，返回国际化
    public let source: String
    public let entities: [ReactionEntity]

    public init(type: Im_V1_EmojiPanel.TypeEnum,
                iconKey: String,
                title: String,
                source: String,
                entities: [ReactionEntity]) {
        self.type = type
        self.iconKey = iconKey
        self.title = title
        self.source = source
        self.entities = entities
    }
}

/// ReactionService
public protocol EmojiDataSourceDependency: EmojiSkinDependency {
    /// 获取「最常使用」分类中的表情
    func getMRUReactions() -> [ReactionEntity]
    /// 获取所有表情分类: 「包含默认」和「企业自定义」
    func getAllReactions() -> [ReactionGroup]
    /// 获取「企业自定义」表情分类
    func getCustomReactions() -> [ReactionGroup]
    /// 表情刷新：冷启动/重新登陆/切租户都会被调用
    func loadReactions()
    /// 处理网络连上的push
    func handleWebStatusPush()
    /// 处理「最常使用」表情的push
    func handleMRUReactionPush(keys: [String])
    /// 处理表情面板上所有分类表情的push
    func handleAllReactionPush(panel: Im_V1_EmojiPanel)
    /// 更新多肤色表情
    func updateReactionSkin(defaultReactionKey: String, skinKey: String)
    /// 更新「最常使用」表情
    func updateUserReaction(key: String)
    /// 获得最近使用表情（已经废弃）
    @available(*, deprecated, message: "use getMRUReactions to instead")
    func getRecentReactions() -> [ReactionEntity]
    /// 获得所有表情（已经废弃）
    @available(*, deprecated, message: "use getAllReactions to instead")
    func getUsedReactions() -> [String]
    /// 获取默认表情（已经废弃）
    @available(*, deprecated, message: "use getAllReactions to instead")
    func getDefaultReactions() -> [ReactionEntity]
}

public final class ReactionListener {
    public var allReactionChangeHandler: () -> Void = {}
    public var mruReactionChangeHandler: () -> Void = {}
    public init() {}
}

public protocol EmojiSkinDependency {
    /// 添加reaction改变事件
    func registReactionListener(_ listener: ReactionListener)
    /// 根据reactionKey获取ReactionEntity
    func getReactionEntityFromOriginKey(_ key: String) -> ReactionEntity?
}

public extension EmojiDataSourceDependency {
    func getDefaultReactions() -> [ReactionEntity] {
            return []
    }
    func getAllReactions() -> [ReactionGroup] {
        return []
    }
    func getCustomReactions() -> [ReactionGroup] {
        return []
    }
    func handleWebStatusPush() {}
    func handleMRUReactionPush(keys: [String]) {}
    func handleAllReactionPush(panel: Im_V1_EmojiPanel) {}
    func updateReactionSkin(defaultReactionKey: String, skinKey: String) {}
    func updateUserReaction(key: String) {}
}

/// EmojiImageService
/// 单例拆分，组件化改造一起处理，TODO：@qujieye
public enum EmojiImageService {
    /// default reaction image service
    public static let `default`: EmojiDataSourceDependency? = {
        #if LarkEmotion_EmojiDependency
        return ReactionServiceDefaultImpl()
        #else
        return nil
        #endif
    }()
}
