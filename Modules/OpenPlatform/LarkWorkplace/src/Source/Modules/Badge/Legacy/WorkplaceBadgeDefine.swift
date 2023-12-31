//
//  WorkplaceBadgeDefine.swift
//  LarkWorkplace
//
//  Created by lilun.ios on 2020/12/22.
//

import Foundation
import LarkWorkplaceModel
/// Badge 相关通知
enum WorkPlaceBadge {
    enum Noti: String, NotificationName {
        case badgePush = "workplace.badge.push"
        case badgeUpdate = "workplace.badge.update"
    }

    struct BadgeSingleKey: Codable {
        let appId: String
        let clientType: WPBadge.ClientType
        let ability: WPBadge.AppType

        func key() -> String {
            return "\(appId)_\(ability)"
        }

        init(appId: String, ability: WPBadge.AppType, clientType: WPBadge.ClientType = .mobile) {
            self.appId = appId
            self.ability = ability
            self.clientType = clientType
        }
    }
}

typealias WorkPlaceBadgeKey = [WorkPlaceBadge.BadgeSingleKey]
