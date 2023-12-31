//
//  RawSystemStream.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/8/1.
//

import Foundation
import LarkStorage
import LarkContainer
import LarkSecurityComplianceInfra

extension Raw {
    
    typealias SysInputStream = Foundation.InputStream
    typealias SysOutputStream = Foundation.OutputStream
    
    // MARK: - InputStream
    
    /// System InputStream wrapper
    class InputStream: NSObject, SBInputStream, Foundation.StreamDelegate, FileRecordHandle {
       
        var hasBytesAvailable: Bool { stream?.hasBytesAvailable ?? false }
        
        let stream: SysInputStream?
        let userResolver: UserResolver
        let info: AESMetaInfo
        var filePath: String { info.filePath }
        let fileRecord: FileMigrationRecord?
        
        init(userResolver: UserResolver, info: AESMetaInfo) throws {
            stream = SysInputStream(fileAtPath: info.filePath)
            self.info = info
            self.userResolver = userResolver
            fileRecord = try? userResolver.resolve(type: FileMigrationRecord.self)
            super.init()
            stream?.delegate = self
            
        }
        
        func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
            guard let stream else {
                Logger.error("input stream is nil")
                return 0
            }
            return stream.read(buffer, maxLength: len)
        }
        
        var streamStatus: Stream.Status { stream?.streamStatus ?? .notOpen }
        
        var streamError: Error? { stream?.streamError }
        
        weak var delegate: StreamDelegate?
        
        func open() {
            stream?.open()
            if stream != nil {
                fileRecord?.startReadFile(withHandle: self)
            }
        }
        
        func close() {
            stream?.close()
            if stream != nil {
                fileRecord?.stopReadFile(withHandle: self)
            }
        }
        
        // MARK: - Foundation.StreamDelegate
        func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
            delegate?.stream?(aStream, handle: eventCode)
        }
    }
    
    /// InputStream with migration to crypto
    final class InputStreamMigration: InputStream {
        override init(userResolver: UserResolver, info: AESMetaInfo) throws {
            let fileRaw = MigrateFileRaw(userResolver: userResolver, info: info)
            try fileRaw.doProcess()
            try super.init(userResolver: userResolver, info: info)
        }
    }
    
    final class InputStreamMigrationPool: InputStream, FileMigrationHandle {
        
        let migrationID = UUID().uuidString
        let migrationPool: FileMigrationPool?
        
        override init(userResolver: UserResolver, info: AESMetaInfo) throws {
            migrationPool = try? userResolver.resolve(type: FileMigrationPool.self)
            try super.init(userResolver: userResolver, info: info)
        }
        
        override func open() {
            if stream != nil {
                migrationPool?.enter(handle: self)
            }
            super.open()
        }
        override func close() {
            if stream != nil {
                migrationPool?.leave(handle: self)
            }
            super.close()
        }
        
        override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
            let length = super.read(buffer, maxLength: len)
            if length > 0 {
                let data = Data(bytes: buffer, count: length)
                migrationPool?.migrateData(data, forHandle: self)
            }
            return length
        }
    }
    
    // MARK: - OutputStream
    
    /// System OutputStream wrapper
    class OutputStream: NSObject, SBOutputStream, Foundation.StreamDelegate {
       
        var hasSpaceAvailable: Bool { stream?.hasSpaceAvailable ?? false }
        
        let stream: SysOutputStream?
        let userResolver: UserResolver
        
        init(userResolver: UserResolver, info: AESMetaInfo, append: Bool) throws {
            stream = SysOutputStream(toFileAtPath: info.filePath, append: append)
            self.userResolver = userResolver
            super.init()
            stream?.delegate = self
        }
        
        func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
            guard let stream else {
                Logger.error("output stream is nil")
                return 0
            }
            return stream.write(buffer, maxLength: len)
        }
        
        var streamStatus: Stream.Status { stream?.streamStatus ?? .notOpen }
        
        var streamError: Error? { stream?.streamError }
        
        weak var delegate: StreamDelegate?
        
        func open() {
            stream?.open()
        }
        
        func close() {
            stream?.close()
        }
        
        // MARK: - Foundation.StreamDelegate
        func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
            delegate?.stream?(aStream, handle: eventCode)
        }
    }
    
    /// OutputStream with migration to crypto
    final class OutputStreamMigration: OutputStream {
        override init(userResolver: UserResolver, info: AESMetaInfo, append: Bool) throws {
            if append {
                let fileRaw = MigrateFileRaw(userResolver: userResolver, info: info)
                try fileRaw.doProcess()
            }
            try super.init(userResolver: userResolver, info: info, append: append)
        }
    }
}
