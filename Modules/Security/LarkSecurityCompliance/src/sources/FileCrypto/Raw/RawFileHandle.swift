//
//  RawFileHandle.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/8/1.
//

import Foundation
import LarkContainer
import LarkStorage

extension Raw {
    class FileHandle: SBFileHandle, FileRecordHandle {
        var filePath: String { info.filePath }
        
        private let fileHandle: SCFileHandle
        let userResolver: UserResolver
        let info: AESMetaInfo
        let usage: FileHandleUsage
        
        let fileRecord: FileMigrationRecord?
        
        deinit {
            switch usage {
            case .reading:
                fileRecord?.stopReadFile(withHandle: self)
            case .writing, .updating:
                fileRecord?.stopWriteFile(withHandle: self)
            @unknown default:
                break
            }
        }
        
        init(userResolver: UserResolver, info: AESMetaInfo, usage: FileHandleUsage) throws {
            self.info = info
            let filePath = info.filePath
            self.usage = usage
            self.userResolver = userResolver
            fileRecord = try? userResolver.resolve(type: FileMigrationRecord.self)
            switch usage {
            case .reading:
                fileHandle = try SCFileHandle(path: filePath, option: .read)
                fileRecord?.startReadFile(withHandle: self)
                
            case .writing(let append):
                if !append {
                    if FileManager.default.fileExists(atPath: filePath) {
                        try? FileManager.default.removeItem(atPath: filePath)
                    }
                    FileManager.default.createFile(atPath: filePath, contents: nil)
                }
                fileHandle = try SCFileHandle(path: filePath, option: append ? .append : .write)
                fileRecord?.startWriteFile(withHandle: self)
                
            case .updating:
                fileHandle = try SCFileHandle(path: filePath, option: .append)
                fileRecord?.startWriteFile(withHandle: self)
                
            @unknown default:
                throw CryptoFileError.customError("file handle usage not supported")
            }
        }
        
        func seek(toOffset offset: UInt64) throws {
            try fileHandle.seek(toOffset: offset)
        }
        
        func synchronize() throws {
            try fileHandle.synchronize()
        }
        
        func close() throws {
            try fileHandle.close()
            
        }
        
        func readToEnd() throws -> Data? {
            try fileHandle.readToEnd()
        }
        
        func read(upToCount count: Int) throws -> Data? {
            try fileHandle.read(upToCount: count)
        }
        
        func offset() throws -> UInt64 {
            try fileHandle.offset()
        }
        
        func seekToEnd() throws -> UInt64 {
            try fileHandle.seekToEnd()
        }
        
        func write(contentsOf data: Data) throws {
            try fileHandle.write(contentsOf: data)
        }
    }
    
    final class FileHandleMigration: FileHandle {
        override init(userResolver: UserResolver, info: AESMetaInfo, usage: FileHandleUsage) throws {
            switch usage {
            case .reading:
                let migrateFile = MigrateFileRaw(userResolver: userResolver, info: info)
                try migrateFile.doProcess()
            case .writing(let append):
                if append, FileManager.default.fileExists(atPath: info.filePath) {
                    let migrateFile = MigrateFileRaw(userResolver: userResolver, info: info)
                    try migrateFile.doProcess()
                }
            case .updating:
                let migrateFile = MigrateFileRaw(userResolver: userResolver, info: info)
                try migrateFile.doProcess()
            @unknown default:
                throw CryptoFileError.customError("file handle usage not supported")
            }
            try super.init(userResolver: userResolver, info: info, usage: usage)
        }
    }
    
    final class FileHandleMigrationPool: FileHandle {
        
        // swiftlint:disable:next nesting
        private struct InternalHandle: FileMigrationHandle {
            let migrationID: String
            let filePath: String
        }
        
        private let migrationHandle: InternalHandle
        let migrationPool: FileMigrationPool?
        
        override init(userResolver: UserResolver, info: AESMetaInfo, usage: FileHandleUsage) throws {
            migrationHandle = InternalHandle(migrationID: UUID().uuidString, filePath: info.filePath)
            if case .reading = usage {
                migrationPool = try? userResolver.resolve(type: FileMigrationPool.self)
                migrationPool?.enter(handle: migrationHandle)
            } else {
                migrationPool = nil
            }
            try super.init(userResolver: userResolver, info: info, usage: usage)
        }
        
        override func close() throws {
            try super.close()
            migrationPool?.leave(handle: migrationHandle)
        }
        
        override func readToEnd() throws -> Data? {
            guard let data = try super.readToEnd() else {
                return nil
            }
            migrationPool?.migrateData(data, forHandle: migrationHandle)
            return data
        }
        
        override func read(upToCount count: Int) throws -> Data? {
            guard let data = try super.read(upToCount: count) else { return nil }
            migrationPool?.migrateData(data, forHandle: migrationHandle)
            return data
        }
    }
}
