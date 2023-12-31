//
//  FeedProvider.swift
//  LarkMessengerUnitTest
//
//  Created by bitingzhu on 2020/8/18.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import XCTest
import LarkModel
import LarkContainer
@testable import LarkFeed

class FeedProviderTest: XCTestCase {
    private lazy var feedProvider: FeedProvider = FeedProvider(userResolver: Container.shared.getCurrentUserResolver())
    private var feedDict: [String: BaseFeedTableCellViewModel] = [:]
    /// feed条数基线
    let baselineFeedCount = 120
    /// 单次pull数量
    let pullCount = 60
    let emptyCount = 0

    /// 单条push到表首
    func testFeedProviderSinglePushToFirst() {
        let count = baselineFeedCount
        let segments = 5
        let stride = count / segments
        for i in 0..<segments {
            /// 场景构建
            resetFeeds(of: count)

            /// 操作执行
            // 构造需要更新的VM
            let vm = feedProvider.getItemsArray()[stride * i]
            let id = vm.feedCardPreview.id
            let newRankTime = feedProvider.getItemsArray()[0].feedCardPreview.rankTime + 1
            vm.feedCardPreview.rankTime = newRankTime
            // 执行更新
            feedProvider.updateItems([vm])
            feedDict[id] = vm

            /// 结果验证
            assertConsistent()
        }
    }

    /// 多条push到表首
    func testFeedProviderMultiplePushToTop() {
        /// 场景构建
        resetFeeds(of: baselineFeedCount)

        /// 操作执行
        let count = feedProvider.getItemsArray().count
        let segments = 5
        let stride = count / segments
        let baseRankTime = feedProvider.getItemsArray()[0].feedCardPreview.rankTime

        var updatedVMs = [BaseFeedTableCellViewModel]()
        for i in 0..<segments {
            // 构造需要更新的VM
            let vm = feedProvider.getItemsArray()[stride * i]
            let id = vm.feedCardPreview.id
            let newRankTime = baseRankTime + i
            vm.feedCardPreview.rankTime = newRankTime
            updatedVMs.append(vm)
            feedDict[id] = vm
        }
        // 执行更新
        feedProvider.updateItems(updatedVMs)

        /// 结果验证
        assertConsistent()
    }

    /// 单条push到表尾
    func testFeedProviderSinglePushToBottom() {
        /// 场景构建
        resetFeeds(of: baselineFeedCount)

        /// 操作执行
        // 构造需要更新的VM
        let count = feedProvider.getItemsArray().count
        let newRankTime = feedProvider.getItemsArray()[count - 1].feedCardPreview.rankTime - 1
        let vm = feedProvider.getItemsArray()[count / 2]
        let id = vm.feedCardPreview.id
        vm.feedCardPreview.rankTime = newRankTime
        // 执行更新
        feedProvider.updateItems([vm])
        feedDict[id] = vm

        /// 结果验证
        assertConsistent()
    }

    /// 多次pull数据
    func testFeedProviderPull() {
        /// 场景构建
        resetFeeds(of: emptyCount)

        for i in 1...5 {
            /// 操作执行
            // 准备pull到的VM
            var pulled = populateFeeds(of: pullCount * i)
            pulled.removeSubrange(0..<pullCount * (i - 1))
            // 打乱pull到的数据
            pulled.shuffle()
            // 执行更新
            feedProvider.updateItems(pulled)
            pulled.forEach { feedDict[$0.feedCardPreview.id] = $0 }

            /// 结果验证
            assertConsistent()
        }
    }

    /// 单条删除
    func testFeedProviderSinglePushRemove() {
        /// 场景构建
        resetFeeds(of: baselineFeedCount)

        /// 操作执行
        // 获取需要删除的VM
        let count = feedProvider.getItemsArray().count
        let vm = feedProvider.getItemsArray()[count / 2]
        let id = vm.feedCardPreview.id
        // 执行删除
        feedProvider.removeItems([id])
        feedDict.removeValue(forKey: id)

        /// 结果验证
        assertConsistent()
    }

    /// 多条删除
    func testFeedProviderMultiplePushRemove() {
        /// 场景构建
        resetFeeds(of: baselineFeedCount)

        /// 操作执行
        let count = feedProvider.getItemsArray().count
        let segments = 5
        let stride = count / segments
        for i in 0..<segments {
            // 获取需要删除的VM
            let vm = feedProvider.getItemsArray()[stride * i - i]
            let id = vm.feedCardPreview.id
            // 执行删除
            feedProvider.removeItems([id])
            feedDict.removeValue(forKey: id)
        }

        /// 结果验证
        assertConsistent()
    }

    /// 全部删除
    func testFeedProviderRemoveAll() {
        /// 场景构建
        resetFeeds(of: baselineFeedCount)

        /// 操作执行
        // 执行删除
        feedProvider.removeAllItems()
        feedDict.removeAll()

        /// 结果验证
        assertConsistent()
    }

    /// 更新thread头像
    func testFeedProviderUpdateThreadAvatar() {
        /// 场景构建
        resetFeeds(of: baselineFeedCount)

        /// 操作执行
        let count = feedProvider.getItemsArray().count
        let segments = 5
        let stride = count / segments
        let baseAvatarKey = "Avatar"
        var avatarDict = [String: ThreadFeedAvatar]()
        for i in 0..<segments {
            // 构造avatar更新字典
            let vm = feedProvider.getItemsArray()[stride * i]
            let id = vm.feedCardPreview.id
            let newAvatarKey = baseAvatarKey + "\(i)"
            var avatar = ThreadFeedAvatar()
            avatar.avatarKey = newAvatarKey
            avatarDict[id] = avatar
        }
        // 执行更新
        feedProvider.updateThreadAvatars(avatarDict)
        for (id, avatar) in avatarDict {
            avatarDict[id] = avatar
        }

        /// 结果验证
        assertConsistentAvatar()
    }
}

extension FeedProviderTest {
    /// 生成单条Preview
    func generatePreview(id: String, rankTime: Int64, avatarKey: String) -> FeedPreview {
        var preview = Feed_V1_FeedCardPreview()
        preview.pair.id = id
        preview.rankTime = rankTime
        preview.avatarKey = avatarKey
        return FeedPreview.transformByCardPreview(preview)
    }

    /// 生成指定数量的VM数组
    func populateFeeds(of count: Int) -> [BaseFeedTableCellViewModel] {
        // swiftlint:disable empty_count
        guard count > 0 else { return [] }
        // swiftlint:enable empty_count

        var vms = [BaseFeedTableCellViewModel]()
        for i in (1...count).reversed() {
            let preview = generatePreview(id: "\(i)", rankTime: Int64(i), avatarKey: "\(i)")
            vms.append(BaseFeedTableCellViewModel(feedCardPreview: preview, bizType: .inbox)!)
        }
        return vms
    }

    /// 重置Feed数据源: FeedProvider和FeedDict
    func resetFeeds(of count: Int) {
        // 两种数据结构分别生成一次VM, 避免修改VM的副作用
        // reset Provider
        let vms1 = populateFeeds(of: count)
        feedProvider = FeedProvider(userResolver: Container.shared.getCurrentUserResolver(), vms: vms1)
        // reset Dict
        let vms2 = populateFeeds(of: count)
        feedDict.removeAll(keepingCapacity: true)
        for vm in vms2 {
            feedDict[vm.feedCardPreview.id] = vm
        }
    }

    /// id和rankTime一致断言
    func assertConsistent() {
        let vms = feedProvider.getItemsArray()
        let count = vms.count
        XCTAssert(count == feedDict.count)

        let flattened = feedDict.values.sorted(by: shouldRankHigher)
        var consistent = true
        var prompt = ""
        for i in 0..<count {
            if vms[i].feedCardPreview.id == flattened[i].feedCardPreview.id,
                vms[i].feedCardPreview.rankTime == flattened[i].feedCardPreview.rankTime {
                continue
            } else {
                consistent = false
                prompt = "\(i)th element mismatched, " +
                    "element in FeedProvider: id \(vms[i].feedCardPreview.id) rankTime \(vms[i].feedCardPreview.rankTime); " +
                "element in FeedDict: id \(flattened[i].feedCardPreview.id) rankTime \(flattened[i].feedCardPreview.rankTime)"
                break
            }
        }
        XCTAssert(consistent, prompt)
    }

    /// id和avatarKey一致断言
    func assertConsistentAvatar() {
        let vms = feedProvider.getItemsArray()
        let count = vms.count
        XCTAssert(count == feedDict.count)

        let flattened = feedDict.values.sorted(by: shouldRankHigher)
        var consistent = true
        var prompt = ""
        for i in 0..<count {
            if vms[i].feedCardPreview.id == flattened[i].feedCardPreview.id,
                vms[i].feedCardPreview.avatarKey == flattened[i].feedCardPreview.avatarKey {
                continue
            } else {
                consistent = false
                prompt = "\(i)th element mismatched, " +
                    "element in FeedProvider: id \(vms[i].feedCardPreview.id) avatarKey \(vms[i].feedCardPreview.avatarKey); " +
                "element in FeedDict: id \(flattened[i].feedCardPreview.id) avatarKey \(flattened[i].feedCardPreview.avatarKey)"
                break
            }
        }
        XCTAssert(consistent, prompt)
    }

    /// 判断前者是否应排于后者之前
    private func shouldRankHigher(_ lhs: BaseFeedTableCellViewModel, _ rhs: BaseFeedTableCellViewModel) -> Bool {
        return lhs.feedCardPreview.rankTime != rhs.feedCardPreview.rankTime ?
            lhs.feedCardPreview.rankTime > rhs.feedCardPreview.rankTime :
            lhs.feedCardPreview.id > rhs.feedCardPreview.id
    }
}
