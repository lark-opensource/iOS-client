//
//  LRUCache.swift
//  CTFoundation
//
//  Created by 张威 on 2020/9/27.
//

import Foundation

/// LRU(Least Recently Used) Cache
public final class LRUCache<Key: Hashable, Value> {

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

    private var list = (head: Node<Key, Value>?.none, tail: Node<Key, Value>?.none)
    private var storage = [Key: Node<Key, Value>]()
    private let lock: DispatchSemaphore?

    public init(capacity: Int, useLock: Bool = false) {
        self.capacity = max(1, capacity)
        self.lock = useLock ? DispatchSemaphore(value: 1) : nil
    }

    deinit {
        // 清除 node 的互相引用，防止引用循环
        storage.values.forEach { node in
            node.prev = nil
            node.next = nil
        }
    }

    public func value(forKey key: Key) -> Value? {
        lock?.wait()
        defer { lock?.signal() }

        #if DEBUG
        defer { checkNodesInDebugMode() }
        #endif

        if let node = storage[key] {
            moveNodeToHead(node)
            return node.value
        }
        return nil
    }

    public func setValue(_ value: Value, forKey key: Key) {
        lock?.wait()
        defer { lock?.signal() }

        #if DEBUG
        defer { checkNodesInDebugMode() }
        #endif

        if let node = storage[key] {
            assert(node.key == key)
            node.key = key
            node.value = value
            moveNodeToHead(node)
        } else {
            let node = Node(key: key, value: value)
            insertNodeToHead(node)
            if curSize > capacity {
                dropTailNode()
            }
        }
    }

    public func removeValue(forKey key: Key, while condition: (Value) -> Bool) {
        lock?.wait()
        defer { lock?.signal() }

        #if DEBUG
        defer { checkNodesInDebugMode() }
        #endif

        dropNode(byKey: key, while: condition)
    }

    public func removeValue(forKey key: Key) {
        removeValue(forKey: key, while: { _ in true })
    }

    #if DEBUG
    private func checkNodesInDebugMode() {
        var node = list.head
        var list1 = [Node<Key, Value>]()
        while node != nil {
            list1.append(node!)
            node = node?.next
        }

        node = list.tail
        var list2 = [Node<Key, Value>]()
        while node != nil {
            list2.append(node!)
            node = node?.prev
        }
        list2.reverse()

        assert(list1.count == list2.count
            && list1.count == curSize
            && curSize == storage.keys.count
            && curSize <= capacity)
        (0..<curSize).forEach { assert(list1[$0] === list2[$0]) }
    }
    #endif

    private func insertNodeToHead(_ node: Node<Key, Value>) {
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

    private func moveNodeToHead(_ node: Node<Key, Value>) {
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

    private func dropNode(byKey key: Key, while condition: (Value) -> Bool) {
        guard let removed = storage[key], condition(removed.value) else { return }

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

        curSize -= 1
        storage.removeValue(forKey: removed.key)
    }

    private func dropTailNode() {
        guard let removed = list.tail else { return }
        assert(removed.next == nil)
        removed.prev?.next = nil
        list.tail = removed.prev
        curSize -= 1
        if removed === list.head {
            list.head = nil
            assert(list.tail == nil)
        }
        storage.removeValue(forKey: removed.key)
    }

}
