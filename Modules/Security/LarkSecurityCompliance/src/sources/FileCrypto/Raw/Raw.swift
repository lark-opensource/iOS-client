//
//  Raw.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/11/28.
//

import Foundation
import LarkSecurityComplianceInfra
import LarkContainer
import LarkStorage

struct Raw {
    static func sandboxInputStream(userResolver: UserResolver, info: AESMetaInfo, enablePool: Bool) -> SBCipherInputStream {
        if enablePool {
            logger.info("create migration pool input stream")
            return SandboxInputStreamMigrationPool(userResolver: userResolver, metaInfo: info)
        } else {
            logger.info("create raw input stream")
            return SandboxInputStream(userResolver: userResolver, metaInfo: info)
        }
    }
    
    static func fileHandle(userResolver: UserResolver, info: AESMetaInfo, usage: FileHandleUsage, enablePool: Bool) throws -> Raw.FileHandle {
        if enablePool {
            logger.info("create migration pool file handle")
            return try Raw.FileHandleMigrationPool(userResolver: userResolver, info: info, usage: usage)
        } else {
            logger.info("create raw file handle")
            return try Raw.FileHandle(userResolver: userResolver, info: info, usage: usage)
        }
    }
    
    static func systemInputStream(userResolver: UserResolver, info: AESMetaInfo, enablePool: Bool) throws -> Raw.InputStream {
        if enablePool {
            logger.info("create migration pool system input stream")
            return try Raw.InputStreamMigrationPool(userResolver: userResolver, info: info)
        } else {
            logger.info("create raw system input stream")
            return try Raw.InputStream(userResolver: userResolver, info: info)
        }
    }
    
    static let logger = Logger(tag: "[file_crypto][file_raw]")
}
