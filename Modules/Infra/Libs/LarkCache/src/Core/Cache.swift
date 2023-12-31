//
//  Cache.swift
//  LarkCache
//
//  Created by Supeng on 2020/8/11.
//

import Foundation
import YYCache
import LarkFileKit
import LarkStorage
import LKCommonsLogging

public typealias LfkPath = LarkFileKit.Path

extension LfkPath: LarkStorage.PathType {

    public var absoluteString: String { absolute.rawValue }

    public var deletingLastPathComponent: LfkPath {
        let string = (rawValue as NSString).deletingLastPathComponent
        return LfkPath(string)
    }

    public func appendingRelativePath(_ relativePath: String) -> LfkPath {
        return self + relativePath
    }

}

/// Cache模块，提供Data缓存，文件缓存功能
/// 对于文件缓存，内部使用数据库，记录文件的大小，最后访问日期。
public class Cache {
    struct Config {
        var rootPath: IsoPath
        var cleanIdentifier: String
    }

    enum InnerConfig {
        case old(CacheConfig)
        case new(Cache.Config)
    }

    let config: InnerConfig
    let yyCache: YYCache?

    public var memoryCache: YYMemoryCache? { yyCache?.memoryCache }
    public var diskCache: YYDiskCache? { yyCache?.diskCache }

    var cleanIdentifier: String {
        switch config {
        case .old(let wrapped): return wrapped.cleanIdentifier
        case .new(let wrapped): return wrapped.cleanIdentifier
        }
    }

    public var rootPath: String {
        switch config {
        case .old(let wrapped): return wrapped.cachePath
        case .new(let wrapped): return wrapped.rootPath.absoluteString
        }
    }

    static let logger = Logger.log(Cache.self, category: "LarkCache.Cache")

    /// YYCache缓存相关文件的文件夹名字
    private static let cacheFolder = "CacheDB"

    /// Convenience initializer based on `CacheConfig`
    convenience init(config: CacheConfig) {
        let path = LfkPath(config.cachePath) + "/" + Self.cacheFolder
        if !path.exists {
            try? path.createDirectory()
        }
        let yyCache = YYCache(path: config.cachePath + "/" + Self.cacheFolder, inlineThreshold: 0, needAutoTrim: false)
        let diskCache = yyCache?.diskCache
        diskCache?.customArchiveBlock = { ($0 as? Data) ?? NSKeyedArchiver.archivedData(withRootObject: $0) }
        diskCache?.customUnarchiveBlock = { NSKeyedUnarchiver.unarchiveObject(with: $0) ?? $0 }
        assert(yyCache != nil, "config: \(config)", event: .initYYCache)
        self.init(config: .old(config), yyCache: yyCache)
    }

    /// Convenience initializer based on `Cache.Config`
    convenience init(config: Config) {
        let yyRootPath = config.rootPath + Self.cacheFolder
        try? yyRootPath.createDirectoryIfNeeded()
        let yyCache = YYCache(path: yyRootPath.absoluteString, inlineThreshold: 0, needAutoTrim: false)
        let diskCache = yyCache?.diskCache
        diskCache?.customArchiveBlock = { ($0 as? Data) ?? NSKeyedArchiver.archivedData(withRootObject: $0) }
        diskCache?.customUnarchiveBlock = { NSKeyedUnarchiver.unarchiveObject(with: $0) ?? $0 }
        assert(yyCache != nil, "config: \(config)", event: .initYYCache)
        self.init(config: .new(config), yyCache: yyCache)
    }

    init(config: InnerConfig, yyCache: YYCache?) {
        self.config = config
        self.yyCache = yyCache
    }

    // MARK: Set/Get Object

    /// Sets the value of the specified key in the cache.
    /// This method may blocks the calling thread until file write finished.
    ///
    /// - Parameters:
    ///   - object: The object to be stored in the cache.
    ///   - key: The key with which to associate the value.
    ///   - extendedData: The extended data with which to associate the value.
    /// - Returns: cached path
    @discardableResult
    public func setObject(_ object: NSCoding, forKey key: String, extendedData: Data? = nil) -> String? {
        YYDiskCache.setExtendedData(extendedData, to: object)
        yyCache?.setObject(object, forKey: key)
        Self.logger.info("setObject, key: \(key)")
        return cachedFilePath(forKey: key)
    }

    /// Returns the value associated with a given key.
    /// This method may blocks the calling thread until file read finished.
    ///
    /// - Parameter key: A string identifying the value.
    /// - Returns: The value associated with key, or nil if no value is associated with key.
    public func object(forKey key: String) -> NSCoding? {
        return yyCache?.object(forKey: key)
    }

    /// 获取obj以及obj关联的extendedData
    ///
    /// - Parameter key: 存入obj时候设置的key
    /// - Returns: obj以及obj关联的extendedData
    public func objectAndEntendedData(forKey key: String) -> (NSCoding, Data?)? {
        if let obj = yyCache?.object(forKey: key) {
            return (obj, YYDiskCache.getExtendedData(from: obj))
        } else {
            return nil
        }
    }

    // MARK: Contains

    /// Returns a boolean value that indicates whether a given key is in cache.
    /// This method may blocks the calling thread until file read finished.
    ///
    /// - Parameter key: A string identifying the value.
    /// - Returns: Whether the key is in cache.
    public func containsObject(forKey key: String) -> Bool {
        return yyCache?.containsObject(forKey: key) ?? false
    }

    /// Returns a boolean value that indicates whether a given file is in cache.
    /// This method may blocks the calling thread until file read finished.

    /// - Parameter key: A string identifying the file name.
    /// - Returns: Whether the key is in cache.
    public func containsFile(forKey key: String) -> Bool {
        guard
            let item = yyCache?.diskCache.storageItem(key),
            let fileName = item.filename
        else {
            return false
        }

        let exists: Bool
        switch config {
        case .old(let wrapped):
            exists = LfkPath(wrapped.cachePath + "/" + fileName).exists
        case .new(let wrapped):
            exists = (wrapped.rootPath + fileName).exists
        }
        if !exists {
            removeFile(forKey: key)
        }
        return exists
    }

    // MARK: Remove

    /// Removes the value of the specified key in the cache.
    /// This method may blocks the calling thread until file delete finished.
    ///
    /// - Parameter key: The key identifying the value to be removed.
    public func removeObject(forKey key: String) {
        yyCache?.removeObject(forKey: key)
        Self.logger.info("removeObject, key: \(key)")
    }

    /// Empties the cache.
    /// This method may blocks the calling thread until file delete finished.
    public func removeAllObjects() {
        switch config {
        case .old(let wrapped):
            LfkPath(wrapped.cachePath).eachChildren { path in
                if !path.rawValue.hasSuffix(Cache.cacheFolder) {
                    try? path.deleteFile()
                }
            }
        case .new(let wrapped):
            wrapped.rootPath.eachChildren(recursive: false) { path in
                guard !path.absoluteString.hasSuffix(Cache.cacheFolder) else { return }
                try? path.removeItem()
            }
        }
        yyCache?.removeAllObjects()
        Self.logger.info("removeAllObjects")
    }

    /// 移除文件，同时移除本地文件和数据库中索引信息
    ///
    /// - Parameter fileKey: 文件key
    public func removeFile(forKey key: String) {
        yyCache?.diskCache.removeFile(key)
        Self.logger.info("removeFile, key: \(key)")
    }

    // MARK: Disk Size

    /// 磁盘缓存总大小 in bytes
    public var totalDiskSize: Int {
        Int(truncatingIfNeeded: yyCache?.diskCache.totalCost() ?? 0)
    }

    // MARK: File Path

    /// 返回被缓存的文件路径
    public func cachedFilePath(forKey key: String) -> String? {
        guard let item = yyCache?.diskCache.storageItem(key) else { return nil }
        return item.filePath
    }

    /// 根据文件名获取文件路径
    /// - Parameter fileKey: 文件名字
    /// - Returns: 文件路径，如果数据库中不存在该文件，则返回rootPath + "/" + fileKey
    /// - NOTE: 使用本方法读取文件，会更新数据库中文件最后访问时间，方便后续LRU策略清理缓存
    public func filePath(forKey fileKey: String) -> String {
        return cachedFilePath(forKey: fileKey) ?? (rootPath + "/" + fileKey)
    }

    /// 根据文件名获取文件路径
    /// - Parameter key: 文件名字
    /// - Returns: 文件路径，如果数据库中不存在该文件，则返回rootPath + "/" + fileName
    /// - NOTE: 使用本方法读取文件，会更新数据库中文件最后访问时间，方便后续LRU策略清理缓存
    public func filePathAndExtendedData(forKey key: String) -> (String, Data?)? {
        if let item = yyCache?.diskCache.storageItem(key) {
            return (rootPath + "/" + (item.filename ?? key), item.extendedData)
        }
        return nil
    }

    // MARK: Save File

    /// 将文件加入到Cache缓存管理，内部会将文件信息(文件名，创建时间)写入到DB。
    /// - Parameters:
    ///   - key: 文件key
    ///   - fileName: 文件名字
    ///   - size: 文件大小，如果不传，该方法会先计算文件大小，再存数据库
    ///   - extendedData: extended data，会存入数据库中，和fileName关联起来。
    /// - Returns: 保存成功后的Path，如果保存失败，返回nil
    /// - NOTE: 存文件的时候，需要保证fileName对应的文件已经在cache.cachePath下，否则存不成功
    @discardableResult
    public func saveFile(
        forKey key: String,
        fileName: String,
        size: Int? = nil,
        extendedData: Data? = nil
    ) -> String? {
        guard let yyCache = yyCache else { return nil }

        if let item = yyCache.diskCache.storageItem(key) {
            if let oldFileName = item.filename, oldFileName != fileName {
                removeFile(forKey: key)
            }
        }
        let filePath: String
        let actualSize: Int32
        switch config {
        case .old(let wrapped):
            filePath = wrapped.cachePath + "/" + fileName
            if let size = size {
                actualSize = Int32(truncatingIfNeeded: size)
            } else {
                actualSize = Int32(truncatingIfNeeded: LfkPath(filePath).recursizeFileSize)
            }
        case .new(let wrapped):
            let innerFilePath = wrapped.rootPath + fileName
            filePath = innerFilePath.absoluteString
            if let size = size {
                actualSize = Int32(truncatingIfNeeded: size)
            } else {
                actualSize = Int32(truncatingIfNeeded: innerFilePath.recursiveFileSize())
            }
        }
        let result = yyCache.diskCache.saveFile(
            with: key,
            fileName: fileName,
            size: actualSize,
            extend: extendedData
        )
        if result {
            Self.logger.info("cache succeed, fileName: \(fileName)")
            return filePath
        } else {
            assertionFailure("cache failed, fileName: \(fileName)", event: .saveFile)
            return nil
        }
    }

    // MARK: Clean

    /// 清理磁盘缓存
    /// - Parameter cleanConfig: 清理配置
    public func cleanDiskCache(cleanConfig: CleanConfig.CacheConfig) {
        if cleanConfig.timeLimit == 0 || cleanConfig.sizeLimit == 0 {
            removeAllObjects()
        } else {
            cleanDiskCache(toAge: TimeInterval(cleanConfig.timeLimit))
            cleanDiskCache(toCost: cleanConfig.sizeLimit)
            cleanEmptyDirectory()
        }
        Self.logger.info("cleanDiskCache")
    }

    private func cleanEmptyDirectory() {
        switch config {
        case .old(let wrapped):
            LfkPath(wrapped.cachePath).eachChildren() { path in
                if !path.rawValue.hasSuffix(Cache.cacheFolder) {
                    let subPath = LfkPath(rootPath) + "/" + path
                    if subPath.isDirectory, subPath.children(recursive: true).isEmpty {
                        try? subPath.deleteFile()
                    }
                }
            }
        case .new(let wrapped):
            wrapped.rootPath.eachChildren(recursive: false) { path in
                guard
                    path.absoluteString.hasSuffix(Cache.cacheFolder),
                    path.isDirectory
                else {
                    return
                }
                let hasNoChildren = (try? path.childrenOfDirectory(recursive: true))?.isEmpty ?? true
                guard hasNoChildren else {
                    return
                }
                try? path.removeItem()
            }
        }
        Self.logger.info("cleanEmptyDirectory")
    }

    /// 清理age时间内，没有使用过的缓存
    /// - Parameter age: age单位是s
    public func cleanDiskCache(toAge age: TimeInterval) {
        yyCache?.diskCache.trim(toAge: age)
        Self.logger.info("cleanDiskCache, age: \(age)")
    }

    /// 将缓存清理到cost bytes内
    /// - Parameter cost: cost单位是bytes
    public func cleanDiskCache(toCost cost: Int) {
        yyCache?.diskCache.trim(toCost: UInt(cost))
        Self.logger.info("cleanDiskCache, cost: \(cost)")
    }
}
