//
//  PickerChatterMeta.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/3/28.
//

import Foundation
import RustPB

public struct PickerChatterMeta: PickerItemMetaType {
    // MARK: - Info
    /// 用户id
    public var id: String
    /// 用户姓名
    public var name: String?
    /// 用户姓名拼音
    public var namePinyin: String?
    /// 用户备注名
    public var alias: String?
    /// 本地化后的真实姓名
    public var localizedRealName: String?
    /// 头像id
    public var avatarId: String?
    /// 头像key
    public var avatarKey: String?
    /// 头像URL
    public var avatarUrl: String?
    /// 头像集合
    public var avatar: RustPB.Basic_V1_ImageSet?
    /// 签名
    public var description: String?
    /// 邮箱
    public var email: String?
    /// 企业邮箱
    public var enterpriseMailAddress: String?
    /// 富文本名称, 主要用于搜索显示匹配query的高亮部分
    public var attributedName: String?
    /// 所属租户id
    public var tenantId: String?
    /// 所属租户名
    public var tenantName: String?
    /// 权限信息
    public var accessInfo: RustPB.Basic_V1_Chatter.AccessInfo?
    /// 标签信息
    public var tagData: RustPB.Basic_V1_TagData?
    /// 无权限原因
    public var deniedReasons: [RustPB.Basic_V1_Auth_DeniedReason]?
    /// 是否是外部用户, true时为跨租户
    public var isOuter: Bool?
    /// 是否是密聊
    public var isCrypto: Bool?
    /// 是否是ka用户, true时为ka用户
    public var isKa: Bool?
    /// 是否离职, true为已离职
    public var isResigned: Bool?
    /// 是否注册过
    public var isRegistered: Bool?
    /// 是否在设定的团队内, 设定的团队id由Picker配置
    ///
    public var isInChat: Bool?
    /// 当前用户是否已在团队里（非通过群间接从属）
    public var isDirectlyInTeam: Bool?
    /// 当前用户状态信息
    public var status: [RustPB.Basic_V1_Chatter.ChatterCustomStatus]?
    /// 单聊信息
    public var p2pChat: PickerChatMeta?
    /// 是否是MyAI
    public var isMyAI: Bool?

    public init(
        id: String,
        name: String? = nil,
        namePinyin: String? = nil,
        alias: String? = nil,
        localizedRealName: String? = nil,
        avatarKey: String? = nil,
        avatar: Basic_V1_ImageSet? = nil,
        description: String? = nil,
        email: String? = nil,
        enterpriseMailAddress: String? = nil,
        attributedName: String? = nil,
        tenantId: String? = nil,
        tenantName: String? = nil,
        accessInfo: Basic_V1_Chatter.AccessInfo? = nil,
        tagData: Basic_V1_TagData? = nil,
        deniedReasons: [Basic_V1_Auth_DeniedReason]? = nil,
        isOuter: Bool? = nil,
        isKa: Bool? = nil,
        isResigned: Bool? = nil,
        isRegistered: Bool? = nil,
        isInChat: Bool? = nil,
        isDirectlyInTeam: Bool? = nil,
        p2pChat: PickerChatMeta? = nil) {
            self.id = id
            self.name = name
            self.namePinyin = namePinyin
            self.alias = alias
            self.localizedRealName = localizedRealName
            self.avatarKey = avatarKey
            self.avatar = avatar
            self.description = description
            self.email = email
            self.enterpriseMailAddress = enterpriseMailAddress
            self.attributedName = attributedName
            self.tenantId = tenantId
            self.tenantName = tenantName
            self.accessInfo = accessInfo
            self.tagData = tagData
            self.deniedReasons = deniedReasons
            self.isOuter = isOuter
            self.isKa = isKa
            self.isResigned = isResigned
            self.isRegistered = isRegistered
            self.isInChat = isInChat
            self.isDirectlyInTeam = isDirectlyInTeam
            self.p2pChat = p2pChat
        }
}
