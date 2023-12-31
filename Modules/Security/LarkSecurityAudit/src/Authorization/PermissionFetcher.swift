//
//  PermissionFetcher.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/12/25.
//

import Foundation
import RxSwift
import ServerPB
import LarkContainer
import LarkSecurityComplianceInfra

final class PermissionFetcher {
    let pullPermissionAPI: PullPermissionAPI

    init(resolver: UserResolver) {
        pullPermissionAPI = PullPermissionAPI(userResolver: resolver)
    }

    var disposeBag = DisposeBag()

    func fetchPermissions(
        permVersion: String?,
        complete: @escaping (Result<ServerPB_Authorization_PullPermissionResponse, Error>) -> Void
    ) {
        disposeBag = DisposeBag()
        SCMonitor.info(business: .security_audit, eventName: "auth_request", category: ["permVer": permVersion ?? ""])

        self.pullPermissionAPI
            .fetchPermissionTypeList(permVersion: permVersion)
            .subscribe(onNext: { (resp) in
                complete(.success(resp))
            }, onError: { (error) in
                SCMonitor.error(business: .security_audit, eventName: "auth_request", error: error)
                complete(.failure(error))
            }).disposed(by: disposeBag)
    }

}
