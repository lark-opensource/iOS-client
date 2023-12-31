//
//  CryptoFile.swift
//  LarkSecurityCompliance
//
//  Created by 汤泽川 on 2022/8/2.
//

import Foundation
import Homeric
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LKCommonsTracker
import RustPB
import SwiftProtobuf

enum CryptoFileError: Error {
    case customError(String)
}

final class RustCryptoFile {
    enum OpenOptions {
        case read
        case write
        /// if exist, open instead
        case create
        /// if exist, throw error
        case createNew
        case append
        /// if open succes, make file empty
        case truncate
    }

    enum SeekWhere: Int {
        case start = 0
        case current
        case end
    }

    let logger = LKCommonsLogging.Logger.log(RustCryptoFile.self, category: "security_compliance")

    private let rustService: RustService
    private let filePath: String
    private var fd: UInt64?

    init(atFilePath path: String, rustService: RustService) {
        filePath = path
        self.rustService = rustService
    }

    func open(options: [OpenOptions]) throws {
        var openOptions = Security_V1_OpenOptions()
        for option in options {
            switch option {
            case .read:
                openOptions.read = true
            case .write:
                openOptions.write = true
            case .create:
                openOptions.create = true
            case .createNew:
                openOptions.createNew = true
            case .append:
                openOptions.append = true
            case .truncate:
                openOptions.truncate = true
            }
        }

        var openRequest = RustPB.Security_V1_OpenRequest()
        openRequest.options = openOptions
        openRequest.path = filePath
        let openResponse: Security_V1_OpenResponse = try sendSyncRequest(openRequest)
        fd = openResponse.secFd
    }

    func close() throws {
        guard let fd = fd else {
            throw CryptoFileError.customError("file is not open")
        }
        var closeRequest = RustPB.Security_V1_CloseRequest()
        closeRequest.secFd = fd

        let _: Security_V1_CloseResponse = try sendSyncRequest(closeRequest)
    }

    func stat() throws -> Security_V1_FileMetadata {
        guard let fd = fd else {
            throw CryptoFileError.customError("file is not open")
        }
        var statRequest = RustPB.Security_V1_StatRequest()
        statRequest.secFd = fd

        let statResponse: Security_V1_StatResponse = try sendSyncRequest(statRequest)
        return statResponse.meta
    }

    /// 移动文件指针到指定位置，返回移动后的指针位置
    func seek(from seekWhere: SeekWhere, offset: Int64) throws -> UInt64 {
        guard let fd = fd else {
            throw CryptoFileError.customError("file is not open")
        }

        var seekRequest = RustPB.Security_V1_SeekRequest()
        seekRequest.seekWhere = RustPB.Security_V1_SeekRequest.SeekWhere(rawValue: seekWhere.rawValue) ?? .start
        seekRequest.secFd = fd
        seekRequest.seekOffset = offset

        let seekResponse: Security_V1_SeekResponse = try sendSyncRequest(seekRequest)
        return seekResponse.position
    }

    func read(maxLength len: UInt32, position: UInt64?) throws -> Data {
        guard let fd = fd else {
            throw CryptoFileError.customError("file is not open")
        }
        var readRequest = RustPB.Security_V1_ReadRequest()
        readRequest.secFd = fd
        readRequest.length = len
        if let position = position {
            readRequest.position = position
        }

        let readResponse: Security_V1_ReadResponse = try sendSyncRequest(readRequest)
        return readResponse.data
    }

    /// 返回实际写入的长度，实际写入的长度可能小于用户提供的数据
    func write(data: Data, position: UInt64?) throws -> UInt32 {
        guard let fd = fd else {
            throw CryptoFileError.customError("file is not open")
        }
        var writeRequest = RustPB.Security_V1_WriteRequest()
        writeRequest.secFd = fd
        writeRequest.data = data
        if let position = position {
            writeRequest.position = position
        }
        let writeResponse: Security_V1_WriteResponse = try sendSyncRequest(writeRequest)
        return writeResponse.length
    }

    /// 立即同步写入缓存到磁盘
    func sync() throws {
        guard let fd = fd else {
            throw CryptoFileError.customError("file is not open")
        }
        var syncRequest = Security_V1_SyncRequest()
        syncRequest.secFd = fd

        let _: Security_V1_SyncResponse = try sendSyncRequest(syncRequest)
    }

    private func sendSyncRequest<Request, Response>(_ request: Request) throws -> Response
        where Request: Message, Response: Message {
        let response: Response
        do {
            response = try rustService.sync(message: request, parentID: nil, allowOnMainThread: true)
        } catch {
            logger.error("Error to call rust cipher method, error: \(error)")
            throw error
        }
        if let errorCode = (response as? ErrorCodeConvertible)?.errCode, errorCode != 0, errorCode != 10_301 {
            Tracker.post(TeaEvent(Homeric.DISK_FILE_CIPHER_ERROR, params: ["error_code": errorCode]))
            var larkError = LarkError()
            larkError.code = errorCode
            let rcError = RCError.businessFailure(errorInfo: BusinessErrorInfo(larkError))
            logger.log(level: .error, "加解密接口错误",
                       additionalData: nil,
                       error: rcError)
            throw RCError.businessFailure(errorInfo: BusinessErrorInfo(larkError))
        } else {
            return response
        }
    }
}

private protocol ErrorCodeConvertible {
    var errCode: Int32 { get }
}

extension Security_V1_OpenResponse: ErrorCodeConvertible {}

extension Security_V1_CloseResponse: ErrorCodeConvertible {}

extension Security_V1_StatResponse: ErrorCodeConvertible {}

extension Security_V1_SeekResponse: ErrorCodeConvertible {}

extension Security_V1_ReadResponse: ErrorCodeConvertible {}

extension Security_V1_WriteResponse: ErrorCodeConvertible {}

extension Security_V1_SyncResponse: ErrorCodeConvertible {}

