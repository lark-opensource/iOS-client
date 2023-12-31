//
//  ReactionAPI.swift
//  LarkSDKInterface
//
//  Created by liuwanlin on 2018/5/31.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel

public protocol ReactionAPI {
    /// 增加Reaction到一个消息，RustSDK会立即push成功态。
    /// 该请求只会对一个消息增加Reaction，不会更新当前用户常用Reaction，更新用户常用Reaction需使用updateRecentlyUsedReaction
    /// - Parameter reaction: ReationModel
    /// - Returns: 跟reaction.messageId相关的全部ReactionModel状态
    func sendReaction(messageId: String, reactionType: String) -> Observable<Void>

    /// 删除一个消息上的Reaction，RustSDK会立即push成功态。
    ///
    /// - Parameter reaction: ReactionModel
    /// - Returns: return 跟reaction.messageId相关的全部ReactionModel状态
    func deleteISendReaction(messageId: String, reactionType: String) -> Observable<Void>

    /// 更新用户最近使用Reaction，PM要求点击Emoji和Reaction都需要发此请求
    func updateRecentlyUsedReaction(reactionType: String) -> Observable<Void>

    /// 获取用户最新 reactions
    func getUserReactions() -> Observable<[String]>

    /// 获取本版本支持的 reactions
    func getUsedReactions() -> Observable<[String]>

    /// 同步用户最新的 reactions
    func syncUserReactions() -> Observable<[String]>

    /// 同步本版本支持的 reactions
    func syncUsedReactions() -> Observable<[String]>

    /// 更新表情的肤色
    func updateReactionSkin(defaultReactionKey: String, skinKey: String) -> Observable<Void>
}

public typealias ReactionAPIProvider = () -> ReactionAPI
