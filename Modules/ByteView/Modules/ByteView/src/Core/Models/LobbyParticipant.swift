//
//  LobbyParticipant.swift
//  ByteView
//
//  Created by kiri on 2021/4/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork

extension LobbyParticipant {
    // 判断是否是 External 参会人
    // 详细参见：https://bytedance.feishu.cn/docs/doccndN4VK3AYa6XK1VZfpBumQc#
    func isExternal(localParticipant: Participant?) -> Bool {
        guard let localParticipant = localParticipant else { return false }

        if identifier == localParticipant.identifier { // 本地用户
            return false
        }

        if localParticipant.tenantTag != .standard { // 自己是小 B 用户，则不关注 external
            return false
        }

        // 自己或者别人是 Guest，都不展示外部标签
        if localParticipant.isLarkGuest || isLarkGuest {
            return false
        }

        // 当前用户租户 ID 未知
        if tenantId == "" || tenantId == "-1" {
            return false
        }

        let userType = user.type
        if userType == .larkUser || userType == .room || userType == .neoUser || userType == .neoGuestUser || userType == .standaloneVcUser || (userType == .pstnUser && bindType == .lark) {
            return tenantId != localParticipant.tenantId
        } else {
            return false
        }
    }
}
