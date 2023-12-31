//
//  DefaultImageDiskCache.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/31.
//

import Foundation

// lint:disable lark_storage_check - 不影响 Lark，无需检查

private let kDiskCacheQueueLabel = "com.bt.cache.disk"
private let kDiskCacheName = "com.bt.disk.cache.default"

/// 默认磁盘缓存
public final class DefaultImageDiskCache: ImageDiskCacheable {

    public var config: ImageDiskCacheConfig

    public var totalCount: UInt {
        var count: UInt = 0
        ioQueue.sync {
            let fileEnumerator = self.fileManager.enumerator(atPath: self.diskCachePath)
            count = UInt(fileEnumerator?.allObjects.count ?? 0)
        }
        return count
    }
    public var totalSize: UInt {
        var size: UInt = 0
        ioQueue.sync {
            let fileEnumerator = self.fileManager.enumerator(atPath: self.diskCachePath)
            while let fileName = fileEnumerator?.nextObject() as? String {
                let filePath = (self.diskCachePath as NSString).appendingPathComponent(fileName)
                let attrs = try? self.fileManager.attributesOfItem(atPath: filePath)
                size += (attrs?[FileAttributeKey.size] as? UInt ?? 0)
            }
        }
        return size
    }
    public var trimDiskInBackground: Bool {
        return self.config.clearCacheWhenEnterBackground
    }
    public var path: String {
        return self.diskCachePath
    }
    public var trimCallback: TrimDiskCallback?

    private let ioQueue = DispatchSafeQueue(label: kDiskCacheQueueLabel)
    private var diskCachePath: String
    private let fileManager = FileManager.default

    public init(with relativePath: String) {
        self.config = .default
        let absolutePath = (NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(relativePath) as NSString
        self.diskCachePath = absolutePath.appendingPathComponent(kDiskCacheName)
    }

    private func _contains(_ key: Key) -> Bool {
        let filePath = self.cachePath(for: key)
        var exists = self.fileManager.fileExists(atPath: filePath)
        if !exists {
            exists = self.fileManager.fileExists(atPath: (filePath as NSString).deletingPathExtension)
        }
        return exists
    }

    public func contains(_ key: Key) -> Bool {
        var exists = false
        ioQueue.sync {
            exists = self._contains(key)
        }
        return exists
    }

    public func contains(_ key: Key, with callback: @escaping (String, Bool) -> Void) {
        ioQueue.async {
            [weak self] in
            if let `self` = self {
                callback(key as String, self._contains(key))
            }
        }
    }

    private func _data(for key: Key) -> Data? {
        let filePath = self.cachePath(for: key)
        var data = try? Data(contentsOf: URL(fileURLWithPath: filePath))
        if data == nil {
            data = try? Data(contentsOf: URL(fileURLWithPath: (filePath as NSString).deletingPathExtension))
        }
        return data
    }

    public func data(for key: Key) -> Data? {
        var data: Data?
        ioQueue.sync {
            data = self._data(for: key)
        }
        return data
    }

    public func data(for key: Key, with callback: @escaping (String, Data?) -> Void) {
        ioQueue.async {
            [weak self] in
            if let `self` = self {
                let data = self._data(for: key)
                callback(key as String, data)
            }
        }
    }

    private func _set(_ data: Data?, for key: Key) {
        guard let data = data else {
            self.remove(for: key)
            return
        }
        if !self.fileManager.fileExists(atPath: self.diskCachePath) {
            try? self.fileManager.createDirectory(atPath: self.diskCachePath,
                                                  withIntermediateDirectories: true,
                                                  attributes: nil)
        }
        let cachePathForKey = self.cachePath(for: key)
        let fileURL = URL(fileURLWithPath: cachePathForKey)
        do {
            try data.write(to: fileURL, options: .atomic)
            try (fileURL as NSURL).setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
        } catch {

        }
    }

    public func set(_ data: Data?, for key: Key) {
        ioQueue.sync {
            self._set(data, for: key)
        }
    }

    public func set(_ data: Data?, for key: Key, with callback: @escaping () -> Void) {
        ioQueue.async {
            [weak self] in
            if let `self` = self {
                self._set(data, for: key)
                callback()
            }
        }
    }

    public func setExistFile(for key: Key, with path: String) {
        // fileExit 要去掉file://
        var newPath = path
        if newPath.hasPrefix("file://") {
            newPath = newPath.replacingOccurrences(of: "file://", with: "")
        }
        guard self.fileManager.fileExists(atPath: newPath) else { return }
        let destPath = self.cachePath(for: key)
        let destURL = URL(fileURLWithPath: destPath)
        let originURL = URL(fileURLWithPath: path)
        // fix移动数据后，发送富文本消息，Rust找不到数据，先保留双份
        try? self.fileManager.copyItem(at: originURL, to: destURL)
    }

    private func _remove(for key: Key) {
        let filePath = self.cachePath(for: key)
        try? self.fileManager.removeItem(atPath: filePath)
    }

    public func remove(for key: Key) {
        ioQueue.sync {
            self._remove(for: key)
        }
    }

    public func remove(for key: Key, with callback: @escaping () -> Void) {
        ioQueue.async {
            [weak self] in
            if let `self` = self {
                self._remove(for: key)
                callback()
            }
        }
    }

    private func _removeAll() {
        do {
            try self.fileManager.removeItem(atPath: self.diskCachePath)
            try self.fileManager.createDirectory(atPath: self.diskCachePath,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
        } catch {
        }
    }

    public func removeAll() {
        ioQueue.sync {
            self._removeAll()
        }
    }

    public func removeAll(with callback: @escaping () -> Void) {
        ioQueue.async {
            [weak self] in
            self?._removeAll()
            callback()
        }
    }

    public func removeExpiredData() {
        ioQueue.sync {
            let diskURL = URL(fileURLWithPath: self.diskCachePath, isDirectory: true)
            // Compute content date key to be used for tests
            let cacheContentDateKey = URLResourceKey.contentModificationDateKey
            let resourceKeys = [URLResourceKey.isDirectoryKey,
                                cacheContentDateKey,
                                URLResourceKey.totalFileAllocatedSizeKey]
            guard let fileEnumerator = self.fileManager.enumerator(at: diskURL,
                                                                   includingPropertiesForKeys: resourceKeys,
                                                                   options: .skipsHiddenFiles,
                                                                   errorHandler: nil) else { return }
            let diskAgeLimit = self.config.expireTime
            let expirationDate = (diskAgeLimit == 0) ? nil : Date(timeIntervalSinceNow: -TimeInterval(diskAgeLimit))
            var cacheFiles = [NSURL: [URLResourceKey: Any]]()
            var currentCacheSize: UInt = 0
            // Enumerate all of the files in the cache directory.  This loop has two purposes:
            //
            //  1. Removing files that are older than the expiration date.
            //  2. Storing file attributes for the size-based cleanup pass.
            var urlsToDelete = [NSURL]()
            while let fileURL = fileEnumerator.nextObject() as? NSURL {
                let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys)
                if let isDirectory = resourceValues?[.isDirectoryKey] as? Bool,
                   !isDirectory {
                    // Remove files that are older than the expiration date;
                    if let resourceValues = resourceValues,
                       let modifiedDate = resourceValues[cacheContentDateKey] as? NSDate,
                       let expirationDate = expirationDate,
                       modifiedDate.laterDate(expirationDate) == expirationDate {
                        urlsToDelete.append(fileURL)
                        continue
                    }
                } else {
                    continue
                }
                // Store a reference to this file and account for its total size.
                let totalAllocatedSize = (resourceValues?[.totalFileAllocatedSizeKey] as? UInt) ?? 0
                currentCacheSize += totalAllocatedSize
                cacheFiles[fileURL] = resourceValues
            }
            for fileURL in urlsToDelete {
                try? self.fileManager.removeItem(at: fileURL as URL)
                if let pathKey = fileURL.absoluteString?.last {
                    self.trimCallback?(String(pathKey))
                }
            }
            // If our remaining disk cache exceeds a configured maximum size, perform a second
            // size-based cleanup pass.  We delete the oldest files first.
            let maxDiskSize = self.config.maxSize
            if maxDiskSize > 0 && currentCacheSize > maxDiskSize {
                let desiredCacheSize = maxDiskSize / 2
                let sortedFiles = (cacheFiles as NSDictionary).keysSortedByValue(options: .concurrent) { (obj1, obj2) -> ComparisonResult in
                    guard let value1 = obj1 as? [URLResourceKey: Any],
                          let date1 = value1[cacheContentDateKey] as? Date,
                          let value2 = obj2 as? [URLResourceKey: Any],
                          let date2 = value2[cacheContentDateKey] as? Date
                    else { return .orderedAscending }
                    return date1.compare(date2)
                } as? [URL]
                // Delete files until we fall below our desired cache size.
                for fileURL in sortedFiles ?? [] {
                    do {
                        try self.fileManager.removeItem(at: fileURL)
                        if let pathKey = fileURL.absoluteString.last {
                            self.trimCallback?(String(pathKey))
                        }
                        let resourceValues = cacheFiles[fileURL as NSURL]
                        let totalAllocatedSize = resourceValues?[.totalFileAllocatedSizeKey] as? UInt ?? 0
                        currentCacheSize -= totalAllocatedSize
                        if currentCacheSize < desiredCacheSize {
                            break
                        }
                    } catch {

                    }
                }
            }

        }
    }

    public func cachePath(for key: Key) -> String {
        let fileName = key.bt.md5
        return (self.path as NSString).appendingPathComponent(fileName)
    }
}
