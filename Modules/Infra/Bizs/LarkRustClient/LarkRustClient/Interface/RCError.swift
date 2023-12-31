//
//  RCError.swift
//  Lark
//
//  Created by Sylar on 2017/12/12.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 服务器返回的错误信息
public struct BusinessErrorInfo {
    /// 旧版本的错误码
    @available(*, deprecated, message: "use errorCode instead")
    public var code: Int32
    /// 新版本的错误码 https://bytedance.feishu.cn/docx/doxcn99FEHGKL5vxRbWarBI0WRI?from=space_home_recent
    public var errorCode: Int32
    ///  用于 debug 的错误信息
    public var debugMessage: String
    /// 用于显示的错误信息
    public var displayMessage: String
    /// 服务器返回错误信息
    @available(*, deprecated, message: "use displayMessage instead")
    public var serverMessage: String
    /// 用于pc显示特殊错误的 title 信息
    public var userErrTitle: String
    /// request id
    public var requestID: String
    /// error类型，一般为网络库报错的错误码，由SDK透传
    /// https://bytedance.us.feishu.cn/docx/CIB8dpNYjoUNvvxywiacRTclnXf
    public var errorStatus: Int32
    /// 安全字段
    public var errorExtra: String

    public var ttLogId: String?
    /// init
    public init(
        code: Int32,
        errorStatus: Int32,
        errorCode: Int32,
        debugMessage: String,
        displayMessage: String,
        serverMessage: String,
        userErrTitle: String,
        requestID: String,
        errorExtra: String = "",
        ttLogId: String? = nil
    ) {
        self.code = code
        self.errorCode = errorCode
        self.debugMessage = debugMessage
        self.displayMessage = displayMessage
        self.serverMessage = serverMessage
        self.userErrTitle = userErrTitle
        self.requestID = requestID
        self.errorStatus = errorStatus
        self.errorExtra = errorExtra
        self.ttLogId = ttLogId
    }

    /// 通过 LarkError init
    public init(_ larkError: LarkError) {
        self.init(
            code: larkError.mappedCode,
            errorStatus: larkError.status,
            errorCode: larkError.code,
            debugMessage: larkError.details.debugMessage,
            displayMessage: larkError.displayMessage,
            serverMessage: larkError.displayMessage,
            userErrTitle: larkError.displayTitle,
            requestID: larkError.details.serverRequestID,
            errorExtra: larkError.hasExtra ? String(data: larkError.extra, encoding: .utf8) ?? "" : "",
            ttLogId: larkError.details.xTtLogid
        )
    }
}

extension BusinessErrorInfo: CustomStringConvertible {
    public var description: String {
        return "code: \(self.code)," +
            "larkErrorCode: \(self.errorCode)," +
            "debugMessage: \(self.debugMessage)," +
            "displayMessage: \(self.displayMessage)," +
            "userErrTitle: \(self.userErrTitle)," +
            "requestID: \(self.requestID)," +
            "ttLogId: \(self.ttLogId)"
    }
}

extension BusinessErrorInfo: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "\(self)"
    }
}

public enum RCError: Error {
    case unknownRustSDKCommand(request: String)
    case requestSerializeFailure(error: Error)
    case responseSerializeFailure(error: Error)
    case invalidEmptyResponse
    case sdkErrorSerializeFailure(error: Error)
    case sdkError
    case transformFailure(error: Error)
    case businessFailure(errorInfo: BusinessErrorInfo)
    /// 内部取消，比如当client deinit时
    case cancel
    case inconsistentUserID
    case timedOut // 请求超时
    case unknownError(error: Error)
}

// MARK: - CustomStringConvertible

extension RCError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .businessFailure(let errorInfo):
            return "业务错误，ErrorInfo: \(errorInfo)"
        case .invalidEmptyResponse:
            return "无效的空请求结果.(RustSDK未返回Response)"
        case .requestSerializeFailure(let error):
            return "RustSDK Request Protobuf 请求序列化失败, \(error)"
        case .responseSerializeFailure(let error):
            return "RustSDK Response Protobuf 返回值序列化失败, \(error)"
        case .sdkErrorSerializeFailure(let error):
            return "RustSDK LarkError Protobuf 错误数据序列化失败, \(error)"
        case .sdkError:
            return "RustSDK 其他错误"
        case .unknownRustSDKCommand(let request):
            return "无法识别的RustSDK Request，解析Command失败, \(request)"
        case .transformFailure(let error):
            return "Rust返回数据模型转化失败, \(error)"
        case .cancel:
            return "Service被释放，回调被取消"
        case .timedOut:
            return "请求超时"
        case .inconsistentUserID:
            return "不一致的sdkUserID"
        case .unknownError(let error):
            return "未知错误, \(error)"
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension RCError: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "\(self)"
    }
}

// MARK: - LocalizedError

extension RCError: LocalizedError {
    public var errorDescription: String? {
        return "\(self)"
    }
}

// MARK: rust修改了错误码，但是业务广泛使用了旧的业务码，这里映射回老的值
extension LarkError {
    // disable-lint: magic number
    var mappedCode: Int32 {
        if status == 599 { return code }
        switch code {
        case 100_000: return 10_000
        case 100_001: return 10_014
        case 100_002: return 10_015
        case 100_011: return 10_024
        case 100_012: return 10_025
        case 100_013: return 10_001
        case 100_014: return 10_002
        case 100_015: return 10_006
        case 100_016: return 10_005
        case 100_052: return 10_008
        case 100_053: return 10_018
        case 100_054: return 10_009
        case 100_101: return 10_003
        case 100_151: return 10_013
        case 100_152: return 10_020
        case 100_153: return 10_021
        case 100_201: return 10_029
        case 101_001: return 10_022
        case 101_002: return 10_017
        case 102_001: return 10_010
        case 102_002: return 10_026
        case 102_003: return 10_011
        case 102_004: return 10_016
        case 103_001: return 10_027
        case 103_002: return 10_028
        case 104_001: return 10_023
        case 105_001: return 10_019
        case 105_002: return 10_030
        default: return code
        }
    }
    // enable-lint: magic number
}
