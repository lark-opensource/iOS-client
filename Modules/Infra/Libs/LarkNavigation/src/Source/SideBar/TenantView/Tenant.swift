//
//  Tenant.swift
//  LarkNavigation
//
//  Created by Supeng on 2021/6/30.
//

import Foundation

enum TenantModel {
    case tenant(Tenant)
    case add
}

struct Tenant {

    enum TenantItemBadge {
        case none
        case number(Int)
        case new
    }

    let id: String
    let showIndicator: Bool
    var badge: TenantItemBadge
    let name: String
    let avatarKey: String
    let showExclamationMark: Bool
    let showShadow: Bool
}
