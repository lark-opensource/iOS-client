//
//  PushUserRecentEmoji.swift
//  ByteViewNetwork
//
//  Created by lutingting on 2022/8/19.
//

import Foundation
import ServerPB

/// PUSH_USER_RECENT_EMOJI = 89314
/// - ServerPB_Videochat_UserRecentEmojiEvent
public struct UserRecentEmojiEvent {
    public var userId: String
    public var recentEmoji: [String]
}

extension UserRecentEmojiEvent: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = ServerPB_Videochat_UserRecentEmojiEvent
    init(pb: ServerPB_Videochat_UserRecentEmojiEvent) {
        self.userId = pb.userID
        self.recentEmoji = pb.recentEmoji
    }
}
