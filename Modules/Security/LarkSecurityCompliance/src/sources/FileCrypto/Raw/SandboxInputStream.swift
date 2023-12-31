//
//  SandboxInputStream.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/7/5.
//

import UIKit
import LarkStorage
import LarkContainer

// ignoring lark storage check for SBCipher implementation
// lint:disable lark_storage_check
extension Raw {
    // MARK: - SandboxInputStream
    /// 明文读取数据
    class SandboxInputStream: SBCipherInputStream, FileRecordHandle {
        let filePath: String
        let metaInfo: AESMetaInfo
        var fileHandle: SCFileHandle?
        let userResolver: UserResolver
        
        let migartionPool: FileMigrationPool?
        
        init(userResolver: UserResolver, metaInfo: AESMetaInfo) {
            self.userResolver = userResolver
            self.metaInfo = metaInfo
            self.filePath = metaInfo.filePath
            migartionPool = try? userResolver.resolve(type: FileMigrationPool.self)
        }
        
        func open(shouldAppend append: Bool) throws {
            fileHandle = try SCFileHandle(path: filePath, option: .read)
            migartionPool?.startReadFile(withHandle: self)
        }
        
        func read(maxLength len: UInt32) throws -> Data {
            guard let fileHandle else { throw CryptoFileError.customError("file stream unavable") }
            guard let data = try fileHandle.read(upToCount: Int(len)) else {
                throw CryptoFileError.customError("read data is nil")
            }
            return data
        }
        
        func readAll() throws -> Data {
            guard let fileHandle else { throw CryptoFileError.customError("file stream unavable") }
            guard let data = try fileHandle.readToEnd() else {
                throw CryptoFileError.customError("read data is nil")
            }
            return data
        }
        
        func close() throws {
            guard let fileHandle else { throw CryptoFileError.customError("file stream unavable") }
            try fileHandle.close()
            migartionPool?.stopReadFile(withHandle: self)
        }
        
        func seek(from where: SBSeekWhere, offset: UInt64) throws -> UInt64 {
            guard let fileHandle else { throw CryptoFileError.customError("file stream unavable") }
            switch `where` {
            case .current:
                let currentOffset = try fileHandle.offset()
                try fileHandle.seek(toOffset: currentOffset)
            case .start:
                try fileHandle.seek(toOffset: offset)
            case .end:
                try fileHandle.seekToEnd()
            }
            return try fileHandle.offset()
        }
    }
    
    // MARK: - SandboxInputStreamMigration
    /// 老的数据迁移（明文-密文）方式，
    /// 即：数据读取前，先进行数据迁移
    final class SandboxInputStreamMigration: SandboxInputStream {
        override func open(shouldAppend append: Bool) throws {
            let migrateFile = MigrateFileRaw(userResolver: userResolver, info: metaInfo)
            try migrateFile.doProcess()
            try super.open(shouldAppend: append)
        }
    }
    
    // MARK: - SandboxInputStreamMigrationPool
    /// 新的数据迁移（明文-密文）方式，
    /// 即：数据读取过程中，进行数据迁移，等本地数据读取完成，再进行迁移并覆盖明文
    final class SandboxInputStreamMigrationPool: SandboxInputStream, FileMigrationHandle {
        
        let migrationID: String
        
        override init(userResolver: UserResolver, metaInfo: AESMetaInfo) {
            migrationID = UUID().uuidString
            super.init(userResolver: userResolver, metaInfo: metaInfo)
        }
        
        override func open(shouldAppend append: Bool) throws {
            migartionPool?.enter(handle: self)
            try super.open(shouldAppend: append)
        }
        
        override func read(maxLength len: UInt32) throws -> Data {
            let data = try super.read(maxLength: len)
            migartionPool?.migrateData(data, forHandle: self)
            return data
        }
        
        override func readAll() throws -> Data {
            let data = try super.readAll()
            migartionPool?.migrateData(data, forHandle: self)
            return data
        }
        
        override func close() throws {
            migartionPool?.leave(handle: self)
            try super.close()
        }
    }
   
}
