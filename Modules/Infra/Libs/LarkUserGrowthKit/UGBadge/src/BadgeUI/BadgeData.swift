//
//  BadgeData.swift
//  UGBadge
//
//  Created by liuxianyu on 2021/11/26.
//

import Foundation
import ServerPB

public typealias BadgeInfo = ServerPB_Ug_reach_material_BadgeMaterial

@dynamicMemberLookup
public struct LarkBadgeData: Equatable {

    let badgeInfo: BadgeInfo

    // Dynamic Member Lookup
    subscript<T>(dynamicMember keyPath: KeyPath<ServerPB.ServerPB_Ug_reach_material_BadgeMaterial, T>) -> T {
        return badgeInfo[keyPath: keyPath]
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.badgeInfo == rhs.badgeInfo
    }
}
