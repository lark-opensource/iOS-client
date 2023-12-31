//
//  KeyedPool.swift
//  CTFoundation
//
//  Created by 张威 on 2020/9/27.
//

import Foundation

/// Keyed Pool
///   - 以 LRU 为淘汰策略
///   - push 和 pop 的时间复杂度均为 O(1)
///   - 支持 Lock
public final class KeyedPool<Key: Hashable, Element> {

    public typealias ElementFactory = (Key) -> Element

    private final class Node<K, V> {
        var key: K
        var value: V
        var prev: Node<K, V>?
        var next: Node<K, V>?

        init(key: K, value: V) {
            self.key = key
            self.value = value
        }
    }

    private let capacity: Int
    private var curSize = 0

    private var list = (head: Node<Key, Element>?.none, tail: Node<Key, Element>?.none)
    private var storage = [Key: Node<Key, Element>]()
    private let lock: DispatchSemaphore?

    private let factory: ElementFactory

    public init(capacity: Int, useLock: Bool = false, factory: @escaping ElementFactory) {
        self.capacity = max(1, capacity)
        self.lock = useLock ? DispatchSemaphore(value: 1) : nil
        self.factory = factory
    }

    deinit {
        // 清除 node 的互相引用，防止引用循环
        storage.values.forEach { node in
            node.prev = nil
            node.next = nil
        }
    }

    public func pop(byKey key: Key) -> Element {
        lock?.wait()
        defer { lock?.signal() }

        #if DEBUG
        defer { checkNodesInDebugMode() }
        #endif

        if let node = dropNode(byKey: key) {
            return node.value
        }
        if curSize < capacity {
            return factory(key)
        }
        if let tail = list.tail {
            guard let node = dropNode(byKey: tail.key), node === tail else {
                assertionFailure()
                return factory(key)
            }
            return node.value
        }
        assertionFailure()
        return factory(key)
    }

    public func push(_ element: Element, forKey key: Key) {
        lock?.wait()
        defer { lock?.signal() }

        #if DEBUG
        defer { checkNodesInDebugMode() }
        #endif

        if let node = storage[key] {
            assert(node.key == key)
            node.key = key
            node.value = element
            moveNodeToHead(node)
        } else {
            let node = Node(key: key, value: element)
            insertNodeToHead(node)
        }
    }

    #if DEBUG
    private func checkNodesInDebugMode() {
        var node = list.head
        var list1 = [Node<Key, Element>]()
        while node != nil {
            list1.append(node!)
            node = node?.next
        }

        node = list.tail
        var list2 = [Node<Key, Element>]()
        while node != nil {
            list2.append(node!)
            node = node?.prev
        }
        list2.reverse()

        assert(list1.count == list2.count
            && list1.count == curSize
            && curSize == storage.keys.count)
        (0..<curSize).forEach { assert(list1[$0] === list2[$0]) }
    }
    #endif

    private func dropNode(byKey key: Key) -> Node<Key, Element>? {
        guard let removed = storage[key] else { return nil }

        curSize -= 1
        storage.removeValue(forKey: removed.key)

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

        return removed
    }

    private func insertNodeToHead(_ node: Node<Key, Element>) {
        assert(list.head?.prev == nil)
        node.prev = nil
        node.next = list.head
        list.head?.prev = node
        if list.tail == nil {
            assert(curSize == 0 && list.head == nil)
            list.tail = node
        }
        list.head = node
        curSize += 1
        storage[node.key] = node
    }

    private func moveNodeToHead(_ node: Node<Key, Element>) {
        guard node !== list.head else { return }
        _ = dropNode(byKey: node.key)
        insertNodeToHead(node)
    }

}
