//
//  PingTenantRestrictFetcher.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/2/2.
//

import Foundation
import LarkContainer
import LarkSecurityComplianceInfra
import LarkAccountInterface
import RxSwift
import LarkSetting
import AppContainer

struct PingTenantRestrictFetcher {

    let userResolver: UserResolver

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        self.client = try userResolver.resolve(assert: HTTPClient.self)
    }

    private let client: HTTPClient

    func pingTenantRestrict() -> Observable<BaseResponse<TenantRestrictResp>> {
        guard let domain = DomainSettingManager.shared.currentSetting[.securityLoginRestriction]?.first else {
            return Observable.error(LSCError.domainInvalid)
        }
        return client.request(HTTPRequest(path: "/ping_tenant_restriction", domain: domain)).retry(2)
    }
}
