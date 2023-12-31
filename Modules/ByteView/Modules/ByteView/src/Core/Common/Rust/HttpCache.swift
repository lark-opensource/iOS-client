//
//  HttpCache.swift
//  ByteView
//
//  Created by kiri on 2021/5/26.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

final class HttpCache {
    static let shared = HttpCache()
    private let logger = Logger.network
    private let lock = NSLock()
    @RwAtomic
    private var cache = [String: Any]()

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeAccount),
                                               name: VCNotification.didChangeAccountNotification, object: nil)
    }

    @objc private func didChangeAccount() {
        clear()
    }

    func contains(key: String) -> Bool {
        cache[key] != nil
    }

    func write(key: String, value: Any) {
        logger.debug("writeToCache: key = \(key)")
        cache[key] = value
    }

    func read<T>(key: String, type: T.Type) -> T? {
        let value = cache[key] as? T
        logger.debug("readFromCache: key = \(key), is nil = \(value == nil)")
        return value
    }

    func clear() {
        logger.debug("resetAllCache")
        cache.removeAll()
    }
}

extension HttpCache {
    enum CacheKey: String {
        case rtcDns
        case rtcFeatureGating
        case appConfig
        case pullVideoChatConfig
        case adminMediaServerSettings
    }

    func contains(key: CacheKey) -> Bool {
        contains(key: key.rawValue)
    }

    func write(key: CacheKey, value: Any) {
        write(key: key.rawValue, value: value)
    }

    func read<T>(key: CacheKey, type: T.Type) -> T? {
        read(key: key.rawValue, type: type)
    }
}
