//
//  CryptoFileHandle.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/8/1.
//

import Foundation
import LarkStorage
import LarkContainer
import LarkSecurityComplianceInfra

struct Crypto { }

extension Crypto {
    final class FileHandle: SBFileHandle {
        
        private let file: AESFile
        let info: AESMetaInfo
        let usage: FileHandleUsage
        
        init(userResolver: UserResolver, info: AESMetaInfo, usage: LarkStorage.FileHandleUsage) throws {
            Logger.info("create file handle begin \(info.filePath)")
            self.info = info
            self.usage = usage
            switch usage {
            case .reading:
                let preprocess = try CryptoPreprocess.Read.v2Preprocess(userResolver: userResolver, info: info)
                self.file = try AESFileFactory.createFile(deviceKey: info.deviceKey, header: preprocess.1, filePath: info.filePath, option: .read)
            case .writing(let append):
                let preprocess = try CryptoPreprocess.Write.v2Preprocess(append: append, userResolver: userResolver, info: info)
                self.file = try AESFileFactory.createFile(deviceKey: info.deviceKey, header: preprocess.1, filePath: info.filePath, option: append ? .append : .write)
            case .updating:
                let preprocess = try CryptoPreprocess.Write.v2Preprocess(append: true, userResolver: userResolver, info: info)
                self.file = try AESFileFactory.createFile(deviceKey: info.deviceKey, header: preprocess.1, filePath: info.filePath, option: .append)
            @unknown default:
                throw CryptoFileError.customError("file handle usage not supported")
            }
            Logger.info("create file handle end \(info.filePath)")
        }
        
        func seek(toOffset offset: UInt64) throws {
            _ = try file.seek(from: .start, offset: offset)
        }
        
        func synchronize() throws {
            try file.sync()
        }
        
        func close() throws {
            try file.close()
        }
        
        func readToEnd() throws -> Data? {
            try file.readToEnd()
        }
        
        func read(upToCount count: Int) throws -> Data? {
            try file.read(maxLength: UInt32(count), position: nil)
        }
        
        func offset() throws -> UInt64 {
            try file.offset()
        }
        
        func seekToEnd() throws -> UInt64 {
            try file.seek(from: .end, offset: 0)
        }
        
        func write(contentsOf data: Data) throws {
            _ = try file.write(data: data, position: nil)
        }
    }
}
