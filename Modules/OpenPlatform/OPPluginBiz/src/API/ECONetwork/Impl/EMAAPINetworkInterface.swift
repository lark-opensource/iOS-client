//
//  EMAAPINetworkInterface.swift
//  EEMicroAppSDK
//
//  Created by xiangyuanyuan on 2021/8/24.
//

import Foundation
import LarkContainer
import LKCommonsLogging

// 请求后端鉴权接口
public final class EMAAPINetworkInterface {
    
    static let logger = Logger.oplog(EMAAPINetworkInterface.self, category: "ECONetwork")
    
    private static var service: ECONetworkService {
        return Injected<ECONetworkService>().wrappedValue
    }
    
    public static func webVerify(
        with context: ECONetworkServiceContext,
        needSession: Bool,
        parameters: [String: Any],
        completionHandler: @escaping ([String: Any]?, Error?) -> Void
    ) {
        var task = Self.service.createTask(
            context: context,
            config: WebVerifyRequestConfig.self,
            params: parameters,
            callbackQueue: DispatchQueue.main
        ) { (response, error) in
            var logID = (response?.response.allHeaderFields["x-tt-logid"]) ?? "empty logid"
            logger.info("config verify logid: \(logID), error:\(error)")
            completionHandler(response?.result, error)
        }
        
        if !needSession {
            task = Self.service.createTask(
                context: context,
                config: WebVerifyWithoutSessionRequestConfig.self,
                params: parameters,
                callbackQueue: DispatchQueue.main
            ) { (response, error) in
                completionHandler(response?.result, error)
            }
        }
        guard let requestTask = task else {
            assertionFailure("create task fail")
            Self.logger.error("create task fail \(context.getTrace().traceId)")
            let opError = OPError.error(monitorCode: CommonMonitorCode.fail)
            completionHandler(nil, opError)
            return
        }
        service.resume(task: requestTask)
    }
    
}
