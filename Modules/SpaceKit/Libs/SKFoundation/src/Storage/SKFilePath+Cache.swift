//
//  SKFilePath+Cache.swift
//  SKFoundation
//
//  Created by ByteDance on 2022/12/17.
//

import Foundation
import LarkCache
import LarkStorage

extension LarkCache.Cache {
    public func getFilePathAndExtendedData(forKey key: String) -> (SKFilePath, Data?)? {
        if let (isoPath, data) = self.iso.filePathAndExtendedData(forKey: key) {
            return (SKFilePath.isoPath(isoPath), data)
        } else {
            DocsLogger.info("LarkCache: filePathAndExtendedData failed")
            return nil
        }
    }
}

extension LarkCache.CryptoCache {
    public func getOriginFilePath(forKey: String) -> SKFilePath {
        let path = self.iso.originFilePath(forKey: forKey)
        return SKFilePath.isoPath(path)
    }
}

