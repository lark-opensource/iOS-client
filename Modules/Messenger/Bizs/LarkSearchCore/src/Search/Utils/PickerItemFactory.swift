//
//  PickerItemFactory.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/3/28.
//

import Foundation
import LarkSDKInterface
import LarkModel
import LarkListItem
import RustPB
import LarkLocalizations
import LarkMessengerInterface

public final class PickerItemFactory {

    var isUseDocIcon: Bool = false

    public static let shared = PickerItemFactory()
    /// 映射场景参考 https://bytedance.feishu.cn/wiki/wikcnREcV7TH3LZd77IYV5jaT8b
    public func makeItem(option: Option, currentTenantId: String) -> PickerItem {
        if let item = option as? PickerItem { return item }
        if let result = option as? LarkSDKInterface.Search.Result {
            return makeItem(result: result)
        }
        if let result = option as? LarkModel.Chat {
            return makeItem(chat: result)
        }
        if let result = option as? LarkModel.Chatter {
            return makeItem(chatter: result, currentTenantId: currentTenantId)
        }
        if let result = option as? LarkSDKInterface.NewSelectExternalContact {
            return makeItem(externalContact: result, currentTenantId: currentTenantId)
        }
        if let result = option as? LarkMessengerInterface.ForwardItem {
            return makeItem(forward: result)
        }
        if let result = option as? LarkSDKInterface.SelectVisibleUserGroup {
            return makeItem(userGroup: result)
        }
        return PickerItem.empty()
    }

    public func makeItem(result: LarkSDKInterface.Search.Result) -> PickerItem {
        var item = PickerItem.empty()
        let base = result.base
        let factory = AttributeStringFactory.shared
        let title = factory.convert(xml: base.titleHighlighted)
        let summary = factory.convert(xml: base.summaryHighlighted)
        let renderData = PickerItem.RenderData(
            title: base.titleHighlighted,
            summary: base.summaryHighlighted,
            titleHighlighted: title,
            summaryHighlighted: summary,
            extrasHighlighted: base.extrasHighlighted,
            explanationTags: base.explanationTags,
            extraInfos: base.extraInfos,
            extraInfoSeparator: base.extraInfoSeparator,
            renderData: base.renderData
        )
        let typedMeta = base.resultMeta.typedMeta
        switch typedMeta {
        case .userMeta(let user):
            let p2p = PickerChatMeta(id: user.p2PChatInfo.chatID,
                                     type: .p2P,
                                     mode: .default,
                                     lastMessageId: user.p2PChatInfo.lastMessageID)
            let name = getLocalizeName(i18n: user.i18NNames)
            let reasons: [RustPB.Basic_V1_Auth_DeniedReason] = user.deniedReason.reduce([]) {
                var arr = $0
                arr.append($1.value)
                return arr
            }
            var meta = PickerChatterMeta(id: user.id,
                                         name: name,
                                         localizedRealName: name,
                                         avatarKey: base.avatarKey,
                                         description: user.description_p,
                                         email: user.mailAddress,
                                         enterpriseMailAddress: user.enterpriseMailAddress,
                                         attributedName: base.titleHighlighted,
                                         tenantId: user.tenantID,
                                         deniedReasons: reasons,
                                         isOuter: user.isCrossTenant,
                                         isRegistered: user.isRegistered,
                                         isInChat: user.extraFields.isInChat,
                                         isDirectlyInTeam: user.extraFields.isDirectlyInTeam,
                                         p2pChat: p2p)
            meta.isCrypto = user.isCrypto
            meta.status = user.customStatus
            meta.avatarId = typedMeta?.avatarID
            item = PickerItem(meta: .chatter(meta))
        case .groupChatMeta(let chat):
            let meta = PickerChatMeta(id: chat.id,
                                      name: renderData.titleHighlighted?.string,
                                      avatarKey: base.avatarKey,
                                      type: chat.type,
                                      mode: chat.mode,
                                      userCount: chat.userCount,
                                      desc: chat.description_p,
                                      enterpriseMailAddress: chat.enterpriseEmail,
                                      lastMessageId: chat.lastMessageID,
                                      isOuter: chat.isCrossTenant,
                                      isCrypto: chat.isCrypto,
                                      isPublic: chat.isPublicV2,
                                      isMeeting: chat.isMeeting,
                                      isKa: chat.isCrossWithKa,
                                      isShield: chat.isShield,
                                      isInTeam: chat.isInTeam)
            return PickerItem(meta: .chat(meta))
        case .userGroupMeta(let group):
            item = PickerItem(meta: .userGroup(.init(id: group.id, meta: group)))
        case .docMeta(let meta):
            var docMeta = PickerDocMeta(title: title.string, meta: meta)
            if isUseDocIcon {
                docMeta.iconInfo = meta.iconInfo
            }
            let docItem = PickerItem(meta: .doc(docMeta))
            item = docItem
        case .wikiMeta(let meta):
            var wikiMeta = PickerWikiMeta(title: title.string, meta: meta)
            if isUseDocIcon {
                wikiMeta.iconInfo = meta.iconInfo
            }
            item = PickerItem(meta: .wiki(wikiMeta))
        case .wikiSpaceMeta(let meta):
            item = PickerItem(meta: .wikiSpace(.init(title: title.string, meta: meta)))
        case .slashCommandMeta(let meta):
            /// .mailUser实体搜出的结果是开放搜索的类型，且搜索结果是经过服务端特化的（PC先行需求，已经上线），id == mail Address，存在summary中
            if result.base.bid .elementsEqual("lark"),
               (result.base.entityType.elementsEqual("mail-contact") || result.base.entityType.elementsEqual("mail-group") ||
                result.base.entityType.elementsEqual("name-card") || result.base.entityType.elementsEqual("mail_shared_account")) {
                item = PickerItem(meta: .mailUser(.init(id: summary.string,
                                                        title: title.string,
                                                        summary: summary.string,
                                                        mailAddress: summary.string,
                                                        imageURL: meta.imageURL,
                                                        meta: meta)))
            } else {
                break
            }
        @unknown default:
            break
        }
        item.renderData = renderData
        return item
    }

    public func makeItem(chat: LarkModel.Chat) -> PickerItem {
        let meta = PickerChatMeta(id: chat.id,
                                  name: chat.name,
                                  namePinyin: chat.namePinyin,
                                  avatarKey: chat.avatarKey,
                                  ownerId: chat.ownerId,
                                  type: chat.type,
                                  mode: chat.chatMode,
                                  userCount: chat.chatterCount,
                                  lastMessageId: chat.lastMessageId,
                                  isDepartment: chat.isDepartment,
                                  isOuter: chat.isCrossTenant,
                                  isCrypto: chat.isCrypto,
                                  isPublic: chat.isPublic,
                                  isMeeting: chat.isMeeting,
                                  isKa: chat.isCrossWithKa)
        return PickerItem(meta: .chat(meta))
    }

    public func makeItem(externalContact contact: LarkSDKInterface.NewSelectExternalContact,
                                currentTenantId: String) -> PickerItem {
        let info = contact.contactInfo
        let chatter = contact.chatter
        let isOuter: Bool? = {
            if currentTenantId.isEmpty { return nil }
            return info.tenantID != currentTenantId
        }()
        let deniedReasons: [Basic_V1_Auth_DeniedReason]? = {
            if let reason = contact.deniedReason { return [reason] }
            return nil
        }()
        let meta = PickerChatterMeta(id: info.userID,
                                     name: info.userName,
                                     namePinyin: info.namePy,
                                     alias: info.alias,
                                     localizedRealName: chatter?.localizedName,
                                     avatarKey: info.avatarKey,
                                     avatar: chatter?.avatar,
                                     description: info.description_p,
                                     email: chatter?.email,
                                     tenantId: info.tenantID,
                                     tenantName: info.tenantName,
                                     accessInfo: chatter?.accessInfo,
                                     deniedReasons: deniedReasons,
                                     isOuter: isOuter,
                                     isResigned: chatter?.isResigned,
                                     isRegistered: chatter?.isRegistered)
        return PickerItem(meta: .chatter(meta))
    }

    public func makeItem(chatter: LarkModel.Chatter, currentTenantId: String) -> PickerItem {
        let isOuter: Bool? = {
            if currentTenantId.isEmpty { return nil }
            return chatter.tenantId != currentTenantId
        }()
        let meta = PickerChatterMeta(id: chatter.id,

                                     name: chatter.name,
                                     namePinyin: chatter.namePinyin,
                                     alias: chatter.alias,
                                     localizedRealName: chatter.localizedName,
                                     avatarKey: chatter.avatarKey,
                                     avatar: chatter.avatar,
                                     description: chatter.description_p.text,
                                     email: chatter.email,
                                     enterpriseMailAddress: chatter.enterpriseEmail,
                                     tenantId: chatter.tenantId,
                                     accessInfo: chatter.accessInfo,
                                     tagData: chatter.tagData,
                                     deniedReasons: chatter.deniedReasons,
                                     isOuter: isOuter,
                                     isResigned: chatter.isResigned,
                                     isRegistered: chatter.isRegistered)
        return PickerItem(meta: .chatter(meta))
    }

    public func makeItem(forward item: LarkMessengerInterface.ForwardItem) -> PickerItem {
        var result = PickerItem.empty()
        if item.type == .user {
            var meta = PickerChatterMeta(
                id: item.id,
                name: item.name,
                localizedRealName: item.localizeName,
                avatarKey: item.avatarKey,
                enterpriseMailAddress: item.enterpriseMailAddress,
                deniedReasons: item.deniedReasons,
                isOuter: item.isCrossTenant,
                isKa: item.isCrossWithKa)
            if let chatId = item.chatId, !chatId.isEmpty {
                meta.p2pChat = PickerChatMeta(id: chatId, type: .p2P, isShield: item.isPrivate)
            }
            meta.isMyAI = item.type.isMyAi
            result.meta = .chatter(meta)
        } else if item.type == .chat {
            var meta = PickerChatMeta(
                id: item.id,
                name: item.name,
                avatarKey: item.avatarKey,
                type: .group,
                mode: item.isThread ? .threadV2 : .default,
                enterpriseMailAddress: item.enterpriseMailAddress,
                isOuter: item.isCrossTenant,
                isCrypto: item.isCrypto,
                isKa: item.isCrossWithKa,
                isShield: item.isPrivate)
            result.meta = .chat(meta)
        }
        return result
    }

    public func makeItem(userGroup: LarkSDKInterface.SelectVisibleUserGroup) -> PickerItem {
        var meta = RustPB.Search_V2_UserGroupMeta()
        meta.id = userGroup.id
        meta.type = userGroup.groupType.rawValue
        meta.name = userGroup.name
        return PickerItem(meta: .userGroup(.init(id: userGroup.id, meta: meta)))
    }

    // MARK: - Private
    private func getLocalizeName(i18n: [String: String]) -> String? {
        let currentLocalizations = LanguageManager.currentLanguage.rawValue.lowercased()
        var result = i18n[currentLocalizations]
        if result.isEmpty { // 没有匹配语言的名字时使用英文兜底
            result = i18n["en_us"]
        }
        return result
    }
}
