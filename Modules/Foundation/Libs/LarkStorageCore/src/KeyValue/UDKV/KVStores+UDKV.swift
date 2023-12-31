//
//  KVStores+UDKV.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

public typealias UDKVStoreMode = KVStoreMode

extension KVStores {

    static func udSuiteName(for space: Space, mode: UDKVStoreMode) -> String {
        switch mode {
        case .normal:
            return "lark_storage." + space.isolationId
        case .shared:
            return Dependencies.appGroupId
        }
    }

    static func udSuiteName(forConfig config: KVStoreConfig, cipherSuite: KVCipherSuite? = nil) -> String {
        switch config.mode {
        case .normal:
            var suiteName = "lark_storage." + config.space.isolationId
            if let cipherName = cipherSuite?.name {
                let domainPart = config.domain.isolationChain(with: "_")
                suiteName += ".Domain_\(domainPart)"
                suiteName += ".Cipher_\(cipherName)"
            }
            return suiteName
        case .shared:
            assert(cipherSuite == nil, event: .unavailable)
            return Dependencies.appGroupId
        }
    }

    /// 构建基于 UserDefaults 的 KVStore 实例
    /// - Parameter space: 指定用户|全局
    /// - Parameter type: 如果为空，则清除所有 KV 数据，否则只清楚指定 type 的数据
    /// - Parameter mode: `.normal`为普通KV，`.shared`为进程共享KV
    public static func udkv(space: Space, domain: DomainType, mode: UDKVStoreMode = .normal) -> KVStore {
        var proxies = KVStoreProxySet.commons
        // check space
        if case .user(let id) = space, id.isEmpty {
            KVStores.assert(
                false,
                "userId should not be empty. domain: \(domain.description)",
                event: .wrongSpace
            )
            proxies.insert(.fail)
        }

        // check domain
        domain.assertInvalid()
        let config = KVStoreConfig(space: space, domain: domain, mode: mode, type: .udkv)
        return udkv(config: config, proxies: proxies)
    }

    static func udkv(config: KVStoreConfig, proxies: KVStoreProxySet) -> KVStore {
        let suiteName = udSuiteName(forConfig: config)
        let base = UDKVStore(suiteName: suiteName) ?? .init()
        return attachingProxies(proxies, config: config, to: base)
    }

}

extension TypedIsolatable where T == KVStores {

    /// 构建 udkv
    public func udkv(mode: UDKVStoreMode = .normal) -> KVStore {
        return KVStores.udkv(space: space.value, domain: domain, mode: mode)
    }

}
