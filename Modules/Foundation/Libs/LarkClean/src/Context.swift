//
//  Context.swift
//  LarkClean
//
//  Created by 7Up on 2023/6/28.
//

import Foundation

/// 触发磁盘清理的上下文
public struct CleanContext: Codable {
    /// 表示用户信息
    public struct User: Codable {
        public let userId: String
        public let tenantId: String

        enum CodingKeys: String, CodingKey {
            case userId
            case tenantId
        }

        public init(userId: String, tenantId: String) {
            self.userId = userId
            self.tenantId = tenantId
        }
    }

    /// 表示退出登录的用户
    public let userList: [User]

    public init(userList: [User]) {
        self.userList = userList
    }

    var logInfo: String {
        "uids: \(userList.map(\.userId)), tids: \(userList.map(\.tenantId))"
    }
}
