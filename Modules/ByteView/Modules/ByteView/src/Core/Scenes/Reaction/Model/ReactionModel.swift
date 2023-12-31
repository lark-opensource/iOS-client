//
//  ReactionModel.swift
//  ByteView
//
//  Created by yangfukai on 2020/12/15.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

class ReactionMessage {
    let userId: String
    let userName: String
    let avatarInfo: AvatarInfo
    let userType: ParticipantType
    let userRole: ParticipantRole
    let reactionKey: String
    var count: Int = 1
    var isShowing = false
    var startTime: Double = Date().timeIntervalSince1970
    var duration: TimeInterval = 0

    init(userId: String,
         userName: String,
         avatarInfo: AvatarInfo,
         userType: ParticipantType,
         userRole: ParticipantRole,
         reactionKey: String) {
        self.userId = userId
        self.userName = userName
        self.avatarInfo = avatarInfo
        self.userType = userType
        self.userRole = userRole
        self.reactionKey = reactionKey
    }

    func isEqual(_ other: ReactionMessage?) -> Bool {
        if let other = other {
            return self.userId == other.userId && self.reactionKey == other.reactionKey
        }
        return false
    }
}

struct Reaction {
    let key: String
    let size: CGSize

    init(key: String, emotion: EmotionDependency) {
        self.key = key
        self.size = emotion.imageByKey(key)?.size ?? CGSize(width: 28, height: 28)
    }
}
