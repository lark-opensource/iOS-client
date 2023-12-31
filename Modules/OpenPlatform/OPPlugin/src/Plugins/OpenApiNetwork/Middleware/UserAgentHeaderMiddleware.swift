//
//  UserAgentHeaderMiddleware.swift
//  OPPlugin
//
//  Created by zhangxudong on 3/10/22.
//

import ECOInfra
import OPPluginManagerAdapter
/// 开放平台 UA 中间件
struct UserAgentHeaderMiddleware: ECONetworkMiddleware {
    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest, Error> {
        var request = request
        if let bapUA = BDPUserAgent.getString(),
            !bapUA.isEmpty {
            let userAgent = ["User-Agent": bapUA]
            request.mergingHeaderFields(with: userAgent)
        }
        return .success(request)
    }
}
