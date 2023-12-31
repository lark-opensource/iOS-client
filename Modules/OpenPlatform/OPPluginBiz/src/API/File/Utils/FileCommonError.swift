//
//  FileCommonError.swift
//  OPPlugin
//
//  Created by ByteDance on 2022/8/19.
//

import Foundation
import LarkOpenAPIModel

/// 业务api调用文件能力统一对外OpenAPIError
public extension FileSystemError {

    var fileCommonErrno: OpenAPICommonErrno {
        switch self {
        case .readPermissionDenied(let file, _):
            return OpenAPICommonErrno.readPermissionDenied(filePath: file.formatTTPath)
        case .writePermissionDenied(let file, _):
            return OpenAPICommonErrno.writePermissionDenied(filePath: file.formatTTPath)
        case .fileNotExists(let file, _):
            return OpenAPICommonErrno.fileNotExists(filePath: file.formatTTPath)
        case .fileAlreadyExists(let file, _):
            return OpenAPICommonErrno.fileAlreadyExists(filePath: file.formatTTPath)
        case .parentNotExists(let file, _):
            return OpenAPICommonErrno.fileNotExists(filePath: file.formatTTPath)
        case .directoryNotEmpty(let file, _):
            return OpenAPICommonErrno.directoryNotEmpty(filePath: file.formatTTPath)
        case .isNotDirectory(let file, _):
            return OpenAPICommonErrno.fileIsNotDirectory(filePath: file.formatTTPath)
        case .isNotFile(let file, _):
            return OpenAPICommonErrno.fileIsNotRegularFile(filePath: file.formatTTPath)
        case .cannotOperatePathAndSubpathAtTheSameTime(_, _, _):
            return OpenAPICommonErrno.cannotOperatePathAndSubPathAtTheSameTime
        case .writeSizeLimit(_, _, _):
            return OpenAPICommonErrno.totalSizeLimitExceeded
        case .overReadSizeThreshold(_, _):
            return OpenAPICommonErrno.readDataExceedsSizeLimit
        case .invalidParam(let param):
            return OpenAPICommonErrno.invalidParam(.invalidParam(param: param))
        case .overWriteSizeThreshold(_, _):
            return OpenAPICommonErrno.writeDataExceedsSizeLimit
        case .invalidFilePath(let rawValue):
            return OpenAPICommonErrno.invalidFilePath(filePath: "`\(rawValue)`")
        case .fileNameTooLong(let rawValue):
            return OpenAPICommonErrno.fileNameTooLong(msg: rawValue)
        default:
            return OpenAPICommonErrno.internalError
        }
    }
    
    
}
