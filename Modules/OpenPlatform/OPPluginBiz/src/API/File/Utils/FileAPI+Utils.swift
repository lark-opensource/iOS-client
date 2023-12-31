//
//  FileAPI+Utils.swift
//  OPPlugin
//
//  Created by Meng on 2021/8/20.
//

import Foundation
import LarkOpenAPIModel

public extension Error {
    var fileSystemUnknownError: OpenAPIError {
        return OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setMonitorMessage("unknown error: \(localizedDescription)")
            .setErrno(OpenAPICommonErrno.unknown)
    }
}
public extension Error {
    var newFileSystemUnknownError: OpenAPIError {
        return OpenAPIError(errno: OpenAPICommonErrno.unknown)
            .setMonitorMessage("unknown error: \(localizedDescription)")
    }
}
public extension FileSystemError {
    var openAPIError: OpenAPIError {
        var apiError: OpenAPIError
        switch self {
        case .system(_):
            apiError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setErrno(OpenAPICommonErrno.internalError)
        case .biz(let bizError):
            apiError = bizError.openAPIError
        case .readPermissionDenied(let file, _):
            apiError = OpenAPIError(code: OpenAPIFileSystemErrorCode.readPermissionDenied)
                .setOuterMessage(OpenAPIFileSystemErrorCode.readPermissionDenied.errMsg + ": \(file.rawValue)")
                .setErrno(OpenAPICommonErrno.readPermissionDenied(filePath: file.formatTTPath))
        case .writePermissionDenied(let file, _):
            apiError = OpenAPIError(code: OpenAPIFileSystemErrorCode.writePermissionDenied)
                .setOuterMessage(OpenAPIFileSystemErrorCode.writePermissionDenied.errMsg + ": \(file.rawValue)")
                .setErrno(OpenAPICommonErrno.writePermissionDenied(filePath: file.formatTTPath))
        case .fileNotExists(let file, _):
            apiError = OpenAPIError(code: OpenAPIFileSystemErrorCode.fileNotExists)
                .setOuterMessage(OpenAPIFileSystemErrorCode.fileNotExists.errMsg + ": \(file.rawValue)")
                .setErrno(OpenAPICommonErrno.fileNotExists(filePath: file.formatTTPath))
        case .fileAlreadyExists(let file, _):
            apiError = OpenAPIError(code: OpenAPIFileSystemErrorCode.fileAlreadyExists)
                .setOuterMessage(OpenAPIFileSystemErrorCode.fileAlreadyExists.errMsg + ": \(file.rawValue)")
                .setErrno(OpenAPICommonErrno.fileAlreadyExists(filePath: file.formatTTPath))
        case .parentNotExists(let file, _):
            apiError = OpenAPIError(code: OpenAPIFileSystemErrorCode.fileNotExists)
                .setOuterMessage(OpenAPIFileSystemErrorCode.fileNotExists.errMsg + ": \(file.rawValue)")
                .setErrno(OpenAPICommonErrno.fileNotExists(filePath: file.formatTTPath))
        case .directoryNotEmpty(let file, _):
            apiError = OpenAPIError(code: OpenAPIFileSystemErrorCode.directoryNotEmpty)
                .setOuterMessage(OpenAPIFileSystemErrorCode.directoryNotEmpty.errMsg + ": \(file.rawValue)")
                .setErrno(OpenAPICommonErrno.directoryNotEmpty(filePath: file.formatTTPath))
        case .isNotDirectory(let file, _):
            apiError = OpenAPIError(code: OpenAPIFileSystemErrorCode.fileIsNotDirectory)
                .setOuterMessage(OpenAPIFileSystemErrorCode.fileIsNotDirectory.errMsg + ": \(file.rawValue)")
                .setErrno(OpenAPICommonErrno.fileIsNotDirectory(filePath: file.formatTTPath))
        case .isNotFile(let file, _):
            apiError = OpenAPIError(code: OpenAPIFileSystemErrorCode.fileIsNotRegularFile)
                .setOuterMessage(OpenAPIFileSystemErrorCode.fileIsNotRegularFile.errMsg + ": \(file.rawValue)")
                .setErrno(OpenAPICommonErrno.fileIsNotRegularFile(filePath: file.formatTTPath))
        case .cannotOperatePathAndSubpathAtTheSameTime(_, _, _):
            apiError = OpenAPIError(code: OpenAPIFileSystemErrorCode.cannotOperatePathAndSubPathAtTheSameTime)
                .setErrno(OpenAPICommonErrno.cannotOperatePathAndSubPathAtTheSameTime)
        case .writeSizeLimit(_, _, _):
            apiError = OpenAPIError(code: OpenAPIFileSystemErrorCode.totalSizeLimitExceeded)
                .setErrno(OpenAPICommonErrno.totalSizeLimitExceeded)
        case .overReadSizeThreshold(_, _):
            apiError = OpenAPIError(code: OpenAPIFileSystemErrorCode.readDataExceedsSizeLimit)
                .setErrno(OpenAPICommonErrno.readDataExceedsSizeLimit)
        case .invalidParam(let param):
            apiError = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: param)))
        case .encryptFailed(_, _, _), .decryptFailed(_, _, _):
            apiError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setErrno(OpenAPICommonErrno.internalError)
        case .overWriteSizeThreshold(_, _):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.writeDataExceedsSizeLimit)
        case .invalidFilePath(let rawValue):
            //这里因为是把原来的invalidTTFile从biz里面提出来了，errCode和errMsg不能变，保持原来的invalidPatam
            apiError = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.invalidFilePath(filePath: "`\(rawValue)`"))
        case .fileNameTooLong(let rawValue):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.fileNameTooLong(msg: rawValue))
        @unknown default:
            apiError = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
        }
        if apiError.monitorMsg != nil{
            return apiError
        }
        return apiError.setMonitorMessage(errorMessage)
    }
}

public extension FileSystemError {
    //无errCode，只有errno的OpenAPIError，只有新增的api才会走这里
    var newOpenAPIError: OpenAPIError {
        var apiError: OpenAPIError
        switch self {
        case .system(_):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.internalError)
        case .biz(let bizError):
            apiError = bizError.newOpenAPIError
        case .readPermissionDenied(let file, _):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.readPermissionDenied(filePath: file.formatTTPath))
                .setMonitorMessage(OpenAPIFileSystemErrorCode.readPermissionDenied.errMsg + ": \(file.formatTTPath)")
        case .writePermissionDenied(let file, _):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.writePermissionDenied(filePath: file.formatTTPath))
                .setMonitorMessage(OpenAPIFileSystemErrorCode.writePermissionDenied.errMsg + ": \(file.formatTTPath)")
        case .fileNotExists(let file, _):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.fileNotExists(filePath: file.formatTTPath))
                .setMonitorMessage(OpenAPIFileSystemErrorCode.fileNotExists.errMsg + ": \(file.formatTTPath)")
        case .fileAlreadyExists(let file, _):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.fileAlreadyExists(filePath: file.formatTTPath))
                .setMonitorMessage(OpenAPIFileSystemErrorCode.fileAlreadyExists.errMsg + ": \(file.formatTTPath)")
        case .parentNotExists(let file, _):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.fileNotExists(filePath: file.formatTTPath))
                .setMonitorMessage(OpenAPIFileSystemErrorCode.fileNotExists.errMsg + ": \(file.formatTTPath)")
        case .directoryNotEmpty(let file, _):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.directoryNotEmpty(filePath: file.formatTTPath))
                .setMonitorMessage(OpenAPIFileSystemErrorCode.directoryNotEmpty.errMsg + ": \(file.formatTTPath)")
        case .isNotDirectory(let file, _):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.fileIsNotDirectory(filePath: file.formatTTPath))
                .setMonitorMessage(OpenAPIFileSystemErrorCode.fileIsNotDirectory.errMsg + ": \(file.formatTTPath)")
        case .isNotFile(let file, _):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.fileIsNotRegularFile(filePath: file.formatTTPath))
                .setMonitorMessage(OpenAPIFileSystemErrorCode.fileIsNotRegularFile.errMsg + ": \(file.formatTTPath)")
        case .cannotOperatePathAndSubpathAtTheSameTime(let src, let dest, _):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.cannotOperatePathAndSubPathAtTheSameTime)
                .setMonitorMessage(OpenAPIFileSystemErrorCode.cannotOperatePathAndSubPathAtTheSameTime.errMsg + ": src:\(src.formatTTPath),dest:\(dest.formatTTPath)")
        case .writeSizeLimit(_, _, _):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.totalSizeLimitExceeded)
        case .overReadSizeThreshold(_, _):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.readDataExceedsSizeLimit)
        case .invalidParam(let param):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.invalidParam(.invalidParam(param: param)))
        case .encryptFailed(_, _, _), .decryptFailed(_, _, _):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.internalError)
        case .overWriteSizeThreshold(_, _):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.writeDataExceedsSizeLimit)
        case .invalidFilePath(let rawValue):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.invalidFilePath(filePath: "`\(rawValue)`"))
        case .fileNameTooLong(let rawValue):
            apiError = OpenAPIError(errno: OpenAPICommonErrno.fileNameTooLong(msg: rawValue))
        @unknown default:
            apiError = OpenAPIError(errno: OpenAPICommonErrno.unknown)
        }
        
        if apiError.monitorMsg != nil{
            return apiError
        }
        return apiError.setMonitorMessage(errorMessage)
    }
}
public extension FileSystemError.BizError {
    var openAPIError: OpenAPIError {
        switch self {
        case .resolveFilePathFailed(let file, _):
            return OpenAPIError(code: OpenAPIFileSystemErrorCode.fileNotExists)
                .setOuterMessage(OpenAPIFileSystemErrorCode.fileNotExists.errMsg + ": \(file.rawValue)")
                .setMonitorMessage("FileSystemError.BizError.resolveFilePathFailed:\(file.rawValue)")
                .setErrno(OpenAPICommonErrno.fileNotExists(filePath: file.formatTTPath))
        case .resolveLocalFileInfoFailed(let file, _):
            return OpenAPIError(code: OpenAPIFileSystemErrorCode.fileNotExists)
                .setOuterMessage(OpenAPIFileSystemErrorCode.fileNotExists.errMsg + ": \(file.rawValue)")
                .setMonitorMessage("FileSystemError.BizError.resolveLocalFileInfoFailed:\(file.rawValue)")
                .setErrno(OpenAPICommonErrno.fileNotExists(filePath: file.formatTTPath))
        default:
            return OpenAPIError(code: OpenAPICommonErrorCode.internalError).setErrno(OpenAPICommonErrno.internalError)
        }
    }
}

public extension FileSystemError.BizError {
    //去除errCode，只有errno的OpenAPIError
    var newOpenAPIError: OpenAPIError {
        switch self {
        case .resolveFilePathFailed(let file, _):
            return OpenAPIError(errno: OpenAPICommonErrno.fileNotExists(filePath: file.formatTTPath))
                .setMonitorMessage("FileSystemError.BizError.resolveFilePathFailed:\(file.rawValue)")
        case .resolveLocalFileInfoFailed(let file, _):
            return OpenAPIError(errno: OpenAPICommonErrno.fileNotExists(filePath: file.formatTTPath))
                .setMonitorMessage("FileSystemError.BizError.resolveLocalFileInfoFailed:\(file.rawValue)")
        default:
            return OpenAPIError(errno: OpenAPICommonErrno.internalError)
        }
    }
}

public extension FileObject {
    var formatTTPath: String {
        return "`\(self.rawValue)`"
    }
}

