//
//  DomainMiddleware.swift
//  OPPlugin
//
//  Created by zhangxudong on 3/10/22.
//

import ECOInfra
import LarkAppConfig
import LarkContainer
import LarkSetting
/// 开放平台 Domain 中间件
struct DomainMiddleware: ECONetworkMiddleware {
    private var appConfiguration: AppConfiguration {
        Injected<AppConfiguration>().wrappedValue
    }
    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest,Error> {
        var request = request
        guard let domain = DomainSettingManager.shared.currentSetting[.open]?.first else {
            return .failure(DomainMiddlewareError.hasNoOpenDomain)
        }
        request.domain =  domain
        return .success(request)
    }
}
/// Domain Error
enum DomainMiddlewareError: String, Error {
    /// 没有找到相应doamin 不应该发生的错误
    case hasNoOpenDomain
}
