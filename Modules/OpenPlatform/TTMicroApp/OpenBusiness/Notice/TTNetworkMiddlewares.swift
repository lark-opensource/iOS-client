//
//  TTNetworkMiddlewares.swift
//  TTMicroApp
//
//  Created by ChenMengqi on 2021/8/9.
//

import Foundation
import ECOInfra
import LKCommonsLogging
import RustPB
import LarkAccountInterface
import LarkAppConfig
import LarkContainer

typealias DomainSettings = RustPB.Basic_V1_DomainSettings

class TTSessionInjector: ECONetworkMiddleware {
    private static let logger = Logger.oplog(TTSessionInjector.self, category: "TTMicroApp")
    
    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest, Error> {
        var request = request
        var sessionHeader = ["Cookie":"session=" + AccountServiceAdapter.shared.currentAccessToken]
        request.mergingHeaderFields(with: sessionHeader)
        return .success(request)
    }
}

class TTDomainMiddleware: ECONetworkMiddleware {
    private var appConfiguration: AppConfiguration {
        Injected<AppConfiguration>().wrappedValue
    }
    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest,Error> {
        var request = request
        request.domain = appConfiguration.settings[.openAppInterface]?.first ?? ""
        return .success(request)
    }
}

class TTResponseVerifyMiddleware: ECONetworkMiddleware {
    
    func didCompleteRequest<ResultType>(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest,
        response: ECONetworkResponse<ResultType>
    ) -> Result<Void, Error> {
        if response.bodyData == nil {
            // 旧逻辑,与原先保持一致
            let msg = "invaild data"
            let error = NSError(domain: msg, code: -9999, userInfo: [NSLocalizedDescriptionKey: msg])
            return .failure(error)
        } else {
//            let str = String(decoding: response.bodyData!, as: UTF8.self)
            return .success(())
        }
    }
}



