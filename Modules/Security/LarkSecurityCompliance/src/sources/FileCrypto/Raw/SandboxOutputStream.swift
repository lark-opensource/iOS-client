//
//  SandboxOutputStream.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/11/28.
//

import Foundation
import LarkContainer

extension Raw {
    // MAKR: - CipherOutputStream
    
    /// 明文写数据
    class SandboxOutputStream: SBCipherOutputStream, FileRecordHandle {
        let info: AESMetaInfo
        let userResolver: UserResolver
        var filePath: String { info.filePath }
        
        private var fileHandle: SCFileHandle?
        private let fileRecord: FileMigrationRecord?
        
        init(userResolver: UserResolver, info: AESMetaInfo) {
            self.info = info
            self.userResolver = userResolver
            fileRecord = try? userResolver.resolve(type: FileMigrationRecord.self)
        }
        
        func open(shouldAppend append: Bool) throws {
            if append {
                if !FileManager.default.fileExists(atPath: filePath) {
                    FileManager.default.createFile(atPath: filePath, contents: Data())
                }
                fileHandle = try SCFileHandle(path: filePath, option: .append)
                try fileHandle?.seekToEnd()
            } else {
                if FileManager.default.fileExists(atPath: filePath) {
                    try FileManager.default.removeItem(atPath: filePath)
                }
                FileManager.default.createFile(atPath: filePath, contents: Data())
                fileHandle = try SCFileHandle(path: filePath, option: .write)
            }
            fileRecord?.startWriteFile(withHandle: self)
        }
        
        func write(data: Data) throws {
            guard let fileHandle else { throw CryptoFileError.customError("file stream unavable") }
            do {
                try fileHandle.write(contentsOf: data)
            } catch {
                throw CryptoFileError.fileStreamError(error)
            }
        }
        
        func close() throws {
            guard let fileHandle else { throw CryptoFileError.customError("file stream unavable") }
            do {
                try fileHandle.close()
            } catch {
                throw CryptoFileError.fileStreamError(error)
            }
            fileRecord?.stopWriteFile(withHandle: self)
        }
    }
    
    /// 写数据前完成数据迁移，然后再进行数据迁移
    final class SandboxOutputStreamMigration: SandboxOutputStream {
        override func open(shouldAppend append: Bool) throws {
            if append, FileManager.default.fileExists(atPath: filePath) {
                let migrateFile = MigrateFileRaw(userResolver: userResolver, info: info)
                try migrateFile.doProcess()
            }
            try super.open(shouldAppend: append)
        }
    }
}
