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

public typealias UserNameFormatRule = Contact_V1_GetAnotherNameFormatResponse.FormatRule

final class DepartmentAPI {
    let userAPI: UserAPI
    init(userAPI: UserAPI) {
        self.userAPI = userAPI
    }

    func fetchDepartmentStructure(departmentId: String,
                                  offset: Int,
                                  count: Int,
                                  extendParam: RustPB.Contact_V1_ExtendParam) -> Observable<DepartmentWithExtendFields> {
        return userAPI.fetchDepartmentStructure(departmentId: departmentId, offset: offset, count: count, extendParam: extendParam)
    }

    func isSuperAdministrator() -> Observable<Bool> {
        return userAPI.isSuperAdministrator()
    }

    func isSuperOrDepartmentAdministrator() -> Observable<Bool> {
        return userAPI.isSuperOrDepartmentAdministrator()
    }

    func getAnotherNameFormat() -> Observable<UserNameFormatRule> {
        return userAPI.getAnotherNameFormat()
    }
}
