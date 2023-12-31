//
//  FeedSelectionServiceImp.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/8/3.
//

import Foundation
import RxSwift
import RxRelay
import ThreadSafeDataStructure
import LarkMessengerInterface
import RustPB

typealias FeedSelectionServiceProvider = () -> FeedSelectionService

final class FeedSelectionServiceImp: FeedSelectionService {
    private var selection = BehaviorRelay<String?>(value: nil)
    // TODO: 待优化
    private let selectionFeedTabRelay = BehaviorRelay<FeedSelection?>(value: nil)

    /// select 缓存
    private var cache = LRUStack<String>()
    /// 当前查看记录节点
    private var currentRecord: LRUStack<String>.Node<String>?

    init() {}

    /// 设置Feed选中
    func setSelected(feedId: String?) {
        selection.accept(feedId)

        let cacheValue = feedId ?? ""
        if let current = self.currentRecord {
            /// 跳转与记录保持一致时，判断为历史记录跳转
            /// 不修改 cache
            if current.value == cacheValue {
                return
            }
            /// 用户手动选择丢弃后面的记录，并删除记录查看指针
            cache.pop(to: current)
            self.currentRecord = nil
        }
        cache.use(cacheValue)
    }

    func selectedRecordID(prev: Bool) -> String? {
        guard let node = self.currentRecord ?? self.cache.head else {
            return nil
        }
        /// 列表中的 prev 与 node 中含义是相反的
        if !prev, let prevNode = node.prev {
            self.currentRecord = prevNode
            return prevNode.value
        } else if prev, let nextNode = node.next {
            self.currentRecord = nextNode
            return nextNode.value
        }
        return nil
    }

    /// 获取当前选中Feed的FeedId
    func getSelected() -> String? {
        return selection.value
    }

    /// 监听选中Feed变化
    func observeSelect() -> Observable<String?> {
        return selection.asObservable()
    }

    /// 监听选中filter tab及feed变化
    var selectFeedObservable: Observable<FeedSelection?> {
        return selectionFeedTabRelay.asObservable()
    }

    func setSelectedFeed(selection: FeedSelection) {
        selectionFeedTabRelay.accept(selection)
    }

    /// 获取当前选中Feed的FeedId
    func getSelectedFeed() -> FeedSelection? {
        return selectionFeedTabRelay.value
    }
}

final class LRUStack<ValueType: Hashable> {

    final class Node<T> {
        let value: T
        var next: Node<T>?
        weak var prev: Node<T>?

        init(_ value: T) {
            self.value = value
        }
    }

    var maxSize: Int = 100
    var head: Node<ValueType>?
    var tail: Node<ValueType>?

    var cache: SafeDictionary<ValueType, Node<ValueType>> = [:] + .readWriteLock

    @discardableResult
    func use(_ value: ValueType) -> ValueType {
        defer {
            removeIfNeeded()
        }
        if let node = cache[value] {
            moveToTop(node)
            return node.value
        } else {
            let node = Node(value)
            push(node)
            return node.value
        }
    }

    func pop(to: Node<ValueType>) {
        let node = head
        if let node, node.value != to.value, node.next != nil {
            remove(node.value)
            pop(to: to)
        }
    }

    func remove(_ value: ValueType) {
        guard let node = cache[value] else {
            return
        }

        if head === node {
            head = node.next
        }

        if tail === node {
            tail = tail?.prev
        }

        node.next?.prev = node.prev
        node.prev?.next = node.next
        node.prev = nil
        node.next = nil

        cache.removeValue(forKey: value)
    }

    func top() -> ValueType? {
        return head?.value
    }

    var isEmpty: Bool {
        return top() == nil
    }

    private func push(_ node: Node<ValueType>) {
        if tail == nil {
            tail = node
        }
        node.prev = nil
        node.next = head
        head?.prev = node
        head = node
        cache[node.value] = node
    }

    private func moveToTop(_ node: Node<ValueType>) {
        guard head?.value != node.value else {
            return
        }
        if node.value == tail?.value {
            tail = node.prev
        }
        node.next?.prev = node.prev
        node.prev?.next = node.next
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
    }

    private func removeIfNeeded() {
        if self.maxSize <= 0 { return }
        guard self.cache.count > self.maxSize else {
            return
        }
        if let tail = self.tail {
            self.remove(tail.value)
        }
    }
}
