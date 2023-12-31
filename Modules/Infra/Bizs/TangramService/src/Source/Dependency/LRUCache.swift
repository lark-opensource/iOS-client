//
//  LRUCache.swift
//  TangramService
//
//  Created by 袁平 on 2021/7/29.
//

import Foundation
final class LRUCache<Key: Hashable, Value> {
    typealias DoublyLink = (previous: Key?, next: Key?)

    private let maxCapacity: Int
    private var store: [Key: Value] = [:]
    private var doublyLink: [Key: DoublyLink] = [:] // 双链表指针
    private var tail: Key? // 超出maxCapacity时，需要移除tail
    private var head: Key? // 移动到首节点时，需要head
    private let threadSafe: Bool
    private var rwLock: pthread_rwlock_t?
    // LRU溢出时回调
    var overflowCallback: ((_ key: Key, _ value: Value) -> Void)?

    init(maxCapacity: Int, threadSafe: Bool = true) {
        self.maxCapacity = maxCapacity
        self.threadSafe = threadSafe
        if threadSafe {
            self.rwLock = pthread_rwlock_t()
            pthread_rwlock_init(&rwLock!, nil)
        }
    }

    func getValue(key: Key) -> Value? {
        safeWrite {
            guard let value = store[key] else { return nil }
            innerMoveToHead(key: key)
            return value
        }
    }

    func getValues(keys: [Key]) -> [Key: Value] {
        safeWrite {
            var values = [Key: Value]()
            keys.forEach { key in
                if let value = store[key] {
                    values[key] = value
                    innerMoveToHead(key: key)
                }
            }
            return values
        }
    }

    func setValue(key: Key, value: Value) {
        safeWrite {
            innerSetValue(key: key, value: value)
        }
    }

    /// 对values操作仅一次加锁，但是不保证values的操作顺序
    func setValues(values: [Key: Value]) {
        safeWrite {
            values.forEach { key, value in
                innerSetValue(key: key, value: value)
            }
        }
    }

    @discardableResult
    func remove(key: Key) -> Value? {
        safeWrite {
            innerRemove(key: key)
        }
    }

    @discardableResult
    func remove(keys: [Key]) -> [Key: Value] {
        var removedKV = [Key: Value]()
        safeWrite {
            keys.forEach { key in
                if let value = innerRemove(key: key) {
                    removedKV[key] = value
                }
            }
        }
        return removedKV
    }

    @discardableResult
    func removeAll() -> [Key: Value] {
        var removedKV = [Key: Value]()
        safeWrite {
            removedKV = store
            store = [:]
            doublyLink = [:]
            tail = nil
            head = nil
        }
        return removedKV
    }
}

// MARK: - without lock
extension LRUCache {
    private func innerSetValue(key: Key, value: Value) {
        // 已有Key
        if store[key] != nil {
            store[key] = value
            innerMoveToHead(key: key)
        } else { // 没有Key，插入头部
            store[key] = value
            doublyLink[key] = (nil, head)
            // 修改head指针
            if let head = head {
                doublyLink[head]?.previous = key
            }
            head = key
            // 首次插入，记录tail
            if store.count == 1 {
                tail = key
            }
            // 超出最大容量，移除尾节点
            if store.count > maxCapacity, let tail = tail, let overflowValue = innerRemove(key: tail) {
                overflowCallback?(tail, overflowValue)
            }
        }
    }

    private func innerRemove(key: Key) -> Value? {
        guard let value = store[key] else { return nil }
        store[key] = nil
        let current = doublyLink[key]
        if let previous = current?.previous {
            doublyLink[previous]?.next = current?.next
        }
        if let next = current?.next {
            doublyLink[next]?.previous = current?.previous
        }
        if key == head {
            head = current?.next
        }
        if key == tail {
            tail = current?.previous
        }
        doublyLink[key] = nil
        return value
    }

    private func innerMoveToHead(key: Key) {
        if doublyLink[key] == nil { return }
        // 已经位于头节点，无需移动
        if key == head { return }
        let current = doublyLink[key]
        // 移除当前节点
        if let previous = current?.previous {
            doublyLink[previous]?.next = current?.next
        }
        if let next = current?.next {
            doublyLink[next]?.previous = current?.previous
        }
        if key == tail {
            tail = current?.previous
        }
        // 添加当前节点到首节点
        doublyLink[key]?.previous = nil
        doublyLink[key]?.next = head
        if let lastHead = head {
            doublyLink[lastHead]?.previous = key
        }
        head = key
    }
}

extension LRUCache {
    func safeRead<T>(_ read: () -> T) -> T {
        if threadSafe, rwLock != nil {
            pthread_rwlock_rdlock(&rwLock!)
            defer { pthread_rwlock_unlock(&rwLock!) }
            return read()
        } else {
            return read()
        }
    }

    @discardableResult
    func safeWrite<T>(_ write: () -> T) -> T {
        if threadSafe, rwLock != nil {
            pthread_rwlock_wrlock(&rwLock!)
            defer { pthread_rwlock_unlock(&rwLock!) }
            return write()
        } else {
            return write()
        }
    }
}
