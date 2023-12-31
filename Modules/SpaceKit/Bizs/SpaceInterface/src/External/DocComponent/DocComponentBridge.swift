//
//  DocComponentBridge.swift
//  SpaceInterface
//
//  Created by lijuyou on 2023/5/18.
//  


import Foundation


public protocol DocComponentBridgeHandler {
    
    /// 业务模块标识
    var module: String { get }
    
    /// 场景标识，不为nil时仅此场景打开文档会注册此Bridge，为nil则所有情况都注册
    var sceneID: String? { get }
    
    func handle(name: String,
                params: [String: Any],
                callback: DocComponentAPICallbackProtocol?,
                context: DocBridgeContext)
}

public protocol DocBridgeContext {
    var docsAPI: DocComponentAPI? { get }
}

/// 回调/消息发送 类型
public enum DocComponentAPICallBackType: String {
    /// 成功
    case success
    /// 失败
    case failure
    /// 取消
    case cancel
}

public protocol DocComponentAPICallbackProtocol {
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
        error: Error?
    )
    
    /// 取消回调
    /// - Parameters:
    ///   - param: API回调参数
    ///   - extra: 额外业务字段
    func callbackCancel(
        param: [String: Any],
        extra: [AnyHashable: Any]?
    )
}

