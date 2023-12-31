//
//  DepartmentAPI.swift
//  LarkContact
//
//  Created by tangyunfei.tyf on 2021/3/4.
//

import Foundation
import RustPB
import RxSwift
import Swinject
import LarkSDKInterface
import LarkMessengerInterface

final class CollaborationDepartmentAPI {
    let userAPI: UserAPI
    init(userAPI: UserAPI) {
        self.userAPI = userAPI
    }

    func fetchDepartmentStructure(tenantId: String,
                                  departmentId: String,
                                  offset: Int,
                                  count: Int,
                                  extendParam: RustPB.Contact_V1_CollaborationExtendParam) -> Observable<CollaborationDepartmentWithExtendFields> {
        return userAPI.fetchCollaborationDepartmentStructure(tenantId: tenantId, departmentId: departmentId, offset: offset, count: count, extendParam: extendParam)
    }

    func fetchCollaborationTenant(offset: Int, count: Int, showConnectType: AssociationContactType?, query: String? = nil) -> Observable<CollaborationTenantModel> {
        var isInternal: Bool?
        if let showConnectType = showConnectType {
            switch showConnectType {
            case .external:
                isInternal = false
            case .internal:
                isInternal = true
            @unknown default:
                isInternal = nil
            }
        }
        return userAPI.fetchCollaborationTenant(offset: offset, count: count, isInternal: isInternal, query: query)
    }

    func isSuperAdministrator() -> Observable<Bool> {
        return userAPI.isSuperAdministrator()
    }
}
