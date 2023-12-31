//
//  FeedProvider.swift
//  LarkFeed
//
//  Created by bitingzhu on 2020/8/17.
//

import Foundation
import RustPB
import LarkModel
import LarkContainer

/// Feed数据源
final class FeedProvider {

    // MARK: - 成员声明

    /// 数据源数组, VM实际存储于此
    /// 随机访问 O(1), 插入/删除 O(n)
    private var itemsArray = [FeedCardCellViewModel]()
    /// 下标缓存字典, 存储从id到下标的映射
    /// 读写单个key O(1)
    private var indicesDict = [String: Int]()

    /// 排序方式
    enum SortMode {
        case full // 全量
        case specified(indices: [Int]) // 指定的下标处数据需要重排（全量、增量视情况而定）
    }

    typealias SortType = (_ lhs: FeedCardCellViewModel, _ rhs: FeedCardCellViewModel) -> Bool
    var sort: SortType?

    /// 互斥锁
    private let lock = MutexLock()
    private let partialSortEnabled: Bool

    // MARK: - 构造函数

    /// 通过VM数组初始化数据源
    /// 目前仅用于单测
    init(partialSortEnabled: Bool, vms: [FeedCardCellViewModel]) {
        self.partialSortEnabled = partialSortEnabled

        self.itemsArray = vms
        for (i, item) in itemsArray.enumerated() {
            // 维护下标字典
            indicesDict[item.feedPreview.id] = i
        }
    }

    /// 初始化空数据源
    init(partialSortEnabled: Bool) {
        self.partialSortEnabled = partialSortEnabled
        self.itemsArray = []
        self.indicesDict = [:]
    }

    // MARK: - 数据操作

    ///
    /// # 数据源操作逻辑
    /// 对外开放update多个VM、remove多个、remove全部、update多个Avatar、重置选中态共五个接口
    /// 这五个对外接口都是线程安全的, 函数体内部负责加解锁, 调用方无需额外考虑同步问题
    /// 内部还包含两个个仅供内部使用的私有方法：update单个VM、remove单个, 没有内置锁
    ///

    /// 更新多个数据项, 内置加解锁逻辑
    func updateItems(_ updatedVMs: [FeedCardCellViewModel]) {
        // 加解锁
        lock.lock()
        defer { lock.unlock() }

        // 用于保存发生更新变动下标集合的数组
        var updatedIndices = [Int]()
        // 提前为index数组预留空间, 避免多次空间分配，提高性能
        updatedIndices.reserveCapacity(updatedVMs.count)

        // 遍历更新数据源
        for vm in updatedVMs {
            updatedIndices.append(_updateSingleItem(vm))
        }

        // 对发生更新的下标集合执行增量排序
        sortItems(.specified(indices: updatedIndices))
    }

    /// 更新单个数据项, 返回最终改动的下标
    /// 仅供Provider内部使用, 没有加解锁逻辑
    private func _updateSingleItem(_ updatedVM: FeedCardCellViewModel) -> Int {
        let id = updatedVM.feedPreview.id
        if let i = indicesDict[id] {
            // 原数据源中已存在, 直接替换对应VM
            itemsArray[i] = updatedVM
            return i
        } else {
            // 源数据源中尚未包含, 在数组尾部插入VM
            let formerCount = itemsArray.count
            itemsArray.append(updatedVM)
            // 维护下标字典
            indicesDict[id] = formerCount
            return formerCount
        }
    }

    /// 删除多个数据项, 内置加解锁逻辑
    func removeItems(_ ids: [String]) {
        // 加解锁
        lock.lock()
        defer { lock.unlock() }

        // 通过id遍历删除每个数据项
        ids.forEach { _removeSingleItem($0) }

        // 有序数组中删掉元素后，原数组保持有序，故无需排序
    }

    /// 删除单个数据项
    /// 仅供Provider内部使用, 没有加解锁逻辑
    private func _removeSingleItem(_ id: String) {
        guard let i = indicesDict[id] else {
            // id对应的数据不存在
            return
        }
        // 从数组和字典中同时删除数据项
        itemsArray.remove(at: i)
        indicesDict.removeValue(forKey: id)
        // 维护下标字典，需注意itemsArray.count是在remove之后取的
        for j in i..<itemsArray.count {
            indicesDict[itemsArray[j].feedPreview.id] = j
        }
    }

    /// 清空数据源, 内置加解锁逻辑
    func removeAllItems() {
        // 加解锁
        lock.lock()
        defer { lock.unlock() }

        // 同时清空数组和字典
        indicesDict.removeAll()
        itemsArray.removeAll()

        // 数组已经没有元素，无需排序
    }

    /// 更新thread数据项的头像, 内置加解锁逻辑
    func updateThreadAvatars(_ avatars: [String: Feed_V1_PushThreadFeedAvatarChanges.Avatar]) {
        // 加解锁
        lock.lock()
        defer { lock.unlock() }

        for (feedId, avatar) in avatars {
            // 若id对应的数据项存在并且是thread类型
            if let i = self.indicesDict[feedId],
                itemsArray[i].feedPreview.basicMeta.feedPreviewPBType == .thread {
                // 更新相应ID、种类为thread的feed的头像: VM是引用类型，可同步更新UI数据
                itemsArray[i].feedPreview.updateAvatar(key: avatar.avatarKey)
            }
        }

        // 更新avatarKey字段不影响cell顺序, 无需排序
    }

    /// 重置选中态, 内置加解锁逻辑
    func resetSelectedState(_ selectedID: String?) {
        // 加解锁
        lock.lock()
        defer { lock.unlock() }

        // 取消所有VM选中态
        itemsArray.forEach { $0.selected = false }
        // 设置即将选中的VM
        if let id = selectedID, let i = indicesDict[id] {
            itemsArray[i].selected = true
        }

        // 更新selected属性不影响cell顺序, 无需排序
    }

    /// 当badge style变化的时候，更新feed
    func updateFeedWhenBadgeStyleChange() {
        // 加解锁
        lock.lock()
        defer { lock.unlock() }
        let itemsArray = self.itemsArray
        // 重新生成feed
        itemsArray.forEach {
            guard $0.checkUpdateWhenMuteBadgeStyleChange() else { return }
            _ = _updateSingleItem($0.copy())
        }
    }

    // MARK: - 排序

    ///
    /// # 数据源排序逻辑
    /// 负责数据源数组排序与字典维护
    /// 全量排序走Swift5内置的的sort方法(基于TimSort, 插入归并) O(nlogn);
    /// 增量增量走部分插入排序 O(mn)
    ///

    /// 执行数据源排序
    private func sortItems(_ mode: SortMode) {
        guard self.partialSortEnabled else {
            // fg关闭增量排序能力, 走全量排序
            fullSort()
            return
        }

        switch mode {
        case .full:
            // 指定全量排序则直接走全量
            fullSort()
        case let .specified(indices):
            // 判断是否适合走增量
            if shouldPerformPartialSort(indices.count) {
                // 适合，走增量
                partialSort(indices)
            } else {
                // 不适合，走全量
                fullSort()
            }
        }
    }

    func setSort(_ sort: @escaping SortType) {
        self.sort = sort
    }

    private func defaultSort(_ lhs: FeedCardCellViewModel, _ rhs: FeedCardCellViewModel) -> Bool {
        let lrt = self.getFeedCardRankTime(feedPreview: lhs.feedPreview)
        let rrt = self.getFeedCardRankTime(feedPreview: rhs.feedPreview)

        return lrt != rrt ? lrt > rrt : lhs.feedPreview.id > rhs.feedPreview.id
    }

    // 取值规则: onTopRankTime > rankTime
    private func getFeedCardRankTime(feedPreview: FeedPreview) -> FeedCardRankTime {
        if feedPreview.basicMeta.onTopRankTime > 0 {
            return .topRankTime(feedPreview.basicMeta.onTopRankTime)
        }
        return .rankTime(feedPreview.basicMeta.rankTime)
    }

    /// 判断前者是否应排于后者之前, inline提高性能
    @inline(__always)
    private func shouldRankHigher(_ lhs: FeedCardCellViewModel, _ rhs: FeedCardCellViewModel) -> Bool {
        if let sort = self.sort {
            return sort(lhs, rhs)
        }
        return defaultSort(lhs, rhs)
    }

    /// 判断是否适合执行增量排序
    private func shouldPerformPartialSort(_ sortingCount: Int) -> Bool {
        // 经验判断, 一般认为待排序元素个数小于等于总元素个数的20分之一即走增量
        // 原因是在此条件下, pull走全量、push走增量, 符合场景的预期
        sortingCount <= itemsArray.count / Cons.sortCount
    }

    /// 全量排序
    private func fullSort() {
        itemsArray.sort(by: shouldRankHigher)
        // 全量维护下标字典
        for i in 0..<itemsArray.count {
            indicesDict[itemsArray[i].feedPreview.id] = i
        }
    }

    /// 增量排序
    private func partialSort(_ indices: [Int]) {
        // 依次对每个有改动的元素执行排序
        for i in indices {
            // 前置条件判断: 1. 元素下标没有越界 2. 若该元素存在后继, 该元素的rankTime需要高于后继 (兜底rankTime减小的case)
            guard i < itemsArray.count,
                !(i + 1 < itemsArray.count && shouldRankHigher(itemsArray[i + 1], itemsArray[i])) else {
                    // 不符合前置条件, 回滚到全量排序
                    fullSort()
                    return
            }
            /// ┌---┐ ---------------------
            /// | j |    j 从 0 迭代到 i-1
            /// | * | 顺序比较arr[j], arr[i]
            /// | * | ---------------------
            /// |---|
            /// | i | 改动点, 需要找到元素在数组中新的位置
            /// |---|
            /// | - | ---------------------
            /// | - |   下方比i值小，无需比较
            /// | - | ---------------------
            /// └---┘
            for j in 0..<i {
                if shouldRankHigher(itemsArray[j], itemsArray[i]) {
                    // j的值比i大, j无需移动, i的预期位置在j之下
                    continue
                } else {
                    /// 调整前 调整后
                    /// ┌---┐ ┌---┐
                    /// | - | | - |
                    /// | - | | - | ------------
                    /// | j | | i |
                    /// | * | |---| i确定插入位置
                    /// | * | | j | i插入在j的位置
                    /// |---| | * | [j, i-1]下挪
                    /// | i | | * |  数组调整结束
                    /// |---| |---|
                    /// | - | | - | ------------
                    /// └---┘ └---┘
                    /// i的值比j大, i应插入于此, [j, i-1]的所有元素需要向下挪动到[j+1, i]
                    itemsArray.withUnsafeMutableBufferPointer { buffer in
                        /// 获取swift数组底层的c指针来操作数组元素
                        /// 避免了耗时的retain/release
                        /// 代价是需要严谨的逻辑避免crash
                        /// ⚠️注意事项:
                        /// 1. 闭包执行期间只能通过buffer访问/修改原数组, 而不能直接访问itemsArray(原swift数组对象)
                        /// 2. 不能将buffer保存到闭包外, 之后再使用
                        /// 3. 不能在闭包内修改buffer的baseAddress(基地址)
                        /// 其中: 1同时通过锁和代码逻辑保证, 2和3通过代码逻辑保证

                        // 将i保存到临时变量
                        let temp = buffer[i]

                        // 下挪[j, i-1]
                        // 等价于()
                        for k in 0..<(i - j) {
                            buffer[i - k] = buffer[i - k - 1]
                            // 维护字典下标
                            indicesDict[buffer[i - k].feedPreview.id] = i - k
                        }

                        // 将i插入到j原来的位置
                        buffer[j] = temp
                        indicesDict[temp.feedPreview.id] = j
                    }
                    break
                }
            }
        }
    }

    // MARK: - 数据访问

    ///
    /// # 数据源外部访问
    /// 提供返回全部VM的数组、通过id查询单个VM两个接口
    /// 均内置加解锁逻辑
    ///

    /// 获取数据源数组, 内置加解锁逻辑
    func getItemsArray() -> [FeedCardCellViewModel] {
        lock.lock()
        defer { lock.unlock() }

        return itemsArray
    }

    /// 通过id获取单个数据源项, 内置加解锁逻辑
    func getItemBy(id: String) -> FeedCardCellViewModel? {
        lock.lock()
        defer { lock.unlock() }

        // 前置条件判断: 数据源存在id对应的数据项下标、下标没有越界
        guard let i = indicesDict[id], i < itemsArray.count else {
            return nil
        }

        return itemsArray[i]
    }

    enum Cons {
        static let sortCount: Int = 20
    }
}
