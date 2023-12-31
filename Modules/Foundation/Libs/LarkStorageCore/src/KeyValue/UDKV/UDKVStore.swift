//
//  UDKVStore.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

/// 基于 UserDefaults 封装的 KVStoreBase
final class UDKVStore: KVStoreBase {

    static var type: KVStoreType { .udkv }

    weak var delegate: KVStoreBaseDelegate?

    let userDefaults: UserDefaults
    /// 对于 `NSCodingObject` 的读写，使用 `NSKeyedUnarchiver` 进行处理
    var useNSKeyedUnarchiver = true

    var suiteName = ""

    var filePaths: [String] {
        let rootPath: String

        if suiteName == Dependencies.appGroupId,
           let rootURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName),
           rootURL.isFileURL
        {
            rootPath = rootURL.path
        } else {
            rootPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        }

        return [NSString.path(withComponents: [rootPath, "Preferences", suiteName + ".plist"])]
    }

    init?(suiteName: String) {
        guard let ud = UserDefaults(suiteName: suiteName) else {
            KVStores.assert(false, "init UDKVStore failed. suiteName: \(suiteName)", event: .initBase)
            return nil
        }
        self.suiteName = suiteName
        self.userDefaults = ud
    }

    // NOTE: 临时针对迁移场景使用
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    init() {
        userDefaults = .standard
    }

    func register(defaults: [String: Any]) {
        userDefaults.register(defaults: defaults)
    }

    func migrate(values: [String: Any]) {
        for (key, value) in values where !contains(key: key) {
            userDefaults.set(value, forKey: key)
        }
    }

    func contains(key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }

    func removeValue(forKey key: String) {
        return userDefaults.removeObject(forKey: key)
    }

    func allKeys() -> [String] {
        return userDefaults.dictionaryRepresentation().keys.filter(keyFilter(_:))
    }

    func allValues() -> [String: Any] {
        return userDefaults.dictionaryRepresentation().filter { keyFilter($0.key) }
    }

    func clearAll() {
        allKeys().forEach(userDefaults.removeObject(forKey:))
    }

    func synchronize() {
        userDefaults.synchronize()
    }

    func loadValue(forKey key: String) -> Bool? {
        return contains(key: key) ? userDefaults.bool(forKey: key) : nil
    }

    /*
     * Int 与 Int64 需要互通, 但是由于历史遗留, 
     * Int64 需要通过 codableGet 解码读取
     */
    func loadValue(forKey key: String) -> Int? {
        if LarkStorageFG.equivalentInteger {
            let value = userDefaults.object(forKey: key)
            guard let value else {
                return nil
            }
            if let intValue = value as? Int {
                return intValue
            }
            if let int64Value: Int64 = codableGet(forKey: key) {
                return Int(int64Value)
            }
            KVStores.assert(false, "failed to load int value, key: \(KVStoreLogProxy.encoded(for: key))", event: .loadInt)
            return nil
        } else {
            return contains(key: key) ? userDefaults.integer(forKey: key) : nil
        }
    }

    func loadValue(forKey key: String) -> Int64? {
        if LarkStorageFG.equivalentInteger {
            guard let intValue: Int = loadValue(forKey: key) else {
                return nil
            }
            return Int64(intValue)
        } else {
            return codableGet(forKey: key)
        }
    }

    func loadValue(forKey key: String) -> Double? {
        return contains(key: key) ? userDefaults.double(forKey: key) : nil
    }

    func loadValue(forKey key: String) -> Float? {
        return contains(key: key) ? userDefaults.float(forKey: key) : nil
    }

    func loadValue(forKey key: String) -> String? {
        return userDefaults.string(forKey: key)
    }

    func loadValue(forKey key: String) -> Data? {
        return userDefaults.data(forKey: key)
    }

    func loadValue(forKey key: String) -> Date? {
        return userDefaults.object(forKey: key) as? Date
    }

    func loadValue<T: NSCodingObject>(forKey key: String) -> T? {
        guard let any = userDefaults.object(forKey: key) else { return nil }
        if let ret = any as? T { return ret }
        guard useNSKeyedUnarchiver else { return nil }

        guard let data = any as? Data else { return nil }
        do {
            let unarchived = try NSKeyedUnarchiver.unarchiveObject(with: data) as? T
            return unarchived
        } catch {
            KVStores.assert(
                false,
                "unarchive failed",
                event: .loadValue,
                extra: [
                    "key": KVStoreLogProxy.encoded(for: key),
                    "suiteName": suiteName,
                    "type": String(describing: T.self)
                ]
            )
            return nil
        }
    }

    func saveValue(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func saveValue(_ value: Int, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    // 历史遗留，Int64 需要通过 codableSet 编码写入
    func saveValue(_ value: Int64, forKey key: String) {
        codableSet(value, forKey: key)
    }

    func saveValue(_ value: Double, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func saveValue(_ value: Float, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func saveValue(_ value: String, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func saveValue(_ value: Data, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func saveValue(_ value: Date, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func saveValue(_ value: NSCodingObject, forKey key: String) {
        let archiveAndSave = {
            do {
                try LarkStorageObjcExceptionHandler.catchException {
                    let archivered = NSKeyedArchiver.archivedData(withRootObject: value)
                    self.userDefaults.set(archivered, forKey: key)
                }
            } catch {
                let logKey = KVStoreLogProxy.encoded(for: key)
                KVStores.assert(
                    false,
                    "archive failed, key: \(logKey), suiteName: \(self.suiteName)",
                    event: .saveValue
                )
            }
        }
        guard useNSKeyedUnarchiver else {
            do {
                try LarkStorageObjcExceptionHandler.catchException {
                    self.userDefaults.set(value, forKey: key)
                }
            } catch {
                let logKey = KVStoreLogProxy.encoded(for: key)
                KVStores.logger.error("userDefaults.set failed. key: \(logKey), err: \(error)")
                archiveAndSave()
            }
            return
        }
        archiveAndSave()
    }

    private func keyFilter(_ key: String) -> Bool {
        return delegate?.judgeSatisfy(forKey: key) ?? true
    }

}
