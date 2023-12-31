//
//  DefaultImageMemoryCache.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/4/1.
//

import Foundation
import YYCache

/// 默认内存缓存
public final class DefaultImageMemoryCache {

    public var config: ImageMemoryCacheConfig {
        didSet {
            cache.costLimit = config.maxSize
            cache.countLimit = config.maxCount
            cache.shouldRemoveAllObjectsWhenEnteringBackground = config.clearCacheWhenEnterBackground

            Log.trace("Set memory cache config \(config)")
        }
    }

    private let cache: YYMemoryCache

    private let semaphore = DispatchSemaphore(value: 1)

    public var removeObjectHandler: ((Key?) -> Void)?

    public init(_ config: ImageMemoryCacheConfig = .default) {
        self.config = config

        let cache = YYMemoryCache()
        cache.costLimit = config.maxSize
        cache.countLimit = config.maxCount
        cache.shouldRemoveAllObjectsWhenEnteringBackground = config.clearCacheWhenEnterBackground
        self.cache = cache

        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarning(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarning(_:)), name: NSNotification.Name.willReceiveMemoryIssue, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)

        Log.trace("Create a default memory cache")
    }

    deinit {
        semaphore.signal()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Notification
    @objc
    func didReceiveMemoryWarning(_ notification: Notification) {
        if config.clearCacheWhenReceiveMemoryWarning {
            removeAllObjects()
            removeObjectHandler?(nil)
        }
    }

    @objc
    func didEnterBackground(_ notification: Notification) {
        if config.clearCacheWhenEnterBackground {
            removeAllObjects()
            removeObjectHandler?(nil)
        }
    }
}

extension DefaultImageMemoryCache: ImageMemoryCacheable {

    public func object(forKey key: Key) -> Object? {
        cache.object(forKey: key) as? Object
    }

    public func setObject(_ obj: Object, forKey key: Key) {
        cache.setObject(obj, forKey: key)

        Log.trace("Set memory cache for \(key), size: \(obj.size)")
    }

    public func setObject(_ obj: Object, forKey key: Key, cost: UInt) {
        cache.setObject(obj, forKey: key, withCost: cost)

        Log.trace("Set memory cache for \(key), size: \(obj.size), cost: \(cost)")
    }

    public func removeObject(forKey key: Key) {
        cache.removeObject(forKey: key)

        Log.trace("Remove memory cache for \(key)")
    }

    public func removeAllObjects() {
        cache.removeAllObjects()

        Log.info("Remove all memory cache")
    }

    public func contains(_ key: Key) -> Bool {
        semaphore.wait()
        defer { semaphore.signal() }

        let contains = (object(forKey: key) != nil)
        return contains
    }

    public var totalCost: UInt {
        cache.totalCost
    }

    public var totalCount: UInt {
        cache.totalCount
    }
}
