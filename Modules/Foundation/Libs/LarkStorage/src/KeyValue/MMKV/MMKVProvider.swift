//
//  MMKVImpl.swift
//  LarkStorage
//
//  Created by 7Up on 2023/9/4.
//

import Foundation
import MMKV

final class MMKVWrapper: MMKVType {
    var wrapped: MMKV

    init?(index: MMKVIndex) {
        let _wrapped: MMKV?
        if index.isMultiProcess {
            _wrapped = MMKV(mmapID: index.mmapId, groupPath: index.rootPath)
        } else {
            _wrapped = MMKV(mmapID: index.mmapId, rootPath: index.rootPath)
        }
        guard let wrapped = _wrapped else {
            return nil
        }
        self.wrapped = wrapped
    }

    func valueSize(forKey key: String, actualSize: Bool) -> Int {
        wrapped.valueSize(forKey: key, actualSize: actualSize)
    }

    func contains(key: String) -> Bool {
        return wrapped.contains(key: key)
    }

    func allKeys() -> [Any] {
        return wrapped.allKeys()
    }

    func removeValue(forKey key: String) {
        wrapped.removeValue(forKey: key)
    }

    func sync() {
        wrapped.sync()
    }

    func close() {
        wrapped.close()
    }

    func bool(forKey key: String) -> Bool {
        return wrapped.bool(forKey: key)
    }

    func set(_ bool: Bool, forKey key: String) {
        wrapped.set(bool, forKey: key)
    }

    func int64(forKey key: String) -> Int64 {
        return wrapped.int64(forKey: key)
    }

    func set(_ int64: Int64, forKey key: String) {
        wrapped.set(int64, forKey: key)
    }

    func float(forKey key: String) -> Float {
        return wrapped.float(forKey: key)
    }

    func set(_ float: Float, forKey key: String) {
        wrapped.set(float, forKey: key)
    }

    func double(forKey key: String) -> Double {
        return wrapped.double(forKey: key)
    }

    func set(_ double: Double, forKey key: String) {
        wrapped.set(double, forKey: key)
    }

    func string(forKey key: String) -> String? {
        return wrapped.string(forKey: key)
    }

    func set(_ string: String, forKey key: String) {
        wrapped.set(string, forKey: key)
    }

    func data(forKey key: String) -> Data? {
        return wrapped.data(forKey: key)
    }

    func set(_ data: Data, forKey key: String) {
        wrapped.set(data, forKey: key)
    }

    func date(forKey key: String) -> Date? {
        return wrapped.date(forKey: key)
    }

    func set(_ date: Date, forKey key: String) {
        wrapped.set(date, forKey: key)
    }

    func object(of cls: AnyClass, forKey key: String) -> Any? {
        return wrapped.object(of: cls.self, forKey: key)
    }

    func set(_ object: NSCodingObject, forKey key: String) {
        wrapped.set(object, forKey: key)
    }

}

// NOTE: 这个 `public` 不能删
final public class MMKVProvider {
    /// 注册 MMKV Provider
    @_silgen_name("Lark.LarkStorage_KeyValueMMKVProvider.LarkStorage")
    public static func registerMMKVProvider() {
        MMKVCache.register(MMKVWrapper.init(index:))
    }
}
