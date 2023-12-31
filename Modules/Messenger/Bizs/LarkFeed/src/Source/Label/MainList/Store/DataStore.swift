//
//  LabelMainListDataStore.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/20.
//

import Foundation
import RustPB
import LarkModel
import LarkOpenFeed

/** LabelMainListDataStore的设计：存储实体
 1. 实体和列表关系分开维护
    1.1 可解耦：实体更新和列表尽量解耦，减少一级列表和二级列表的关联关系
    1.2 可减少丢数据
    1.3 减少 更新数据 及 refresh 次
 2. 实体使用map，列表关系使用indexData
 3. 接口为纯粹的增删改查
 */

protocol DataStoreInterface {
    var indexData: IndexData { get }
    var labelEntityMap: [Int: LabelViewModel] { get }

    // 一级列表
    mutating func update(labels: [LabelViewModel])
    mutating func remove(labelIds: [Int])
    mutating func updateLabelList(hasMore: Bool, nextCursor: IndexCursor)
    func getLabel(index: Int) -> LabelViewModel?
    func getLabels() -> [LabelViewModel]
    func filter(_ isIncluded: ((LabelViewModel) -> Bool)) -> DataStoreInterface
    mutating func getLabelRequestSortRule(_ labelId: Int) -> Feed_V1_FeedGroupItemOrderRule

    // 二级列表
    mutating func update(feedEntities: [FeedCardViewModelInterface])
    mutating func update(feedRelations: [EntityItem])
    mutating func remove(feeds: [IndexDataInterface])
    mutating func updateFeedList(labelId: Int, hasMore: Bool, nextCursor: IndexCursor)
    func getFeed(indexPath: IndexPath) -> LabelFeedViewModel?
    func getFeeds(labelId: Int) -> [LabelFeedViewModel]

    var description: String { get }
}

struct LabelMainListDataStore: DataStoreInterface {
    // 实体关系 id: Entity
    private(set) var labelEntityMap: [Int: LabelViewModel] = [:]
    private var feedEntityMap: [Int: LabelFeedViewModel] = [:]
    // feed关系实体缓存 [feedId: [labelId: EntityItem]]
    private var feedEntityItemsMap: [Int: [Int: EntityItem]] = [:]
    // 记录默认请求二级标签的排序值，每个标签只赋值一次
    private var requestSortRuleMap: [Int: Feed_V1_FeedGroupItemOrderRule] = [:]

    // 列表关系
    private(set) var indexData = IndexData.default()

    init() {}

    mutating func update(labels: [LabelViewModel]) {
        var expiredIds: [Int] = []
        labels.forEach({ label in
            let labelId = label.item.id
            var canUpdate = false
            if let oldLabel = self.labelEntityMap[labelId] {
                if label.meta.updateTime >= oldLabel.meta.updateTime {
                    canUpdate = true
                }
            } else {
                requestSortRuleMap[labelId] = label.meta.feedGroup.keywordGroupData.orderBy
                canUpdate = true
            }
            guard canUpdate else {
                expiredIds.append(labelId)
                return
            }
            let needReload = checkIfNeedReloadFeedRelations(label)
            self.labelEntityMap[labelId] = label
            if needReload {
                // NOTE：先更新实体再触发刷新逻辑
                reloadFeedRelations(labelId)
            }
            self.indexData.update(childId: labelId, originOrder: label.item.position, version: label.meta.updateTime)
        })
        self.indexData.sort()
        if !expiredIds.isEmpty {
            let errorMsg = "expiredIds \(expiredIds)"
            let info = FeedBaseErrorInfo(type: .warning(), errorMsg: errorMsg)
            FeedExceptionTracker.Label.updateLabels(node: .checkExpiredFeeds, info: info)
        }
    }

    private func checkIfNeedReloadFeedRelations(_ arrivedLabel: LabelViewModel) -> Bool {
        // 一级标签排序规则变化时需要更新相应二级标签的关系表
        let labelId = arrivedLabel.item.id
        if let localLabel = labelEntityMap[labelId],
           localLabel.meta.feedGroup.keywordGroupData.orderBy !=
            arrivedLabel.meta.feedGroup.keywordGroupData.orderBy {
            return true
        }
        return false
    }

    mutating func remove(labelIds: [Int]) {
        labelIds.forEach({ labelId in
            remove(labelId: labelId)
        })
    }

    // TODO: Rust需要优化，remove没有带version
    private mutating func remove(labelId: Int) {
        guard labelEntityMap[labelId] != nil else {
            let errorMsg = "local label does not exist: \(labelId)"
            let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
            FeedExceptionTracker.Label.removeLabel(node: .checkLocalLabel, info: info)
            return
        }
        self.labelEntityMap.removeValue(forKey: labelId)
        self.requestSortRuleMap.removeValue(forKey: labelId)
        self.indexData.remove(childId: labelId)
    }

    mutating func updateLabelList(hasMore: Bool, nextCursor: IndexCursor) {
        self.indexData.update(hasMore: hasMore, nextCursor: nextCursor)
    }

    mutating func getLabelRequestSortRule(_ labelId: Int) -> Feed_V1_FeedGroupItemOrderRule {
        if let rule = requestSortRuleMap[labelId] {
            return rule
        }
        // 兜底策略：map中没有找到相应rule, 则默认按时序规则
        requestSortRuleMap[labelId] = .asFeedCard
        return .asFeedCard
    }

    func getLabel(index: Int) -> LabelViewModel? {
        guard let indexData = self.indexData.getChildIndexData(index: index) else { return nil }
        return labelEntityMap[indexData.id]
    }

    func getLabels() -> [LabelViewModel] {
        return self.indexData.childIndexList.compactMap({ labelEntityMap[$0.id] })
    }

    func filter(_ isIncluded: ((LabelViewModel) -> Bool)) -> DataStoreInterface {
        var store = self
        let removeIds = store.getLabels().compactMap({ label -> Int? in
            isIncluded(label) ? nil : label.item.id
        })
        // TODO: remove 需要优化
        store.remove(labelIds: removeIds)
        return store
    }
}

extension LabelMainListDataStore {

    // 二级列表

    // 更新feed实体
    mutating func update(feedEntities: [FeedCardViewModelInterface]) {
        var errorFeedIds = [String]()
        var expiredIds: [Int] = []
        feedEntities.forEach({ feed in
            guard let id = Int(feed.feedPreview.id) else {
                let errorMsg = "string->int \(feed.feedPreview.id)"
                let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
                FeedExceptionTracker.Label.updateFeedEntity(node: .checkFeedId, info: info)
                return
            }
            let canUpdateEntity: Bool
            if let cacheFeed = self.feedEntityMap[id] {
                canUpdateEntity = feed.feedPreview.basicMeta.updateTime >= cacheFeed.feedPreview.basicMeta.updateTime
            } else {
                canUpdateEntity = true
                errorFeedIds.append("id: \(id)")
            }
            guard canUpdateEntity else {
                expiredIds.append(id)
                return
            }
            self.feedEntityMap[id] = LabelFeedViewModel(feedViewModel: feed)
        })

        if !expiredIds.isEmpty {
            let errorMsg = "expiredIds: \(expiredIds)"
            let info = FeedBaseErrorInfo(type: .warning(), errorMsg: errorMsg)
            FeedExceptionTracker.Label.updateFeedEntity(node: .checkExpiredFeeds, info: info)
        }

        if !errorFeedIds.isEmpty {
            let errorMsg = "local feed does not exist: \(errorFeedIds)"
            let info = FeedBaseErrorInfo(type: .warning(), errorMsg: errorMsg)
            FeedExceptionTracker.Label.updateFeedEntity(node: .checkErrorFeeds, info: info)
        }
    }

    // 更新feed关系表
    mutating func update(feedRelations: [EntityItem]) {
        var sortIds: Set<Int> = []
        var errorFeedIds = [String]()
        var expiredIds: [Int] = []
        feedRelations.forEach({ feedRelation in
            let feedId = feedRelation.id
            // 更新列表关系：向列表中插入indexData
            guard var label = self.indexData.getChildIndexData(id: feedRelation.parentId) else {
                errorFeedIds.append("labelId: \(feedRelation.parentId), feedId: \(feedId), ")
                return
            }

            guard let originOrder = getFeedOriginOrder(feedRelation) else {
                errorFeedIds.append("labelId: \(feedRelation.parentId), feedId: \(feedId), ")
                return
            }

            let canUpdateRelation: Bool
            if let index = label.childIndexMap[feedId],
               index < label.childIndexList.count {
                let cacheIndexData = label.childIndexList[index]
                canUpdateRelation = feedRelation.updateTime >= cacheIndexData.version
            } else {
                canUpdateRelation = true
                errorFeedIds.append("id: \(feedId)")
            }
            guard canUpdateRelation else {
                expiredIds.append(feedId)
                return
            }

            updateFeedRelation(feedId, feedRelation.parentId, feedRelation)
            label.update(childId: feedId, originOrder: originOrder, version: feedRelation.updateTime)
            self.indexData.update(childIndexData: label)
            sortIds.insert(label.id)
        })
        if !expiredIds.isEmpty {
            let errorMsg = "expiredIds: \(expiredIds)"
            let info = FeedBaseErrorInfo(type: .warning(), errorMsg: errorMsg)
            FeedExceptionTracker.Label.updateFeedEntity(node: .checkExpiredFeeds, info: info)
        }
        if !errorFeedIds.isEmpty {
            let errorMsg = "local feeds does not exist: \(errorFeedIds)"
            let info = FeedBaseErrorInfo(type: .warning(), errorMsg: errorMsg)
            FeedExceptionTracker.Label.updateFeedEntity(node: .checkErrorFeeds, info: info)
        }

        // 更新列表排序
        sortIds.forEach({ id in
            guard var label = self.indexData.getChildIndexData(id: id) else { return }
            label.sort()
            self.indexData.update(childIndexData: label)
        })
    }

    // 刷新特定标签下feed关系表
    mutating func reloadFeedRelations(_ labelId: Int) {
        guard let labelvm = labelEntityMap[labelId],
              var labelIndexer = self.indexData.getChildIndexData(id: labelId) else { return }
        let feeds = getFeeds(labelId: labelId)
        feeds.forEach { feed in
            guard let feedId = Int(feed.feedPreview.id),
                  let feedRelation = findFeedRelation(feedId, labelId),
                  let originOrder = getFeedOriginOrder(feedRelation) else { return }
            labelIndexer.update(childId: feedId, originOrder: originOrder, version: feedRelation.updateTime)
        }
        labelIndexer.sort()
        self.indexData.update(childIndexData: labelIndexer)
    }

    // 从Cache里查找EntityItem
    func findFeedRelation(_ feedId: Int, _ labelId: Int) -> EntityItem? {
        guard let feedRelationMap = feedEntityItemsMap[feedId],
              let feedRelation = feedRelationMap[labelId] else {
            return nil
        }
        return feedRelation
    }

    // 更新Cache里存储的EntityItem
    mutating func updateFeedRelation(_ feedId: Int, _ labelId: Int, _ relation: EntityItem?) {
        guard let relation = relation else {
            self.feedEntityItemsMap.removeValue(forKey: feedId)
            return
        }
        if var feedRelationMap = self.feedEntityItemsMap[feedId] {
            feedRelationMap[labelId] = relation
            self.feedEntityItemsMap[feedId] = feedRelationMap
        } else {
            self.feedEntityItemsMap[feedId] = [labelId: relation]
        }
    }

    func getFeedOriginOrder(_ item: EntityItem) -> Int64? {
        guard let feedEntity = feedEntityMap[item.id],
              let label = labelEntityMap[item.parentId] else {
            return nil
        }

        if label.meta.feedGroup.keywordGroupData.orderBy == .position {
            return item.position
        } else {
            return Int64(feedEntity.feedPreview.basicMeta.rankTime)
        }
    }

    // TODO: Rust需要优化，remove没有带version
    mutating func remove(feeds: [IndexDataInterface]) {
        var errorIds: [String] = []
        feeds.forEach({ feed in
            guard var label = self.indexData.getChildIndexData(id: feed.parentId) else {
                errorIds.append("\(feed.id) -> \(feed.parentId), ")
                return
            }
            label.remove(childId: feed.id)
            self.indexData.update(childIndexData: label)
        })

        if !errorIds.isEmpty {
            let errorMsg = "local label does not exist: \(errorIds)"
            let info = FeedBaseErrorInfo(type: .warning(), errorMsg: errorMsg)
            FeedExceptionTracker.Label.removeFeeds(node: .checkErrorFeeds, info: info)
        }
    }

    mutating func updateFeedList(labelId: Int, hasMore: Bool, nextCursor: IndexCursor) {
        guard var indexData = self.indexData.getChildIndexData(id: labelId) else {
            let errorMsg = "local label does not exist: labelId: \(labelId), hasMore: \(hasMore), nextCursor: \(nextCursor)"
            let info = FeedBaseErrorInfo(type: .warning(), errorMsg: errorMsg)
            FeedExceptionTracker.Label.updateFeedList(node: .getChildIndexData, info: info)
            return
        }
        indexData.update(hasMore: hasMore, nextCursor: nextCursor)
        self.indexData.update(childIndexData: indexData)
    }

    func getFeeds(labelId: Int) -> [LabelFeedViewModel] {
        return indexData.getChildIndexData(id: labelId)?.childIndexList.compactMap({ feedEntityMap[$0.id] }) ?? []
    }

    func getFeed(indexPath: IndexPath) -> LabelFeedViewModel? {
        guard let id = self.indexData.getChildIndexData(index: indexPath.section)?.getChildIndexData(index: indexPath.row)?.id else { return nil }
        return self.feedEntityMap[id]
    }
}

// TODO: 避免无效数据更新，减少UI刷新次数，这个不应该在数据层上做，成本比较高，应该交给diff库来做
extension LabelMainListDataStore {
    func canUpdate() -> Bool {
        return true
    }

    func canDelete() -> Bool {
        return true
    }

    func canSort() -> Bool {
        return true
    }

    // 是否可以分页
    func canPage() -> Bool {
        return true
    }
}

extension LabelMainListDataStore {
    var description: String {
        let labels = getLabels()
        let feedsInfo = labels.map({ label -> String in
            let labelId = label.item.id
            let feeds = getFeeds(labelId: labelId)
            let feedsInfo = feeds.map({ $0.feedPreview.description })
            return "labelId: \(labelId), "
                + "feedsCount: \(feeds.count), "
                + "feedsInfo: \(feedsInfo)"
        })
        return "indexData: \(indexData.description), "
            + "labelsCount: \(labels.count), "
            + "labelsIndex: \(self.indexData.childIndexList.map({ $0.description })), "
            + "labelsInfo: \(labels.map({ $0.description })), "
            + "feedsInfo: \(feedsInfo)"
    }
}
