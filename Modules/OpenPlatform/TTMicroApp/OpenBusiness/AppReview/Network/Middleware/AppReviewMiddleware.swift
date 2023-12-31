//
//  AppReviewPathMiddleware.swift
//  TTMicroApp
//
//  Created by xiangyuanyuan on 2021/12/22.
//

import Foundation
import ECOInfra
import LarkAppConfig
import LarkContainer
import LarkOpenPluginManager
import LarkAccountInterface
import LarkEnv

/// syncAppReview path拼接中间件
class AppReviewSyncPathMiddleware: ECONetworkMiddleware {

    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest, Error> {
        guard let context = task.context as? AppReviewContext else {
            return .failure(OPError.incompatibleResultType(detail: "AppReviewSyncPathMiddleware fail because appid is nil"))
        }
        var request = request
        request.path += "\(context.appId)/score"
        return .success(request)
    }
}

/// AppReview  frequency path拼接中间件
class AppReviewFrequencyPathMiddleware: ECONetworkMiddleware {

    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest, Error> {
        guard let context = task.context as? AppReviewContext else {
            return .failure(OPError.incompatibleResultType(detail: "AppReviewFrequencyPathMiddleware fail because appid is nil"))
        }
        var request = request
        request.path += "\(context.appId)/api/frequency_check"
        return .success(request)
    }
}

class AppReviewDomainMiddleware: ECONetworkMiddleware {
    private var appConfiguration: AppConfiguration {
        Injected<AppConfiguration>().wrappedValue
    }
    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest,Error> {
        var request = request
        request.domain = appConfiguration.settings[.internalApi]?.first ?? ""
        return .success(request)
    }
}

class AppReviewHeaderInjector: ECONetworkMiddleware {
    
    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest, Error> {
        let larkSession = AccountServiceAdapter.shared.currentAccessToken
        var request = request
        request.mergingHeaderFields(with: ["Cookie": "session=\(larkSession)"])
        return .success(request)
    }
}

