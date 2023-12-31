//
//  KVStoreCryptoProxy.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import CommonCrypto

/// Crypto Proxy
final class KVStoreCryptoProxy: KVStoreProxy {
    static var type: KVStoreProxyType { .crypto }
    var wrapped: KVStore
    let cipher: KVCipher

    init(wrapped: KVStore, cipher: KVCipher) {
        self.wrapped = wrapped
        self.cipher = cipher
    }

    func value<T: Codable>(forKey key: String) -> T? {
        let hashedKey = cipher.hashed(forKey: key)
        guard let data: Data = wrapped.value(forKey: hashedKey) else {
            return nil
        }
        return decryptValue(from: data)
    }

    func set<T: Codable>(_ value: T, forKey key: String) {
        if let data = encryptValue(value) {
            let hashedKey = cipher.hashed(forKey: key)
            wrapped.set(data, forKey: hashedKey)
        }
    }

    func object<O: NSCodingObject>(forKey key: String) -> O? {
        let hashedKey = cipher.hashed(forKey: key)
        guard let data: Data = wrapped.value(forKey: hashedKey) else {
            return nil
        }
        return decryptObject(from: data)
    }

    func setObject<O: NSCodingObject>(_ obj: O, forKey key: String) {
        if let data = encryptObject(obj) {
            let hashedKey = cipher.hashed(forKey: key)
            wrapped.set(data, forKey: hashedKey)
        }
    }

    func register(defaults: [String: Any]) {
        wrapped.register(defaults: encryptValues(defaults))
    }

    func migrate(values: [String : Any]) {
        wrapped.migrate(values: encryptValues(values))
    }

    func contains(key: String) -> Bool {
        let hashedKey = cipher.hashed(forKey: key)
        return wrapped.contains(key: hashedKey)
    }

    func removeValue(forKey key: String) {
        let hashedKey = cipher.hashed(forKey: key)
        wrapped.removeValue(forKey: hashedKey)
    }

    func clearAll() {
        wrapped.clearAll()
    }

    func allKeys() -> [String] {
        KVStores.assert(false, event: .unavailable)
        return []
    }

    func allValues() -> [String: Any] {
        KVStores.assert(false, event: .unavailable)
        return [:]
    }
}

extension KVStoreCryptoProxy {

    // iOS 12 无法 encode 基本类型
    // https://bugs.swift.org/browse/SR-6163
    struct JsonWrapper<T: Codable>: Codable {
        let value: T
    }

    private func decryptValue<T: Codable>(from data: Data) -> T? {
        do {
            let data = try cipher.decrypt(data)
            return try cipher.decode(from: data)
        } catch {
            KVStores.assert(
                false,
                "decrypt failed. T: \(String(describing: T.self)), err: \(error)",
                event: .decrypt
            )
            return nil
        }
    }

    private func decryptObject<O: NSCodingObject>(from data: Data) -> O? {
        do {
            let data = try cipher.decrypt(data)
            let unarchived = try NSKeyedUnarchiver.unarchiveObject(with: data) as? O
            return unarchived
        } catch {
            KVStores.assert(
                false,
                "decrypt failed. T: \(String(describing: O.self)), err: \(error)",
                event: .decrypt
            )
            return nil
        }
    }

    private func encryptValue<T: Codable>(_ value: T) -> Data? {
        do {
            let data = try cipher.encode(value: value)
            return try cipher.encrypt(data)
        } catch {
            KVStores.assert(
                false,
                "encrypt failed. T: \(String(describing: T.self)), err: \(error)",
                event: .encrypt
            )
            return nil
        }
    }

    private func encryptObject<O: NSCodingObject>(_ obj: O) -> Data? {
        do {
            let data = NSKeyedArchiver.archivedData(withRootObject: obj)
            return try cipher.encrypt(data)
        } catch {
            KVStores.assert(
                false,
                "encrypt failed. T: \(String(describing: O.self)), err: \(error)",
                event: .encrypt
            )
            return nil
        }
    }

    private func encryptValues(_ values: [String: Any]) -> [String: Any] {
        var ret = [String: Any]()
        var failedKeys = [String]()
        for (key, value) in values {
            if let v = value as? Codable, let data = encryptValue(v) {
                let hashedKey = cipher.hashed(forKey: key)
                ret[hashedKey] = data
            } else if let o = value as? NSCodingObject, let data = encryptObject(o) {
                let hashedKey = cipher.hashed(forKey: key)
                ret[hashedKey] = data
            } else {
                failedKeys.append(key)
            }
        }
        KVStores.assert(failedKeys.isEmpty, "encrypt failed. keys: \(failedKeys)", event: .encrypt)
        return ret
    }

    fileprivate static func udSuiteName(
        space: Space,
        domain: DomainType,
        mode: UDKVStoreMode
    ) -> String {
        switch mode {
        case .normal:
            return "lark_storage." + space.isolationId
        case .shared:
            return Dependencies.appGroupId
        }
    }

}

public extension KVStore {

    /// 为 KVStore 提供加密算法
    /// - Parameters:
    ///  - suite: 加解密算法套件，默认为 aes
    /// - Returns: KVStore
    func usingCipher(suite: KVCipherSuite) -> KVStore {
        guard let cipher = KVCipherManager.shared.cipher(forSuite: suite) else {
            KVStores.assertionFailure("missing cipher. suite: \(suite)")
            return self
        }
        guard let logProxy: KVStoreLogProxy = findProxy() else {
            KVStores.assertionFailure()
            return self
        }
        let config = logProxy.config
        var (oldBase, proxies) = allComponents()

        // make a new base
        var newBase: KVStoreBase?
        if let oldBase {
            switch type(of: oldBase).type {
            case .udkv:
                let newSuiteName = KVStores.udSuiteName(forConfig: config, cipherSuite: suite)
                newBase = UDKVStore(suiteName: newSuiteName)
            case .mmkv:
                let newMmapId = KVStores.mmkvId(forConfig: config, cipherSuite: suite)
                guard let rootPath = KVStores.mmkvRootPath(with: config.mode) else {
                    KVStores.assertionFailure()
                    return self
                }
                newBase = MMKVStore(mmapId: newMmapId, rootPath: rootPath)
            }
        } else {
            KVStores.assertionFailure()
        }
        // remove old crypto proxy if needed
        proxies.removeAll(where: { $0 is KVStoreCryptoProxy })
        guard let base = newBase else {
            KVStores.assertionFailure()
            return self
        }

        // rebuild proxy chains. note: crypto proxy at the bottom
        var ret: KVStoreProxy = KVStoreCryptoProxy(wrapped: base, cipher: cipher)
        for proxy in proxies {
            proxy.wrapped = ret
            ret = proxy
        }
        return ret
    }

}
