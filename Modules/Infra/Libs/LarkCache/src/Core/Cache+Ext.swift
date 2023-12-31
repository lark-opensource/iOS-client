//
//  Cache+Ext.swift
//  LarkCache
//
//  Created by zhangwei on 2022/8/2.
//

import Foundation
import LarkStorage

/// Convenience Api
public extension Cache {
    func object(forKey key: String) -> Data? {
        guard let nscoding: NSCoding = object(forKey: key) else {
            return nil
        }
        return nscoding as? Data
    }

    @discardableResult
    func saveFile(named fileName: String, size: Int? = nil) -> String? {
        return saveFile(forKey: fileName, fileName: fileName, size: size, extendedData: nil)
    }
}

/// Public Api based on LfkPath
public extension Cache {
    @discardableResult
    func set(object: NSCoding, forKey key: String, extendedData: Data? = nil) -> LfkPath? {
        return setObject(object, forKey: key, extendedData: extendedData).map(LfkPath.init(_:))
    }

    @discardableResult
    func set(object: Data, forKey key: String, extendedData: Data? = nil) -> LfkPath? {
        let nsdata = object as NSData
        return setObject(nsdata, forKey: key, extendedData: extendedData).map(LfkPath.init(_:))
    }

    @discardableResult
    func saveFile(
        key: String,
        fileName: String,
        size: Int? = nil,
        extendedData: Data? = nil
    ) -> LfkPath? {
        return saveFile(forKey: key, fileName: fileName, size: size, extendedData: extendedData)
            .map(LfkPath.init(_:))
    }

    @discardableResult
    func saveFileName(_ fileName: String, size: Int? = nil) -> LfkPath? {
        return saveFile(named: fileName, size: size).flatMap(LfkPath.init(_:))
    }
}


/// Will be deprecated
public extension Cache {
    @available(*, deprecated, renamed: "filePath(forKey:)", message: "Please use filePath(forKey:)")
    func filePath(_ fileKey: String) -> String {
        return filePath(forKey: fileKey)
    }

    @available(*, deprecated, renamed: "filePathAndExtendedData(forKey:)", message: "Please use filePathAndExtendedData(forKey:)")
    func filePathAndExtendData(_ fileKey: String) -> (String, Data?)? {
        return filePathAndExtendedData(forKey: fileKey)
    }

    @available(*, deprecated, renamed: "removeFile(forKey:)", message: "Please use removeFile(forKey:)")
    func removeFile(_ fileKey: String) {
        removeFile(forKey: fileKey)
    }

    @available(*, deprecated, renamed: "containsFile(forKey:)", message: "Please use containsFile(forKey:)")
    func containsFile(_ fileKey: String) -> Bool {
        return containsFile(forKey: fileKey)
    }
}

/// Will be deprecated
public extension CryptoCache {
    @available(*, deprecated, renamed: "originFilePath(forKey:)", message: "Please use originFilePath(forKey:)")
    func originFilePath(fileKey: String) -> String {
        return originFilePath(forKey: fileKey)
    }
}
