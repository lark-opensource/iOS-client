//
//  RelationTag.swift
//  ByteViewNetwork
//
//  Created by admin on 2022/11/25.
//

import Foundation
import ServerPB
import RustPB
import LarkLocalizations

typealias SerPBVCRelationTag = ServerPB_Videochat_VCRelationTag
typealias SerPBCollaborationRelationTag = ServerPB_Collaboration_RelationTag
typealias SerPBRelationTagType = ServerPB_Collaboration_RelationTagType
typealias PBContactRelationTag = Contact_V1_RelationTag
typealias PBRelationTagType = Contact_V1_RelationTagType
typealias PBI18nText = Basic_V1_I18nText
typealias ServerPBI18nText = ServerPB_Entities_I18nText
typealias ServerPBTargetTenantInfo = ServerPB_Collaboration_TargetTenantInfo
typealias PBTagData = Basic_V1_TagData
typealias PBTagDataItem = Basic_V1_TagData.TagDataItem
typealias PBTagItemType = Basic_V1_RequestTagTypeEnum
typealias PBTagItemRelationTagType = Basic_V1_ResponseTagTypeEnum

// MARK: TargetTenantInfo
/// 目标租户信息
public struct TargetTenantInfo {
    /// 别名信息
    public var alias: RelationI18nText?
    /// 组织关系标签
    public var relationTag: CollaborationRelationTag?
}

extension TargetTenantInfo {
    var serverPbType: ServerPBTargetTenantInfo {
        var info = ServerPBTargetTenantInfo()
        if let alias = alias {
            info.alias = alias.serverPbType
        }
        if let relationTag = relationTag {
            info.relationTag = relationTag.serverPbType
        }
        return info
    }
}

extension ServerPBTargetTenantInfo {
    var vcType: TargetTenantInfo {
        var info = TargetTenantInfo()
        info.alias = hasAlias ? alias.vcType : nil
        info.relationTag = hasRelationTag ? relationTag.vcType : nil
        return info
    }
}

// MARK: RelationTag
///* 关系标签类型
public enum RelationTagType: Int {
    ///* 未设置
    case unset // = 0
    ///* 外部
    case external // = 1
    ///* 关联组织
    case partner // = 2
    ///* TenantName
    case tenantName // = 3

    var serverPbType: SerPBRelationTagType {
        SerPBRelationTagType(rawValue: self.rawValue) ?? .unset
    }

    var pbType: PBRelationTagType {
        PBRelationTagType(rawValue: self.rawValue) ?? .unset
    }

    var pbTagItemRelationTagType: PBTagItemRelationTagType {
        PBTagItemRelationTagType(rawValue: self.rawValue) ?? .relationTagUnset
    }
}

extension PBRelationTagType {
    var vcType: RelationTagType {
        RelationTagType(rawValue: self.rawValue) ?? .unset
    }
}

extension SerPBRelationTagType {
    var vcType: RelationTagType {
        RelationTagType(rawValue: self.rawValue) ?? .unset
    }
}

public struct CollaborationRelationTag: Equatable {
    /// 关系标签类型
    public var relationTagType: RelationTagType
    /// 标签内容
    public var relationTag: RelationI18nText?
    /// 关系标签的唯一标识
    public var tagIdentifier: String?
}

public extension CollaborationRelationTag {
    /// 本地化的关系文案
    var meetingTagText: String? {
        guard relationTagType == .partner || relationTagType == .tenantName else {
            return nil
        }
        return relationTag?.localizedText
    }
}

extension CollaborationRelationTag {
    var serverPbType: SerPBCollaborationRelationTag {
        var tag = SerPBCollaborationRelationTag()
        tag.relationTagType = relationTagType.serverPbType
        if let relationTag = relationTag {
            tag.relationTag = relationTag.serverPbType
        }
        if let tagIdentifier = tagIdentifier {
            tag.tagIdentifier = tagIdentifier
        }
        return tag
    }

    var pbType: PBContactRelationTag {
        var tag = PBContactRelationTag()
        tag.relationTagType = relationTagType.pbType
        if let relationTag = relationTag {
            tag.relationTag = relationTag.pbType
        }
        if let tagIdentifier = tagIdentifier {
            tag.tagIdentifier = tagIdentifier
        }
        return tag
    }
}

extension PBContactRelationTag {
    var vcType: CollaborationRelationTag {
        var tag = CollaborationRelationTag(relationTagType: relationTagType.vcType)
        if hasRelationTag {
            tag.relationTag = relationTag.vcType
        }
        if hasTagIdentifier {
            tag.tagIdentifier = tagIdentifier
        }
        return tag
    }
}

extension SerPBCollaborationRelationTag {
    var vcType: CollaborationRelationTag {
        var tag = CollaborationRelationTag(relationTagType: relationTagType.vcType)
        if hasRelationTag {
            tag.relationTag = relationTag.vcType
        }
        if hasTagIdentifier {
            tag.tagIdentifier = tagIdentifier
        }
        return tag
    }
}

// MARK: VCRelationTag
/// vc用户维度标签key
public struct VCRelationTag {
    public struct User: Equatable {
        public enum TypeEnum: Int {
            case unknown
            /// lark 用户
            case larkUser
            /// 群聊
            case chat
            /// 会议室
            case room
        }

        public var type: TypeEnum
        public var id: Int64

        public init(type: TypeEnum, id: String) {
            self.type = type
            self.id = Int64(id) ?? 0
        }

        public init(type: TypeEnum, id: Int64) {
            self.type = type
            self.id = id
        }
    }

    public var user: User
    public var relationTag: CollaborationRelationTag?

    public var userID: String { user.userID }

    public var relationText: String? {
        if let relationTag = self.relationTag, let relationText = relationTag.relationTag?.localizedText,
           relationTag.relationTagType != .unset {
            return relationText
        }
        return nil
    }
}

extension VCRelationTag: CustomStringConvertible {
    public var description: String {
        String(
            indent: "VCRelationTag",
            "id: \(user.id)",
            "type: \(user.type)",
            "tagType: \(relationTag?.relationTagType)",
            "text: \(relationTag?.relationTag?.localizedText?.hashValue)"
        )
    }
}

extension VCRelationTag.User: CustomStringConvertible {
    public var description: String {
        String(
            indent: "VCRelationTag.User",
            "id: \(id)",
            "type: \(type)"
        )
    }
}

extension SerPBVCRelationTag {
    var vcType: VCRelationTag {
        let user = self.user.vcType
        let relationTag = self.relationTag.vcType
        return VCRelationTag(user: user, relationTag: relationTag)
    }
}

public extension VCRelationTag.User {
    var userID: String {
        "\(id)"
    }

    var userIdentifier: String {
        "\(id)_\(type.rawValue)"
    }
}

// MARK: I18nText
/// i18n 文本
public struct RelationI18nText: Equatable {
    /// 兜底文案
    public var text: String
    /// 国际化文案
    public var i18NText: [String: String]
}

extension RelationI18nText {
    var serverPbType: ServerPBI18nText {
        var i18n = ServerPBI18nText()
        i18n.text = text
        i18n.i18NText = i18NText
        return i18n
    }

    var pbType: PBI18nText {
        var i18n = PBI18nText()
        i18n.fallbackText = text
        i18n.i18NText = i18NText
        return i18n
    }
}

public extension RelationI18nText {
    /// 本地化的关系文案
    var localizedText: String? {
        let currentLang = LanguageManager.currentLanguage.rawValue.lowercased()
        var relationText = ""
        if let i18Text = i18NText[currentLang] {
            relationText = i18Text
        }
        return !relationText.isEmpty ? relationText : !text.isEmpty ? text : nil
    }
}

extension PBI18nText {
    var vcType: RelationI18nText {
        RelationI18nText(text: fallbackText, i18NText: i18NText)
    }
}

extension ServerPBI18nText {
    var vcType: RelationI18nText {
        RelationI18nText(text: text, i18NText: i18NText)
    }
}

// MARK: User
extension SerPBVCRelationTag.User {
    var vcType: VCRelationTag.User {
        let type = VCRelationTag.User.TypeEnum(rawValue: type.rawValue) ?? .unknown
        return VCRelationTag.User(type: type, id: id)
    }
}

extension VCRelationTag.User {
    var serverPbType: SerPBVCRelationTag.User {
        var user = SerPBVCRelationTag.User()
        user.type = SerPBVCRelationTag.User.TypeEnum(rawValue: type.rawValue) ?? .unknown
        user.id = id
        return user
    }
}

public extension ByteviewUser {
    var relationTagUser: VCRelationTag.User {
        let uid = Int64(id) ?? 0
        var userType: VCRelationTag.User.TypeEnum
        switch type {
        case .larkUser:
            userType = .larkUser
        case .room:
            userType = .room
        default:
            userType = .unknown
        }
        return VCRelationTag.User(type: userType, id: uid)
    }
}

public extension Participant {
    var relationTagUser: VCRelationTag.User {
        return user.relationTagUser
    }
}

// MARK: Basic_V1_RequestTagTypeEnum
public enum TagItemType: Int {
    case unknown  // = 0
    /// 关系标签（可能为外部标签、B2B自定义标签、企业名称标签）
    case relationTag // = 1

    var pbType: PBTagItemType {
        PBTagItemType(rawValue: self.rawValue) ?? .unknownTagType
    }
}

extension PBTagItemType {
    var vcType: TagItemType {
        TagItemType(rawValue: self.rawValue) ?? .unknown
    }
}

extension PBTagItemRelationTagType {
    var vcType: RelationTagType {
        RelationTagType(rawValue: self.rawValue) ?? .unset
    }
}

// MARK: Basic_V1_TagData
public struct RelationTagData: Equatable {
    public var tagDataItems: [TagDataItem]

    // Basic_V1_TagData.TagDataItem
    public struct TagDataItem: Equatable {
        /// tag文案
        public var textVal: String?

        public var tagID: String?

        public var tagItemType: TagItemType = .unknown

        public var relationTagType: RelationTagType = .unset

        public var priority: Int32?
    }
}

extension RelationTagData.TagDataItem {
    var pbType: PBTagDataItem {
        var item = PBTagDataItem()
        if let textVal = textVal {
            item.textVal = textVal
        }
        if let tagID = tagID {
            item.tagID = tagID
        }
        item.reqTagType = tagItemType.pbType
        item.respTagType = relationTagType.pbTagItemRelationTagType
        item.priority = priority ?? 0

        return item
    }
}

extension PBTagDataItem {
    var vcType: RelationTagData.TagDataItem {
        var item = RelationTagData.TagDataItem()
        item.relationTagType = respTagType.vcType
        item.tagItemType = reqTagType.vcType
        item.textVal = hasTextVal ? textVal : nil
        item.tagID = hasTagID ? tagID : nil
        item.priority = hasPriority ? priority : 0
        return item
    }
}

extension RelationTagData {
    var pbType: PBTagData {
        var data = PBTagData()
        for item in tagDataItems {
            data.tagDataItems.append(item.pbType)
        }
        return data
    }
}

extension PBTagData {
    var vcType: RelationTagData {
        var data = RelationTagData(tagDataItems: [])
        for item in tagDataItems {
            data.tagDataItems.append(item.vcType)
        }
        return data
    }
}
