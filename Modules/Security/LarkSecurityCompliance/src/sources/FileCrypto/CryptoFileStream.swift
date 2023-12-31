//
//  CryptoFileStream.swift
//  LarkSecurityCompliance
//
//  Created by 汤泽川 on 2022/8/2.
//

import Foundation
import LarkStorage
import LarkRustClient
import LarkContainer
import LarkSecurityComplianceInfra

class CryptoFileStream: SBCipherOutputStream, SBCipherInputStream {

    fileprivate var cryptoFile: AESFile?
    fileprivate let info: AESMetaInfo
    let userResolver: UserResolver

    init(info: AESMetaInfo, userResolver: UserResolver) {
        self.info = info
        self.userResolver = userResolver
    }

    func open(shouldAppend append: Bool) throws {
        assertionFailure()
    }

    func close() throws {
        guard let cryptoFile else {
            SCLogger.error("crypto_file_stream/close/error: cryptor is not open")
            throw CryptoFileError.customError("file is not open")
        }
        do {
            try cryptoFile.close()
        } catch {
            Logger.error("crypto_file_stream/close/error: \(error)")
            throw error
        }
    }

    func read(maxLength len: UInt32) throws -> Data {
        guard let cryptoFile else {
            SCLogger.error("crypto_file_stream/read/error: cryptor is not open")
            throw CryptoFileError.customError("file is not open")
        }
        do {
            let data = try cryptoFile.read(maxLength: len, position: nil)
            return data
        } catch {
            SCLogger.error("crypto_file_stream/read/error: \(error)")
            throw error
        }
    }

    func readAll() throws -> Data {
        guard let cryptoFile else {
            SCLogger.error("crypto_file/readall/error: cryptor is not open")
            throw CryptoFileError.customError("file is not open")
        }
        do {
            let data = try cryptoFile.read(maxLength: UInt32.max, position: 0)
            return data
        } catch {
            SCLogger.error("crypto_file/readall/error: \(error)")
            throw error
        }
    }
    
    func seek(from where: SBSeekWhere, offset: UInt64) throws -> UInt64 {
        guard let cryptoFile else {
            SCLogger.error("crypto_file/seek/error: cryptor is not open")
            throw CryptoFileError.customError("file is not open")
        }
        var seekWhere: AESSeekWhere {
            switch `where` {
            case .start:
                return .start
            case .current:
                return .current
            case .end:
                return .end
            }
        }
        do {
            return try cryptoFile.seek(from: seekWhere, offset: offset)
        } catch {
            SCLogger.error("crypto_file/seek/error: \(error)")
            throw error
        }
    }

    func write(data: Data) throws {
        guard let cryptoFile else {
            SCLogger.error("crypto_file/write/error: cryptor is not open")
            throw CryptoFileError.customError("file is not open")
        }
        do {
            _ = try cryptoFile.write(data: data, position: nil)
        } catch {
            SCLogger.error("crypto_file/write/error: \(error)")
            throw error
        }
    }
}

final class EncryptFileStream: CryptoFileStream {
    override func open(shouldAppend append: Bool) throws {
        let option: AESFileOption = append ? .append : .write
        do {
            let result = try preprocess(append)
            self.cryptoFile = try AESFileFactory.createFile(deviceKey: result.0, header: result.1, filePath: info.filePath, option: option)
        } catch {
            SCLogger.error("crypto_file/open/error: \(error)")
            throw error
        }
    }
    
    private func preprocess(_ append: Bool) throws -> (Data, AESHeader) {
        let aHeader: AESHeader
        var deviceKey = info.deviceKey
        if append { // append 场景先进行数据迁移，然后再去check Header
            let migrateFile = MigrateFileV2(userResolver: userResolver, info: info)
            if let header = try migrateFile.doProcess() {
                aHeader = header
            } else {
                aHeader = try AESHeader(filePath: info.filePath)
                do {
                    try aHeader.checkV2Header(did: info.did, uid: info.uid, deviceKey: info.deviceKey)
                } catch AESHeader.CheckError.didNotMatched(let did) {
                    let service = try userResolver.resolve(type: FileCryptoService.self)
                    deviceKey = try service.deviceKey(did: did)
                }
            }
        } else { // write 场景，直接创建新header
            aHeader = AESHeader(key: info.deviceKey,
                               uid: Int64(info.uid) ?? 0,
                               did: Int64(info.did) ?? 0)
        }
        return (deviceKey, aHeader)
    }
}

final class DecryptFileStream: CryptoFileStream {
    override func open(shouldAppend append: Bool) throws {
        do {
            let result = try preprocess()
            cryptoFile = try AESFileFactory.createFile(deviceKey: result.0, header: result.1, filePath: info.filePath, option: .read)
        } catch {
            SCLogger.error("crypto_file/open/error: \(error)")
            throw error
        }
    }
    
    /// 预处理：1. 迁移、2. header校验
    private func preprocess() throws -> (Data, AESHeader) {
        let aHeader: AESHeader
        var deviceKey = info.deviceKey
        let migrateFile = MigrateFileV2(userResolver: userResolver, info: info)
        if let header = try migrateFile.doProcess() { // 迁移完成直接返回新header
            aHeader = header
        } else { // 无需迁移，取当前的header
            aHeader = try AESHeader(filePath: info.filePath)
            do {
                try aHeader.checkV2Header(did: info.did, uid: info.uid, deviceKey: info.deviceKey)
            } catch AESHeader.CheckError.didNotMatched(let did) {
                let service = try userResolver.resolve(type: FileCryptoService.self)
                deviceKey = try service.deviceKey(did: did)
            }
        }
        return (deviceKey, aHeader)
    }
}
