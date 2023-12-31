//
//  LRUStack.swift
//  AudioSessionStack
//
//  Created by lvdaqian on 2018/11/15.
//

import Foundation

final class LRUStack<ValueType: Hashable> {

    final class Node<T> {
        let value: T
        var next: Node<T>?
        weak var prev: Node<T>?

        init(_ value: T) {
            self.value = value
        }
    }

    private var lock = pthread_rwlock_t()
    private var head: Node<ValueType>?
    private var cache: [ValueType: Node<ValueType>] = [:]

    init() {
        pthread_rwlock_init(&lock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&lock)
    }
}

// MARK: write functions
extension LRUStack {
    @discardableResult
    func use(_ value: ValueType) -> ValueType {
        pthread_rwlock_wrlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        if let node = cache[value] {
            moveToTop(node)
            return node.value
        } else {
            let node = Node(value)
            push(node)
            return node.value
        }
    }

    @discardableResult
    func pop() -> ValueType? {
        pthread_rwlock_wrlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        guard let node = head else {
            return nil
        }
        cache.removeValue(forKey: node.value)

        head = node.next
        head?.prev = nil
        node.next = nil

        return node.value
    }

    func remove(_ value: ValueType) {
        pthread_rwlock_wrlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        guard let node = cache[value] else {
            return
        }

        if head?.value == node.value {
            head = node.next
        }

        node.next?.prev = node.prev
        node.prev?.next = node.next
        node.prev = nil
        node.next = nil

        cache.removeValue(forKey: value)
    }
}

// MARK: read functions
extension LRUStack {
    func top() -> ValueType? {
        pthread_rwlock_rdlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        return head?.value
    }

    var isEmpty: Bool {
        pthread_rwlock_rdlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        return top() == nil
    }

    var values: [ValueType] {
        pthread_rwlock_rdlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        return cache.values.map { $0.value }
    }

    func exist(_ filter: (ValueType) -> Bool) -> Bool {
        pthread_rwlock_rdlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        var p = head
        while p != nil {
            guard let value = p?.value else { return false }
            if filter(value) {
                return true
            } else {
                p = p?.next
                continue
            }
        }
        return false
    }

    func reduce(_ startValue: ValueType?, _ executor: (ValueType?, ValueType?) -> ValueType?) -> ValueType? {
        pthread_rwlock_rdlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        var result = startValue
        var p = head
        while p != nil {
            result = executor(result, p?.value)
            p = p?.next
        }
        return result
    }
}

// MARK: private functions
private extension LRUStack {
    func push(_ node: Node<ValueType>) {
        node.prev = nil
        node.next = head
        head?.prev = node
        head = node
        cache[node.value] = node
    }

    func moveToTop(_ node: Node<ValueType>) {
        guard head?.value != node.value else {
            return
        }
        node.next?.prev = node.prev
        node.prev?.next = node.next
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
    }
}
