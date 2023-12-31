//
//  Chat.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Basic_V1_Chat
public struct Chat {
    public init(id: String, type: TypeEnum, name: String, avatarKey: String, chatterID: String,
                tenantID: String, isCrossTenant: Bool, desc: String, userCount: Int32, lastMessagePosition: Int32) {
        self.id = id
        self.type = type
        self.name = name
        self.avatarKey = avatarKey
        self.chatterID = chatterID
        self.tenantID = tenantID
        self.isCrossTenant = isCrossTenant
        self.desc = desc
        self.userCount = userCount
        self.lastMessagePosition = lastMessagePosition
    }

    public var id: String

    public var type: TypeEnum

    public var name: String

    public var avatarKey: String

    /// P2P Chat
    public var chatterID: String

    public var tenantID: String

    public var isCrossTenant: Bool

    /// Group Chat
    public var desc: String

    public var userCount: Int32

    public var lastMessagePosition: Int32

    public enum TypeEnum: Int, Hashable {
        case unknown // = 0
        case p2P // = 1
        case group // = 2

        /// 小组类型
        case topicGroup // = 3
    }
}
