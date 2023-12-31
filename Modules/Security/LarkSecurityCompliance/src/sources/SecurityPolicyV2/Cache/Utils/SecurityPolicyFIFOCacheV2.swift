//
//  SecurityPolicyFIFOCacheV2.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/4.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import ThreadSafeDataStructure

extension SecurityPolicyV2 {
    public class FIFOCache: SecurityPolicyCache {
        var type: CacheType {
            .fifo(maxSize: self.max)
        }

        public static let writeCacheQueue = DispatchQueue(label: "security_policy_local_cache")

        private let store: SCKeyValueStorage
        private let cacheKey: String

        private static let currentKey = "index_key_current"
        private static let firstKey = "index_key_first"
        private static let countKey = "index_key_count"
        private static let maxKey = "index_key_max"

        /// 缓存开始的index
        private var safeFirst: SafeAtomic<Int> = 0 + .readWriteLock
        private var first: Int {
            get {
                safeFirst.value
            }
            set {
                safeFirst.value = newValue
                store.set(newValue, forKey: Self.firstKey)
            }
        }
        /// 当前缓存index
        private var safeCurrent: SafeAtomic<Int> = -1 + .readWriteLock
        private var current: Int {
            get {
                safeCurrent.value
            }
            set {
                safeCurrent.value = newValue
                store.set(newValue, forKey: Self.currentKey)
            }
        }
        /// 当前缓存值
        private var safeCount: SafeAtomic<Int> = 0 + .readWriteLock
        private(set) var count: Int {
            get {
                safeCount.value
            }
            set {
                safeCount.value = newValue
                store.set(newValue, forKey: Self.countKey)
            }
        }
        /// 缓存阈值
        public let max: Int

        required public init(userID: String, maxSize: Int, cacheKey: String) {
            self.cacheKey = cacheKey
            store = SCKeyValue.MMKV(userId: userID, business: .securityPolicy(subBiz: cacheKey))
            max = maxSize
            first = store.value(forKey: Self.firstKey) ?? 0
            current = store.value(forKey: Self.currentKey) ?? -1
            count = store.value(forKey: Self.countKey) ?? 0

            let oldCount = store.value(forKey: Self.maxKey) ?? 0
            if oldCount != maxSize {
                Self.writeCacheQueue.async { [weak self] in
                    guard let self else { return }
                    self.migrateData(withOldMax: oldCount)
                }
                store.set(maxSize, forKey: Self.maxKey)
            }
        }

        public func write<T: Codable>(value: T, forKey rawKey: String) {
            let key = rawKey.md5()
            // swiftlint:disable:next unused_optional_binding
            if let _: T = store.value(forKey: key) {
                store.set(value, forKey: key)
                return
            }

            // 如果将要超过阈值，删除第一个元素，first ++
            if count >= max {
                let removeIndexKey = first.idx
                let removeKey: String = store.value(forKey: removeIndexKey) ?? ""
                store.removeObject(forKey: removeKey)
                first = (first + 1) % max
                count -= 1
            }
            // 新增一个元素， current ++
            current = (current + 1) % max
            store.set(key, forKey: current.idx)
            store.set(value, forKey: key)
            count += 1
        }

        public func read<T>(forKey rawKey: String) -> T? where T: Decodable, T: Encodable {
            let key = rawKey.md5()
            let value: T? = store.value(forKey: key)
            return value
        }

        public func getAllRealCache<T: Codable>() -> [T] {
            var index = 0
            var result = [T]()
            while index < count {
                let key = store.value(forKey: ((index + first) % max).idx) ?? ""
                guard !key.isEmpty,
                      let value: T = store.value(forKey: key) else {
                    index += 1
                    continue
                }
                result.append(value)

                index += 1
            }
            return result
        }
        
        func contains(forKey rawKey: String) -> Bool {
            store.contains(key: rawKey)
        }

        public func cleanAll() {
            Self.writeCacheQueue.async { [weak self] in
                guard let self else { return }
                self.store.clearAll()
                self.store.set(self.max, forKey: Self.maxKey)
                self.first = 0
                self.current = -1
                self.count = 0
            }
        }

        func removeValue(forKey rawKey: String) {
            assertionFailure("FIFO Cache dosen't support remove value")
        }

        private func migrateData(withOldMax oldMax: Int) {
            guard oldMax > 0 else { return }
            // 阈值从小变大，且之前的数据也没有达到阈值
            if count < max && first < current {
                return
            }
            var allMigrateKeys = [String]()

            var index = 0
            while index < self.count {
                let indexKey = ((index + first) % oldMax).idx
                guard let key: String = store.value(forKey: indexKey) else {
                    index += 1
                    continue
                }
                // 只迁移curent往后的max条数据
                if count - index <= max {
                    allMigrateKeys.append(key)
                } else {
                    store.removeObject(forKey: key)
                }
                store.removeObject(forKey: indexKey)
                index += 1
            }
            index = 0
            while index < allMigrateKeys.count {
                store.set(allMigrateKeys[index], forKey: index.idx)
                index += 1
            }

            first = 0
            current = allMigrateKeys.count - 1
            count = allMigrateKeys.count
        }
    }
}

extension SecurityPolicyV2.FIFOCache {
    func markInvalid() {
        var index = 0
        while index < self.count {
            let key = store.value(forKey: ((index + first) % max).idx) ?? ""
            guard !key.isEmpty,
                  var value: SecurityPolicyValidateResultCache = store.value(forKey: key) else {
                index += 1
                continue
            }
            value.markInvalid()
            store.set(value, forKey: key)
            index += 1
        }
    }
}

fileprivate extension Int {
    var idx: String { "idx_\(self)" }
}
