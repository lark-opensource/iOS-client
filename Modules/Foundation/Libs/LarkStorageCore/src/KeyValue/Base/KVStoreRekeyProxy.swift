//
//  KVStoreRekeyProxy.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

private let globalKeyPrefix = "lskv" // abbreviation of 'LarkStorage KV'

/// 对 key 基于 space + domain 进行映射处理
final class KVStoreRekeyProxy: KVStoreProxy, KVStoreBaseDelegate {
    static var type: KVStoreProxyType { .rekey }
    var wrapped: KVStore

    private let keyPrefix: String

    init(wrapped: KVStore, config: KVStoreConfig) {
        self.wrapped = wrapped

        let spacePart = "space_" + config.space.isolationId
        let domainPart = "domain_" + config.domain.isolationChain(with: "_")
        self.keyPrefix = "\(globalKeyPrefix).\(spacePart).\(domainPart)."

        self.findBase()?.delegate = self
    }

    // MARK: KVStore

    func value<T: Codable>(forKey key: String) -> T? {
        return wrapped.value(forKey: encodedKey(from: key))
    }

    func set<T: Codable>(_ value: T, forKey key: String) {
        wrapped.set(value, forKey: encodedKey(from: key))
    }

    func object<O: NSCodingObject>(forKey key: String) -> O? {
        return _forward_get_object(to: wrapped, forKey: encodedKey(from: key))
    }

    func setObject<O: NSCodingObject>(_ obj: O, forKey key: String) {
        _forward_set_object(to: wrapped, forKey: encodedKey(from: key), object: obj)
    }

    func register(defaults: [String: Any]) {
        var mapped = [String: Any]()
        for (key, value) in defaults {
            mapped[encodedKey(from: key)] = value
        }
        wrapped.register(defaults: mapped)
    }

    func migrate(values: [String : Any]) {
        var mapped = [String: Any]()
        for (key, value) in values {
            mapped[encodedKey(from: key)] = value
        }
        wrapped.migrate(values: mapped)
    }

    func contains(key: String) -> Bool {
        wrapped.contains(key: encodedKey(from: key))
    }

    func removeValue(forKey key: String) {
        log.info("remove value for key:\(key)")
        wrapped.removeValue(forKey: encodedKey(from: key))
    }

    func allKeys() -> [String] {
        return wrapped.allKeys().map(decodedKey(from:))
    }

    func allValues() -> [String: Any] {
        var ret = [String: Any]()
        for (key, value) in wrapped.allValues() {
            ret[decodedKey(from: key)] = value
        }
        return ret
    }

    // MARK: KVStoreBaseDelegate

    func judgeSatisfy(forKey key: String) -> Bool {
        return key.hasPrefix(keyPrefix)
    }

    // MARK: Encode/Decode Key

    func encodedKey(from key: String) -> String {
        KVStores.assert(!key.hasPrefix(keyPrefix), "key: \(key), prefix: \(keyPrefix)", event: .rekey)
        return "\(keyPrefix)\(key)"
    }

    func decodedKey(from key: String) -> String {
        if key.hasPrefix(keyPrefix) {
            let prefixIndex = key.index(key.startIndex, offsetBy: keyPrefix.count)
            return String(key.substring(from: prefixIndex))
        } else {
            return key
        }
    }

}
