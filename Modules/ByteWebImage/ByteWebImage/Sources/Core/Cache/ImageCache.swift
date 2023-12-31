//
//  ImageCache.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/31.
//

import Foundation
import EEAtomic

/// 图片缓存
public final class ImageCache {

    public typealias Priority = Float

    public typealias Key = String

    /// 默认实例
    public static let `default` = ImageCache()

    /// 标识符
    public let identifier: String
    /// 缓存名称
    public var name: String { identifier }

    /// 优先级
    public var priority: Priority = 1.0

    /// 缓存配置
    public var config: ImageCacheConfig {
        get {
            ImageCacheConfig(memory: memoryCache.config, disk: diskCache.config)
        }
        set {
            memoryCache.config = newValue.memory
            diskCache.config = newValue.disk
        }
    }

    /// 内存缓存
    public private(set) var memoryCache: any ImageMemoryCacheable
    /// 磁盘缓存
    @AtomicObject
    public private(set) var diskCache: any ImageDiskCacheable

    /// 内存键缓存
    internal var memoryKey = MemoryKey()

    /// 后台任务
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    private convenience init() {
        self.init("com.bt.image.cache")
    }

    public convenience init(_ identifier: String) {
        let memoryCache = DefaultImageMemoryCache()
        let diskCache = DefaultImageDiskCache(with: identifier)

        self.init(identifier, memoryCache: memoryCache, diskCache: diskCache)
    }

    /// 初始化
    /// - Parameters:
    ///   - identifier: 标识符(缓存名称)
    ///   - memoryCache: 内存缓存实例
    ///   - diskCache: 磁盘缓存实例
    public init(_ identifier: String, memoryCache: some ImageMemoryCacheable, diskCache: some ImageDiskCacheable) {
        self.identifier = identifier
        self.memoryCache = memoryCache
        self.diskCache = diskCache

        self.memoryCache.removeObjectHandler = { [weak self] key in
            guard let self else { return }
            if let key {
                self.memoryKey.removeObject(forKey: self.processKey(key), fuzzy: false)
            } else {
                self.memoryKey.removeAllObjects()
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// 重置磁盘缓存
    public func resetDiskCache(_ diskCache: some ImageDiskCacheable) {
        diskCache.config = self.diskCache.config
        self.diskCache = diskCache
    }

    @objc func applicationDidEnterBackground(_ notification: Notification) {
        guard diskCache.config.clearCacheWhenEnterBackground else { return }

        let endBackgroundTask = { [weak self] in
            guard let task = self?.backgroundTask else { return }
            UIApplication.shared.endBackgroundTask(task)
            self?.backgroundTask = .invalid
        }

        let taskName = identifier + ".backgroundTask"
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: taskName, expirationHandler: endBackgroundTask)

        DispatchImageQueue.async { [weak self] in
            self?.removeExpiredObjectsInDisk()
            DispatchQueue.main.async(execute: endBackgroundTask)
        }
    }
}

extension ImageCache: Hashable {

    public static func == (lhs: ImageCache, rhs: ImageCache) -> Bool {
        lhs.identifier == rhs.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
