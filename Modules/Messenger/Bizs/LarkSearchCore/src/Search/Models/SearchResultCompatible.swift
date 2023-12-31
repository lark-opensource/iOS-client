//
//  SearchResultCompatible.swift
//  LarkSearchCore
//
//  Created by SolaWing on 2021/1/10.
//
// 本文件负责V1 V2 的兼容转换。方便接口返回V1，V2的数据都能处理。以后全面切V2后需要清理掉

import Foundation
import LarkModel
import RustPB
import LarkSDKInterface
import LarkListItem

extension Search_Sections_V1_SectionHeader: SearchSectionHeader {}

extension Search_Sections_V1_SectionFooter: SearchSectionFooter {}

extension Search_V2_SectionMeta: SearchSectionMeta {
    public var headerInfo: SearchSectionHeader { header }
    public var footerInfo: SearchSectionFooter { footer }
    public var results: [SearchResultType] { items.map { Search.Result(base: $0, contextID: nil) } }
}

extension Search_V1_SearchChatterMeta: SearchMetaChatterType {
    public var relationTag: RustPB.Search_V2_TagData { Search_V2_TagData() }

    public var enterpriseEmail: String { mailAddress }
    public var customStatus: [Basic_V1_Chatter.ChatterCustomStatus] { [] }

    public var isCrypto: Bool { false }
    public var isInChat: Bool { !inChatIds.isEmpty }
    public var isBlockedFromLocalSearch: Bool { false }
}
extension Search_V1_SearchChatMeta: SearchMetaChatType {
    public var enterpriseEmail: String { "" }
    public var enabledEmail: Bool { false }
    public var isShield: Bool { false }
    public var relationTag: RustPB.Search_V2_TagData { Search_V2_TagData() }
    public var description: String { "" }
}
extension Search_V1_SearchMessageMeta: SearchMetaMessageType {
    public var createTime: Int64 {
        // v1 没有create_time
        return 0
    }

    public var contentType: Basic_V1_Message.TypeEnum { type }
    public var docExtraInfosType: [Search_V2_MessageMeta.DocExtraInfo] {
        docExtraInfos.map {
            var v = Search_V2_MessageMeta.DocExtraInfo()
            if $0.hasType { v.type = $0.type }
            if $0.hasURL { v.url = $0.url }
            if $0.hasName { v.name = $0.name }
            return v
        }
    }
    public var threadMessageType: Basic_V1_Message.ThreadMessageType { .unknownThreadMessage }
    public var rootMessagePosition: Int32 { 0 }
    public var isFileAccessAuth: Bool { false }
}
extension Search_V1_SearchDocMeta: SearchMetaDocType {
    public var isShareFolder: Bool { false }
    public var relationTag: RustPB.Search_V2_TagData { Search_V2_TagData() }
    public var iconInfo: String { "" }
}
extension Search_Slash_V1_SlashCommandMeta: SearchMetaSlashType {
    public var slashCommand: Search_V2_SlashCommandMeta.SlashCommandType { slashCommandType.asV2() }
    public var tags: [Search_V2_SlashCommandMeta.SlashCommandTag] { tag.map { $0.asV2() } }
    public var imageURL: String { "" }
}
extension Search_V1_SearchMessageMeta: SearchMetaEmailType {}
extension Search_V1_SearchOncallMeta: SearchMetaOncallType {
    public var tagsV1: [Basic_V1_Tag] { tags }
}
extension Search_V1_SearchCryptoP2PChatMeta: SearchMetaCryptoP2PChatType {
    public var customStatus: [Basic_V1_Chatter.ChatterCustomStatus] { return [] }
    public var isRemind: Bool { false }
    public var doNotDisturbEndTime: Int64 { return 0 }
    public var isCrypto: Bool { return true }
    public var relationTag: RustPB.Search_V2_TagData { Search_V2_TagData() }
}
extension Search_V1_SearchThreadMeta: SearchMetaThreadType {}
extension Search_V1_SearchLinkMeta: SearchMetaLinkType {}
extension Search_V1_SearchWikiMeta: SearchMetaWikiType {
    public var type: Basic_V1_Doc.TypeEnum { .wiki }
    public var wikiInfo: [Search_V1_WikiInfo] { [] }
    public var isCrossTenant: Bool { false }
    public var updateTime: Int64 { 0 }
    public var ownerName: String { "" }
    public var ownerID: String { "" }
    public var chatID: String { "" }
    public var threadID: String { "" }
    public var threadPosition: Int32 { 0 }
    public var position: Int32 { 0 }
    public var isShareFolder: Bool { false }
    public var docMetaType: SearchMetaDocType { docMeta }
    public var relationTag: RustPB.Search_V2_TagData { Search_V2_TagData() }
    public var iconInfo: String { "" }
}

extension Search_V2_UserMeta: SearchMetaChatterType {
    public var enterpriseEmail: String { enterpriseMailAddress }
    public var isCrypto: Bool { false }
    public var isRemind: Bool { p2PChatInfo.isRemind }
    public var p2PChatID: String { p2PChatInfo.chatID }
    public var lastMessagePosition: Int32 { p2PChatInfo.lastMessagePosition }
    public var lastMessagePositionBadgeCount: Int32 { p2PChatInfo.lastMessagePositionBadgeCount }
    public var readPosition: Int32 { p2PChatInfo.readPosition }
    public var readPositionBadgeCount: Int32 { p2PChatInfo.readPositionBadgeCount }

    public var withBotTag: String { "" }

    public var type: Basic_V1_Chatter.TypeEnum { .user }
    public var isInChat: Bool { extraFields.isInChat }
}
extension Search_V2_BotMeta: SearchMetaChatterType {
    public var isCrypto: Bool { false }
    public var isRemind: Bool { p2PChatInfo.isRemind }
    public var p2PChatID: String { p2PChatInfo.chatID }
    public var lastMessagePosition: Int32 { p2PChatInfo.lastMessagePosition }
    public var lastMessagePositionBadgeCount: Int32 { p2PChatInfo.lastMessagePositionBadgeCount }
    public var readPosition: Int32 { p2PChatInfo.readPosition }
    public var readPositionBadgeCount: Int32 { p2PChatInfo.readPositionBadgeCount }

    public var deniedPermissions: [Basic_V1_Auth_ActionType] { [] }
    public var deniedReason: [Int32: Basic_V1_Auth_DeniedReason] { [:] }
    public var hasWorkStatus: Bool { false }
    public var workStatus: Basic_V1_WorkStatus { Basic_V1_WorkStatus() }
    public var doNotDisturbEndTime: Int64 { 0 }
    public var isRegistered: Bool { false }
    public var type: Basic_V1_Chatter.TypeEnum { .bot }
    public var isInChat: Bool { false }
    public var enterpriseEmail: String { "" }
    public var mailAddress: String { "" }
    public var customStatus: [Basic_V1_Chatter.ChatterCustomStatus] { [] }
    public var relationTag: RustPB.Search_V2_TagData { Search_V2_TagData() }
    public var isBlockedFromLocalSearch: Bool { false }
}

extension Search_V2_MyAIMeta: SearchMetaChatterType {
    public var type: Basic_V1_Chatter.TypeEnum { .ai }
    public var description_p: String { "" }
    public var descriptionFlag: Basic_V1_Chatter.Description.TypeEnum { .onDefault }
    public var timezone: RustPB.Search_V1_TimeZone { .init() }
    public var withBotTag: String { "" }
    public var tenantID: String { "" }
    public var isCrypto: Bool { false }
    public var isRemind: Bool { true }
    public var lastMessagePosition: Int32 { 0 }
    public var lastMessagePositionBadgeCount: Int32 { 0 }
    public var readPosition: Int32 { 0 }
    public var readPositionBadgeCount: Int32 { 0 }
    public var deniedPermissions: [Basic_V1_Auth_ActionType] { [] }
    public var deniedReason: [Int32: Basic_V1_Auth_DeniedReason] { [:] }
    public var hasWorkStatus: Bool { false }
    public var workStatus: Basic_V1_WorkStatus { .init() }
    public var doNotDisturbEndTime: Int64 { 0 }
    public var isRegistered: Bool { false }
    public var isInChat: Bool { false }
    public var enterpriseEmail: String { "" }
    public var mailAddress: String { "" }
    public var customStatus: [Basic_V1_Chatter.ChatterCustomStatus] { [] }
    public var relationTag: Search_V2_TagData { .init() }
    public var isBlockedFromLocalSearch: Bool { false }
}

extension Search_V2_ChatMeta: SearchMetaChatType {
    public var chatMode: Basic_V1_Chat.ChatMode { mode }
    public var description: String { description_p }
}
extension Search_V2_CryptoP2PChatMeta: SearchMetaCryptoP2PChatType {
    public var type: Chatter.TypeEnum { .user }

    public var doNotDisturbEndTime: Int64 { return 0 }
    public var isCrypto: Bool { return true }
    public var withBotTag: String { "" }

    public var isRemind: Bool { p2PChatInfo.isRemind }
    public var p2PChatID: String { p2PChatInfo.chatID }
    public var lastMessagePosition: Int32 { p2PChatInfo.lastMessagePosition }
    public var lastMessagePositionBadgeCount: Int32 { p2PChatInfo.lastMessagePositionBadgeCount }
    public var readPosition: Int32 { p2PChatInfo.readPosition }
    public var readPositionBadgeCount: Int32 { p2PChatInfo.readPositionBadgeCount }
}
extension Search_V2_MessageMeta: SearchMetaMessageType {
    public var contentType: Basic_V1_Message.TypeEnum { type }
    // TODO:
    public var fromName: String { "" }
    public var fromAvatarKey: String { "" }
    public var p2PChatterIDString: String { p2PChatterID }
    public var docExtraInfosType: [DocExtraInfo] { docExtraInfos }
}
extension Search_V2_SlashCommandMeta: SearchMetaSlashType {
    public var slashCommand: SlashCommandType { slashCommandType }
    public var tags: [SlashCommandTag] { tag }
}
extension Search_V2_DocMeta: SearchMetaDocType {
    public var wikiInfo: [Search_V1_WikiInfo] { [] } // v2不在把wikiInfo放到doc里。直接用wikiMeta
}
// v2 doctype的字段移动到wiki里了，最终会分离独立
extension Search_V2_WikiMeta: SearchMetaWikiType {
    public var wikiInfo: [Search_V1_WikiInfo] {
        [tap(Search_V1_WikiInfo()) {
            if self.hasToken { $0.wikiToken = self.token }
            if self.hasSpaceID { $0.spaceID = self.spaceID }
            if self.hasSpaceName { $0.spaceName = self.spaceName }
            if self.hasURL { $0.url = self.url }
        }]
    }

    public var isShareFolder: Bool { false }
    public var docMetaType: SearchMetaDocType { self }
}
extension Search_V2_ThreadMeta: SearchMetaThreadType {}
extension Search_V2_URLMeta: SearchMetaLinkType {
    // TODO: not implement
    public var fromName: String { "" }

    public var originalURL: String { url }
    public var position: Int32 { messagePosition }
}
extension Search_V2_OncallMeta: SearchMetaOncallType {
    public var chatID: String { "" } // TODO:
    public var tagsV1: [Basic_V1_Tag] { tags.compactMap { Basic_V1_Tag(rawValue: Int($0)) } }
    public var isOfficialOncall: Bool { isOfficial }
    // TODO: crossTagInfo
    public var crossTagInfo: String { "" }
    public var hasCrossTagInfo: Bool { false }
}

extension SearchMeta {
    var searchType: Search_V1_SearchResult.TypeEnum {
        switch self {
        case .chatter: return .chatter
        case .chat: return .chat
        case .message: return .message
        case .doc: return .doc
        case .email: return .email
        case .box: return .box
        case .oncall: return .oncall
        case .cryptoP2PChat: return .cryptoP2PChat
        case .shieldP2PChat: return .cryptoP2PChat
        case .thread: return .thread
        case .openApp: return .openApp
        case .link: return .link
        case .external: return .external
        case .wiki: return .wiki
        case .workspace: return .wiki
        case .calendar: return .unknown
        case .mail: return .email
        case .department: return .department
        case .slash: return .slashCommand
        case .qaCard: return .qa
        case .customization: return .qa
        case .mailContact: return .mailContact
        }
    }
}

extension Search_Slash_V1_SlashCommandMeta {

    func asV2() -> Search_V2_SlashCommandMeta {
        var type = Search_V2_SlashCommandMeta()
        if hasAppLink { type.appLink = appLink }
        if hasSlashCommandType { type.slashCommandType = slashCommandType.asV2() }
        if hasDescription_p { type.description_p = description_p }
        if hasExtra { type.extra = extra }
        type.tag = tag.map { $0.asV2() }

        return type
    }

}

extension Search_Slash_V1_SlashCommandMeta.SlashCommandType {

    func asV2() -> Search_V2_SlashCommandMeta.SlashCommandType {
        switch self {
        case .entity: return .entity
        case .filter: return .filter
        @unknown default:
            fatalError("Unknown case")
        }
    }

}

extension Search_Slash_V1_SlashCommandMeta.SlashCommandTag {

    func asV2() -> Search_V2_SlashCommandMeta.SlashCommandTag {
        var tag = Search_V2_SlashCommandMeta.SlashCommandTag()
        tag.type = type
        tag.text = text
        return tag
    }

}

extension Search_V2_SearchResult {
    func asSearchMeta() -> Search.Meta? {
        switch self.resultMeta.typedMeta {
        case .sectionMeta(let meta): return .section(meta)
        case .userMeta(let meta): return .chatter(meta)
        case .botMeta(let meta): return .chatter(meta)
        case .groupChatMeta(let meta): return .chat(meta)
        case .userGroupMeta(let meta): if self.type == .userGroup {
            return .userGroup(meta)
        } else if self.type == .userGroupAssign {
            return .userGroupAssign(meta)
        } else if self.type == .newUserGroup {
            return .newUserGroup(meta)
        } else {
            return nil
        }
        case .cryptoP2PChatMeta(let meta): return .cryptoP2PChat(meta)
        case .shieldP2PChatMeta(let meta): return .shieldP2PChat(meta)
        case .messageMeta(let meta): return .message(meta)
        case .oncallMeta(let meta): return .oncall(meta)
        case .threadMeta(let meta): return .thread(meta)
        case .urlMeta(let meta): return .link(meta)
        // case .qaCardMeta(let meta): return
        case .appMeta(let meta): return .openApp(meta)
        case .departmentMeta(let meta): return .department(meta)
        case .docMeta(let meta): return .doc(meta)
        case .wikiMeta(let meta): return .wiki(meta)
        case .wikiSpaceMeta(let meta): return .workspace(meta)
        case .qaCardMeta(let meta): return .qaCard(meta)
        case .slashCommandMeta(let meta): return .slash(meta)
        case .customizationMeta(let meta): return .customization(meta)
        case .mailContactMeta(let meta): return .mailContact(meta)
        case .resourceMeta(let meta): return .resource(meta)
        case .messageFileMeta(let meta): return .messageFile(meta)
        case .myAiMeta(let meta): return .chatter(meta)
        case .facilityMeta(let meta): return .facility(meta)
        case .some(let meta):
            assertionFailure("unimplemented type \(self.type.rawValue) \(meta)")
            return nil
        case nil:
            return nil
        @unknown default:
            return nil
        }
    }

    // enable-lint: long_function
    public var tags: [Basic_V1_Tag] {
        // NOTE: 有其他类型加了tags需要到这里添加
        switch resultMeta.typedMeta {
        case .userMeta(let meta): return meta.tags
        case .botMeta(let meta): return meta.tags
        case .groupChatMeta(let meta): return meta.tags
        case .oncallMeta(let meta): return meta.tagsV1
        @unknown default: return []
        }
    }
}
