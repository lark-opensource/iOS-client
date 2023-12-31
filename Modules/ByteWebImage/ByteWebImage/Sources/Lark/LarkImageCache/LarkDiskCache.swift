//
//  LarkDiskCache.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/4/11.
//

import EEAtomic
import Foundation
import LarkCache
import LKCommonsLogging

private let kDiskCacheName = "com.bt.disk.cache.lark"

public final class LarkDiskCache: ImageDiskCacheable {

    public var totalCount: UInt { 0 }
    public var totalSize: UInt {
        UInt(self.cache.totalDiskSize)
    }

    public var trimDiskInBackground: Bool {
        return self.config.clearCacheWhenEnterBackground
    }

    public var path: String {
        // 拼接 path 而不是从 self.cache 取 path 的原因是：
        // 启动时需要取 avatarPath，但如果初始化 LarkCache 的成本比较大，并且有卡死问题
        CacheConfig(relativePath: Self.path(for: relativePath, accountID: accountID),
                    cacheDirectory: .cache, cleanIdentifier: "").cachePath
    }
    public var trimCallback: TrimDiskCallback?
    public var config: ImageDiskCacheConfig {
        didSet {
            guard isCacheInitialized else { return }
            self.cache.diskCache?.costLimit = config.maxSize
            self.cache.diskCache?.countLimit = config.maxCount
        }
    }

    @SafeLazy
    private var cache: LarkCache.Cache
    /// Swift String和OC不同，非线程安全，挺恶心的
    private var stringSemahore = DispatchSemaphore(value: 1)

    private var relativePath: String
    private var crypto: Bool
    private var accountID: String?
    private var isCacheInitialized = false

    public init(with relativePath: String, crypto: Bool = false, accountID: String? = nil) {
        self.config = .default
        self.relativePath = relativePath
        self.crypto = crypto
        self.accountID = accountID
        // 因为 SafeLazy 不能捕获 self，在这里手动捕获下
        weak var weakSelf: LarkDiskCache?
        self._cache = SafeLazy { // Cache 初始化成本比较高且易卡死，这里使用懒加载
            guard let self = weakSelf else {
                assertionFailure("不应该取不到 self")
                return CacheManager.shared.cache(relativePath: "", directory: .cache, cleanIdentifier: "")
            }
            Self.logger.info("LarkDiskCache cache init with relativePath: \(self.relativePath)")
            return self.initCache()
        }
        weakSelf = self
        Self.logger.info("LarkDiskCache self init with relativePath: \(self.relativePath)")
    }

    private func initCache() -> LarkCache.Cache {
        let cache: LarkCache.Cache
        if crypto {
            cache = CacheManager.shared.cache(relativePath: Self.path(for: relativePath, accountID: accountID),
                                                   directory: .cache).asCryptoCache()
        } else {
            cache = CacheManager.shared.cache(relativePath: Self.path(for: relativePath, accountID: accountID),
                                                   directory: .cache)
        }
        self.isCacheInitialized = true
        cache.diskCache?.costLimit = config.maxSize
        cache.diskCache?.countLimit = config.maxCount
        return cache
    }

    deinit {
        stringSemahore.signal()
    }

    private static let logger = Logger.log(LarkDiskCache.self, category: "LarkDiskCache")

    private static let stringSemaphore = DispatchSemaphore(value: 1)

    static func path(for relativePath: String, accountID: String? = nil) -> String {
        stringSemaphore.wait()
        defer { stringSemaphore.signal() }
        let accountDir: String
        if let accountID = accountID {
            accountDir = "/\(accountID)"
        } else {
            accountDir = ""
        }
        return (relativePath as NSString).appendingPathComponent(kDiskCacheName + accountDir)
    }

}

extension LarkDiskCache {

    public func contains(_ key: Key) -> Bool {
        return self.cache.containsObject(forKey: key)
    }

    public func contains(_ key: Key, with callback: @escaping (String, Bool) -> Void) {
        DispatchImageQueue.async {
            let hasCache = self.cache.containsObject(forKey: key)
            callback(key, hasCache)
        }
    }

    public func data(for key: Key) -> Data? {
        let filePath = self.cache.filePath(forKey: key)
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
              !data.isEmpty else {
            return self.cache.diskCache?.object(forKey: key) as? Data
        }
        return data
    }

    public func data(for key: Key, with callback: @escaping (String, Data?) -> Void) {
        DispatchImageQueue.async {
            let data = self.data(for: key)
            callback(key, data)
        }
    }

    public func set(_ data: Data?, for key: Key) {
        self.cache.diskCache?.setObject(data as NSCoding?, forKey: key)
    }

    public func set(_ data: Data?, for key: Key, with callback: @escaping () -> Void) {
        DispatchImageQueue.async {
            self.set(data, for: key)
            callback()
        }
    }

    public func setExistFile(for key: Key, with path: String) {
        let fileManager = FileManager.default
        // fileExit 要去掉file://
        var newPath = path
        if newPath.hasPrefix("file://") {
            newPath = newPath.replacingOccurrences(of: "file://", with: "")
        }
        guard fileManager.fileExists(atPath: newPath) else { return }
        let destPath = self.cachePath(for: key)
        let destURL = URL(fileURLWithPath: destPath)
        let originURL = URL(fileURLWithPath: newPath)
        // fix移动数据后，发送富文本消息，Rust找不到数据，先保留双份
        try? fileManager.copyItem(at: originURL, to: destURL)
        self.cache.saveFile(key: key, fileName: key)
    }

    public func remove(for key: Key) {
        self.cache.diskCache?.removeObject(forKey: key)
    }

    public func remove(for key: Key, with callback: @escaping () -> Void) {
        DispatchImageQueue.async {
            self.remove(for: key)
            callback()
        }
    }

    public func removeAll() {
        self.cache.removeAllObjects()
    }

    public func removeAll(with callback: @escaping () -> Void) {
        DispatchImageQueue.async {
            self.cache.removeAllObjects()
            callback()
        }
    }

    public func removeExpiredData() {
//        self.cache.diskCache?.trim(toCost: self.config?.diskSizeLimit ?? (256 * 1024 * 1024))
//        self.cache.diskCache?.trim(toAge: TimeInterval(self.config?.diskAgeLimit ?? (7 * 24 * 60 * 60)))
        // 按照整体的清理策略来，不自定义了
    }

    public func cachePath(for key: Key) -> String {
        stringSemahore.wait()
        defer {
            stringSemahore.signal()
        }
        return self.cache.filePath(forKey: key)
    }

}
