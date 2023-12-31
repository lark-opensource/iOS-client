//
//  OpenAPIBaseResponse.swift
//  LarkOpenApis
//
//  Created by lixiaorui on 2021/2/1.
//

import UIKit

open class OpenAPIBaseResult {
    
    public init() {}

    open func toJSONDict() -> [AnyHashable: Any] {
        assertionFailure("please implement in subclass")
        return [:]
    }
}

public enum OpenAPIBaseResponse<Result: OpenAPIBaseResult> {
    case failure(error: OpenAPIError)
    case success(data: Result?)
    case `continue`(event: String, data: Result?) // 与webview统一bridge协议保持一致，表示向js持续发送消息
}

public typealias OpenAPISimpleResponse = OpenAPIBaseResponse<OpenAPIBaseResult>
public typealias OpenAPISimpleCallback = (OpenAPISimpleResponse) -> Void

public final class OpenAPIError: NSObject, Error {

    // 对内/外错误码，由配置平台配置
    public let code: OpenAPIErrorCodeProtocol

    // 详细错误: 一般直接塞入
    public private(set) var detailError: Error?

    // 对内错误信息：会接入到实时埋点中，用于监控诊断
    public private(set) var monitorMsg: String?

    // 内部错误 Code: API 埋点使用
    // TODO: (meng) 目前仅为兼容 network，长期需要设计业务扩展性字段
    public private(set) var innerCode: Int?

    // 对外错误码：会以errCode:XXX的形式返回给业务方，理论上最终也由平台生成，这里为了兼容已对外的错误码
    public private(set) var outerCode: Int?

    // 对外错误信息：会以errMsg:XXX的形式返回给业务方，理论上最终也由平台生成，这里为了兼容已对外的错误信息
    public private(set) var outerMessage: String?

    // 错误情况下的附加信息，部分接口在错误时需要返回其他信息
    // key中含有errMsg同时setOuterMessage时，对外返回的errMsg会以setOuterMessage的值为准
    // key中含有errCode同时setOuterCode时，对外返回的errCode会以setOuterCode的值为准
    public private(set) var additionalInfo: [AnyHashable: Any] = [:]
    
    /// 加入 errno 及 errstring 逻辑包装
    public var errnoInfo: [String: Any] {
        var errno: Int?
        var errstring: String?
        if let errnoError = errnoError {
            errno = errnoError.errnoValue
            errstring = errnoError.errString
        }
        var data: [String: Any] = [:]
        data["errno"] = errno
        data["errString"] = errstring
        return data
    }
    
    public private(set) var errnoError: OpenAPIErrnoError?
    
    public final class OpenAPIErrnoError {
        let errno: OpenAPIErrnoProtocol
        init(errno: OpenAPIErrnoProtocol) {
            self.errno = errno
        }
        public var errString: String {
            errno.errString
        }
        
        public var errnoValue: Int {
            errno.errno()
        }
    }
    
    /// 设置 errno
    /// - Parameters:
    ///   - errno:
    ///   - msg: 设置 msg，该 msg 会强制覆盖掉 errno 原本的 msg
    /// - Returns: OpenAPIError 对象
    @discardableResult
    public func setErrno(_ errno: OpenAPIErrnoProtocol) -> OpenAPIError {
        errnoError = .init(errno: errno)
        return self
    }
    
    @discardableResult
    public func setError(_ error: Error?) -> OpenAPIError {
        self.detailError = error
        return self
    }

    @discardableResult
    public func setAddtionalInfo(_ info: [AnyHashable: Any]) -> OpenAPIError {
        self.additionalInfo = info
        return self
    }

    // 最终需要对外暴露的是APICode平台拉下来的三端一致的code，此处用于兼容线上版本
    // 透出给业务方的code策略: 优先返回outerCode，其次返回code的outerErrorCode
    @available(*, deprecated, message: "不允许裸塞 outerCode 了，存量的即将被改造，建议使用 OpenAPIErrorCodeProtocol")
    @discardableResult
    public func setOuterCode(_ code: Int) -> OpenAPIError {
        self.outerCode = code
        return self
    }

    // 最终需要对外暴露的是APICode平台拉下来的三端一致的message，此处用于兼容线上版本
    // 透出给业务方的message策略: 优先返回outerMessage，其次返回code的outerErrorMessage
    @discardableResult
    public func setOuterMessage(_ message: String) -> OpenAPIError {
        self.outerMessage = message
        return self
    }

    // 内部诊断使用的message
    @discardableResult
    public func setMonitorMessage(_ msg: String) -> OpenAPIError {
        self.monitorMsg = msg
        return self
    }

    /// 设置 monitorCode，加在 API 埋点信息
    @discardableResult
    public func setMonitorCode(_ code: Int) -> OpenAPIError {
        self.innerCode = code
        return self
    }

    /// API错误
    /// - Parameters:
    ///   - code: 平台配置的错误枚举
    ///   - filename: 自动填入无需传入
    ///   - function: 自动填入无需传入
    ///   - line: 自动填入无需传入
    public init(
        code: OpenAPIErrorCodeProtocol,
        filename: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        // TODO:(meng) API Code 实现比较完整后考虑做成初始化校验而不是 assert 提示。
        assert(code is _OpenAPIErrorCodeProtocol, "对外的 API Code 不允许在 LarkOpenAPIModel 外部定义")
        self.code = code
        super.init()
    }
    
    /// API errno 错误
    /// - Parameters:
    ///   - errno: errno 按照业务域功能域及异常码组成的唯一错误描述
    ///   - msg: 额外的一些错误信息
    ///   - filename: 自动填入无需传入
    ///   - function: 自动填入无需传入
    ///   - line: 自动填入无需传入
    public init(
        errno: OpenAPIErrnoProtocol,
        msg: String? = nil,
        filename: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        self.errnoError = .init(errno: errno)
        self.code = OpenAPICommonErrorCode.errno
        super.init()
    }

    public override var description: String {
        var result = ""
        if let innerMsg = monitorMsg {
            result += "innerMsg: \(innerMsg)"
        }
        if let innerCode = innerCode {
            result += ", innerCode: \(innerCode)"
        }
        if let outerCode = outerCode {
            result += ", outerCode: \(String(outerCode))"
        }
        if let outerMessage = outerMessage {
            result += ", outerMessage: \(outerMessage)"
        }
        if let errnoError = errnoError {
            result += ", errno: \(errnoError.errnoValue), errString: \(errnoError.errString)"
        }
        if result.isEmpty {
            result = code.description
        } else {
            result += ", \(code.description)"
        }
        return result
    }
}
