//
//  CryptoFileSize.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/9/22.
//

import Foundation
import LarkContainer

// ignoring lark storage check for file crypto beforehand
// lint:disable lark_storage_check
struct CryptoFileSize {
    
    static func size(userResolver: UserResolver, _ filePath: String) throws -> Int {
        let version = try AESHeader(filePath: filePath).encryptVersion()
        switch version {
        case .v1:
            let path = CryptoPath(userResolver: userResolver)
            let newPath = try path.decrypt(filePath)
            return try Self.calculateSize(path: newPath, subSize: 0)
        case .v2, .regular:
            return try Self.calculateSize(path: filePath, subSize: version == .v2 ? 96 : 0)
        }
    }
    
    private static func calculateSize(path: String, subSize: Int) throws -> Int {
        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        let sizeNum = attrs[.size] as? NSNumber
        let size = sizeNum?.intValue ?? 0
        return size - subSize
    }
}
