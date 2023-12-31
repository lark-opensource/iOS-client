//
//  OpenPluginNetwork+Error.swift
//  OPPlugin
//
//  Created by MJXin on 2022/1/18.
//

import Foundation
import LarkRustClient
import OPPluginManagerAdapter
import LarkOpenAPIModel
import LarkOpenPluginManager



extension OpenPluginNetwork {
    
    /// 网络 API 业务错误
    enum OpenPluginNetworkError: Error {
        typealias URLString = String
        typealias FilePath = String
        typealias Message = String
        
        case unknown(Message?)
       
        // MARK: - 变量异常
        ///缺少必要变量(通常是必须变量拿到了空)
        case missingRequiredParams(Message)
        case createContextFail
        
        // MARK: - 序列化错误
        
        case codeInputModelFail(Message)
        case codeInternalModelFail(Message)
        /// url 序列化失败 , 参数为 url str
        case encodeUrlFail(URLString)
        
        // MARK: - 文件逻辑错误
        case invalidFilePath(FilePath)
        /// 沙箱对象不存在
        case storageModuleNotFound
        /// 生成随机临时路径失败
        case getRandomTmpPathFail
        /// 无读权限,  参数为 url str
        case readPermissionDenied(FilePath)
        /// 无写权限
        case writePermissionDenied(FilePath)
        /// 文件或文件路径不存在
        case fileNotExists(FilePath)
        /// 写入大小超限制
        case writeSizeLimit(FilePath)
    }

    /// 网络 API 错误处理逻辑, 用于将各种不同类型的错误转为 OpenAPIError
    /// - Parameters:
    ///   - context: api 的上下文
    ///   - error: 原始错误
    /// - Returns: 处理后的 API 错误
    static func apiError(context: OpenAPIContext, error: Error)  -> OpenAPIError {
        if let error = error as? OpenPluginNetworkError {
            switch error {
            case .missingRequiredParams(let msg):
                return OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage(msg)
                    .setError(error)
                    .setErrno(OpenAPICommonErrno.internalError)
            case .createContextFail:
                return OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setError(error)
                    .setErrno(OpenAPICommonErrno.internalError)
            case .codeInputModelFail(let msg):
                return OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setMonitorMessage(msg)
                    .setError(error)
                    .setErrno(OpenAPICommonErrno.internalError)
            case .codeInternalModelFail(let msg):
                return OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage(msg)
                    .setError(error)
                    .setErrno(OpenAPICommonErrno.internalError)
            case .encodeUrlFail(let urlStr):
                return OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setMonitorMessage("Encode url fail \(urlStr)")
                    .setError(error)
                    .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "url")))
            case .invalidFilePath(let filePath):
                return OpenAPIError(code: NetworkAPIErrorCode.invalidFilePath)
                    .setOuterMessage("Invalid filePath: \(filePath)")
                    .setMonitorMessage("Invalid filePath: \(filePath)")
                    .setError(error)
                    .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "filePath")))
            case .storageModuleNotFound:
                return OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setError(error)
                    .setErrno(OpenAPICommonErrno.internalError)
            case .getRandomTmpPathFail:
                return OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setError(error)
                    .setErrno(OpenAPICommonErrno.internalError)
            case .readPermissionDenied(let filePath):
                return OpenAPIError(code: NetworkAPIErrorCode.permissionDenied)
                    .setOuterMessage("Permission denied, read \(filePath)")
                    .setError(error)
                    .setErrno(OpenAPICommonErrno.readPermissionDenied(filePath: filePath))
            case .writePermissionDenied(let filePath):
                return OpenAPIError(code: NetworkAPIErrorCode.permissionDenied)
                    .setOuterMessage("Permission denied, write \(filePath)")
                    .setError(error)
                    .setErrno(OpenAPICommonErrno.writePermissionDenied(filePath: filePath))
            case .fileNotExists(let filePath):
                return OpenAPIError(code: NetworkAPIErrorCode.fileNotExists)
                    .setOuterMessage("No such file or directory \(filePath)")
                    .setError(error)
                    .setErrno(OpenAPICommonErrno.fileNotExists(filePath: filePath))
            case .writeSizeLimit(let filePath):
                return OpenAPIError(code: NetworkAPIErrorCode.sizeLimit)
                    .setOuterMessage("Saved file size limit exceeded \(filePath)")
                    .setError(error)
                    .setErrno(OpenAPICommonErrno.totalSizeLimitExceeded)
            case .unknown:
                context.apiTrace.error("Unknown error from network api: \(error.localizedDescription)")
                break;
            }
            
        } else if let error = error as? FileSystemError {
            var fileErrno = error.fileCommonErrno
            var networkError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("File system error")
                .setError(error)

            switch error {
            case .biz(_):
                networkError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage("File system error")
                    .setError(error)
            case .invalidFilePath(let filePath):
                networkError = OpenAPIError(code: NetworkAPIErrorCode.invalidFilePath)
                    .setOuterMessage("Invalid filePath: \(filePath)")
                    .setMonitorMessage("Invalid filePath: \(filePath)")
                    .setError(error)
                fileErrno = OpenAPICommonErrno.invalidParam(.invalidParam(param: "filePath"))
            case .readPermissionDenied(let fileObj, _):
                networkError = OpenAPIError(code: NetworkAPIErrorCode.permissionDenied)
                    .setOuterMessage("Permission denied, read \(fileObj.rawValue)")
                    .setError(error)
            case .writePermissionDenied(let fileObj, _):
                networkError = OpenAPIError(code: NetworkAPIErrorCode.permissionDenied)
                    .setOuterMessage("Permission denied, write \(fileObj.rawValue)")
                    .setError(error)
            case .fileNotExists(let fileObj, _):
                networkError = OpenAPIError(code: NetworkAPIErrorCode.fileNotExists)
                    .setOuterMessage("No such file or directory \(fileObj.rawValue)")
                    .setError(error)
            case .parentNotExists(let fileObj, _):
                networkError = OpenAPIError(code: NetworkAPIErrorCode.fileNotExists)
                    .setOuterMessage("No such file or directory \(fileObj.rawValue)")
                    .setError(error)
            case .writeSizeLimit(_ ,let fileObj, _):
                networkError = OpenAPIError(code: NetworkAPIErrorCode.sizeLimit)
                    .setOuterMessage("Save file size limit exceeded \(fileObj.rawValue)")
                    .setError(error)
            default:
                networkError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage("File system error")
                    .setError(error)
            }
            networkError.setErrno(fileErrno)
            return networkError
        } else if let error = error as? RCError {
            switch error {
            case .businessFailure(let errorInfo):
                return apiError(fromBusinessError: errorInfo).setError(error)
            default:
                context.apiTrace.error("Unknown error from rust: \(error.localizedDescription)")
            }
        }
        
        return OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setError(error)
            .setErrno(OpenAPICommonErrno.unknown)
    }
    
    /// Rust-SDK 业务错误 -> OpenAPIError 的映射
    /// - Parameter error: RCError 中 BusinessErrorInfo, rust-sdk 抛给端上的业务错误类型
    /// - Returns: 映射后的 API 错误
    private static func apiError(fromBusinessError error: BusinessErrorInfo) -> OpenAPIError {
        var apiError: OpenAPIError
        switch error.errorCode {
        case 100: apiError = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
        case 102: apiError = OpenAPIError(code:OpenAPICommonErrorCode.internalError)
        case 104: apiError = OpenAPIError(code:OpenAPICommonErrorCode.invalidParam)
        case 301: apiError = OpenAPIError(code:NetworkAPIErrorCode.cancelled)
        case 302: apiError = OpenAPIError(code:NetworkAPIErrorCode.timeout)
        case 303: apiError = OpenAPIError(code:NetworkAPIErrorCode.offilne)
        case 304: apiError = OpenAPIError(code:NetworkAPIErrorCode.networkSDKError)
        case 305: apiError = OpenAPIError(code:NetworkAPIErrorCode.networkFail)
        case 306: apiError = OpenAPIError(code:NetworkAPIErrorCode.downloadFail)
        /*
         1. rust 现在还不包含文件系统，不会返回文件相关的错误，这块之前是冗余设计
         2. 1000101～1000106 错误定义的很模糊，并不能明确映射到 errno 错误码
         3. 在网络 V2 的线上 errorCode 分布看板也确实没有看到 1000101～1000106 错误码
         所以对 1000101～1000106 errorCode 不映射对应的 errno
         */
        case 1000101: apiError = OpenAPIError(code:NetworkAPIErrorCode.invalidFilePath)
        case 1000102: apiError = OpenAPIError(code:NetworkAPIErrorCode.permissionDenied)
        case 1000103: apiError = OpenAPIError(code:NetworkAPIErrorCode.createFileFail)
        case 1000104: apiError = OpenAPIError(code:NetworkAPIErrorCode.writeFileFail)
        case 1000105: apiError = OpenAPIError(code:NetworkAPIErrorCode.fileNotExists)
        case 1000106: apiError = OpenAPIError(code:NetworkAPIErrorCode.sizeLimit)
        default: apiError = OpenAPIError(code:OpenAPICommonErrorCode.unknown)
        }
        if let errno = OpenAPINetworkRustErrno(errCode: Int(error.errorCode), errString: error.displayMessage) {
            apiError.setErrno(errno)
        } else {
            apiError.setErrno(OpenAPICommonErrno.unknown)
        }
        return apiError.setOuterMessage(error.displayMessage).setMonitorMessage(error.debugMessage)
    }
}
