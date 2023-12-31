//
//  FileSystem+Error.swift
//  TTMicroApp
//
//  Created by Meng on 2021/8/3.
//

import Foundation
import LarkCache

public enum FileSystemError: Error {
    static let SRC_FILE_RAW_VALUE_KEY = "file_system_src_file_raw_value"
    static let DEST_FILE_RAW_VALUE_KEY = "file_system_dest_file_raw_value"
    static let INVALID_PARAM_KEY = "file_system_invalid_param"

    /// 业务错误
    public enum BizError: Error {

        /// 未知错误
        case unknown(Error?)

        /// 创建 FileObject 失败
//        case constructFileObjectFailed(String)

        /// 不是合法的 ttfile
//        case invalidTTFile(String)

        /// 通过 BDPLocalFileInfo 获取 filePath 失败
        case resolveFilePathFailed(FileObject, FileSystem.Context)

        /// 通过 BDPLocalFileInfo 获取 pkgPath 失败
        case resolvePkgPathFailed(FileObject, FileSystem.Context)

        /// 获取 package reader 失败
        case resolvePkgReaderFailed(FileSystem.Context)

        /// 获取 storage module 失败
        case resolveStorageModuleFailed(FileSystem.Context)

        /// 获取 BDPLocalFileInfo 失败
        case resolveLocalFileInfoFailed(FileObject, FileSystem.Context)

        /// 获取沙箱路径失败
        case resolveSandboxPathFailed(FileSystem.Context)

        /// 通过 reader 读取文件 data 失败
        case readPkgDataFailed(String, Error?, FileSystem.Context)

        /// 尝试对 package path 做写操作
        case tryWriteToPackagePath(FileObject, FileSystem.Context)

        /// 计算文件大小数据溢出, src, dest, dataSize
        case calculateSizeOverflow(FileObject?, FileObject, UInt64, FileSystem.Context)

        /// 读取包文件目录失败
        case listPackageContentsFailed(FileObject, FileSystem.Context)

        /// 解压缩失败
        case unzipFailed(FileObject, FileObject, FileSystem.Context)

        /// oc interface 调用入参不合法，nonull 传了 nil
        case resolveParamsFromObjcFailed

        /// 解析包路径资源缓存失败
        case resolveAuxiliaryFileFailed(Error?, FileObject, FileSystem.Context)

        /// fileHandle 读取数据失败
        case fileHandleReadDataFailed(FileObject, FileSystem.Context)
    }

    /// FileManager 系统接口报错
    case system(Error)

    /// 业务错误
    case biz(BizError)

    /// 无读权限
    case readPermissionDenied(FileObject, FileSystem.Context)

    /// 无写权限
    case writePermissionDenied(FileObject, FileSystem.Context)

    /// 文件不存在
    case fileNotExists(FileObject, FileSystem.Context)

    /// 文件已存在
    case fileAlreadyExists(FileObject, FileSystem.Context)

    /// 父目录不存在
    case parentNotExists(FileObject, FileSystem.Context)

    /// 文件夹非空
    case directoryNotEmpty(FileObject, FileSystem.Context)

    /// 不是文件夹
    case isNotDirectory(FileObject, FileSystem.Context)

    /// 不是文件
    case isNotFile(FileObject, FileSystem.Context)

    /// 不能同时操作路径和它的子路径
    case cannotOperatePathAndSubpathAtTheSameTime(FileObject, FileObject, FileSystem.Context)

    /// 写入文件文件大小限制
    case writeSizeLimit(FileObject?, FileObject, FileSystem.Context)

    /// 读取文件大小超过阈值
    case overReadSizeThreshold(FileObject, FileSystem.Context)

    /// 参数错误
    case invalidParam(String)

    /// 加密失败
    case encryptFailed(String, CryptoError.EncryptError, FileSystem.Context)

    /// 解密失败
    case decryptFailed(String, CryptoError.DecryptError, FileSystem.Context)

    /// 单次写入文件大小超过阈值
    case overWriteSizeThreshold(FileObject, FileSystem.Context)
    
    ///不是合法的filePath
    case invalidFilePath(String)
    
    ///文件名过长
    case fileNameTooLong(String)

}

extension FileSystemError: CustomNSError {
    public static var errorDomain: String {
        return "ecosystem.filesystem.error"
    }

    public var errorCode: Int {
        return errorCodeType.rawValue
    }

    public var errorUserInfo: [String : Any] {
        var result: [String: Any] = [:]
        switch self {
        case .system(let error):
            result = [NSUnderlyingErrorKey: error as NSError]
        case .biz(let error):
            let bizError = NSError(domain: BizError.errorDomain, code: error.errorCode, userInfo: error.errorUserInfo)
            result = [NSUnderlyingErrorKey: bizError]
        case .readPermissionDenied(let file, _):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
        case .writePermissionDenied(let file, _):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
        case .fileNotExists(let file, _):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
        case .fileAlreadyExists(let file, _):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
        case .parentNotExists(let file, _):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
        case .directoryNotEmpty(let file, _):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
        case .isNotDirectory(let file, _):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
        case .isNotFile(let file, _):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
        case .cannotOperatePathAndSubpathAtTheSameTime(let src, let dest, _):
            result = [
                FileSystemError.SRC_FILE_RAW_VALUE_KEY: src.rawValue,
                FileSystemError.DEST_FILE_RAW_VALUE_KEY: dest.rawValue
            ]
        case .writeSizeLimit(let src, let dest, _):
            if let src = src {
                result = [
                    FileSystemError.SRC_FILE_RAW_VALUE_KEY: src.rawValue,
                    FileSystemError.DEST_FILE_RAW_VALUE_KEY: dest.rawValue
                ]
            } else {
                result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: dest.rawValue]
            }
        case .overReadSizeThreshold(let file, _):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
        case .invalidParam(let param):
            result = [FileSystemError.INVALID_PARAM_KEY: param]
        case .encryptFailed(_, _, _):
            result = [:]
        case .decryptFailed(_, _, _):
            result = [:]
        case .overWriteSizeThreshold(let file, _):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
        case .invalidFilePath(let rawValue):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: rawValue]
        case .fileNameTooLong(let rawValue):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: rawValue]
        }
    
        result.merge([NSLocalizedDescriptionKey: errorMessage], uniquingKeysWith: { $1 })
        return result
    }

    public var errorMessage: String {
        return errorCodeType.message
    }

    var errorCodeType: FileSystemErrorCode {
        switch self {
        case .system(_):
            return .system
        case .biz(_):
            return .biz
        case .readPermissionDenied(_, _):
            return .readPermissionDenied
        case .writePermissionDenied(_, _):
            return .writePermissionDenied
        case .fileNotExists(_, _):
            return .fileNotExists
        case .fileAlreadyExists(_, _):
            return .fileAlreadyExists
        case .parentNotExists(_, _):
            return .parentNotExists
        case .directoryNotEmpty(_, _):
            return .directoryNotEmpty
        case .isNotDirectory(_, _):
            return .isNotDirectory
        case .isNotFile(_, _):
            return .isNotFile
        case .cannotOperatePathAndSubpathAtTheSameTime(_, _, _):
            return .cannotOperatePathAndSubpathAtTheSameTime
        case .writeSizeLimit(_, _, _):
            return .writeSizeLimit
        case .overReadSizeThreshold(_, _):
            return .overReadSizeThreshold
        case .invalidParam(_):
            return .invalidParam
        case .encryptFailed(_, _, _):
            return .encryptFailed
        case .decryptFailed(_, _, _):
            return .decryptFailed
        case .overWriteSizeThreshold(_, _):
            return .overWriteSizeThreshold
        case .invalidFilePath(_):
            return .invalidFilePath
        case .fileNameTooLong(_):
            return .fileNameTooLong
        }
    }

    var categoryValue: [String: Any] {
        var result: [String: Any] = [
            OPMonitorEventKey.error_domain: FileSystemError.errorDomain,
            OPMonitorEventKey.error_code: errorCode,
            OPMonitorEventKey.error_msg: errorMessage
        ]
        if case .invalidParam(let param) = self {
            result["invalid_param"] = param
        }
        if case .system(let systemError as NSError) = self {
            result["system_error_domain"] = systemError.domain
            result["system_error_code"] = systemError.code
            result["system_error_msg"] = systemError.description
        }
        if case .biz(let bizError) = self {
            result["biz_error_domain"] = FileSystemError.BizError.errorDomain
            result["biz_error_code"] = bizError.errorCode
            result["biz_error_msg"] = bizError.errorMessage
            result.merge(bizError.categoryValue, uniquingKeysWith: { $1 })
        }
        if case .encryptFailed(let filePath, let error, _) = self {
            result["encrypt_file_path"] = filePath
            result["encrypt_file_error_type"] = "unknown"
            if case .fileNotFoundError = error {
                result["encrypt_file_error_type"] = "fileNotFound"
            }
            if case .sdkError(error: let sdkErr) = error {
                result["encrypt_file_error_type"] = "sdkError"
                result["encrypt_file_error_msg"] = sdkErr.localizedDescription
            }
        }

        if case .decryptFailed(let filePath, let error, _) = self {
            result["decrypt_file_path"] = filePath
            result["decrypt_file_error_type"] = "unknown"
            if case .fileNotFoundError = error {
                result["decrypt_file_error_type"] = "fileNotFound"
            }
            if case .sdkError(error: let sdkErr) = error {
                result["decrypt_file_error_type"] = "sdkError"
                result["decrypt_file_error_msg"] = sdkErr.localizedDescription
            }
        }
        return result
    }
}

extension FileSystemError: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "[FileSystem.Error] code: \(errorCode), message: \(errorMessage), userInfo: \(errorUserInfo)"
    }

    public var debugDescription: String {
        return description
    }
}

extension FileSystemError.BizError: CustomNSError {
    public static var errorDomain: String {
        return "ecosystem.filesystem.error.biz"
    }

    public var errorCode: Int {
        return errorCodeType.rawValue
    }

    public var errorUserInfo: [String : Any] {
        var result: [String: Any] = [:]
        switch self {
        case .unknown(let err):
            if let error = err {
                result = [NSUnderlyingErrorKey: error]
            } else {
                result = [:]
            }
//        case .constructFileObjectFailed(let rawValue):
//            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: rawValue]
//        case .invalidTTFile(let rawValue):
//            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: rawValue]
        case .resolveFilePathFailed(let file, _):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
        case .resolvePkgPathFailed(let file, _):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
        case .resolvePkgReaderFailed(_):
            result = [:]
        case .resolveStorageModuleFailed(_):
            result = [:]
        case .resolveLocalFileInfoFailed(let file, _):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
        case .resolveSandboxPathFailed(_):
            result = [:]
        case .readPkgDataFailed(_, let err, _):
            if let error = err {
                result = [NSUnderlyingErrorKey: error]
            } else {
                result = [:]
            }
        case .tryWriteToPackagePath(let file, _):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
        case .calculateSizeOverflow(let src, let dest, _, _):
            if let src = src {
                result = [
                    FileSystemError.SRC_FILE_RAW_VALUE_KEY: src.rawValue,
                    FileSystemError.DEST_FILE_RAW_VALUE_KEY: dest.rawValue
                ]
            } else {
                result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: dest.rawValue]
            }
        case .listPackageContentsFailed(let file, _):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
        case .unzipFailed(let src, let dest, _):
            result = [
                FileSystemError.SRC_FILE_RAW_VALUE_KEY: src.rawValue,
                FileSystemError.DEST_FILE_RAW_VALUE_KEY: dest.rawValue
            ]
        case .resolveParamsFromObjcFailed:
            result = [:]
        case .resolveAuxiliaryFileFailed(let err, let file, _):
            if let error = err {
                result = [
                    NSUnderlyingErrorKey: error,
                    FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue
                ]
            } else {
                result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
            }
        case .fileHandleReadDataFailed(let file, _):
            result = [FileSystemError.DEST_FILE_RAW_VALUE_KEY: file.rawValue]
        }

        result.merge([NSLocalizedDescriptionKey: errorMessage], uniquingKeysWith: { $1 })
        return result
    }

    public var errorMessage: String {
        return errorCodeType.message
    }

    var errorCodeType: FileSystemBizErrorCode {
        switch self {
        case .unknown(_):
            return .unknown
//        case .constructFileObjectFailed(_):
//            return .constructFileObjectFailed
//        case .invalidTTFile(_):
//            return .invalidTTFile
        case .resolveFilePathFailed(_, _):
            return .resolveFilePathFailed
        case .resolvePkgPathFailed(_, _):
            return .resolvePkgPathFailed
        case .resolvePkgReaderFailed(_):
            return .resolvePkgReaderFailed
        case .resolveStorageModuleFailed(_):
            return .resolveStorageModuleFailed
        case .resolveLocalFileInfoFailed(_, _):
            return .resolveLocalFileInfoFailed
        case .resolveSandboxPathFailed(_):
            return .resolveSandboxPathFailed
        case .readPkgDataFailed(_, _, _):
            return .readPkgDataFailed
        case .tryWriteToPackagePath(_, _):
            return .tryWriteToPackagePath
        case .calculateSizeOverflow(_, _, _, _):
            return .calculateSizeOverflow
        case .listPackageContentsFailed(_, _):
            return .listPackageContentsFailed
        case .unzipFailed(_, _, _):
            return .unzipFailed
        case .resolveParamsFromObjcFailed:
            return .resolveParamsFromObjcFailed
        case .resolveAuxiliaryFileFailed(_, _, _):
            return .resolveAuxiliaryFileFailed
        case .fileHandleReadDataFailed(_, _):
            return .fileHandleReadDataFailed
        }
    }

    var categoryValue: [String: Any] {
        switch self {
        case .unknown(let err):
            if let e = err, case let error = e as NSError {
                return [
                    "biz_unknown_error_domain": error.domain,
                    "biz_unknown_error_code": error.code,
                    "biz_unknown_error_msg": error.description
                ]
            } else {
                return ["biz_unknown_error_msg": err?.localizedDescription ?? ""]
            }
        case .readPkgDataFailed(let pkgPath, let err, _):
            if let e = err, case let error = e as NSError {
                return [
                    "read_pkg_data_path": pkgPath,
                    "read_pkg_data_error_domain": error.domain,
                    "read_pkg_data_error_code": error.code,
                    "read_pkg_data_error_msg": error.description
                ]
            } else {
                return [
                    "read_pkg_data_path": pkgPath,
                    "read_pkg_data_error_msg": err.debugDescription
                ]
            }
        case .calculateSizeOverflow(_, _, let size, _):
            return ["write_size": size]
        case .resolveAuxiliaryFileFailed(let err, _, _):
            if let e = err, case let error = e as NSError {
                return [
                    "resolve_auxiliary_error_domain": error.domain,
                    "resolve_auxiliary_error_code": error.code,
                    "resolve_auxiliary_error_msg": error.description
                ]
            } else {
                return ["resolve_auxiliary_error_msg": err.debugDescription]
            }
        default:
            return [:]
        }
    }
}

extension FileSystemError.BizError: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "[FileSystem.Error.Biz] code: \(errorCode), message: \(errorMessage), userInfo: \(errorUserInfo)"
    }

    public var debugDescription: String {
        return description
    }
}

@objc public enum FileSystemErrorCode: Int, CaseIterable {
    case system                                             = 10001
    case biz                                                = 10002
    case readPermissionDenied                               = 10003
    case writePermissionDenied                              = 10004
    case fileNotExists                                      = 10005
    case fileAlreadyExists                                  = 10006
    case parentNotExists                                    = 10007
    case directoryNotEmpty                                  = 10008
    case isNotDirectory                                     = 10009
    case isNotFile                                          = 10010
    case cannotOperatePathAndSubpathAtTheSameTime           = 10011
    case writeSizeLimit                                     = 10012
    case overReadSizeThreshold                              = 10013
    case invalidParam                                       = 10014
    case encryptFailed                                      = 10015
    case decryptFailed                                      = 10016
    case overWriteSizeThreshold                             = 10017
    case invalidFilePath                                    = 10018
    case fileNameTooLong                                    = 10019

    var message: String {
        switch self {
        case .system:
            return "system error"
        case .biz:
            return "biz error"
        case .readPermissionDenied:
            return "read permission denied"
        case .writePermissionDenied:
            return "write permission denied"
        case .fileNotExists:
            return "file not exists"
        case .fileAlreadyExists:
            return "file already exists"
        case .parentNotExists:
            return "parent not exists"
        case .directoryNotEmpty:
            return "directory not empty"
        case .isNotDirectory:
            return "is not directory"
        case .isNotFile:
            return "is not file"
        case .cannotOperatePathAndSubpathAtTheSameTime:
            return "cannot operate path and subpath at the same time"
        case .writeSizeLimit:
            return "write size limit"
        case .overReadSizeThreshold:
            return "over read size threshold"
        case .invalidParam:
            return "invalid param"
        case .encryptFailed:
            return "encrypt failed"
        case .decryptFailed:
            return "decrypt failed"
        case .overWriteSizeThreshold:
            return "over write size threshold"
        case .invalidFilePath:
            return "invalid ttfile"
        case .fileNameTooLong:
            return "file name too long"
        }
    }
}

@objc enum FileSystemBizErrorCode: Int, CaseIterable {
    case unknown                                = 10000
//    case constructFileObjectFailed              = 10001
//    case invalidTTFile                          = 10002
    case resolveFilePathFailed                  = 10003
    case resolvePkgPathFailed                   = 10004
    case resolvePkgReaderFailed                 = 10005
    case resolveStorageModuleFailed             = 10006
    case resolveLocalFileInfoFailed             = 10007
    case resolveSandboxPathFailed               = 10008
    case readPkgDataFailed                      = 10009
    case tryWriteToPackagePath                  = 10010
    case calculateSizeOverflow                  = 10011
    case listPackageContentsFailed              = 10012
    case unzipFailed                            = 10013
    case resolveParamsFromObjcFailed            = 10014
    case resolveAuxiliaryFileFailed             = 10015
    case fileHandleReadDataFailed               = 10016

    var message: String {
        switch self {
        case .unknown:
            return "unknown"
//        case .constructFileObjectFailed:
//            return "construct file object failed"
//        case .invalidTTFile:
//            return "invalid ttfile"
        case .resolveFilePathFailed:
            return "resolve file path failed"
        case .resolvePkgPathFailed:
            return "resolve package path failed"
        case .resolvePkgReaderFailed:
            return "resolve package reader failed"
        case .resolveStorageModuleFailed:
            return "resolve storage module failed"
        case .resolveLocalFileInfoFailed:
            return "resolve local fileinfo failed"
        case .resolveSandboxPathFailed:
            return "resolve sandbox path failed"
        case .readPkgDataFailed:
            return "read package data failed"
        case .tryWriteToPackagePath:
            return "try write to package path"
        case .calculateSizeOverflow:
            return "calculate size overflow"
        case .listPackageContentsFailed:
            return "list package contents"
        case .unzipFailed:
            return "unzip failed"
        case .resolveParamsFromObjcFailed:
            return "resolve params from objc failed"
        case .resolveAuxiliaryFileFailed:
            return "resovle auxiliary file failed"
        case .fileHandleReadDataFailed:
            return "file handle read data failed"
        }
    }
}
