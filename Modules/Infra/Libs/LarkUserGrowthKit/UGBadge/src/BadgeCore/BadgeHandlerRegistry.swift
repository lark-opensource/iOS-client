//
//  BadgeHandlerRegistry.swift
//  UGBadge
//
//  Created by liuxianyu on 2021/11/26.
//

import Foundation

public protocol BadgeHandler {
    // 是否可展示
    func isBadgeEnable(badgeId: String) -> Bool
}

public extension BadgeHandler {
    func isBadgeEnable(badgeData: LarkBadgeData) -> Bool {
        return false
    }
}

public final class BadgeHandlerRegistry {
    var badgeHandlers: [String: BadgeHandler] = [:]

    public init() {}

    public func register(badgeName: String, for handler: BadgeHandler) {
        badgeHandlers[badgeName] = handler
    }

    public func getBadgeHandler(badgeName: String) -> BadgeHandler? {
        return badgeHandlers[badgeName]
    }
}
