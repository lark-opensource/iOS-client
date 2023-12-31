//
//  ProjectServiceImpl.swift
//  LarkMeegoProjectBiz
//
//  Created by shizhengyu on 2023/4/14.
//

import Foundation
import LarkContainer
import LarkMeegoStorage
import LarkAccountInterface

private enum Agreement {
    static let innerDomainTenantId = "1"
}

class ProjectServiceImpl: ProjectService {
    private let passportUserService: PassportUserService
    private lazy var userSpStorage: UserSharedSpStorage = {
        return UserSharedSpStorage(associatedUserId: self.passportUserService.user.userID)
    }()

    init(userResolver: UserResolver) throws {
        passportUserService = try userResolver.resolve(assert: PassportUserService.self)
    }

    func cachedProjectKey(by simpleName: String) -> String? {
        if simpleName.isEmpty {
            return nil
        }
        let domainType = passportUserService.userTenant.tenantID == Agreement.innerDomainTenantId ? "meego" : "project"
        return try? userSpStorage.getString(with: "project_service_name2key(\(domainType))_\(simpleName)")
    }
}
