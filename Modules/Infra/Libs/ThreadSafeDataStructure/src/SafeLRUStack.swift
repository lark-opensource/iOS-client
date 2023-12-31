//
//  SafeLRUStack.swift
//  ThreadSafeDataStructure
//
//  Created by Saafo on 2021/5/25.
//

import Foundation

/// 线程安全的 LRU 栈
public final class SafeLRUStack<ValueType: Hashable> {

    // MARK: Public Interfaces

    /// 栈容量
    public var maxSize: Int {
        synchronizationDelegate.readOperation {
            unsafeLRUStack.maxSize
        }
    }

    // MARK: Internal Attributes

    private let unsafeLRUStack: UnsafeLRUStack<ValueType>

    //swiftlint:disable weak_delegate
    private let synchronizationDelegate: SynchronizationDelegate
    //swiftlint:enable weak_delegate

    // MARK: Public Functions

    /// 线程安全的 LRU 栈
    /// - Parameters:
    ///   -  maxSize: 栈容量，默认值为 100
    ///   - synchronization: 同步方法，因为 LRU 写更频繁，故默认值为 `semaphore`
    public init(maxSize: Int = 100, synchronization: SynchronizationType = .semaphore) {
        self.unsafeLRUStack = UnsafeLRUStack(maxSize: maxSize)
        self.synchronizationDelegate = synchronization.generateSynchronizationDelegate()
    }

    /// 使用一次数值，已存在会刷新位置，不存在会加入缓存
    /// - Returns: 是否已经存在
    @discardableResult
    public func use(_ value: ValueType) -> Bool {
        synchronizationDelegate.writeOperation {
            unsafeLRUStack.use(value)
        }
    }

    /// 从栈顶开始取值
    @discardableResult
    public func pop() -> ValueType? {
        synchronizationDelegate.writeOperation {
            unsafeLRUStack.pop()
        }
    }

    /// 从栈顶开始，一直删到（但不包括） value 节点
    public func pop(to value: ValueType) {
        synchronizationDelegate.writeOperation {
            unsafeLRUStack.pop(to: value)
        }
    }

    /// 移除值为 value 的节点
    public func remove(_ value: ValueType) {
        synchronizationDelegate.writeOperation {
            unsafeLRUStack.remove(value)
        }
    }

    /// 返回栈顶值
    public func top() -> ValueType? {
        synchronizationDelegate.readOperation {
            unsafeLRUStack.top()
        }
    }

    /// 栈是否为空
    public var isEmpty: Bool {
        synchronizationDelegate.readOperation {
            unsafeLRUStack.isEmpty
        }
    }
}

/// 线程不安全的 LRU 栈
public final class UnsafeLRUStack<ValueType: Hashable> {

    /// 节点数据结构
    class Node<T> {
        let value: T
        var next: Node<T>?
        weak var prev: Node<T>?

        init(_ value: T) {
            self.value = value
        }
    }

    /// 线程不安全的 LRU 栈
    /// - Parameter maxSize: 栈容量，默认值为 100
    public init(maxSize: Int = 100) {
        self.maxSize = maxSize
    }

    /// 栈容量
    public var maxSize: Int

    var head: Node<ValueType>?
    var tail: Node<ValueType>?

    var cache: [ValueType: Node<ValueType>] = [:]

    /// 使用一次数值，已存在会刷新位置，不存在会加入缓存
    /// - Returns: 是否已经存在
    @discardableResult
    public func use(_ value: ValueType) -> Bool {
        if let node = cache[value] {
            moveToTop(node)
            return true
        } else {
            let node = Node(value)
            push(node)
            removeIfNeeded()
            return false
        }
    }

    /// 从栈顶开始取值
    @discardableResult
    public func pop() -> ValueType? {
        guard let node = head else {
            return nil
        }
        remove(node.value)
        return node.value
    }

    /// 从栈顶开始，一直删到（但不包括） value 节点
    public func pop(to value: ValueType) {
        if let node = head, node.value != value, node.next != nil {
            remove(node.value)
            pop(to: value)
        }
    }

    /// 移除值为 value 的节点
    public func remove(_ value: ValueType) {
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

    /// 返回栈顶值
    public func top() -> ValueType? {
        return head?.value
    }

    /// 栈是否为空
    public var isEmpty: Bool {
        return top() == nil
    }

    deinit { // deinit 时节点循环引用，需要手动清除节点
        while pop() != nil {}
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
