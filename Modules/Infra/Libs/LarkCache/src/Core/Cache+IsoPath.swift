//
//  Cache+IsoPath.swift
//  LarkCache
//
//  Created by zhangwei on 2022/11/24.
//

import Foundation
import LarkStorage
import LKCommonsTracker

public final class IsoExtension<BaseType> {
    public var base: BaseType
    public init(_ base: BaseType) {
        self.base = base
    }
}

public protocol IsoExtensionCompatible {
    associatedtype IsoCompatibleType
    var iso: IsoCompatibleType { get }
}

public extension IsoExtensionCompatible {
    var iso: IsoExtension<Self> {
        return IsoExtension(self)
    }
}

extension Cache: IsoExtensionCompatible {}

extension Cache {
    func isoPath(
        fromRawPath rawPath: String,
        file: String = #fileID,
        line: Int = #line
    ) -> IsoPath? {
        guard case .new(let conf) = config else {
            #if DEBUG || ALPHA
            fatalError("unexpected invoke")
            #else
            let event = SlardarEvent(
                name: "lark_storage_assert",
                metric: [:],
                category: [
                    "scene": "lark_cache",
                    "event": "isoPath"
                ],
                extra: [:]
            )
            Cache.logger.error("unexpected invoke. path: \(rawPath), file: \(file), line: \(line)")
            DispatchQueue.global(qos: .utility).async {
                Tracker.post(event)
            }
            return nil
            #endif
        }
        if let relativePath = AbsPath(rawPath).relativePath(to: conf.rootPath) {
            return conf.rootPath + relativePath
        } else if let sdkPath = try? IsoPath.parse(fromRust: rawPath) {
            return sdkPath
        } else {
            return nil
        }
    }
}

extension IsoExtension where BaseType: Cache {

    /// 描述是否允许 .iso 接口，如果 Cache 基于 IsoPath 初始化，返回 true，表示可用 iso 接口
    public var isEnabled: Bool {
        if case .new = base.config {
            return true
        } else {
            return false
        }
    }

    public var rootPath: IsoPath {
        guard case .new(let conf) = base.config else {
#if DEBUG || ALPHA
        fatalError("unexpected invoke")
#else
        return IsoPath.global
            .in(domain: Domain.biz.core.child("LarkCache"))
            .build(.cache)
#endif
        }
        return conf.rootPath
    }

    /// Sets the value of the specified key in the cache.
    /// This method may blocks the calling thread until file write finished.
    ///
    /// - Parameters:
    ///   - object: The object to be stored in the cache.
    ///   - key: The key with which to associate the value.
    ///   - extendedData: The extended data with which to associate the value.
    /// - Returns: cached path
    @discardableResult
    public func setObject(_ object: NSCoding, forKey key: String, extendedData: Data? = nil) -> IsoPath? {
        guard let rawPath = base.setObject(object, forKey: key, extendedData: extendedData) else {
            return nil
        }
        return base.isoPath(fromRawPath: rawPath)
    }

    /// 返回被缓存的文件路径
    public func cachedFilePath(forKey key: String) -> IsoPath? {
        guard let rawPath = base.cachedFilePath(forKey: key) else { return nil }
        return base.isoPath(fromRawPath: rawPath)
    }

    internal func internalFilePath(forKey fileKey: String) -> IsoPath {
        if let cachedPath = cachedFilePath(forKey: fileKey) {
            return cachedPath
        }
        if case .new(let conf) = base.config {
            return conf.rootPath + fileKey
        }
        #if DEBUG || ALPHA
        fatalError("unexpected invoke")
        #else
        return IsoPath.global
            .in(domain: Domain.biz.core.child("LarkCache"))
            .build(forType: .cache, relativePart: fileKey)
        #endif
    }

    /// 根据文件名获取文件路径
    /// - Parameter fileKey: 文件名字
    /// - Returns: 文件路径，如果数据库中不存在该文件，则返回rootPath + "/" + fileKey
    /// - NOTE: 使用本方法读取文件，会更新数据库中文件最后访问时间，方便后续LRU策略清理缓存
    public func filePath(forKey fileKey: String) -> IsoPath {
        return internalFilePath(forKey: fileKey)
    }

    /// 根据文件名获取文件路径
    /// - Parameter key: 文件名字
    /// - Returns: 文件路径，如果数据库中不存在该文件，则返回rootPath + "/" + fileName
    /// - NOTE: 使用本方法读取文件，会更新数据库中文件最后访问时间，方便后续LRU策略清理缓存
    public func filePathAndExtendedData(forKey key: String) -> (IsoPath, Data?)? {
        guard let (rawPath, data) = base.filePathAndExtendedData(forKey: key) else { return nil }
        guard let isoPath = base.isoPath(fromRawPath: rawPath) else { return nil }
        return (isoPath, data)
    }

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
    ) -> IsoPath? {
        guard let rawPath = base.saveFile(
            forKey: key,
            fileName: fileName,
            size: size,
            extendedData: extendedData
        ) else {
            return nil
        }
        return base.isoPath(fromRawPath: rawPath)
    }
}

extension IsoExtension where BaseType == CryptoCache {
    public func originFilePath(forKey fileKey: String) -> IsoPath {
        return internalFilePath(forKey: fileKey)
    }
}
