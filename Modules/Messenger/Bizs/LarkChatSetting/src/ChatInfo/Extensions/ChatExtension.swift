//
//  ChatExtension.swift
//  LarkChatSetting
//
//  Created by 姜凯文 on 2020/4/15.
//

import Foundation
import LarkModel
import LarkFeatureGating

extension Chat {
    func chatCanBeShared(currentUserId: String) -> Bool {
        // 单聊
        if self.type == .p2P {
            if self.chatter?.type == .bot || self.chatterHasResign || self.chatter?.type == .ai {
                return false
            }
            return true
        } else {
            // 群聊
            if self.isCrypto || self.isOncall || self.isFrozen { return false }
            let isAdmin = self.isGroupAdmin
            let groupCanBeShared = self.ownerId == currentUserId || isAdmin || self.shareCardPermission == .allowed
            return groupCanBeShared
        }
    }
}
