//
//  Chatter.swift
//  Model
//
//  Created by qihongye on 2018/3/13.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import RustPB

public typealias WorkStatus = RustPB.Basic_V1_WorkStatus

public final class Chatter: ModelProtocol, Equatable, AtomicExtra {
    public typealias Description = RustPB.Basic_V1_Chatter.Description
    public typealias DescriptionType = RustPB.Basic_V1_Chatter.Description.TypeEnum
    public typealias AccessInfo = RustPB.Basic_V1_Chatter.AccessInfo

    public typealias PBModel = RustPB.Basic_V1_Chatter

    public typealias TypeEnum = RustPB.Basic_V1_Chatter.TypeEnum
    public typealias ChatExtra = RustPB.Basic_V1_Chatter.ChatExtra
    public typealias FocusStatus = RustPB.Basic_V1_Chatter.ChatterCustomStatus
    public typealias TagData = RustPB.Basic_V1_TagData

    public var id: String
    public var isAnonymous: Bool
    public var isFrozen: Bool
    public var name: String
    public var localizedName: String
    public var enUsName: String
    public var namePinyin: String
    public var alias: String // 备注名
    public var anotherName: String // 别名
    public var nameWithAnotherName: String // name+another拼接
    public var type: TypeEnum
    public var avatarKey: String
    public var avatar: ImageSet
    public var updateTime: TimeInterval
    public var creatorId: String
    public var isResigned: Bool
    public var isRegistered: Bool
    // swiftlint:disable identifier_name
    public var description_p: Chatter.Description
    // swiftlint:enable identifier_name
    public var tenantId: String
    public var workStatus: WorkStatus
    public var majorLanguage: String
    public var profileEnabled: Bool
    // 星标联系人
    public var isSpecialFocus: Bool

    /// 用户自定义状态列表
    public var focusStatusList: [Chatter.FocusStatus]
    // 屏蔽机器人消息
    public var botForbiddenInfo: Basic_V1_Chatter.BotMutedInfo?
    public var deniedReasons: [RustPB.Basic_V1_Auth_DeniedReason]?

    /// 获取某时刻生效的自定义状态
    @available(*, deprecated, message: "Call topActive on focusStatusList instead.")
    public func getValidFocusStatus(atTime time: Int64) -> Chatter.FocusStatus? {
        return focusStatusList.first { focus in
            time >= focus.effectiveInterval.startTime
                && time <= focus.effectiveInterval.endTime
        }
    }

    /// 查询某时刻是否有勿扰 Icon
    public func hasNotDisturbStatus(atTime time: Int64) -> Bool {
        return time <= doNotDisturbEndTime / 1000
    }

    public var chatExtra: ChatExtra? {
        get {
            return atomicExtra.value.chatExtra
        }
        set {
            atomicExtra.value.chatExtra = newValue
        }
    }
    public var accessInfo: AccessInfo
    public var doNotDisturbEndTime: Int64
    public var email: String?

    struct ChatterExtra {
        var chatExtra: ChatExtra?
    }
    typealias ExtraModel = ChatterExtra
    var atomicExtra: SafeAtomic<ChatterExtra>

    // bot config
    public var withBotTag: String
    public var canJoinGroup: Bool

    // openApp
    public var openAppId: String
    public var openApp: RustPB.Basic_V1_OpenApp?

    // 迁移时，后面再考虑放在哪里
    public var department: String = ""

    public var medalKey: String = ""
    public var isDefaultAvatar: Bool = false

    public var acceptSmsPhoneUrgent: Bool

    public var timeZoneID: String = ""

    public var displayName: String {
        if !alias.isEmpty {
            return alias
        }
        return localizedName
    }

    //考虑别名
    public var displayWithAnotherName: String {
        if !alias.isEmpty {
            return alias
        }
        return self.nameWithAnotherName
    }

    // 企业邮箱信息，部分接口附带
    public var enterpriseEmail: String?
    public var tagData: RustPB.Basic_V1_TagData?
    public var chatChatterListDepartmentName: String

    public init(id: String,
                isAnonymous: Bool,
                isFrozen: Bool,
                name: String,
                localizedName: String,
                enUsName: String,
                namePinyin: String,
                alias: String,
                anotherName: String,
                nameWithAnotherName: String,
                type: TypeEnum,
                avatarKey: String,
                avatar: ImageSet,
                updateTime: TimeInterval,
                creatorId: String,
                isResigned: Bool,
                isRegistered: Bool,
                description: RustPB.Basic_V1_Chatter.Description,
                withBotTag: String,
                canJoinGroup: Bool,
                tenantId: String,
                workStatus: WorkStatus,
                majorLanguage: String,
                profileEnabled: Bool,
                focusStatusList: [Chatter.FocusStatus],
                chatExtra: ChatExtra?,
                accessInfo: AccessInfo,
                email: String?,
                doNotDisturbEndTime: Int64,
                openAppId: String,
                acceptSmsPhoneUrgent: Bool,
                medalKey: String = "",
                timeZoneID: String = "",
                isDefaultAvatar: Bool = false,
                isSpecialFocus: Bool = false,
                botForbiddenInfo: Basic_V1_Chatter.BotMutedInfo? = nil,
                tagData: RustPB.Basic_V1_TagData? = nil,
                chatChatterListDepartmentName: String = "") {
        self.id = id
        self.isAnonymous = isAnonymous
        self.isFrozen = isFrozen
        self.name = name
        self.localizedName = localizedName
        self.enUsName = enUsName
        self.namePinyin = namePinyin
        self.type = type
        self.avatarKey = avatarKey
        self.avatar = avatar
        self.updateTime = updateTime
        self.creatorId = creatorId
        self.isResigned = isResigned
        self.isRegistered = isRegistered
        self.description_p = description
        self.withBotTag = withBotTag
        self.canJoinGroup = canJoinGroup
        self.tenantId = tenantId
        self.workStatus = workStatus
        self.majorLanguage = majorLanguage
        self.profileEnabled = profileEnabled
        self.alias = alias
        self.anotherName = anotherName
        self.nameWithAnotherName = nameWithAnotherName
        self.accessInfo = accessInfo
        self.doNotDisturbEndTime = doNotDisturbEndTime
        self.email = email
        self.openAppId = openAppId
        self.acceptSmsPhoneUrgent = acceptSmsPhoneUrgent
        self.timeZoneID = timeZoneID
        self.medalKey = medalKey
        self.atomicExtra = SafeAtomic(value: ChatterExtra(chatExtra: chatExtra))
        self.focusStatusList = focusStatusList
        self.isDefaultAvatar = isDefaultAvatar
        self.isSpecialFocus = isSpecialFocus
        self.botForbiddenInfo = botForbiddenInfo
        self.tagData = tagData
        self.chatChatterListDepartmentName = chatChatterListDepartmentName
    }

    public static func == (_ lhs: Chatter, _ rhs: Chatter) -> Bool {
        return lhs.id == rhs.id
    }

    public func transform() -> PBModel {
        var pbModel = PBModel()
        pbModel.id = self.id
        pbModel.isAnonymous = self.isAnonymous
        pbModel.isFrozen = self.isFrozen
        pbModel.name = self.name
        pbModel.localizedName = self.localizedName
        pbModel.enUsName = self.enUsName
        pbModel.namePinyin = self.namePinyin
        pbModel.alias = self.alias
        pbModel.nameWithAnotherName = self.nameWithAnotherName
        pbModel.type = self.type
        pbModel.avatarKey = self.avatarKey
        pbModel.avatar = self.avatar
        pbModel.updateTime = Int64(self.updateTime)
        pbModel.creatorID = self.creatorId
        pbModel.isResigned = self.isResigned
        pbModel.isRegistered = self.isRegistered
        pbModel.description_p = self.description_p
        pbModel.tenantID = self.tenantId
        pbModel.workStatus = self.workStatus
        pbModel.majorLanguage = self.majorLanguage
        pbModel.profileEnabled = self.profileEnabled
        pbModel.acceptSmsPhoneUrgent = self.acceptSmsPhoneUrgent
        pbModel.email = self.email ?? ""
        pbModel.timeZone.timeZoneID = self.timeZoneID
        pbModel.avatarMedal.key = self.medalKey
        pbModel.status = focusStatusList
        pbModel.isDefaultAvatar = self.isDefaultAvatar
        pbModel.isSpecialFocus = isSpecialFocus
        if let data = self.tagData {
            pbModel.tagInfo = data
        }
        pbModel.chatChatterListDepartmentName = chatChatterListDepartmentName
        return pbModel
    }

    public static func transform(pb: Basic_V1_Chatter) -> Chatter {
        return make(pb: pb, auths: nil)
    }

    public static func make(pb: PBModel, auths: Basic_V1_Auth_ChattersAuthResult? = nil) -> Chatter {
        let res = Chatter(
            id: pb.id,
            isAnonymous: pb.isAnonymous,
            isFrozen: pb.isFrozen,
            name: pb.name,
            localizedName: pb.localizedName,
            enUsName: pb.enUsName,
            namePinyin: pb.namePinyin,
            alias: pb.alias,
            anotherName: pb.anotherName,
            nameWithAnotherName: pb.nameWithAnotherName,
            type: pb.type,
            avatarKey: pb.avatarKey,
            avatar: pb.avatar,
            updateTime: TimeInterval(pb.updateTime),
            creatorId: pb.creatorID,
            isResigned: pb.isResigned,
            isRegistered: pb.isRegistered,
            description: pb.description_p,
            withBotTag: pb.withBotTag,
            canJoinGroup: pb.canJoinGroup,
            tenantId: pb.tenantID,
            workStatus: pb.workStatus,
            majorLanguage: pb.majorLanguage,
            profileEnabled: pb.profileEnabled,
            focusStatusList: pb.status,
            chatExtra: pb.chatExtra,
            accessInfo: pb.accessInfo,
            email: pb.email,
            doNotDisturbEndTime: pb.doNotDisturbEndTime,
            openAppId: pb.openAppID,
            acceptSmsPhoneUrgent: pb.acceptSmsPhoneUrgent,
            medalKey: pb.avatarMedal.showSwitch ? pb.avatarMedal.key : "",
            timeZoneID: pb.timeZone.timeZoneID,
            isDefaultAvatar: pb.isDefaultAvatar,
            isSpecialFocus: pb.isSpecialFocus,
            botForbiddenInfo: pb.mutedInfo,
            tagData: pb.tagInfo,
            chatChatterListDepartmentName: pb.chatChatterListDepartmentName)
        if let reason = auths?.deniedReasons[pb.id] {
            res.deniedReasons = [reason]
        }
        return res
    }

    public static func transformChatChatter(
        entity: RustPB.Basic_V1_Entity,
        chatID: String,
        id: String
    ) throws -> Chatter {
        guard let pb = entity.chatChatters[chatID]?.chatters[id] else {
            throw LarkModelError.entityIncompleteData(message: "entity没有对应chatChatter chatID:\(chatID) chatterID:\(id)")
        }
        let chatter: Chatter = transform(pb: pb)
        /// 如果有对应的openApp，则读取openApp
        if entity.openApps.keys.contains(chatter.openAppId) {
            chatter.openApp = entity.openApps[chatter.openAppId]
        }
        return chatter
    }

    public static func transformChatter(
        entity: RustPB.Basic_V1_Entity,
        id: String
    ) throws -> Chatter {
        guard let pb = entity.chatters[id] else {
            throw LarkModelError.entityIncompleteData(message: "entity.chatters缺少对应chatter id: \(id)")
        }
        let chatter: Chatter = transform(pb: pb)
        /// 如果有对应的openApp，则读取openApp
        if entity.openApps.keys.contains(chatter.openAppId) {
            chatter.openApp = entity.openApps[chatter.openAppId]
        }
        return chatter
    }

    public static func transformChatter(
        entity: RustPB.Basic_V1_Entity,
        message: RustPB.Basic_V1_Message,
        id: String
    ) throws -> Chatter {
        if message.channel.type == .chat {
            var chatID = message.channel.id
            if chatID.isEmpty {
                chatID = message.chatID
            }
            return try transformChatChatter(entity: entity, chatID: chatID, id: id)
        }
        return try transformChatter(entity: entity, id: id)
    }

    public func merge(_ chatExtra: ChatExtra?) -> Chatter {
        if self.chatExtra == nil {
            self.chatExtra = chatExtra
        }
        return self
    }
}

public extension Chatter {
    var avatarOriginFirstUrl: String {
        return self.avatar.origin.urls.first ?? ""
    }

    var avatarThumbFirstUrl: String {
        return self.avatar.thumbnail.urls.first ?? ""
    }

    var isCustomer: Bool {
        return self.tenantId == "0"
    }

    var isToCUnRegistered: Bool {
        return self.isCustomer && !self.isRegistered
    }
}
