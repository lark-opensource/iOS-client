//
//  SearchUser.swift
//  ByteView
//
//  Created by kiri on 2021/11/19.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

enum SearchedUserStatus: Equatable {
    case idle // 空闲
    case inMeeting // 在当前会议中
    case busy // 忙碌, 别的会议
    case ringing // 电话中
    case inviting // 本次会议响铃
    case waiting // 等候中
}

struct SearchedUser: Equatable {
    let id: String
    let isExternal: Bool
    let name: String
    let avatarInfo: AvatarInfo
    let workStatus: User.WorkStatus
    var description: String?
    let status: SearchedUserStatus?
    let byteviewUser: ByteviewUser?
    let unsupportedRtcVersion: Bool

    /// https://bytedance.feishu.cn/wiki/wikcnJmMDsPDEG0OmEIW8gYvN8g
    /// 1. 若 executive_mode = true,  走原有高管模式逻辑
    /// 2. 若 executive_mode = false, 则进入协作权限判断
    let executiveMode: Bool
    var collaborationType: LarkUserCollaborationType?
    let tenantId: String?
    let crossTenant: Bool?
    let customStatuses: [User.CustomStatus]

    let isRobot: Bool

    // 会中信息
    let participant: Participant?
    let lobbyParticipant: LobbyParticipant?
    /// 关联标签
    let relationTagWhenRing: CollaborationRelationTag?

    init(id: String,
         isExternal: Bool,
         name: String,
         avatarInfo: AvatarInfo,
         workStatus: User.WorkStatus,
         byteviewUser: ByteviewUser? = nil,
         description: String? = nil,
         status: SearchedUserStatus? = nil,
         unsupportedRtcVersion: Bool = false,
         executiveMode: Bool = false,
         participant: Participant? = nil,
         lobbyParticipant: LobbyParticipant? = nil,
         collaborationType: LarkUserCollaborationType? = nil,
         isRobot: Bool = false,
         tenantId: String? = nil,
         crossTenant: Bool? = nil,
         customStatuses: [User.CustomStatus] = [],
         relationTagWhenRing: CollaborationRelationTag? = nil) {
        self.id = id
        self.isExternal = isExternal
        self.name = name
        self.avatarInfo = avatarInfo
        self.executiveMode = executiveMode
        self.workStatus = workStatus
        self.byteviewUser = byteviewUser
        self.description = description
        self.status = status
        self.unsupportedRtcVersion = unsupportedRtcVersion
        self.participant = participant
        self.lobbyParticipant = lobbyParticipant
        self.collaborationType = collaborationType
        self.isRobot = isRobot
        self.tenantId = tenantId
        self.crossTenant = crossTenant
        self.customStatuses = customStatuses
        self.relationTagWhenRing = relationTagWhenRing
    }
}

extension SearchedUser {
    var flagImage: UIImage? {
        return isRobot ? CommonResources.Robot : nil
    }

    // 单向联系人，分享页面和分享搜索页面，点击toast用
    var isCollaborationBlocked: Bool {
        self.collaborationType == .blocked
    }

    // 单向联系人，分享页面和分享搜索页面，点击toast用
    var isCollaborationBeBlocked: Bool {
        self.collaborationType == .beBlocked
    }

    // 单向联系人，参会人搜索点击事件用，有单向限制
    var isCollaborationTypeLimited: Bool {
        self.collaborationType == .blocked
        || self.collaborationType == .beBlocked
        || self.collaborationType == .requestNeeded
    }

    // 单向联系人，参会人列表样式用，单向限制是屏蔽对方或者被屏蔽按钮都要置灰，requestNeeded不做任何处理
    var isCollaborationTypeLimitedBlocked: Bool {
        self.collaborationType == .blocked || self.collaborationType == .beBlocked
    }

    var choiceState: ChoiceItemStateOptions {
        if executiveMode || unsupportedRtcVersion {
            return .disabled
        }
        switch status {
        case .none, .some(.idle):
            return .normal
        case .some(.inMeeting):
            return [.disabled, .already]
        case .some(.busy), .some(.ringing), .some(.inviting), .some(.waiting):
            return .disabled
        }
    }
}

struct ChoiceItemStateOptions: OptionSet {
    let rawValue: UInt

    init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    static let normal = ChoiceItemStateOptions(rawValue: 1 << 0)
    static let overflow = ChoiceItemStateOptions(rawValue: 1 << 1)
    static let selected = ChoiceItemStateOptions(rawValue: 1 << 2)
    static let disabled = ChoiceItemStateOptions(rawValue: 1 << 3)
    static let already = ChoiceItemStateOptions(rawValue: 1 << 4)
    static let blocked = ChoiceItemStateOptions(rawValue: 1 << 5)
}
