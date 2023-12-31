//
//  FlagDataProvider.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/18.
//

import Foundation
import RustPB
import LarkModel
import LarkOpenFeed

// 标记的类型：feed 和 message
public enum FlagItemType: Int {
    case feed
    case message
}

public protocol FlagItemInterface {
    var feedPreview: FeedPreview? { get }
    var message: Message? { get }
    var feedVM: FeedCardViewModelInterface? { get }
    var messageVM: FlagMessageCellViewModel? { get }
}

// FlagItem的模型
public final class FlagItem: FlagItemInterface {
    // 标记的类型
    public let type: FlagItemType
    // 标记的id：如果是feed类型的话就是feedId，如果是message类型的话就是messageId
    public let flagId: String
    // 创建时间
    public let createTime: TimeInterval
    // 排序的时间
    public let rankTime: TimeInterval
    // 更新的时间
    public let updateTime: TimeInterval
    // 是否是脏数据
    public var isDirty: Bool = false
    // 真正的CellVM：外面不要直接获取，请通过协议对外暴露
    private let cellViewModel: AnyObject
    // feed类型的flagItem里面是FeedPreview
    public var feedPreview: FeedPreview? {
        guard let feedVM = self.cellViewModel as? FeedCardViewModelInterface else {
            return nil
        }
        return feedVM.feedPreview
    }
    // message类型的flagItem里面是Message
    public var message: Message? {
        guard let messageVM = self.cellViewModel as? FlagMessageCellViewModel else {
            return nil
        }
        return messageVM.message
    }
    // message类型的flagItem里面的VM是FeedCardViewModelInterface
    public var feedVM: FeedCardViewModelInterface? {
        guard let feedVM = self.cellViewModel as? FeedCardViewModelInterface else {
            return nil
        }
        return feedVM
    }
    // feed类型的flagItem里面的VM是FlagMessageCellViewModel
    public var messageVM: FlagMessageCellViewModel? {
        guard let messageVM = self.cellViewModel as? FlagMessageCellViewModel else {
            return nil
        }
        return messageVM
    }

    // 这个唯一标识符用来插入更新数据库，因为话题的根消息messageId和话题本身的feedId是一样的，用flagId没法区分
    public var uniqueId: String {
        if self.type == .message {
            return  "message_" + self.flagId
        }
        return "feed_" + self.flagId
    }

    public init(type: FlagItemType, flagId: String, createTime: Double, rankTime: Double, updateTime: Double, cellViewModel: AnyObject) {
        self.type = type
        self.flagId = flagId
        self.createTime = createTime
        self.rankTime = rankTime
        self.updateTime = updateTime
        self.cellViewModel = cellViewModel
    }
}

final class FlagMutexLock {

    let semaphore: DispatchSemaphore

    init() {
        semaphore = DispatchSemaphore(value: 0)
        semaphore.signal() // 保证V操作次数>=P
    }

    func lock() {
        semaphore.wait()
    }

    func unlock() {
        semaphore.signal()
    }
}

// FlagList数据源
public final class FlagDataProvider {
    /// 数据源数组, VM实际存储于此
    /// 随机访问 O(1), 插入/删除 O(n)
    private var itemsArray = [FlagItem]()
    /// 下标缓存字典, 存储从id到下标的映射
    /// 读写单个key O(1)
    private var indicesDict = [String: Int]()
    /// 排序方式，默认是按照标记创建的时间排序
    private var sortingRule: Feed_V1_FlagSortingRule = .default

    /// 排序方式
    enum SortMode {
        case full // 全量
        case specified(indices: [Int]) // 指定的下标处数据需要重排（全量、增量视情况而定）
    }

    typealias SortType = (_ lhs: FlagItem, _ rhs: FlagItem) -> Bool
    var sort: SortType?

    /// 互斥锁
    private let lock = FlagMutexLock()

    // MARK: - 构造函数

    /// 通过VM数组初始化数据源
    /// 目前仅用于单测
    init(vms: [FlagItem]) {
        self.itemsArray = vms
        for (i, item) in itemsArray.enumerated() {
            // 维护下标字典
            indicesDict[item.uniqueId] = i
        }
    }

    /// 初始化空数据源
    init() {
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
    func updateItems(_ updatedItems: [FlagItem]) {
        // 加解锁
        lock.lock()
        defer { lock.unlock() }

        // 用于保存发生更新变动下标集合的数组
        var updatedIndices = [Int]()
        // 提前为index数组预留空间, 避免多次空间分配，提高性能
        updatedIndices.reserveCapacity(updatedItems.count)

        // 遍历更新数据源
        for item in updatedItems {
            updatedIndices.append(_updateSingleItem(item))
        }

        // 对发生更新的下标集合执行增量排序
        sortItems(.specified(indices: updatedIndices))
    }

    /// 更新单个数据项, 返回最终改动的下标
    /// 仅供Provider内部使用, 没有加解锁逻辑
    private func _updateSingleItem(_ updatedItem: FlagItem) -> Int {
        if let i = indicesDict[updatedItem.uniqueId] {
            // 在替换VM之前需要先把原来的选中状态保存下来
            if let feedVM = itemsArray[i].feedVM {
                updatedItem.feedVM?.selected = feedVM.selected
            } else if let messageVM = itemsArray[i].messageVM {
                updatedItem.messageVM?.selected = messageVM.selected
            }
            // 原数据源中已存在, 直接替换对应VM
            itemsArray[i] = updatedItem
            return i
        } else {
            // 源数据源中尚未包含, 在数组尾部插入VM
            let formerCount = itemsArray.count
            itemsArray.append(updatedItem)
            // 维护下标字典
            indicesDict[updatedItem.uniqueId] = formerCount
            return formerCount
        }
    }

    /// 删除多个数据项, 内置加解锁逻辑
    func removeItems(_ uniqueIds: [String]) {
        // 加解锁
        lock.lock()
        defer { lock.unlock() }

        // 通过id遍历删除每个数据项
        uniqueIds.forEach { _removeSingleItem($0) }

        // 有序数组中删掉元素后，原数组保持有序，故无需排序
    }

    /// 删除单个数据项
    /// 仅供Provider内部使用, 没有加解锁逻辑
    private func _removeSingleItem(_ uniqueId: String) {
        guard let i = indicesDict[uniqueId] else {
            // id对应的数据不存在
            return
        }
        // 从数组和字典中同时删除数据项
        itemsArray.remove(at: i)
        indicesDict.removeValue(forKey: uniqueId)
        // 维护下标字典，需注意itemsArray.count是在remove之后取的
        for j in i..<itemsArray.count {
            indicesDict[itemsArray[j].uniqueId] = j
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
            let uniqueId = "feed_" + feedId
            if let i = self.indicesDict[uniqueId], let feedVM = itemsArray[i].feedVM, feedVM.feedPreview.basicMeta.feedPreviewPBType == .thread {
                // 更新相应ID、种类为thread的feed的头像: VM是引用类型，可同步更新UI数据
                feedVM.feedPreview.updateAvatar(key: avatar.avatarKey)
            }
        }
        // 更新avatarKey字段不影响cell顺序, 无需排序
    }

    /// 重置选中态, 内置加解锁逻辑
    func resetSelectedState(_ selectedUniqueId: String?) {
        // 加解锁
        lock.lock()
        defer { lock.unlock() }

        // 取消所有VM选中态
        itemsArray.forEach { item in
            if let feedVM = item.feedVM {
                feedVM.selected = false
            } else if let messageVM = item.messageVM {
                messageVM.selected = false
            }
        }
        // 设置即将选中的VM
        if let id = selectedUniqueId, let i = indicesDict[id] {
            if let feedVM = itemsArray[i].feedVM {
                feedVM.selected = true
            } else if let messageVM = itemsArray[i].messageVM {
                messageVM.selected = true
            }
        }
        // 更新selected属性不影响cell顺序, 无需排序
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
        fullSort()
    }

    func setSort(_ sort: @escaping SortType) {
        self.sort = sort
    }

    private func defaultSort(_ lhs: FlagItem, _ rhs: FlagItem) -> Bool {
        if self.sortingRule == .message {
            // 按照消息更新时间排序
            return lhs.rankTime > rhs.rankTime
        }
        // 按照标记时间排序
        return lhs.createTime > rhs.createTime
    }

    /// 判断前者是否应排于后者之前, inline提高性能
    @inline(__always)
    private func shouldRankHigher(_ lhs: FlagItem, _ rhs: FlagItem) -> Bool {
        if let sort = self.sort {
            return sort(lhs, rhs)
        }
        return defaultSort(lhs, rhs)
    }

    /// 判断是否适合执行增量排序
    private func shouldPerformPartialSort(_ sortingCount: Int) -> Bool {
        // 经验判断, 一般认为待排序元素个数小于等于总元素个数的20分之一即走增量
        // 原因是在此条件下, pull走全量、push走增量, 符合场景的预期
        sortingCount <= itemsArray.count / 20
    }

    /// 全量排序
    private func fullSort() {
        itemsArray.sort(by: shouldRankHigher)
        // 全量维护下标字典
        for i in 0..<itemsArray.count {
            indicesDict[itemsArray[i].uniqueId] = i
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
                            indicesDict[buffer[i - k].uniqueId] = i - k
                        }

                        // 将i插入到j原来的位置
                        buffer[j] = temp
                        indicesDict[temp.uniqueId] = j
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
    func getItemsArray() -> [FlagItem] {
        lock.lock()
        defer { lock.unlock() }

        return itemsArray
    }

    /// 通过id获取单个数据源项, 内置加解锁逻辑
    func getItemBy(uniqueId: String) -> FlagItem? {
        lock.lock()
        defer { lock.unlock() }

        // 前置条件判断: 数据源存在id对应的数据项下标、下标没有越界
        guard let i = indicesDict[uniqueId], i < itemsArray.count else {
            return nil
        }

        return itemsArray[i]
    }

    // MARK: - 设置数据排序方式

    ///
    /// 目前有两种：按照标记时间排序、按照消息最新时间排序
    func setFlagSortingRole(_ sortingRule: Feed_V1_FlagSortingRule) {
        self.sortingRule = sortingRule
    }
}
