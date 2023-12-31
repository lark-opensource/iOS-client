//
//  HTTPError.swift
//  ECOInfra
//
//  Created by MJXin on 2021/10/24.
//

import Foundation

public struct HttpError: Error {
    public let code: Int
    public let msg: String?
}


/// 网络错误
public enum ECONetworkError: Error {

    //MARK: ✅ 预期的业务错误
    
    /// 服务端返回 http code
    /// 由 ECONetworkStatusCodeValidator 决定哪些 Code 会被作为错误返回, 默认是 200...<300
    case http(HttpError)
    
    /// 请求被取消
    /// 来源: 调用方主动取消
    case cancel
    
    /// 中间件产生的错误, 由中间件产生的错误都包装在这个 case 中
    /// 错误来源: 业务 middleware 抛出
    case middewareError(Error)
    
    /// 未通过校验
    case validateFail(Error)
    
    //MARK: 🅾️ 代码错误: 若触发了下面错误类型, 证明有 bug
    
    /// 内部错误, 代码出问题了
    /// 错误来源:  NetworkService 内部代码异常,  联系 @majiaxin.jx 处理
    case innerError(OPError)
    
    /// 网络错误, 请求无法到达服务端或者无法收到响应
    /// 错误来源: URLSession 网络请求失败, 内为 URLSession 报错
    case networkError(Error)
    
    /// 请求错误, 请求数据有问题, 优先检查 URL, 其次检查必要参数, 如 upload 场景的 body,url 等
    /// 错误来源: ECONetworkRequest, 内为 URLRequest 生成报错
    case requestError(Error)
    
    /// 响应错误, 响应数据有问题
    /// 错误来源: ECONetworkResponse
    case responseError(Error)
    
    /// 序列化 reqeust 失败, serilizer 与 request 不匹配或 request 数据异常导致
    /// 错误来源: RequestSerilizer 抛出, 内为序列化器抛错
    case serilizeRequestFail(Error)
    
    /// 序列化 response 失败, serilizer 与 response 不匹配或 response 数据异常导致
    /// 错误来源: ResponseSerilizer 抛出, 内为序列化器抛错
    case serilizeResponseFail(Error)
    
    /// 未知, 尽量不要归类到此
    case unknown(Error)
    
    //MARK: 构造函数
    
    static func responseTypeError(detail: String) -> Self {
        return .responseError(OPError.invalidSerializedType(detail: detail))
    }
    
    static func requestParamsError(detail: String) -> Self {
        return .requestError(OPError.createTaskWithWrongParams(detail: detail))
    }
    
    static func pipelineError(msg: String?) -> Self {
        return .innerError(OPError.missRequireParams(detail: msg))
    }
    
    static func stepsError(msg: String?) -> Self {
        .innerError(OPError.missRequireParams(detail: msg))
    }
}

fileprivate extension ECONetworkError {
    var nsError: (nsError: NSError, errorType: String)  {
        var errorType = ""
        var nsError = self as NSError
        switch self {
        case .http(let httpError):
            nsError = httpError as NSError
            errorType = "http"
            break
        case .middewareError(let middlewareError):
            nsError = middlewareError as NSError
            errorType = "middewareError"
            break
        case .validateFail(let validateError):
            nsError = validateError as NSError
            errorType = "validateFail"
            break
        case .innerError(let innerError):
            nsError = (innerError.originError ?? innerError) as NSError
            errorType = "innerError"
            break
        case .networkError(let networkError):
            nsError = networkError as NSError
            errorType = "networkError"
            break
        case .requestError(let requestError):
            nsError = requestError as NSError
            errorType = "requestError"
            break
        case .responseError(let responseError):
            nsError = responseError as NSError
            errorType = "responseError"
            break
        case .serilizeRequestFail(let serializeError):
            nsError = serializeError as NSError
            errorType = "serilizeRequestFail"
            break
        case .serilizeResponseFail(let serializeError):
            nsError = serializeError as NSError
            errorType = "serilizeResponseFail"
            break
        case .unknown(let unknownError):
            nsError = unknownError as NSError
            errorType = "unknown"
            break
        case .cancel:
            nsError = NSError(domain: "Cancel", code: -1)
            errorType = "cancel"
            break
        }
        return (nsError, errorType)
    }
}

struct ECONetworkErrorWapper {
    let errorCode: Int
    let errorMessage: String

    var larkErrorCode: Int?
    var larkErrorStatus: Int?

    init?(error: ECONetworkError?) {
        guard let error = error else {
            return nil
        }
        let nsError = error.nsError.nsError
        let errorMsgPrefix = error.nsError.errorType

        larkErrorCode = nsError.userInfo["larkErrorCode"] as? Int
        larkErrorStatus = nsError.userInfo["larkErrorStatus"] as? Int

        errorCode = nsError.code
        errorMessage = "\(errorMsgPrefix): \(nsError.localizedDescription)"
    }
}
