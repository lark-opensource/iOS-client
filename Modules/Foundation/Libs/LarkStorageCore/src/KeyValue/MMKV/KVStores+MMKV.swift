//
//  KVStores+MMKV.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

public typealias MMKVStoreMode = KVStoreMode

extension KVStores {

    /// 判断是否是跨进程共享路径
    public static func isMultiProcessPath(_ path: String) -> Bool {
        let appGroupId = Dependencies.appGroupId
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return false
        }
        return path.lowercased().starts(with: url.path.lowercased())
    }

    static func mmkvRootPath(with mode: MMKVStoreMode) -> String? {
        switch mode {
        case .normal:
            let rootPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
            return (rootPath as NSString).appendingPathComponent("MMKV")
        case .shared:
            let appGroupId = Dependencies.appGroupId
            guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
                return nil
            }
            let rootPath = url.path
            // 和 MMKVCore 内部保持一致，使用 `mmkv` 作为子目录
            return (rootPath as NSString).appendingPathComponent("mmkv")
        }
    }

    static func mmkvId(with space: Space) -> String {
        return "lark_storage." + space.isolationId
    }

    static func mmkvId(forConfig config: KVStoreConfig, cipherSuite: KVCipherSuite? = nil) -> String {
        var ret = "lark_storage." + config.space.isolationId
        if let cipherName = cipherSuite?.name {
            let domainPart = config.domain.isolationChain(with: "_")
            ret += ".Domain_\(domainPart)"
            ret += ".Cipher_\(cipherName)"
        }
        return ret
    }

    /// 构建基于 MMKV 的 KVStore
    public static func mmkv(space: Space, domain: DomainType, mode: MMKVStoreMode = .normal) -> KVStore {
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

        let config = KVStoreConfig(space: space, domain: domain, mode: mode, type: .mmkv)
        return mmkv(config: config, proxies: proxies)
    }

    static func mmkv(config: KVStoreConfig, proxies: KVStoreProxySet) -> KVStore {
        guard
            let rootPath = mmkvRootPath(with: config.mode)
        else {
            return KVStoreFailProxy(wrapped: UDKVStore(), config: config)
        }
        let base = MMKVStore(mmapId: mmkvId(with: config.space), rootPath: rootPath)
        return attachingProxies(proxies, config: config, to: base)
    }

}

extension TypedIsolatable where T == KVStores {

    public func mmkv(mode: MMKVStoreMode = .normal) -> KVStore {
        return KVStores.mmkv(space: space.value, domain: domain, mode: mode)
    }

}

extension KVStores {
    public static func mmkv(mmapID: String, rootPath: String, space: Space, domain: DomainType) -> KVStore {
        return MMKVStore(mmapId: mmapID, rootPath: rootPath)
    }
}
