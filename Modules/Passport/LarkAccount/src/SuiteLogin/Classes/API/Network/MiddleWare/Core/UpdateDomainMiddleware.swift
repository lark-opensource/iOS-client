//
//  UpdateDomainMiddleware.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/9/29.
//

import Foundation
import LarkContainer
import LKCommonsLogging

// https://bytedance.feishu.cn/docx/Vi9FdXgF3o3JZQxay0qc9ZTQnw7
class UpdateDomainMiddleware: HTTPMiddlewareProtocol {
    static let logger = Logger.plog(UpdateDomainMiddleware.self, category: "UpdateDomainMiddleware")

    @Provider var helper: V3APIHelper

    func config() -> [HTTPMiddlewareAspect: HTTPMiddlewarePriority] {
        [
            .request: .lowest
        ]
    }

    func handle<ResponseData: ResponseV3>(request: PassportRequest<ResponseData>, complete: @escaping () -> Void) {
        defer { complete() }

        guard V3NormalConfig.enableChangeGeo else {
            return
        }

        if let domain = request.context.uniContext?.flowDomain {
            Self.logger.info("n_net_use_flow_domain", body: "domain: \(domain) path: \(request.path)")

            request.domain = domain
            request.host = helper.fetchDomain(domain)
        }

    }
}
