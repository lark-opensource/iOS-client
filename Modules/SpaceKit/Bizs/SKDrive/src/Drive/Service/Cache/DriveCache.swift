//
//  DriveCache.swift
//  SKECM
//
//  Created by Weston Wu on 2020/8/27.
//

import Foundation
import LarkCache
import SKFoundation
import LarkStorage
import SKCommon

extension CCM {
    enum Drive: Biz {
        static let parent: Biz.Type? = CCM.self
        static var path: String = "drive"
    }
}

extension CCM.Drive {
    // 永久缓存
    enum PersistentCache: Biz {
        static let parent: Biz.Type? = CCM.Drive.self
        static var path: String = "persistent_cache"
    }

    // 临时缓存
    enum TransientCache: Biz {
        static let parent: Biz.Type? = CCM.Drive.self
        static var path: String = "transient_cache"
    }
}

extension DriveCache {

    struct Record: Codable, Hashable, CustomStringConvertible {

        typealias RecordType = DriveCacheType

        let token: String
        let version: String
        let recordType: RecordType

        let originName: String
        let originFileSize: UInt64?
        let fileType: String?

        var originFileExtension: String? {
            SKFilePath.getFileExtension(from: originName)
        }
        
        var cacheType: DriveCacheService.CacheType

        private enum CodingKeys: String, CodingKey {
            case token
            case version
            case recordType
            case originName
            case originFileSize
            case fileType
        }
        
        var fileID: String {
            if version == nil {
                return "\(recordType.identifier)_\(token)"
            } else {
                return "\(recordType.identifier)_\(token)_\(version)"
            }
            
        }
        
        init(token: String,
             version: String,
             recordType: RecordType,
             originName: String,
             originFileSize: UInt64?,
             fileType: String?,
             cacheType: DriveCacheService.CacheType) {
            self.token = token
            self.version = version
            self.recordType = recordType
            self.originName = originName
            self.originFileSize = originFileSize
            self.fileType = fileType
            self.cacheType = cacheType
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            token = try container.decode(String.self, forKey: .token)
            version = try container.decode(String.self, forKey: .version)
            recordType = try container.decode(RecordType.self, forKey: .recordType)
            originName = try container.decode(String.self, forKey: .originName)
            originFileSize = try? container.decodeIfPresent(UInt64.self, forKey: .originFileSize)
            fileType = try? container.decodeIfPresent(String.self, forKey: .fileType)
            cacheType = .transient // 兼容旧版本数据迁移，旧版本没有这个字段
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(token)
            hasher.combine(version)
            hasher.combine(recordType.identifier)
        }
        
        var description: String { return "token: \(token.encryptToken), version: \(version), originFileSize: \(originFileSize), fileType: \(fileType)" }
    }

    struct Node: Codable {
        let record: Record
        let fileName: String
        let fileSize: UInt64
        // 受沙盒路径的影响，每次读取时需要更新一下 fileURL
        fileprivate(set) var fileURL: SKFilePath?

        var fileExtension: String? {
            SKFilePath.getFileExtension(from: fileName)
        }

        var filePath: String {
            guard let path = fileURL?.pathString else {
                spaceAssertionFailure("filePath Not setted")
                return ""
            }
            return path
        }
        enum CodingKeys: String, CodingKey {
            case record
            case fileName
            case fileSize
        }
    }

    enum CacheError: Error {
        case fileNotFound
        case extendedDataNotFound
        case parseExtendedDataFailed(parseError: Error)
        case getFileSizeFailed
        case getFileNameFailed
        case moveFileFailed
        case copyFileFailed
        case saveInLarkCacheFailed
    }
}

class DriveCache {
    // 永久缓存
    static func createPersistentCache() -> DriveCache {
        let space: Space = .global
        let domain = Domain.biz.ccm.child("drive").child("persistent_cache")
        let cachePath: IsoPath = .in(space: space, domain: domain).build(.library)
        let cache: CryptoCache = CacheManager.shared.cache(
            rootPath: cachePath,
            cleanIdentifier: "library/Caches/DocsSDK/drive/persistent_cache"
        ).asCryptoCache()
        return DriveCache(name: "persistent", cache: cache)
    }

    // 临时缓存
    static func createTransientCache() -> DriveCache {
        let space: Space = .global
        let domain = Domain.biz.ccm.child("drive").child("transient_cache")
        let cachePath: IsoPath = .in(space: space, domain: domain).build(.cache)
        let cache: CryptoCache = CacheManager.shared.cache(
            rootPath: cachePath,
            cleanIdentifier: "caches/Caches/DocsSDK/drive/transient_cache"
        ).asCryptoCache()
        return DriveCache(name: "transient", cache: cache)
    }
    let name: String
    private let cache: CryptoCache //加密Cache
    var dirPath: String {
        return cache.rootPath
    }

    init(name: String, cache: CryptoCache) {
        self.name = name
        self.cache = cache
    }

    func isFileExist(record: Record) -> Bool {
        cache.containsFile(forKey: record.fileID)
    }

    func getFile(record: Record) -> Result<Node, CacheError> {
        guard let (filePath, extendedData) = cache.getFilePathAndExtendedData(forKey: record.fileID) else { return .failure(.fileNotFound) }
        guard let nodeData = extendedData else {
            DocsLogger.error("drive.cache.wrapper --- failed to get drive cache file, extendedData not found", extraInfo: ["cache-name": name])
            deleteFile(record: record)
            return .failure(.extendedDataNotFound)
        }
        do {
            var node = try JSONDecoder().decode(Node.self, from: nodeData)
            node.fileURL = filePath
            return .success(node)
        } catch {
            DocsLogger.error("drive.cache.wrapper --- failed to get drive cache file, parse extendedData failed", extraInfo: ["cache-name": name], error: error)
            deleteFile(record: record)
            return .failure(.parseExtendedDataFailed(parseError: error))
        }
    }

    // 引入落盘加密后，save 完成不再返回 node，避免返回了未解密的文件导致无法预览
    func saveFile(fileURL: SKFilePath, record: Record, moveInsteadOfCopy: Bool = true, rewriteFileName: Bool) -> Result<SKFilePath, CacheError> {
        guard let fileSize = fileURL.fileSize else {
            DocsLogger.error("drive.cache.wrapper --- failed to save drive cache file, unable to retrive file size", extraInfo: ["cache-name": name])
            return .failure(.getFileSizeFailed)
        }
        var fileName = fileURL.pathURL.lastPathComponent.trimmingCharacters(in: .whitespaces)
        if rewriteFileName {
            fileName = record.fileID + "_" + fileName
        }
    
        guard !fileName.isEmpty else {
            DocsLogger.error("drive.cache.wrapper --- failed to save drive cache file, unable to retrive file name", extraInfo: ["cache-name": name])
            return .failure(.getFileNameFailed)
        }
        let cacheURL = cache.getOriginFilePath(forKey: fileName)
        if moveInsteadOfCopy {
            guard fileURL.copyItem(to: cacheURL) else {
                DocsLogger.error("drive.cache.wrapper --- failed to copy drive cache file", extraInfo: ["cache-name": name])
                return .failure(.copyFileFailed)
            }
            do {
                try fileURL.removeItem()
            } catch {
                DocsLogger.error("drive.cache.wrapper --- failed to move drive cache file", extraInfo: ["cache-name": name], error: error)
            }
        } else {
            guard fileURL.copyItem(to: cacheURL) else {
                DocsLogger.error("drive.cache.wrapper --- failed to copy drive cache file", extraInfo: ["cache-name": name])
                return .failure(.copyFileFailed)
            }
        }
        let fileNode = Node(record: record, fileName: fileName, fileSize: fileSize, fileURL: cacheURL)
        do {
            let extendedData = try JSONEncoder().encode(fileNode)
            guard cache.saveFile(key: record.fileID, fileName: fileName, size: Int(fileSize), extendedData: extendedData) != nil else {
                DocsLogger.error("drive.cache.wrapper --- save file in larkCache failed", extraInfo: ["cache-name": name])
                return .failure(.saveInLarkCacheFailed)
            }
            return .success(cacheURL)
        } catch {
            DocsLogger.error("drive.cache.wrapper --- failed to encode extendedData", extraInfo: ["cache-name": name], error: error)
            return .failure(.parseExtendedDataFailed(parseError: error))
        }
    }

    func deleteFile(record: Record) {
        cache.removeFile(forKey: record.fileID)
    }

    func deleteAll() {
        cache.removeAllObjects()
    }
}
