//
//  PermissionExemptRules.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/17.
//

import Foundation
import SpaceInterface

struct PermissionExemptRules: PermissionExemptConfig, Equatable {
    let shouldCheckFileStrategy: Bool
    let shouldCheckDLP: Bool
    let shouldCheckSecurityAudit: Bool
    let shouldCheckUserPermission: Bool

    static var `default`: PermissionExemptRules {
        return PermissionExemptRules()
    }

    static var userPermissionOnly: PermissionExemptRules {
        return PermissionExemptRules(shouldCheckFileStrategy: false,
                                     shouldCheckDLP: false,
                                     shouldCheckSecurityAudit: false,
                                     shouldCheckUserPermission: true)
    }

    init(shouldCheckFileStrategy: Bool = true,
         shouldCheckDLP: Bool = true,
         shouldCheckSecurityAudit: Bool = true,
         shouldCheckUserPermission: Bool = true) {
        self.shouldCheckFileStrategy = shouldCheckFileStrategy
        self.shouldCheckDLP = shouldCheckDLP
        self.shouldCheckSecurityAudit = shouldCheckSecurityAudit
        self.shouldCheckUserPermission = shouldCheckUserPermission
    }

}
