//
//  DiskStorage.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/10/15.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import LarkCache
import LarkFileKit

/// Represents a set of conception related to storage which stores a certain type of value in disk.
/// This is a namespace for the disk storage types. A `Backend` with a certain `Config` will be used to describe the
/// storage. See these composed types for more information.
public enum DiskStorage {

    /// Represents a storage back-end for the `DiskStorage`. The value is serialized to data
    /// and stored as file in the file system under a specified location.
    ///
    /// You can config a `DiskStorage.Backend` in its initializer by passing a `DiskStorage.Config` value.
    /// or modifying the `config` property after it being created. `DiskStorage` will use file's attributes to keep
    /// track of a file for its expiration or size limitation.
    public class Backend<T: DataTransformable> {
        public let cache: Cache

        /// The config used for this disk storage.
        public var config: Config

        /// Creates a disk storage with the given `DiskStorage.Config`.
        ///
        /// - Parameter config: The config used for this disk storage.
        /// - Throws: An error if the folder for storage cannot be got or created.
        public init(config: Config) throws {
            self.config = config
            switch config.useCrypto {
            case .notCrypto:
                self.cache = CacheManager
                    .shared
                    .cache(relativePath: "KingFisher" + "/" + config.name, directory: .cache)
            case .crypto(accountID: let accountID):
                let accountDir: String
                if let accountID = accountID {
                    accountDir = "/\(accountID)"
                } else {
                    accountDir = ""
                }
                self.cache = CacheManager
                    .shared
                    .cache(relativePath: "KingFisher" + accountDir + "/" + config.name,
                           directory: .cache,
                           cleanIdentifier: "library/Caches/KingFisher" + "/user_id" + "/" + config.name)
                    .asCryptoCache()
            }

        }

        public func store(
            value: T,
            forKey key: String,
            expiration: StorageExpiration? = nil) throws
        {
            let data: Data
            do {
                data = try value.toData()
            } catch {
                throw KingfisherError.cacheError(reason: .cannotConvertToData(object: value, error: error))
            }
            let fileName = cacheFileName(forKey: key)
            let path = Path(cache.rootPath) + fileName
            try path.write(data)
            cache.saveFileName(fileName)
        }

        public func value(forKey key: String) throws -> T? {
            let fileName = cacheFileName(forKey: key)
            if let value: Data = try? Path(cache.filePath(forKey: fileName)).read() {
                return try T.fromData(value)
            }
            return nil
        }

        public func isCached(forKey key: String) -> Bool {
            // 这里需要读db，判断文件是否完整写入，只通过文件是否存在并不能保证文件里的内容是完整写入了的。
            return (cache.cachedFilePath(forKey: cacheFileName(forKey: key)) != nil)
                && Path(cache.filePath(forKey: cacheFileName(forKey: key))).exists
        }

        public func remove(forKey key: String) throws {
            cache.removeObject(forKey: cacheFileName(forKey: key))
        }

        public func removeAll() throws {
            cache.removeAllObjects()
        }

        public func cacheFileName(forKey key: String) -> String {
            if let ext = config.pathExtension {
                return "\(key).\(ext)"
            }
            return key
        }
    }
}

extension DiskStorage {
    /// Represents the config used in a `DiskStorage`.
    public struct Config {

        /// The file size limit on disk of the storage in bytes. 0 means no limit.
        public var sizeLimit: UInt

        /// The `StorageExpiration` used in this disk storage. Default is `.days(7)`,
        /// means that the disk cache would expire in one week.
        public var expiration: StorageExpiration = .days(7)

        /// The preferred extension of cache item. It will be appended to the file name as its extension.
        /// Default is `nil`, means that the cache file does not contain a file extension.
        public var pathExtension: String? = nil

        /// Default is `true`, means that the cache file name will be hashed before storing.
        public var usesHashedFileName = true

        let name: String
        let fileManager: FileManager
        let directory: URL?

        public enum CryptoConfig {
            case notCrypto
            case crypto(accountID: String?)
        }
        let useCrypto: CryptoConfig


        var cachePathBlock: ((_ directory: URL, _ cacheName: String) -> URL)! = {
            (directory, cacheName) in
            return directory.appendingPathComponent(cacheName, isDirectory: true)
        }

        /// Creates a config value based on given parameters.
        ///
        /// - Parameters:
        ///   - name: The name of cache. It is used as a part of storage folder. It is used to identify the disk
        ///           storage. Two storages with the same `name` would share the same folder in disk, and it should
        ///           be prevented.
        ///   - sizeLimit: The size limit in bytes for all existing files in the disk storage.
        ///   - fileManager: The `FileManager` used to manipulate files on disk. Default is `FileManager.default`.
        ///   - directory: The URL where the disk storage should live. The storage will use this as the root folder,
        ///                and append a path which is constructed by input `name`. Default is `nil`, indicates that
        ///                the cache directory under user domain mask will be used.
        public init(
            name: String,
            sizeLimit: UInt,
            fileManager: FileManager = .default,
            directory: URL? = nil,
            useCrypto: CryptoConfig)
        {
            self.name = name
            self.fileManager = fileManager
            self.directory = directory
            self.sizeLimit = sizeLimit
            self.useCrypto = useCrypto
        }
    }
}

extension DiskStorage {
    struct FileMeta {
    
        let url: URL
        
        let lastAccessDate: Date?
        let estimatedExpirationDate: Date?
        let isDirectory: Bool
        let fileSize: Int
        
        static func lastAccessDate(lhs: FileMeta, rhs: FileMeta) -> Bool {
            return lhs.lastAccessDate ?? .distantPast > rhs.lastAccessDate ?? .distantPast
        }
        
        init(fileURL: URL, resourceKeys: Set<URLResourceKey>) throws {
            let meta = try fileURL.resourceValues(forKeys: resourceKeys)
            self.init(
                fileURL: fileURL,
                lastAccessDate: meta.creationDate,
                estimatedExpirationDate: meta.contentModificationDate,
                isDirectory: meta.isDirectory ?? false,
                fileSize: meta.fileSize ?? 0)
        }
        
        init(
            fileURL: URL,
            lastAccessDate: Date?,
            estimatedExpirationDate: Date?,
            isDirectory: Bool,
            fileSize: Int)
        {
            self.url = fileURL
            self.lastAccessDate = lastAccessDate
            self.estimatedExpirationDate = estimatedExpirationDate
            self.isDirectory = isDirectory
            self.fileSize = fileSize
        }

        func expired(referenceDate: Date) -> Bool {
            return estimatedExpirationDate?.isPast(referenceDate: referenceDate) ?? true
        }
        
        func extendExpiration(with fileManager: FileManager) {
            guard let lastAccessDate = lastAccessDate,
                  let lastEstimatedExpiration = estimatedExpirationDate else
            {
                return
            }
            
            let originalExpiration: StorageExpiration =
                .seconds(lastEstimatedExpiration.timeIntervalSince(lastAccessDate))
            let attributes: [FileAttributeKey : Any] = [
                .creationDate: Date().fileAttributeDate,
                .modificationDate: originalExpiration.estimatedExpirationSinceNow.fileAttributeDate
            ]

            try? fileManager.setAttributes(attributes, ofItemAtPath: url.path)
        }
    }
}

