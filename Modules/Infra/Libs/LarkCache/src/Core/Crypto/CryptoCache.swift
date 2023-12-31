//
//  CryptoCache.swift
//  LarkCache
//
//  Created by Supeng on 2020/12/23.
//

import Foundation
import YYCache

/// 默认加解密的Cache
/// set相关接口需要传入未加密的data和file
/// get相关接口返回解密后的data和file
public final class CryptoCache: Cache {
    public convenience init(cache: Cache) {
        self.init(config: cache.config, yyCache: cache.yyCache)
    }

    // MARK: Set/Get Object

    public override func setObject(
        _ object: NSCoding,
        forKey key: String,
        extendedData: Data? = nil
    ) -> String? {
        guard let str = super.setObject(object, forKey: key, extendedData: extendedData) else {
            return nil
        }
        return try? str.encrypt().rawValue
    }

    public override func object(forKey key: String) -> NSCoding? {
        objectAndEntendedData(forKey: key)?.0
    }

    public override func objectAndEntendedData(forKey key: String) -> (NSCoding, Data?)? {
        let result = yyCache?.memoryCache.object(forKey: key) as? NSCoding
        if let result = result {
            //如果内存缓存命中了，直接返回内存缓存中的数据（信任内存缓存中数据都是未加密数据）
            return (result, YYDiskCache.getExtendedData(from: result))
        } else {
            if let item = yyCache?.diskCache.storageItem(key),
               let path = item.filePath,
               let decryptedData: Data = try? path.decrypt().read() {
                let nscodingData = decryptedData as NSCoding
                //设置extendedData
                YYDiskCache.setExtendedData(item.extendedData, to: nscodingData)
                //设置memoryCache
                yyCache?.memoryCache.setObject(nscodingData, forKey: key)
                return (nscodingData, item.extendedData)
            }
        }
        return nil
    }

    // MARK: Save File

    @discardableResult
    public override func saveFile(
        forKey key: String,
        fileName: String,
        size: Int? = nil,
        extendedData: Data? = nil
    ) -> String? {
        guard let pathStr = super.saveFile(forKey: key, fileName: fileName, size: size, extendedData: extendedData) else {
            return nil
        }
        return try? pathStr.encrypt().rawValue
    }

    // MARK: File Path

    public override func filePath(forKey fileKey: String) -> String {
        (try? super.filePath(forKey: fileKey).decrypt().rawValue) ?? super.filePath(forKey: fileKey)
    }

    public override func filePathAndExtendedData(forKey key: String) -> (String, Data?)? {
        let result = super.filePathAndExtendedData(forKey: key)
        if let decryptPath = try? result?.0.decrypt().rawValue {
            return (decryptPath, result?.1)
        }
        return nil
    }

    public func originFilePath(forKey fileKey: String) -> String {
        super.filePath(forKey: fileKey)
    }
}

public extension Cache {
    func asCryptoCache() -> CryptoCache {
        (self as? CryptoCache) ?? CryptoCache(cache: self)
    }
}
