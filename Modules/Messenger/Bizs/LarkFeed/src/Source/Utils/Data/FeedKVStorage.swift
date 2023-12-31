//
//  FeedKVStorage.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/8/18.
//

import Foundation
import RustPB
import LarkAccountInterface
import LarkSDKInterface
import LKCommonsLogging
import LarkModel
import LarkStorage
import LarkSetting
import LarkFeedBase

extension KVStores {
    struct Feed {
        /// 构建 Feed 业务用户无关的 `KVStore`
        static func global() -> KVStore {
            return KVStores.udkv(space: .global, domain: Domain.biz.feed)
        }

        /// 构建 Feed 业务用户相关的 `KVStore`
        static func user(id: String) -> KVStore {
            return KVStores.udkv(space: .user(id: id), domain: Domain.biz.feed)
        }
    }
}

struct FeedKVStorage {
    private let userId: String
    private let store: KVStore

    init(userId: String) {
        self.userId = userId
        self.store = KVStores.Feed.user(id: userId)
    }
}

// MARK: Feeds
extension FeedKVStorage {
    // 缓存 10 条 feed 数据
    private static let feedThreshold = 10

    private static let feedKey = KVKey<[Data]?>("feed")

    // 存储：在进入后台或进程被kill的时候
    func saveFeeds(_ feeds: [FeedCardCellViewModel]) {
        guard !userId.isEmpty else { return }
        let count = min(Self.feedThreshold, feeds.count)
        var list = [Data]()
        var cacheIds: [String] = []
        for index in 0..<count {
            let cellViewModel = feeds[index]
            let preview = cellViewModel.feedPreview.preview
            if let data = try? preview.serializedData() {
                list.append(data)
                cacheIds.append(cellViewModel.feedPreview.id)
            }
        }
        store[Self.feedKey] = list
        saveFeedBadgeStyle()
        FeedContext.log.info("feedlog/dataStream/cache/feeds/save. count: \(cacheIds.count), \(cacheIds)")
    }

    // 读取：比 GetFeedCards 接口早一些，目前放在preload之前了
    func getLocalFeeds() -> [FeedPreview]? {
        guard let list = store[Self.feedKey] else { return nil }
        var previews = [FeedPreview]()
        list.forEach { data in
            if var preview = try? Feed_V1_FeedEntityPreview(serializedData: data) {
                preview.updateTime = FeedLocalCode.feedKVStorageFlag
                let feed = FeedPreview.transformByEntityPreview(preview)
                previews.append(feed)
            }
        }
        FeedContext.log.info("feedlog/dataStream/cache/feeds/get. count: \(previews.count). \(previews.map({ $0.id }))")
        guard !previews.isEmpty else {
            return nil
        }
        return previews
    }
}

// MARK: FeedBadgeStyle
extension FeedKVStorage {
    private static let feedBadgeStyleKey = KVKey<Int?>("feed.badge")

    // 存储：在进入后台或进程被kill的时候
    func saveFeedBadgeStyle() {
        store[Self.feedBadgeStyleKey] = FeedBadgeBaseConfig.badgeStyle.rawValue
    }

    func getFeedBadgeStyle() -> Settings_V1_BadgeStyle? {
        guard let value = store[Self.feedBadgeStyleKey],
              let style = Settings_V1_BadgeStyle(rawValue: value) else { return nil }
        return style
    }
}

// MARK: Shortcuts
extension FeedKVStorage {
    // 缓存 7 条 shortcut 数据
    private static let shortcutThreshold = 7

    private static let shortcutKey = KVKey<[[String: Data]]?>("shortcut")

    // 存储：在进入后台或进程被kill的时候
    func saveShortcuts(_ shortcuts: [ShortcutCellViewModel]) {
        if userId.isEmpty { return }
        let count = min(Self.shortcutThreshold, shortcuts.count)
        var list = [[String: Data]]()
        var cacheIds: [String] = []
        for index in 0..<count {
            let cellViewModel = shortcuts[index]
            let preview = cellViewModel.preview.preview
            if let previewData = try? preview.serializedData(),
               let shortcutData = try? cellViewModel.shortcut.serializedData() {
                    let dict = ["previewData": previewData,
                                "shortcutData": shortcutData]
                    list.append(dict)
                    cacheIds.append(cellViewModel.preview.id)
            }
        }
        store[Self.shortcutKey] = list
        FeedContext.log.info("feedlog/shortcut/dataflow/cache/save. count: \(cacheIds.count), \(cacheIds)")
    }

    // 读取：shortcutVM初始化的时候读取，保证比shortcut的pull和push更早一些
    func getLocalShortcuts() -> [ShortcutResult]? {
        guard let list = store[Self.shortcutKey] else { return nil }
        var shortcuts = [ShortcutResult]()
        list.forEach { dict in
            guard let shortcutData = dict["shortcutData"], let shortcut = try? Feed_V1_Shortcut(serializedData: shortcutData) else { return }
            guard let previewData = dict["previewData"] else { return }
            if var preview = try? Feed_V1_FeedEntityPreview(serializedData: previewData) {
                preview.updateTime = FeedLocalCode.feedKVStorageFlag
                let feed = FeedPreview.transformByEntityPreview(preview)
                let result = ShortcutResult(shortcut: shortcut, preview: feed)
                shortcuts.append(result)
            }
        }
        FeedContext.log.info("feedlog/shortcut/dataflow/cache/get. \(shortcuts.map({ $0.preview.id }))")
        guard !shortcuts.isEmpty else {
            return nil
        }
        return shortcuts
    }
}

// MARK: 免打扰分组
// TODO: 免打扰fg、分组fg的代码未来都会下掉，这些fg都已经全量很久
extension FeedKVStorage {
    private static let feedShowMuteKey = KVKey<Bool?>("feed.showMute")

    // 存储：在进入后台或进程被kill的时候
    func saveFeedShowMuteState(_ showMute: Bool) {
        store[Self.feedShowMuteKey] = showMute
        FeedContext.log.info("feedlog/dataStream/cache/muteState/save. \(showMute)")
    }

    func getFeedShowMuteState() -> Bool {
        guard let showMute = store[Self.feedShowMuteKey] else { return false }
        FeedContext.log.info("feedlog/dataStream/cache/muteState/get. \(showMute)")
        return showMute
    }
}

// MARK: Labels
extension FeedKVStorage {
    private static let labelExpandKey = KVKey<[Int: Bool]?>("feed.label.expand")

    // 存储：在进入后台或进程被kill的时候
    func saveLabelsExpandedState(_ ids: [Int: Bool]) {
        if userId.isEmpty { return }
        store[Self.labelExpandKey] = ids
        FeedContext.log.info("feedlog/label/cache/expandedState/save. \(ids)")
    }

    func getLastLabelsExpandedState() -> [Int: Bool]? {
        guard let labelIds = store[Self.labelExpandKey] else { return nil }
        FeedContext.log.info("feedlog/label/cache/expandedState/get. \(labelIds)")
        guard !labelIds.isEmpty else {
            return nil
        }
        return labelIds
    }
}

// MARK: feed 三栏（侧边栏）展示收起态
extension FeedKVStorage {
    private static let feedFilterExpandKey = KVKey<[Int: Bool]?>("feed.filter.expand")

    // 存储：在进入后台或进程被kill的时候
    func saveFiltersExpandedState(_ ids: [Int: Bool]) {
        if userId.isEmpty { return }
        store[Self.feedFilterExpandKey] = ids
        FeedContext.log.info("feedlog/threeColumns/cache/expandedState/save. \(ids)")
    }

    func getLastFiltersExpandedState() -> [Int: Bool]? {
        guard let ids = store[Self.feedFilterExpandKey] else { return nil }
        FeedContext.log.info("feedlog/threeColumns/cache/expandedState/get \(ids)")
        guard !ids.isEmpty else {
            return nil
        }
        return ids
    }
}

// MARK: Teams
extension FeedKVStorage {
    private static let teamExpandKey = KVKey<[Int: Bool]?>("feed.team.expand")

    // 存储：在进入后台或进程被kill的时候
    func saveTeamsExpandedState(_ ids: [Int: Bool]) {
        if userId.isEmpty { return }
        store[Self.teamExpandKey] = ids
        FeedContext.log.info("teamlog/cache/expandedState/save. \(ids)")
    }

    func getLastTeamsExpandedState() -> [Int: Bool]? {
        guard let ids = store[Self.teamExpandKey] else { return nil }
        FeedContext.log.info("teamlog/cache/expandedState/get. \(ids)")
        guard !ids.isEmpty else {
            return nil
        }
        return ids
    }
}

// MARK: FeedRuleMd5
extension FeedKVStorage {
    private static let feedRuleMd5Key = KVKey<String?>("feed.rule.md5")

    // 存储：在进入后台或进程被kill的时候
    func saveFeedRuleMd5(_ md5: String) {
        FeedContext.log.info("feedlog/filter/feedRuleMd5/save. \(md5)")
        store[Self.feedRuleMd5Key] = md5
    }

    func getFeedRuleMd5() -> String? {
        guard let value = store[Self.feedRuleMd5Key] else { return nil }
        FeedContext.log.info("feedlog/filter/feedRuleMd5/get. \(value)")
        return value
    }
}
