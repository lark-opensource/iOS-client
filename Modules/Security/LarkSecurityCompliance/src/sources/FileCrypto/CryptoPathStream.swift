//
//  CryptoPathStream.swift
//  LarkSecurityCompliance
//
//  Created by 汤泽川 on 2022/8/2.
//

import Foundation
import LarkStorage
import LarkRustClient
import LarkSecurityComplianceInfra
import LarkContainer

// ignoring lark storage check for SBCipher implementation
// lint:disable lark_storage_check

final class EncryptPathStream: SBCipherOutputStream {

    let filePath: String
    var fileHandle: SCFileHandle?
    lazy var cryptoPath = CryptoPath(userResolver: userResolver)
    let userResolver: UserResolver

    init(userResolver: UserResolver, atFilePath path: String) {
        filePath = path
        self.userResolver = userResolver
    }

    func open(shouldAppend append: Bool) throws {
        do {
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
        } catch {
            SCLogger.error("path_stream/open/error: \(error)")
            throw error
        }
    }

    func write(data: Data) throws {
        guard let fileHandle else { throw CryptoFileError.customError("file stream unavable") }
        do {
            try fileHandle.write(contentsOf: data)
        } catch {
            SCLogger.error("path_stream/write/error: \(error)")
            throw CryptoFileError.fileStreamError(error)
        }
    }

    func close() throws {
        guard let fileHandle else { throw CryptoFileError.customError("file stream unavable") }
        do {
            try fileHandle.close()
            try cryptoPath.encrypt(filePath)
        } catch {
            SCLogger.error("path_stream/close/error: \(error)")
            throw CryptoFileError.fileStreamError(error)
        }
    }
}

final class DecryptPathStream: SBCipherInputStream {

    let filePath: String
    var fileHandle: SCFileHandle?
    let userResolver: UserResolver
    lazy var cryptoPath = CryptoPath(userResolver: userResolver)

    init(userResolver: UserResolver, atFilePath path: String) {
        filePath = path
        self.userResolver = userResolver
    }

    func open(shouldAppend append: Bool) throws {
        let decryptPath = try cryptoPath.decrypt(filePath)

        fileHandle = try SCFileHandle(path: decryptPath, option: .read)
    }

    func read(maxLength len: UInt32) throws -> Data {
        guard let fileHandle else { throw CryptoFileError.customError("file stream unavable") }
        do {
            guard let data = try fileHandle.read(upToCount: Int(len)) else {
                throw CryptoFileError.customError("read data is nil")
            }
            return data
        } catch {
            SCLogger.error("path_stream/read/error: \(error)")
            throw error
        }
    }

    func readAll() throws -> Data {
        guard let fileHandle else { throw CryptoFileError.customError("file stream unavable") }
        do {
            guard let data = try fileHandle.readToEnd() else {
                throw CryptoFileError.customError("read data is nil")
            }
            return data
        } catch {
            SCLogger.error("path_stream/readall/error: \(error)")
            throw error
        }
    }

    func close() throws {
        guard let fileHandle else { throw CryptoFileError.customError("file stream unavable") }
        do {
            try fileHandle.close()
        } catch {
            SCLogger.error("path_stream/close/error: \(error)")
            throw error
        }
    }

    func seek(from where: SBSeekWhere, offset: UInt64) throws -> UInt64 {
        guard let fileHandle else { throw CryptoFileError.customError("file stream unavable") }
        switch `where` {
        case .current:
            let currentOffset = try fileHandle.offset()
            try fileHandle.seek(toOffset: currentOffset + offset)
        case .start:
            try fileHandle.seek(toOffset: offset)
        case .end:
            try fileHandle.seekToEnd()
        }
        do {
            return try fileHandle.offset()
        } catch {
            SCLogger.error("path_stream/seek/error: \(error)")
            throw error
        }
    }
}
