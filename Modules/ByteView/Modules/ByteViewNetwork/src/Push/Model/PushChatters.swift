//
//  PushChatters.swift
//  ByteViewNetwork
//
//  Created by fakegourmet on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Basic_V1_Entity
/// - PUSH_CHATTERS = 5010
public struct ChattersEntity {
    public init(users: [String: User]) {
        self.users = users
    }

    public var users: [String: User]
}

extension ChattersEntity: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Basic_V1_Entity
    init(pb: Basic_V1_Entity) {
        self.users = pb.chatters.mapValues { $0.toUser() }
    }
}

extension ChattersEntity: CustomStringConvertible {
    public var description: String {
        if users.count > 10 {
            return String(indent: "ChattersEntity", "users: count=\(users.count)")
        } else {
            return String(indent: "ChattersEntity", "users: \(users.values)")
        }
    }
}
