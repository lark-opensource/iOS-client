//
//  MineUGBadge.swift
//  LarkMine
//
//  Created by liuxianyu on 2021/12/1.
//

import UIKit
import Foundation

enum MineUGBadgeID: String {
    case privacy = "RP_USER_PRIVACY_BADGE"
    case agreement = "RP_USER_AGREEMENT_BADGE"
    case main = "RP_LOCAL_MINE_MAIN_BADGE"
    case setting = "RP_LOCAL_MINE_SETTING_BADEG"
    case about = "RP_LOCAL_MINE_ABOUT_BADGE"
    case upgrade = "RP_LOCAL_MINE_UPGRADE_BADGE"
}

enum MineUGBadgeScene: String {
    case setting = "SCENE_BADGE_SETTING"
}

struct MineBadgeNode {
    var isLeaf: Bool = false
    var leafIds: [String] = []
    var parentIds: [String] = []
    var badgeId: String
}

enum MineBadgeNodeStyle {
    case none
    case dot(UIColor = UIColor.ud.colorfulRed)
    case label(String)
    case upgrade
}
