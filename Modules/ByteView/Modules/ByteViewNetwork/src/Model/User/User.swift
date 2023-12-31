//
//  User.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/9/7.
//

import Foundation
import ByteViewCommon
import RustPB

public struct User: Equatable {
    // 业务逻辑上需要将CustomStatus原封不动传给后端，因此此处仍然使用PB的数据结构
    public typealias CustomStatus = Basic_V1_Chatter.ChatterCustomStatus

    public let id: String
    public var name: String
    public var alias: String
    public var avatarInfo: AvatarInfo
    public var displayName: String
    public var anotherName: String
    public let workStatus: WorkStatus
    public let isRobot: Bool
    public let tenantId: String
    /// 是否未知用户
    public let isUnknown: Bool
    public let customStatuses: [CustomStatus]

    public var inMeetingName: String?
    /// 针对 pstn 绑定用户
    public var nickName: String?

    public init(id: String, name: String, displayName: String, anotherName: String, alias: String, avatarInfo: AvatarInfo, workStatus: WorkStatus, isRobot: Bool,
                tenantId: String, customStatuses: [CustomStatus]) {
        self.isUnknown = false
        self.id = id
        self.name = name
        self.alias = alias
        self.displayName = displayName
        self.anotherName = anotherName
        self.avatarInfo = avatarInfo
        self.workStatus = workStatus
        self.isRobot = isRobot
        self.tenantId = tenantId
        self.customStatuses = customStatuses
    }

    public init(unknown id: String) {
        self.isUnknown = true
        self.id = id
        self.name = I18n.View_VM_Unknown
        self.alias = ""
        self.displayName = ""
        self.anotherName = ""
        self.avatarInfo = .unknown
        self.workStatus = .default
        self.isRobot = false
        self.tenantId = ""
        self.customStatuses = []
    }
}

extension User {
    public enum WorkStatus: Int, Equatable {
        /// 默认
        case `default`
        /// 出差
        case business
        /// 请假
        case leave
        /// 开会
        case meeting
    }
}

extension User: CustomStringConvertible {
    public var description: String {
        String(
            indent: "User",
            "id: \(id)",
            "avatar: \(avatarInfo)",
            "tenantId: \(tenantId)",
            "isUnknown: \(isUnknown)",
            "hasName: \(!name.isEmpty)",
            "hasAnotherName: \(!anotherName.isEmpty)",
            "workStatus: \(workStatus)",
            "isRobot: \(isRobot)"
        )
    }
}
