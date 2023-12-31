////
////  FeedProviderUnitTest.swift
////  LarkFeed-Unit-Tests
////
////  Created by 白镜吾 on 2023/8/14.
////
//
//import XCTest
//import LarkModel
//import RustPB
//import LarkContainer
//import Foundation
//import LarkOpenFeed
//@testable import LarkFeed
//
//final class FeedProviderUnitTest: XCTestCase {
//
//    private lazy var feedProvider: FeedProvider = FeedProvider(partialSortEnabled: true)
//    private var feedDict: [String: FeedCardCellViewModel] = [:]
//    /// feed条数基线
//    let baselineFeedCount = 120
//    /// 单次pull数量
//    let pullCount = 60
//    let emptyCount = 0
//
//    /// 单条push到表首
//    func testFeedProviderSinglePushToFirst() {
//        let count = baselineFeedCount
//        let segments = 5
//        let stride = count / segments
//        for i in 0..<segments {
//            /// 场景构建
//            resetFeeds(of: count)
//
//            /// 操作执行
//            // 构造需要更新的VM
//            let vm = feedProvider.getItemsArray()[stride * i]
//            let id = vm.feedPreview.id
//            let avatarKey = vm.feedPreview.uiMeta.avatarKey
//            let newRankTime = Int64(feedProvider.getItemsArray()[0].feedPreview.basicMeta.rankTime + 1)
//
//            let newVM = MockFeed.generateFeedCardCellViewModel(feedID: id, rankTime: newRankTime, avatarKey: avatarKey)
//            // 执行更新
//            feedProvider.updateItems([newVM])
//            feedDict[id] = newVM
//
//            /// 结果验证
//            assertConsistent()
//        }
//    }
//
//    /// 多条push到表首
//    func testFeedProviderMultiplePushToTop() {
//        /// 场景构建
//        resetFeeds(of: baselineFeedCount)
//
//        /// 操作执行
//        let count = feedProvider.getItemsArray().count
//        let segments = 5
//        let stride = count / segments
//        let baseRankTime = feedProvider.getItemsArray()[0].feedPreview.basicMeta.rankTime
//
//        var updatedVMs = [FeedCardCellViewModel]()
//        for i in 0..<segments {
//            // 构造需要更新的VM
//            let vm = feedProvider.getItemsArray()[stride * i]
//            let id = vm.feedPreview.id
//            let avatarKey = vm.feedPreview.uiMeta.avatarKey
//            let newRankTime = Int64(baseRankTime + i)
//
//            let newVM = MockFeed.generateFeedCardCellViewModel(feedID: id, rankTime: newRankTime, avatarKey: avatarKey)
//            updatedVMs.append(newVM)
//            feedDict[id] = newVM
//        }
//        // 执行更新
//        feedProvider.updateItems(updatedVMs)
//
//        /// 结果验证
//        assertConsistent()
//    }
//
//    /// 单条push到表尾
//    func testFeedProviderSinglePushToBottom() {
//        /// 场景构建
//        resetFeeds(of: baselineFeedCount)
//
//        /// 操作执行
//        // 构造需要更新的VM
//        let count = feedProvider.getItemsArray().count
//        let vm = feedProvider.getItemsArray()[count / 2]
//        let id = vm.feedPreview.id
//        let avatarKey = vm.feedPreview.uiMeta.avatarKey
//        let newRankTime = Int64(feedProvider.getItemsArray()[count - 1].feedPreview.basicMeta.rankTime - 1)
//
//        let newVM = MockFeed.generateFeedCardCellViewModel(feedID: id, rankTime: newRankTime, avatarKey: avatarKey)
//        // 执行更新
//        feedProvider.updateItems([newVM])
//        feedDict[id] = newVM
//
//        /// 结果验证
//        assertConsistent()
//    }
//
//    /// 单条删除
//    func testFeedProviderSinglePushRemove() {
//        /// 场景构建
//        resetFeeds(of: baselineFeedCount)
//
//        /// 操作执行
//        // 获取需要删除的VM
//        let count = feedProvider.getItemsArray().count
//        let vm = feedProvider.getItemsArray()[count / 2]
//        let id = vm.feedPreview.id
//        // 执行删除
//        feedProvider.removeItems([id])
//        feedDict.removeValue(forKey: id)
//
//        /// 结果验证
//        assertConsistent()
//    }
//
//    /// 多条删除
//    func testFeedProviderMultiplePushRemove() {
//        /// 场景构建
//        resetFeeds(of: baselineFeedCount)
//
//        /// 操作执行
//        let count = feedProvider.getItemsArray().count
//        let segments = 5
//        let stride = count / segments
//        for i in 0..<segments {
//            // 获取需要删除的VM
//            let vm = feedProvider.getItemsArray()[stride * i - i]
//            let id = vm.feedPreview.id
//            // 执行删除
//            feedProvider.removeItems([id])
//            feedDict.removeValue(forKey: id)
//        }
//
//        /// 结果验证
//        assertConsistent()
//    }
//
//    /// 全部删除
//    func testFeedProviderRemoveAll() {
//        /// 场景构建
//        resetFeeds(of: baselineFeedCount)
//
//        /// 操作执行
//        // 执行删除
//        feedProvider.removeAllItems()
//        feedDict.removeAll()
//
//        /// 结果验证
//        assertConsistent()
//    }
//
//    /// 增量排序
//    func testFeedProviderPartialSort() {
//        /// 场景构建
//        resetFeeds(of: baselineFeedCount)
//        /// 操作执行
//
//        let count = feedProvider.getItemsArray().count
//        let segments = baselineFeedCount / 20 - 1
//        let stride = count / segments
//        let baseRankTime = feedProvider.getItemsArray()[0].feedPreview.basicMeta.rankTime
//
//        var updatedVMs = [FeedCardCellViewModel]()
//        for i in 0..<segments {
//            // 构造需要更新的VM
//            let vm = feedProvider.getItemsArray()[stride * i]
//            let id = vm.feedPreview.id
//            let avatarKey = vm.feedPreview.uiMeta.avatarKey
//            let newRankTime = Int64(baseRankTime + i)
//            let newVM = MockFeed.generateFeedCardCellViewModel(feedID: id, rankTime: newRankTime, avatarKey: avatarKey)
//            updatedVMs.append(newVM)
//            feedDict[id] = newVM
//        }
//        // 执行更新
//        feedProvider.updateItems(updatedVMs)
//
//    }
//
//    /// 全量排序
//    func testFeedProviderFullSort() {
//        /// 场景构建
//        resetFeeds(of: baselineFeedCount, partialSortEnabled: false)
//        /// 操作执行
//
//        let count = feedProvider.getItemsArray().count
//        let segments = baselineFeedCount / 20 - 1
//        let stride = count / segments
//        let baseRankTime = feedProvider.getItemsArray()[0].feedPreview.basicMeta.rankTime
//
//        var updatedVMs = [FeedCardCellViewModel]()
//        for i in 0..<segments {
//            // 构造需要更新的VM
//            let vm = feedProvider.getItemsArray()[stride * i]
//            let id = vm.feedPreview.id
//            let avatarKey = vm.feedPreview.uiMeta.avatarKey
//            let newRankTime = Int64(baseRankTime + i)
//            let newVM = MockFeed.generateFeedCardCellViewModel(feedID: id, rankTime: newRankTime, avatarKey: avatarKey)
//            updatedVMs.append(newVM)
//            feedDict[id] = newVM
//        }
//        // 执行更新
//        feedProvider.updateItems(updatedVMs)
//    }
//
//    /// 更新 thread 头像
//    func testFeedProviderUpdateThreadAvatar() {
//        /// 场景构建
//        resetFeeds(of: baselineFeedCount)
//
//        /// 操作执行
//        let count = feedProvider.getItemsArray().count
//        let segments = 5
//        let stride = count / segments
//        let baseAvatarKey = "Avatar"
//        var avatarDict = [String: Feed_V1_PushThreadFeedAvatarChanges.Avatar]()
//        for i in 0..<segments {
//            // 构造avatar更新字典
//            let vm = feedProvider.getItemsArray()[stride * i]
//            let id = vm.feedPreview.id
//            let newAvatarKey = baseAvatarKey + "\(i)"
//            var avatar = Feed_V1_PushThreadFeedAvatarChanges.Avatar()
//            avatar.avatarKey = newAvatarKey
//            avatarDict[id] = avatar
//        }
//        // 执行更新
//        feedProvider.updateThreadAvatars(avatarDict)
//        for (id, avatar) in avatarDict {
//            avatarDict[id] = avatar
//        }
//
//        /// 结果验证
//        assertConsistentAvatar()
//    }
//
//}
//
//extension FeedProviderUnitTest {
//
//    /// 重置 feedProvider 和 feedDict 的值
//    func resetFeeds(of count: Int, partialSortEnabled: Bool = true) {
//        // 两种数据结构分别生成一次VM, 避免修改VM的副作用
//        // reset Provider
//        let vms1 = MockFeed.populateFeeds(of: count)
//        feedProvider = FeedProvider(partialSortEnabled: partialSortEnabled, vms: vms1)
//        // reset Dict
//        let vms2 = MockFeed.populateFeeds(of: count)
//        feedDict.removeAll(keepingCapacity: true)
//        for vm in vms2 {
//            feedDict[vm.feedPreview.id] = vm
//        }
//    }
//
//    /// id和rankTime一致断言
//    func assertConsistent() {
//        let vms = feedProvider.getItemsArray()
//        let count = vms.count
//        XCTAssert(count == feedDict.count)
//
//        let flattened = feedDict.values.sorted(by: MockFeed.shouldRankHigher)
//        var consistent = true
//        var prompt = ""
//        for i in 0..<count {
//            if vms[i].feedPreview.id == flattened[i].feedPreview.id,
//               vms[i].feedPreview.basicMeta.rankTime == flattened[i].feedPreview.basicMeta.rankTime {
//                continue
//            } else {
//                consistent = false
//                prompt = "\(i)th element mismatched, " +
//                "element in FeedProvider: id \(vms[i].feedPreview.id) rankTime \(vms[i].feedPreview.basicMeta.rankTime); " +
//                "element in FeedDict: id \(flattened[i].feedPreview.id) rankTime \(flattened[i].feedPreview.basicMeta.rankTime)"
//                break
//            }
//        }
//        XCTAssert(consistent, prompt)
//    }
//
//    /// id和avatarKey一致断言
//    func assertConsistentAvatar() {
//        let vms = feedProvider.getItemsArray()
//        let count = vms.count
//        XCTAssert(count == feedDict.count)
//
//        let flattened = feedDict.values.sorted(by: MockFeed.shouldRankHigher)
//        var consistent = true
//        var prompt = ""
//        for i in 0..<count {
//            if vms[i].feedPreview.id == flattened[i].feedPreview.id,
//               vms[i].feedPreview.uiMeta.avatarKey == flattened[i].feedPreview.uiMeta.avatarKey {
//                continue
//            } else {
//                consistent = false
//                prompt = "\(i)th element mismatched, " +
//                    "element in FeedProvider: id \(vms[i].feedPreview.id) avatarKey \(vms[i].feedPreview.uiMeta.avatarKey); " +
//                "element in FeedDict: id \(flattened[i].feedPreview.id) avatarKey \(flattened[i].feedPreview.uiMeta.avatarKey)"
//                break
//            }
//        }
//        XCTAssert(consistent, prompt)
//    }
//}
