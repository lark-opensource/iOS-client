//
//  MMKVStore.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import EEAtomic

/// 基于 MMKV 封装的 KVStoreBase
final class MMKVStore: KVStoreBase {
    static var type: KVStoreType { .mmkv }

    weak var delegate: KVStoreBaseDelegate?

    private let index: MMKVIndex

    var mmkv: MMKVType? { MMKVCache.item(forIndex: index) }

    var useRawStorage = false

    /// MMKV 暂不支持 shared 模式下的 filePaths 查询，后续可能支持
    var filePaths: [String] {
        guard mmkv != nil else { return [] }
        let mmapID = index.mmapId
        return [
            (index.rootPath as NSString).appendingPathComponent(mmapID),
            (index.rootPath as NSString).appendingPathComponent(mmapID + ".crc")
        ]
    }

    init(mmapId: String, rootPath: String) {
        self.index = .init(mmapId: mmapId, rootPath: rootPath)
    }

    // TODO: 该接口未经过充分测试，现仅供单测使用
    func removeFromCache() {
        MMKVCache.removeItem(forIndex: index)
    }

    func register(defaults: [String: Any]) {
        // 暂不支持
    }

    func migrate(values: [String: Any]) {
        guard let mmkv else { return }

        for (key, value) in values where !mmkv.contains(key: key) {
            if let t = value as? KVStoreBasicType {
                t.save(in: self, forKey: key)
            } else if let t = value as? NSCodingObject {
                saveValue(t, forKey: key)
            }
        }
    }

    func contains(key: String) -> Bool {
        return mmkv?.contains(key: key) ?? false
    }

    func removeValue(forKey key: String) {
        mmkv?.removeValue(forKey: key)
    }

    func allKeys() -> [String] {
        guard let mmkv else { return [] }
        return mmkv.allKeys().compactMap(keyCompactMap)
    }

    func allValues() -> [String: Any] {
        guard let mmkv else { return [:] }
        var values: [String: Any] = [:]
        for key in mmkv.allKeys().compactMap(keyCompactMap) {
            values[key] = innerGetValue(forKey: key, with: mmkv)
        }
        return values
    }

    func clearAll() {
        guard let mmkv else { return }
        for key in mmkv.allKeys().compactMap(keyCompactMap) {
            mmkv.removeValue(forKey: key)
        }
    }

    func synchronize() {
        mmkv?.sync()
    }

    func loadValue(forKey key: String) -> Bool? {
        return contains(key: key) ? mmkv?.bool(forKey: key) : nil
    }

    func loadValue(forKey key: String) -> Int? {
        guard let mmkv else { return nil }
        return contains(key: key) ? Int(mmkv.int64(forKey: key)) : nil
    }

    func loadValue(forKey key: String) -> Int64? {
#if DEBUG || ALPHA
        // TODO: 验证目前是否有 MMKV 对 Int64 的读写，下面 FG 全量后去掉
        KVStores.assert(false, "unexpected load Int64, key: \(key)", event: .mmkvInt64)
#endif
        if LarkStorageFG.equivalentInteger || useRawStorage {
            return contains(key: key) ? mmkv?.int64(forKey: key) : nil
        } else {
            return codableGet(forKey: key)
        }
    }

    func loadValue(forKey key: String) -> Double? {
        return contains(key: key) ? mmkv?.double(forKey: key) : nil
    }

    func loadValue(forKey key: String) -> Float? {
        return contains(key: key) ? mmkv?.float(forKey: key) : nil
    }

    func loadValue(forKey key: String) -> String? {
        return mmkv?.string(forKey: key)
    }

    func loadValue(forKey key: String) -> Data? {
        return mmkv?.data(forKey: key)
    }

    func loadValue(forKey key: String) -> Date? {
        return mmkv?.date(forKey: key)
    }

    func loadValue<T: NSCodingObject>(forKey key: String) -> T? {
        return mmkv?.object(of: T.self, forKey: key) as? T
    }

    func saveValue(_ value: Bool, forKey key: String) {
        mmkv?.set(value, forKey: key)
    }

    func saveValue(_ value: Int, forKey key: String) {
        mmkv?.set(Int64(value), forKey: key)
    }

    func saveValue(_ value: Int64, forKey key: String) {
#if DEBUG || ALPHA
        // TODO: 验证目前是否有 MMKV 对 Int64 的读写，下面 FG 全量后去掉
        KVStores.assert(false, "unexpected save Int64, key: \(key)", event: .mmkvInt64)
#endif
        if LarkStorageFG.equivalentInteger || useRawStorage {
            mmkv?.set(value, forKey: key)
        } else {
            codableSet(value, forKey: key)
        }
    }

    func saveValue(_ value: Double, forKey key: String) {
        mmkv?.set(value, forKey: key)
    }

    func saveValue(_ value: Float, forKey key: String) {
        mmkv?.set(value, forKey: key)
    }

    func saveValue(_ value: String, forKey key: String) {
        mmkv?.set(value, forKey: key)
    }

    func saveValue(_ value: Data, forKey key: String) {
        mmkv?.set(value, forKey: key)
    }

    func saveValue(_ value: Date, forKey key: String) {
        mmkv?.set(value, forKey: key)
    }

    func saveValue(_ value: NSCodingObject, forKey key: String) {
        mmkv?.set(value, forKey: key)
    }

    private func keyCompactMap(_ key: Any) -> String? {
        guard
            let key = key as? String,
            delegate?.judgeSatisfy(forKey: key) ?? true
        else {
            return nil
        }
        return key
    }

    private func innerGetValue(forKey key: String, with mmkv: MMKVType) -> Any? {
        if let str = mmkv.string(forKey: key) {
            return str
        } else if let data = mmkv.data(forKey: key) {
            return data
        } else if let array = mmkv.object(of: NSArray.self, forKey: key) {
            return array
        } else if let dic = mmkv.object(of: NSDictionary.self, forKey: key) {
            return dic
        }

        switch mmkv.valueSize(forKey: key, actualSize: false) {
        case 1, 2:
            return mmkv.int64(forKey: key)
        case 4:
            return mmkv.float(forKey: key)
        case 8:
            return mmkv.double(forKey: key)
        default:
            return nil
        }
    }

}

public struct MMKVCache {
    static let lock = UnfairLock()
    static var dict = [MMKVIndex: MMKVType]()

    static let useLruCache = LarkStorageFG.mmkvUseLruCache

    private static let loadableKey = "LarkStorage_KeyValueMMKVProvider"
    public typealias Provider = (_ index: MMKVIndex) -> MMKVType?

    private static var _provider: Provider?
    static var provider: Provider? {
        Dependencies.loadOnce(loadableKey)
        return _provider
    }

    public static func register(_ provider: @escaping Provider) {
        _provider = provider
    }

    static func item(forIndex index: MMKVIndex) -> MMKVType? {
        if useLruCache {
            return NewMMKVCache.item(forIndex: index)
        }
        lock.lock()
        defer { lock.unlock() }

        if let exists = dict[index] {
            return exists
        }
        guard let provider else {
            #if DEBUG || ALPHA
            fatalError("unexpected")
            #else
            return nil
            #endif
        }

        guard let new = provider(index) else {
            KVStores.assert(
                false,
                "init MMKVStore failed. mmapID: \(index.mmapId), rootPath: \(index.rootPath)",
                event: .initBase
            )
            return nil
        }

        dict[index] = new
        return new
    }

    static func removeItem(forIndex index: MMKVIndex) {
        if useLruCache {
            NewMMKVCache.removeItem(forIndex: index)
        }

        lock.lock()
        defer { lock.unlock() }

        dict.removeValue(forKey: index)
    }
}

private struct NewMMKVCache {
    typealias Inner = LRUCache<MMKVIndex, MMKVType>
    /// 最多允许同时打开 30 个 MMKV
    static let capacity = 30
    static let inner = Inner(capacity: capacity) { index, mmkv in
        KVStores.logger.info("[MMKVCache] close mmkv. mmapId: \(index.mmapId), path: \(index.rootPath)")
        mmkv.close()
    }

    static func item(forIndex index: MMKVIndex) -> MMKVType? {
        if let exists = inner.value(forKey: index) {
            return exists
        }

        guard let provider = MMKVCache.provider else {
            #if DEBUG || ALPHA
            fatalError("unexpected")
            #else
            return nil
            #endif
        }

        guard let new = provider(index) else {
            KVStores.assert(
                false,
                "mmapId: \(index.mmapId), rootPath: \(index.rootPath)",
                event: .initBase
            )
            return nil
        }
        KVStores.logger.info("[MMKVCache] create mmkv. mmapId: \(index.mmapId), path: \(index.rootPath)")
        inner.setValue(new, forKey: index)
        return new
    }

    static func removeItem(forIndex index: MMKVIndex) {
        inner.removeValue(forKey: index)?.close()
    }
}
