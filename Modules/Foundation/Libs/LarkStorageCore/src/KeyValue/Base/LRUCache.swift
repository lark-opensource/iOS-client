//
//  LRUCache.swift
//  LarkStorage
//
//  Created by 7Up on 2023/8/25.
//

import Foundation
import EEAtomic

/// LRU(Least Recently Used) Cache
final class LRUCache<Key: Hashable, Value> {

    private final class Node {
        var key: Key
        var value: Value
        var prev: Node?
        var next: Node?

        init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }

    let capacity: Int

    // protect dict and list
    private let lock = UnfairLock()
    private var dict = [Key: Node]()
    private var list = (head: Node?.none, tail: Node?.none)

    typealias OverflowEvent = ((_ key: Key, _ value: Value) -> Void)
    private let onOverflow: OverflowEvent?

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return dict.count
    }

    init(capacity: Int, onOverflow: OverflowEvent? = nil) {
        self.capacity = max(1, capacity)
        self.onOverflow = onOverflow
    }

    deinit {
        // 清除 node 的互相引用，防止引用循环
        dict.values.forEach { node in
            node.prev = nil
            node.next = nil
        }
    }

    func value(forKey key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }

        guard let node = dict[key] else {
            return nil
        }
        moveNodeToHead(node)
        return node.value
    }

    func setValue(_ value: Value, forKey key: Key) {
        lock.lock()
        defer { lock.unlock() }

        if let node = dict[key] {
            assert(node.key == key)
            node.key = key
            node.value = value
            moveNodeToHead(node)
        } else {
            let node = Node(key: key, value: value)
            insertNodeToHead(node)
            if dict.count > capacity {
                let removed = dropTailNode()
                if let removed, let onOverflow {
                    onOverflow(removed.key, removed.value)
                }
            }
        }
    }

    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }

        return dropNode(byKey: key)?.value
    }

    private func insertNodeToHead(_ node: Node) {
        assert(list.head?.prev == nil)
        node.prev = nil
        node.next = list.head
        list.head?.prev = node
        if list.tail == nil {
            assert(dict.count == 0 && list.head == nil)
            list.tail = node
        }
        list.head = node
        dict[node.key] = node
    }

    private func moveNodeToHead(_ node: Node) {
        guard node !== list.head else { return }

        let prev = node.prev
        let next = node.next
        prev?.next = next
        next?.prev = prev

        node.next = list.head
        list.head?.prev = node
        node.prev = nil

        if node === list.tail {
            list.tail = prev
        }

        list.head = node
    }

    private func dropNode(byKey key: Key) -> Node? {
        guard let removed = dict[key] else {
            return nil
        }

        let prev = removed.prev
        let next = removed.next
        prev?.next = next
        next?.prev = prev

        if removed === list.head {
            list.head = next
        }
        if removed === list.tail {
            list.tail = prev
        }

        dict.removeValue(forKey: removed.key)
        return removed
    }

    private func dropTailNode() -> Node? {
        guard let removed = list.tail else {
            return nil
        }
        assert(removed.next == nil)
        removed.prev?.next = nil
        list.tail = removed.prev
        if removed === list.head {
            list.head = nil
            assert(list.tail == nil)
        }
        dict.removeValue(forKey: removed.key)
        return removed
    }

}
