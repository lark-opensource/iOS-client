//
//  ReactionServiceImpl.swift
//  LarkSDK
//
//  Created by 李晨 on 2019/2/3.
//

import Foundation
import RxSwift
import LKCommonsLogging
import ThreadSafeDataStructure
import RustPB
import ServerPB
import LarkContainer
import LarkRustClient
import LarkAccountInterface
import LarkFeatureGating
import LarkEmotion
import LarkStorage
import LarkSetting
import UIKit
import LarkLocalizations

final public class ReactionServiceDefaultImpl: EmojiDataSourceDependency {
    private static let logger = Logger.log(ReactionServiceDefaultImpl.self, category: "Module.LarkEmotionKeyboard.ReactionService")

    @Provider private var client: RustService

    private let disposeBag: DisposeBag = DisposeBag()

    // 最常使用表情两行FG
    public var isCommonlyUsedABTestEnable: Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: "im.emoji.commonly_used_abtest")
    }

    // 最常使用表情
    private var mruReactions: SafeDictionary<String, [String]> = [:] + .semaphore
    // 所有表情资源
    private var allReactions: SafeDictionary<String, [ReactionGroup]> = [:] + .semaphore

    private let currentUserId = { AccountServiceAdapter.shared.currentChatterId }

    private var reactionListenerWrppers: Set<ReactionListenerWrpper> = []
    private let lock = NSLock()

    public init() {}

    // MARK: EmojiDataSourceDependency
    
    // 根据类型获取用户的Reactions：最近使用/最常使用
    public func getMRUReactions() -> [ReactionEntity] {
        return self.getReactions()
    }
    
    // 获得最近使用表情（已经废弃）
    public func getRecentReactions() -> [ReactionEntity] {
        self.getReactions()
    }

    // 获得所有表情（已经废弃）
    public func getUsedReactions() -> [String] {
        return getDefaultReactions().map { $0.key }
    }

    // 获取默认表情（已经废弃）
    public func getDefaultReactions() -> [ReactionEntity] {
        var reactions = self.allReactions[self.currentUserId()]?.first(where: { $0.type == .default })?.entities ?? []
        // 兜底reaction
        if reactions.isEmpty {
            reactions = EmotionResouce.reactions.map { ReactionEntity(key: $0, selectSkinKey: $0, skinKeys: EmotionResouce.shared.skinKeysBy(key: $0), size: EmotionResouce.shared.sizeBy(key: $0)) }
        }
        return reactions
    }

    // 获取所有表情分类: 包含默认和企业自定义
    public func getAllReactions() -> [ReactionGroup] {
        // 这个接口是提供给上层业务的，所以需要把每个表情分组里面”非法的“表情过滤掉，业务不关心那些表情是非法的，统一在这边收口
        var filterGroups: [ReactionGroup] = []
        // 这边是从服务端接口返回的原始表情分组
        let serverGroups = self.allReactions[self.currentUserId()] ?? []
        // 如果为空的话直接返回不用再走下面的过滤逻辑和打日志了
        if serverGroups.isEmpty {
            return []
        }
        // 日志上报
        var params: [String: String] = [:]
        var extraInfo: [(title: String, entitiesCount: Int)] = []
        for group in serverGroups {
            let tuples = (title: group.title, entitiesCount: group.entities.count)
            extraInfo.append(tuples)
        }
        params["count"] = "\(serverGroups.count)"
        params["groups"] = "\(extraInfo)"
        Self.logger.info("ReactionServiceDefaultImpl: allReactionGroups from server", additionalData: params)
        // 开始过滤逻辑
        for group in serverGroups {
            // 过滤已经下线、没有图片的表情
            let filterEntities = group.entities
                .filter({
                    // 如果是企业自定义表情的话不需要过滤
                    if group.type == .custom {
                        return true
                    }
                    // 过滤已经下线的表情
                    let isDeleted = EmotionResouce.shared.isDeletedBy(key: $0.selectSkinKey)
                    if isDeleted {
                        Self.logger.error("ReactionServiceDefaultImpl: emojiKey \($0.selectSkinKey) is deleted, remove from group")
                    }
                    return !isDeleted
                })
                .filter({
                    // 如果是企业自定义表情的话不需要过滤
                    if group.type == .custom {
                        return true
                    }
                    // 过滤没有图片的表情
                    let image = EmotionResouce.shared.imageBy(key: $0.selectSkinKey)
                    if image == nil {
                        Self.logger.error("ReactionServiceDefaultImpl: type = \(group.type) emojiKey \($0.selectSkinKey) has no image, remove from group")
                    }
                    return image != nil
                })
            // 更新数据源
            filterGroups.append(ReactionGroup(type: group.type, iconKey: group.iconKey, title: group.title, source: group.source, entities: filterEntities))
        }
        // 日志上报
        params.removeAll()
        extraInfo.removeAll()
        for group in filterGroups {
            let tuples = (title: group.title, entitiesCount: group.entities.count)
            extraInfo.append(tuples)
        }
        params["count"] = "\(filterGroups.count)"
        params["groups"] = "\(extraInfo)"
        Self.logger.info("ReactionServiceDefaultImpl: allReactionGroups after filter", additionalData: params)
        // 把过滤以后得表情分组返回
        return filterGroups
    }

    // 获取企业自定义表情分类
    public func getCustomReactions() -> [ReactionGroup] {
        self.allReactions[self.currentUserId()]?.filter({ $0.type == .custom }) ?? []
    }

    // 表情刷新：冷启动/重新登陆/切租户都会被调用
    public func loadReactions() {
        self.loadLocalReactions()
        self.fetchServerReactions()
    }

    // 处理网络连上的push
    public func handleWebStatusPush() {
        self.fetchUserReactions()
    }
    
    // 处理最常使用表情的push
    public func handleMRUReactionPush(keys: [String]) {
        ReactionServiceDefaultImpl.logger.info("ReactionServiceDefaultImpl push mru reactions: \(keys)")
        self.handleUserReactions(keys: keys)
    }

    // 处理表情面板上所有分类表情的push
    public func handleAllReactionPush(panel: Im_V1_EmojiPanel) {
        let emojiKeys = panel.emojisOrder.flatMap({ $0.keys })
        ReactionServiceDefaultImpl.logger.info("ReactionServiceDefaultImpl push all Reactions: keysCount = \(emojiKeys.count)")
        self.handleAllReactions(panel: panel)
    }
    
    // 更新多肤色表情
    public func updateReactionSkin(defaultReactionKey: String, skinKey: String) {
        self.rustUpdateReactionSkin(defaultReactionKey: defaultReactionKey, skinKey: skinKey).subscribe(onNext: { (res) in
            ReactionServiceDefaultImpl.logger.info("ReactionServiceDefaultImpl updateReactionSkin: \(defaultReactionKey) skinKey: \(skinKey) userSkinVersion = \(res.userSkinVersion)")
        }, onError: { (error) in
            ReactionServiceDefaultImpl.logger.error("ReactionServiceDefaultImpl updateReactionSkin: \(defaultReactionKey) skinKey: \(skinKey) failed", error: error)
        }).disposed(by: disposeBag)
    }
    
    /// 更新用户最近和最常使用表情
    public func updateUserReaction(key: String) {
        var request = ServerPB_Reactions_UpdateUserRecentlyUsedReactionRequest()
        request.reactionKey = key
        self.client.sendPassThroughAsyncRequest(request, serCommand: .updateUserRecentlyUsedEmoji).subscribe().dispose()
    }

    // MARK: EmojiSkinDependency

    public func registReactionListener(_ listener: ReactionListener) {
        defer { lock.unlock() }
        let wrapper = ReactionListenerWrpper()
        wrapper.listener = listener
        lock.lock()
        reactionListenerWrppers.insert(wrapper)
    }

    public func getReactionEntityFromOriginKey(_ key: String) -> ReactionEntity? {
        let reactions = self.getAllReactions().flatMap({ $0.entities })
        return reactions.first { entity in
            return entity.key == key
        }
    }

    // MARK: 私有方法
    
    private func loadLocalReactions() {
        self.loadUserReactions()
        self.loadAllReactions()
    }

    private func fetchServerReactions() {
        self.fetchUserReactions()
        self.fetchAllReactions()
    }

    private func loadUserReactions() {
        let beginTime = CACurrentMediaTime()
        self.rustGetUserReactions().subscribe(onNext: { [weak self] (keys) in
            // 转成ms
            let time = (CACurrentMediaTime() - beginTime) * 1000
            // 获取最常使用表情
            EmotionTracker.trackerSlardar(event: "emoji_get_mru_reactions", time: time, category: ["from_local" : true], metric: [:], error: nil)
            EmotionTracker.trackerTea(event: Const.getMruReactionsEvent, time: time, extraParams: [Const.local: true], error: nil)
            ReactionServiceDefaultImpl.logger.info("ReactionServiceDefaultImpl get reactions success")
            self?.handleUserReactions(keys: keys)
        }, onError: { (error) in
            // 转成ms
            let time = (CACurrentMediaTime() - beginTime) * 1000
            // 获取最常使用表情
            EmotionTracker.trackerSlardar(event: "emoji_get_mru_reactions", time: time, category: ["from_local" : true], metric: [:], error: error)
            EmotionTracker.trackerTea(event: Const.getMruReactionsEvent, time: time, extraParams: [Const.local: true], error: error)
            ReactionServiceDefaultImpl.logger.error("ReactionServiceDefaultImpl get reactions failed", error: error)
        }).disposed(by: disposeBag)
    }

    private func loadAllReactions() {
        let beginTime = CACurrentMediaTime()
        self.rustGetAllReactions().subscribe(onNext: { [weak self] (res) in
            // 转成ms
            let time = (CACurrentMediaTime() - beginTime) * 1000
            // 获取 Emoji 面板数据
            EmotionTracker.trackerSlardar(event: "emoji_get_emoji_panel", time: time, category: ["from_local" : true], metric: [:], error: nil)
            EmotionTracker.trackerTea(event: Const.getEmojiPanelEvent, time: time, extraParams: [Const.local: true], error: nil)
            ReactionServiceDefaultImpl.logger.info("ReactionServiceDefaultImpl get all reactions success")
            self?.handleAllReactions(panel: res.emojiPanel)
        }, onError: { (error) in
            // 转成ms
            let time = (CACurrentMediaTime() - beginTime) * 1000
            // 获取 Emoji 面板数据
            EmotionTracker.trackerSlardar(event: "emoji_get_emoji_panel", time: time, category: ["from_local" : true], metric: [:], error: error)
            EmotionTracker.trackerTea(event: Const.getEmojiPanelEvent, time: time, extraParams: [Const.local: true], error: error)
            ReactionServiceDefaultImpl.logger.error("ReactionServiceDefaultImpl get all Reactions failed", error: error)
        }).disposed(by: disposeBag)
    }

    private func fetchUserReactions() {
        let beginTime = CACurrentMediaTime()
        self.rustSyncUserReactions().subscribe(onNext: { [weak self] (keys) in
            // 转成ms
            let time = (CACurrentMediaTime() - beginTime) * 1000
            // 获取最常使用表情
            EmotionTracker.trackerSlardar(event: "emoji_get_mru_reactions", time: time, category: ["from_local" : false], metric: [:], error: nil)
            EmotionTracker.trackerTea(event: Const.getMruReactionsEvent, time: time, extraParams: [Const.local: false], error: nil)
            ReactionServiceDefaultImpl.logger.info("ReactionServiceDefaultImpl fetch reactions success")
            self?.handleUserReactions(keys: keys)
        }, onError: { (error) in
            // 转成ms
            let time = (CACurrentMediaTime() - beginTime) * 1000
            // 获取最常使用表情
            EmotionTracker.trackerSlardar(event: "emoji_get_mru_reactions", time: time, category: ["from_local" : false], metric: [:], error: error)
            EmotionTracker.trackerTea(event: Const.getMruReactionsEvent, time: time, extraParams: [Const.local: false], error: error)
            ReactionServiceDefaultImpl.logger.error("ReactionServiceDefaultImpl sync reactions failed", error: error)
        }).disposed(by: disposeBag)
    }

    private func fetchAllReactions() {
        let beginTime = CACurrentMediaTime()
        self.rustSyncAllReactions().subscribe(onNext: { [weak self] (res) in
            // 转成ms
            let time = (CACurrentMediaTime() - beginTime) * 1000
            // 获取 Emoji 面板数据
            EmotionTracker.trackerSlardar(event: "emoji_get_emoji_panel", time: time, category: ["from_local" : false], metric: [:], error: nil)
            EmotionTracker.trackerTea(event: Const.getEmojiPanelEvent, time: time, extraParams: [Const.local: false], error: nil)
            ReactionServiceDefaultImpl.logger.info("ReactionServiceDefaultImpl fetch all reactions success")
            self?.handleAllReactions(panel: res.emojiPanel)
        }, onError: { (error) in
            // 转成ms
            let time = (CACurrentMediaTime() - beginTime) * 1000
            // 获取 Emoji 面板数据
            EmotionTracker.trackerSlardar(event: "emoji_get_emoji_panel", time: time, category: ["from_local" : false], metric: [:], error: error)
            EmotionTracker.trackerTea(event: Const.getEmojiPanelEvent, time: time, extraParams: [Const.local: false], error: error)
            ReactionServiceDefaultImpl.logger.error("ReactionServiceDefaultImpl sync all Reactions failed", error: error)
        }).disposed(by: disposeBag)
    }

    private func handleUserReactions(keys: [String]) {
        self.mruReactions[self.currentUserId()] = keys
        // 保存在UserDefault里面，给桌面Extention用
        self.saveUserReactionsToUserDefault(keys: keys)
        defer { lock.unlock() }
        var releaseArray: [ReactionListenerWrpper] = []
        lock.lock()
        self.reactionListenerWrppers.forEach { wrapper in
            if let listener = wrapper.listener {
                listener.mruReactionChangeHandler()
            } else {
                releaseArray.append(wrapper)
            }
        }
        _ = releaseArray.map { self.reactionListenerWrppers.remove($0) }
    }

    private func handleAllReactions(panel: Im_V1_EmojiPanel) {
        defer { lock.unlock() }
        _ = panel.emojisOrder.flatMap({ $0.keys })
        mainThreadTask { [weak self] in
            guard let self =  self else { return }
            var triggerKeys: [String] = []
            let allReactionGroups = panel.emojisOrder.map { emoji -> ReactionGroup in
                let entities = emoji.keys.compactMap { emojiKey -> ReactionEntity? in
                    let key = emojiKey.key
                    let selectSkinKey = emojiKey.selectedSkinKey
                    let displayKey = !selectSkinKey.isEmpty ? selectSkinKey : key
                    // 根据表情面板里面的分类挨个给allResouces缓存里面的对象赋值正确的类型
                    if let resource = EmotionResouce.shared.resourceBy(key: key) {
                        resource.type = emoji.type
                    }
                    // 如果本地缓存中没有对应key的资源的话需要统一再拉取下
                    if !EmotionResouce.shared.isInAllResoucesMapBy(key: key) {
                        triggerKeys.append(key)
                        // 如果本地缓存中没有这个key那么是新增的表情，不用判断isDeleted直接加到分组里面
                        return ReactionEntity(key: key,
                                              selectSkinKey: displayKey,
                                              skinKeys: EmotionResouce.shared.skinKeysBy(key: key),
                                              size: EmotionResouce.shared.sizeBy(key: key))
                    }
                    guard EmotionResouce.shared.isDeletedBy(key: displayKey) == false else { return nil }
                    return ReactionEntity(key: key,
                                          selectSkinKey: displayKey,
                                          skinKeys: EmotionResouce.shared.skinKeysBy(key: key),
                                          size: EmotionResouce.shared.sizeBy(key: key))
                }
                return ReactionGroup(type: emoji.type, iconKey: emoji.iconKey, title: emoji.title, source: emoji.source, entities: entities)
            }
            // 判断表情面板有没有下发企业自定义表情
            var hasCustomEmotion = false
            for group in allReactionGroups {
                if group.type == .custom {
                    hasCustomEmotion = true
                    break
                }
            }
            if hasCustomEmotion {
                KVPublic.Emotion.customEmotion.setValue("1")
            } else {
                KVPublic.Emotion.customEmotion.setValue("0")
            }
            self.allReactions[self.currentUserId()] = allReactionGroups
            DispatchQueue.global().async {
                // 统一拉取本地缓存中不存在的表情资源
                EmotionResouce.shared.fetchResouce(keys: triggerKeys)
                self.saveAllReactionsToUserDefault()
            }
        }
        var releaseArray: [ReactionListenerWrpper] = []
        lock.lock()
        self.reactionListenerWrppers.forEach { wrapper in
            if let listener = wrapper.listener {
                listener.allReactionChangeHandler()
            } else {
                releaseArray.append(wrapper)
            }
        }
        _ = releaseArray.map { self.reactionListenerWrppers.remove($0) }
    }

    private func mainThreadTask(_ task: @escaping () -> Void) {
        if Thread.isMainThread {
            task()
        } else {
            DispatchQueue.main.async {
                task()
            }
        }
    }
    
    private func rustGetUserReactions() -> Observable<[String]> {
        var request = Im_V1_GetUserMRUReactionsRequest()
        request.syncDataStrategy = .local
        return self.client.sendAsyncRequest(request,
                                            transform: { (response: Im_V1_GetUserMRUReactionsResponse) -> [String] in
            return response.userMruReactions
        })
    }

    private func rustSyncUserReactions() -> Observable<[String]> {
        var request = Im_V1_GetUserMRUReactionsRequest()
        request.syncDataStrategy = .forceServer
        return self.client.sendAsyncRequest(request,
                                            transform: { (response: Im_V1_GetUserMRUReactionsResponse) -> [String] in
            return response.userMruReactions
        })
    }

    private func rustGetAllReactions() -> Observable<Im_V1_GetEmojiPanelResponse> {
        var request = RustPB.Im_V1_GetEmojiPanelRequest()
        request.syncDataStrategy = .local
        return self.client.sendAsyncRequest(request)
    }

    private func rustSyncAllReactions() -> Observable<Im_V1_GetEmojiPanelResponse> {
        var request = RustPB.Im_V1_GetEmojiPanelRequest()
        request.syncDataStrategy = .forceServer
        return self.client.sendAsyncRequest(request)
    }
    
    private func rustUpdateReactionSkin(defaultReactionKey: String, skinKey: String) -> Observable<Im_V1_UpdateUserReactionSkinResponse> {
        var request = RustPB.Im_V1_UpdateUserReactionSkinRequest()
        request.reactionToSkinKey = [defaultReactionKey: skinKey]
        return self.client.sendAsyncRequest(request)
    }

    private func saveAllReactionsToUserDefault() {
        let groups = self.getAllReactions().filter { reactionGroup in
            reactionGroup.type == .default
        }
        guard let reactionEntities = groups.first?.entities else {
            return
        }
        let resouce = EmotionResouce.shared
        // 把reactionKey转换为emojiKey：存在对应的 emoji_key & 未下线 & 本地有图
        let emojiEntities = reactionEntities.compactMap({ entity in
            return ReactionEntity(key: resouce.emotionKeyBy(reactionKey: entity.key) ?? "",
                                  selectSkinKey: resouce.emotionKeyBy(reactionKey: entity.selectSkinKey) ?? (resouce.emotionKeyBy(reactionKey: entity.key) ?? ""),
                                  skinKeys: entity.skinKeys.compactMap { resouce.emotionKeyBy(reactionKey: $0) },
                                  size: entity.size)
        })
            .filter({ !$0.selectSkinKey.isEmpty && !$0.key.isEmpty })
            .filter({ !resouce.isDeletedBy(key: $0.selectSkinKey) })
            .filter({ resouce.imageBy(key: $0.selectSkinKey) != nil })

        let emojiKeys = emojiEntities.map { emojiEntity in
            resouce.reactionKeyBy(emotionKey: emojiEntity.key) ?? ""
        }
        // 表情资源是跟语言走的，所以当设置语言发生变化的时候需要更新UserDefault里面的表情图片
        let currentLanguage = BundleI18n.currentLanguage.rawValue
        var needSave: Bool = true
        if let userDefaultKeys = KVPublic.EmotionKeyboard.defaultEmojiKeys.value(),
           let UserDefaultLanguage = KVPublic.EmotionKeyboard.defaultLanguage.value() {
            let setA = Set(emojiKeys)
            let setB = Set(userDefaultKeys)
            // 数据和设置的语言都没有发生变化
            if setA == setB && currentLanguage == UserDefaultLanguage {
                // 如果和之前保存的结果一样那就不用再次保存了
                needSave = false
            }
        }
        // 如果没有变化的话就不需要保存，直接返回即可
        guard needSave else { return }
        // 构造key->png的映射
        var emojiDataMap: [String: Data] = [:]
        for emojikey in emojiKeys {
            if let png = resouce.imageBy(key: emojikey)?.pngData() {
                emojiDataMap[emojikey] = png
            }
        }
        // 存到UserDefault里面
        // 保存keys
        KVPublic.EmotionKeyboard.defaultEmojiKeys.setValue(emojiKeys)
        // 保存key->png映射
        KVPublic.EmotionKeyboard.defaultEmojiDataMap.setValue(emojiDataMap)
        // 保存设置语言
        KVPublic.EmotionKeyboard.defaultLanguage.setValue(currentLanguage)
        // 同步下
        KVPublic.EmotionKeyboard.synchronize()
    }

    private func saveUserReactionsToUserDefault(keys: [String]) {
        let reactionKeys = Array(keys.prefix(7))
        // 存到UserDefault里面
        KVPublic.EmotionKeyboard.mruEmojiKeys.setValue(reactionKeys)
        KVPublic.EmotionKeyboard.synchronize()
    }
    
    // 获取不同类型的表情：最常使用
    private func getReactions() -> [ReactionEntity] {
        var reactionKeys = self.mruReactions[self.currentUserId()] ?? []
        // 打印出过滤之前的数据
        Self.logger.info("ReactionServiceDefaultImpl: befor fiter user reaction reactionKeys = \(reactionKeys)")
        // 去掉不可用的
        reactionKeys = reactionKeys.filter({ !EmotionResouce.shared.isDeletedBy(key: $0) })
        // 用兜底reaction进行补齐
        reactionKeys.append(contentsOf: EmotionResouce.mruReactions.filter({ !reactionKeys.contains($0) })
                                .filter({ !EmotionResouce.shared.isDeletedBy(key: $0) }) )
        // 一行9个，2行18个：历史逻辑，保持不动
        var count = Const.onelineCount
        if isCommonlyUsedABTestEnable {
            count = Const.twolineCount
        }
        let keys = Array(reactionKeys.prefix(count))
        // 打印出过滤之后的数据，方便比较哪些key是非法的
        Self.logger.info("ReactionServiceDefaultImpl: after fiter reaction reactionKeys = \(keys)")
        return keys.map {
            var size = CGSize(width: 28, height: 28)
            if let entity = self.getReactionEntityFromOriginKey($0) {
                size = entity.size
            }
            // 这边一定要注意不能返回多肤色！！！
            return ReactionEntity(key: $0, selectSkinKey: $0, skinKeys: [], size: size)
        }
    }
}

extension ReactionServiceDefaultImpl {
    enum Const {
        public static let onelineCount: Int = 9
        public static let twolineCount: Int = 18
        public static let getEmojiPanelEvent: String = "emoji_get_emoji_panel"
        public static let getMruReactionsEvent: String = "emoji_get_mru_reactions"
        public static let local: String = "local"
    }
}

final class ReactionListenerWrpper: NSObject {
    weak var listener: ReactionListener?
}
