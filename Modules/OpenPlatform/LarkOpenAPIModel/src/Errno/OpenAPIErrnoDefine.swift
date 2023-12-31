//
//  OpenAPIErrnoDefine.swift
//  LarkOpenAPIModel
//
//  Created by 王飞 on 2022/5/25.
//

import Foundation

public enum OpenAPILoginErrno: Int, OpenAPIErrnoProtocol {
    
    case serverError = 001
    case syncSession = 002
    
    public var bizDomain: Int { 10 }
    public var funcDomain: Int { 00 }
    
    public var errString: String {
        switch self {
        case .serverError:
            return "server error"
        case .syncSession:
            return "update session failed"
        }
    }
}

public enum OpenAPIOpenSchemaErrno: Int, OpenAPIErrnoProtocol {
    
    case emptySchema = 002
    case notAllowed = 003
    case invalidSchema = 004
    case redirectFailed = 005
    
    public var bizDomain: Int { 14 }
    public var funcDomain: Int { 06 }
    
    public var errString: String {
        switch self {
        case .emptySchema:
            return "empty schema param"
        case .notAllowed:
            return "not in the white list"
        case .invalidSchema:
            return "schema invalid"
        case .redirectFailed:
            return "Unable to process the redirect"
        }
    }
}

public enum OpenAPIGetUserInfoErrno: Int, OpenAPIErrnoProtocol {
    
    case invalidSession = 001
    case getUserInfoFailed = 002
    
    public var bizDomain: Int { 10 }
    public var funcDomain: Int { 01 }
    
    public var errString: String {
        switch self {
        case .invalidSession:
            return "invalid session, please login"
        case .getUserInfoFailed:
            return "get user info failed"
        }
    }
}


public enum OpenAPIShowModalErrno: Int, OpenAPIErrnoProtocol {
    case invalidParams = 001
    
    public var bizDomain: Int { 11 }
    public var funcDomain: Int { 00 }
    
    public var errString: String {
        switch self {
        case .invalidParams:
            return "invalid title and content"
        }
    }
}

public enum OpenAPIOpenDocumentErrno: Int, OpenAPIErrnoProtocol {

    /// 非飞书云文档
    case notCloudFile = 001
    /// 非本地沙箱路径
    case invalidFilePath = 002
    /// 无读权限
    case readPermissionDenied = 003
    /// 文件不存在
    case fileNotExist = 004
    /// 不是一个文件
    case notFile = 005
    /// 主进程服务挂掉 - iOS 没有该 code，为了与 Android / PC 对齐，写在这里
    case mainThreadDead = 006
    
    public var bizDomain: Int { 12 }
    public var funcDomain: Int { 04 }

    public var errString: String {
        switch self {
        case .notCloudFile:
            return "filePath of cloudFile not support"
        case .invalidFilePath:
            return "filePath invalid"
        case .readPermissionDenied:
            return "read permission denied"
        case .fileNotExist:
            return "file not exists"
        case .notFile:
            return "not a regular file"
        case .mainThreadDead:
            return "internal service error"
        }
    }
}

/// 后台音频
public enum OpenAPIBGAudioErrno: Int, OpenAPIErrnoProtocol {
    /// 操作时没有音频实例
    case noneAudio = 001
    
    public var bizDomain: Int { 13 }
    public var funcDomain: Int { 04 }
    
    public var errString: String {
        switch self {
        case .noneAudio:
            return "no audio is playing"
        }
    }
    
}
