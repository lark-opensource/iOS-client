//
//  PullPermissionAPI.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/12/25.
//

import Foundation
import LarkRustClient
import LarkContainer
import RustPB
import ServerPB
import RxSwift
import LKCommonsLogging

final class PullPermissionAPI: UserResolverWrapper {

    enum APIError: Error {
        case rustIsNil
    }

    static let logger = Logger.log(PullPermissionAPI.self, category: "SecurityAudit.PullPermissionAPI")

    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    @ScopedProvider var client: RustService?

    func fetchPermissionTypeList(
        permVersion: String?
    ) -> Observable<ServerPB_Authorization_PullPermissionResponse> {
        guard let client else {
            return .error(APIError.rustIsNil)
        }
        var request = ServerPB.ServerPB_Authorization_PullPermissionRequest()
        let appId = Int64(SecurityAuditManager.shared.conf.appId)
        let apiVer = Const.apiVersion
        request.appID = appId
        request.apiVersion = apiVer
        if let permVer = permVersion {
            request.permVersion = permVer
        } else {
            request.permVersion = ""
        }
        Self.logger.info("pull permission", additionalData: [
            "appId": String(describing: appId),
            "appVer": apiVer,
            "permVer": String(describing: permVersion)
        ])
        return client.sendPassThroughAsyncRequest(request, serCommand: .pullPermission)
    }
}
