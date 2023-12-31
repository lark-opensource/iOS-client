//
//  Badge+LogInfo.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/7/7.
//

import Foundation
import LarkWorkplaceModel

extension Rust.OpenAppBadgeNode: WorkplaceCompatible {}
extension WorkplaceExtension where BaseType == Rust.OpenAppBadgeNode {
    var logInfo: [String: String] {
        return [
            "feature": "\(base.feature)",
            "appId": base.appID,
            "needShow": "\(base.needShow)",
            "updateTime": base.updateTime,
            "badgeNum": "\(base.badgeNum)",
            "hasExtra": "\(base.hasExtra)",
            "extra.count": "\(base.extra.count)",
            "version": base.version
        ]
    }
}

extension WPBadge: WorkplaceCompatible {}
extension WorkplaceExtension where BaseType == WPBadge {
    var logInfo: [String: String] {
        return [
            "appAbility": "\(base.appAbility)",
            "id": base.appId,
            "version": "\(base.version)",
            "updateTime": "\(base.updateTime)",
            "badgeNum": "\(base.badgeNum)",
            "needShow": "\(base.needShow)"
        ]
    }
}

extension BadgeLoadType.LoadData: WorkplaceCompatible {}
extension WorkplaceExtension where BaseType == BadgeLoadType.LoadData {
    var logInfo: [String: String] {
        switch base {
        case .template(let templateData):
            return [
                "components": "\(templateData.components.map({ ($0.componentID, $0.groupType) }))",
                "components.count": "\(templateData.components.count)",
                "scene": "\(templateData.scene)",
                "portalId": templateData.portalId
            ]
        case .web(let webData):
            return [
                "badgeNodes": "\(webData.badgeNodes.map({ $0.wp.logInfo }))",
                "badgeNodes.count": "\(webData.badgeNodes.count)",
                "scene": "\(webData.scene)",
                "portalId": webData.portalId
            ]
        }
    }
}
