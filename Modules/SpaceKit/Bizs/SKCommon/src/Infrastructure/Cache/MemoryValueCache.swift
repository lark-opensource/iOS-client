//
//  MemoryValueCache.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/9/3.
//  
// 在内存中的，可以存放valueType的cache
//https://www.swiftbysundell.com/posts/caching-in-swift

import Foundation

final class DocValueCache<Key: Hashable, Value> {
    private var wrapped: NSCache<WrappedKey, Entry> =  {
        let c = NSCache<WrappedKey, Entry>()
        c.totalCostLimit = 50 * 1024 * 1024
        c.countLimit = 100
        return c
    }()

    /// 因为 NSCache 不支持获取所有的keys，所以额外使用一个集合保存所有的keys
    private var keySet = Set<Key>()

    func insert(_ value: Value, forKey key: Key) {
        let entry = Entry(value: value)
        wrapped.setObject(entry, forKey: WrappedKey(key))
        keySet.insert(key)
    }

    func value(forKey key: Key) -> Value? {
        let entry = wrapped.object(forKey: WrappedKey(key))
        return entry?.value
    }

    func removeValue(forKey key: Key) {
        let entry = wrapped.object(forKey: WrappedKey(key))
        wrapped.removeObject(forKey: WrappedKey(key))
        keySet.remove(key)
        //不在主线程释放，避免卡顿
        DispatchQueue.global(qos: .default).async {
            _ = entry?.value
        }
    }

    func allKeys() -> [Key] {
        return [Key].init(keySet)
    }
}

private extension DocValueCache {
    final class WrappedKey: NSObject {
        let key: Key

        init(_ key: Key) { self.key = key }

        override var hash: Int { return key.hashValue }

        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }

            return value.key == key
        }
    }
}

private extension DocValueCache {
    final class Entry {
        let value: Value

        init(value: Value) {
            self.value = value
        }
    }
}

extension DocValueCache {
    subscript(key: Key) -> Value? {
        get { return value(forKey: key) }
        set {
            guard let value = newValue else {
                // If nil was assigned using our subscript,
                // then we remove any value for that key:
                removeValue(forKey: key)
                return
            }

            insert(value, forKey: key)
        }
    }
}
