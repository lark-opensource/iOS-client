//
//  LarkLynxBridgeMethodManager.swift
//  LarkLynxKit
//
//  Created by ByteDance on 2023/2/21.
//

import Foundation
import LKCommonsLogging

public final class LarkLynxBridgeMethodManager: NSObject {
    static let logger = Logger.oplog(LarkLynxBridgeMethodManager.self, category: LarkLynxDefines.larkLynxKit)
    private var bridgeMethods: [String: LarkLynxMethod] = [:]
    private let bridgeMethodsLock = DispatchSemaphore(value: 1)
    public static let shared = LarkLynxBridgeMethodManager()
    
    public func asyncCall(tag: String, apiName: String, params: [AnyHashable: Any]?, context: LarkLynxBridgeContext, callback: @escaping ([AnyHashable: Any]?) -> Void) {
        let bridgeMethod = checkBeforeCall(tag: tag, apiName: apiName)
        guard let bridgeMethod = bridgeMethod else {
            Self.logger.error("BridgeMethodManager: bridgeMethod is nil,tag:\(tag), apiName:\(apiName)")
            return
        }
        bridgeMethod.handle(params: params, context: context, callback: callback)
        
    }
    
    /// 在真正调用bridgeMethod前，进行一些通用检查，包括api是否配置、是否有对应实现、是否经过鉴权等
    /// - Parameters:
    ///   - apiName: 接口名
    /// - Returns: 对应接口是否在主线程运行、参数类型、插件类型、检查失败具体错误
    private func checkBeforeCall(
        tag: String,
        apiName: String
    ) -> LarkLynxMethod? {
        // check 该apiName是否注册
        guard let methodClass = LarkLynxInitializer.shared.getLynxBridgeMethods(tag: tag)?[apiName] as? LarkLynxMethod.Type else {
            return nil
        }
        
        let bridgeMethod = getBridgeMethodAndCreateIfNeeded(with: apiName, methodClass: methodClass)
        return bridgeMethod
    }
    
    private func getBridgeMethodAndCreateIfNeeded(
        with methodName: String,
        methodClass: LarkLynxMethod.Type
    ) -> LarkLynxMethod {
        bridgeMethodsLock.wait()
        defer {
            bridgeMethodsLock.signal()
        }
        if let method = bridgeMethods[methodName] {
            return method
        }
        let method = methodClass.init()
        bridgeMethods[methodName] = method
        return method
    }
    
}
