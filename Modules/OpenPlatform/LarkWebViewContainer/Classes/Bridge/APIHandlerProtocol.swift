//
//  APIHandlerProtocol.swift
//  LarkWebViewContainer
//
//  Created by 新竹路车神 on 2020/8/27.
//

import Foundation
import ECOInfra

/// 覆写提示
let overrideMessage = "please override it"

/// 错误回调使用的key
public let errMsgKey = "errMsg"

/// 套件统一Bridge协议Key
enum APIMessageKey: String {
    /// API 名字
    case apiName
    /// API 参数
    case data
    /// 回调ID
    case callbackID
    /// 额外业务字段
    case extra
    /// 回调类型
    case callbackType
}

/// 回调/消息发送 类型
public enum CallBackType: String {
    /// 成功
    case success
    /// 失败
    case failure
    /// 取消
    case cancel
    /// 发送消息
    case continued
}

/// API 数据结构
@objcMembers
public final class APIMessage: NSObject {
    /// API 名字
    public let apiName: String

    /// API 参数
    public let data: [String: Any]

    /// 回调ID
    public let callbackID: String?
    
    /// 额外业务字段
    public let extra: [AnyHashable: Any]?

    public init(
        apiName: String,
        data: [String: Any] = [String: Any](),
        callbackID: String? = nil,
        extra: [AnyHashable: Any]? = nil
    ) {
        self.apiName = apiName
        self.data = data
        self.callbackID = callbackID
        self.extra = extra
        super.init()
    }
}

/// API基础协议（套件统一API框架上线后废弃该结构）
public protocol APIHandlerProtocol {
    /// 是否在主线程执行
    var shouldInvokeInMainThread: Bool { get }

    /// API实现
    /// - Parameters:
    ///   - message: API 信息数据结构
    ///   - context: API 上下文
    ///   - apiCallback: 回调对象
    func invoke(
        with message: APIMessage,
        context: Any,
        callback: APICallbackProtocol
    )
}

/// API回调对象
public protocol APICallbackProtocol {
    /// 成功回调
    /// - Parameters:
    ///   - param: API回调参数
    ///   - extra: 额外业务字段
    func callbackSuccess(
        param: [String: Any],
        extra: [AnyHashable: Any]?
    )
    
    /// 失败回调
    /// - Parameters:
    ///   - param: API回调参数
    ///   - extra: 额外业务字段
    ///   - error: 用于埋点的错误对象
    func callbackFailure(
        param: [String: Any],
        extra: [AnyHashable: Any]?,
        error: OPError?
    )
    
    /// 取消回调
    /// - Parameters:
    ///   - param: API回调参数
    ///   - extra: 额外业务字段
    ///   - error: 用于埋点的错误对象
    func callbackCancel(
        param: [String: Any],
        extra: [AnyHashable: Any]?,
        error: OPError?
    )

    /// 发送消息
    /// - Parameters:
    ///   - param: 消息参数
    ///   - extra: 额外业务字段
    func callbackContinued(
        param: [String: Any],
        extra: [AnyHashable: Any]?
    )
    
    /// 发送消息
    /// - Parameters:
    ///   - event: 消息名称
    ///   - param: 消息参数
    ///   - extra: 额外业务字段
    func callbackContinued(
        event: String,
        param: [String: Any],
        extra: [AnyHashable: Any]?
    )
}

//  便利方法
public extension APICallbackProtocol {
    /// 成功回调便利方法
    func callbackSuccess() {
        callbackSuccess(param: [String: Any](), extra: nil)
    }
    func callbackSuccess(param: [String: Any]) {
        callbackSuccess(param: param, extra: nil)
    }

    /// 失败回调便利方法
    func callbackFailure() {
        callbackFailure(param: [String: Any](), extra: nil, error: nil)
    }
    func callbackFailure(param: [String: Any]) {
        callbackFailure(param: param, extra: nil, error: nil)
    }

    /// 取消回调便利方法
    func callbackCancel() {
        callbackCancel(param: [String: Any](), extra: nil, error: nil)
    }
    func callbackCancel(param: [String: Any]) {
        callbackCancel(param: param, extra: nil, error: nil)
    }

    /// 持续回调便利方法
    func callbackContinued() {
        callbackContinued(param: [String: Any](), extra: nil)
    }
    
    func callbackContinued(
        event: String,
        param: [String: Any],
        extra: [AnyHashable: Any]?
    ) {
        assertionFailure("请自定义APICallbackProtocol的对象实现该方法")
    }
}
