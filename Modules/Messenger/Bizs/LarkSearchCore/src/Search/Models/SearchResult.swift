//
//  SearchResult.swift
//  LarkSearchCore
//
//  Created by SolaWing on 2021/1/8.
//

import UIKit
import Foundation
import RustPB
import ServerPB
import LarkModel
import EEAtomic
import LarkSDKInterface
import LarkSearchFilter
import Homeric
import LarkListItem
import LarkMessengerInterface
import LarkAccountInterface

/// Search NameSpace
extension Search {
    /// V2 Result Wrapper
    public final class Result: SearchResultType {

        public var card: Search.Card?
        public let base: Search_V2_SearchResult
        public let contextID: String?

        public init(base: Search_V2_SearchResult, contextID: String?) {
            self.base = base
            self.contextID = contextID

            self._title = SafeLazy {
                return SearchAttributeString(searchHighlightedString: base.titleHighlighted.removeNewLines()).attributeText
            }
            self._summary = SafeLazy {
                return SearchAttributeString(searchHighlightedString: base.summaryHighlighted.removeNewLines()).attributeText
            }
            self._extra = SafeLazy {
                return SearchAttributeString(searchHighlightedString: base.extrasHighlighted.removeNewLines()).attributeText
            }
        }

        public var id: String { base.id }
        public var type: Search.Types { Types(base.type) }
        public var avatarKey: String { base.avatarKey }
        public var avatarID: String? { base.resultMeta.typedMeta?.avatarID }
        @SafeLazy public var title: NSAttributedString
        public func title(by tag: String) -> NSAttributedString { title }
        @SafeLazy public var summary: NSAttributedString
        @SafeLazy public var extra: NSAttributedString
        public func extra(by tag: String) -> NSAttributedString { extra }

        public var meta: Search.Meta? { base.asSearchMeta() }

        public func getV2Meta() -> Search_V2_SearchResult.ResultMeta.OneOf_TypedMeta? { base.resultMeta.typedMeta }

        public var icon: Basic_V1_Icon? {
            switch getV2Meta() {
            case .docMeta(let meta):
                return meta.hasIcon ? meta.icon : nil
            @unknown default: return nil
            }
        }
        public var imageURL: String {
            switch getV2Meta() {
            case .urlMeta(let m2):
                if m2.hasIconURL, !m2.iconURL.isEmpty { return m2.iconURL }
            case .slashCommandMeta(let m2):
                if m2.hasImageURL, !m2.imageURL.isEmpty { return m2.imageURL }
            @unknown default: break
            }
            return ""
        }
        public var tags: [Basic_V1_Tag] { base.tags }
        public var explanationTags: [Search_V2_ExplanationTag] { base.explanationTags }
        public var renderData: String { base.renderData }
        public var sourceType: Search_V2_ResultSourceType { base.sourceType }

        public var bid: String { base.bid }

        public var entityType: String { base.entityType }

        public var isSpotlight: Bool = false
        public var extraInfos: [Search_V2_ExtraInfoBlock] { base.extraInfos }
        public var extraInfoSeparator: String { base.extraInfoSeparator }
    }

    /// V2 card
    public final class CardResult: SearchResultType {

        public var historyType: SearchHistoryType = .chat

        init(id: String, renderContent: String, templateName: String) {
            self.id = id
            self.card = Search.Card(id: id, renderContent: renderContent, templateName: templateName)
        }

        public var id: String

        public var type: Search.Types {
            .ServiceCard
        }

        public var contextID: String? { "" }

        public var avatarID: String? { "" }

        public var avatarKey: String { "" }

        public var summary: NSAttributedString {
            SearchAttributeString(searchHighlightedString: "").attributeText
        }

        public func extra(by tag: String) -> NSAttributedString {
            SearchAttributeString(searchHighlightedString: "").attributeText
        }

        public func title(by tag: String) -> NSAttributedString {
            SearchAttributeString(searchHighlightedString: "").attributeText
        }

        public var meta: Search.Meta? { nil }

        public var card: Search.Card?

        public var icon: Basic_V1_Icon? { nil }

        public var imageURL: String { "" }

        public var tags: [Basic_V1_Tag] = []

        public var bid: String { "" }

        public var entityType: String { "" }

        public var isSpotlight: Bool = false
        public var extraInfos: [Search_V2_ExtraInfoBlock] = []
        public var extraInfoSeparator: String { "" }
    }

    public final class UniversalRecommendResult: SearchResultType {
        public var card: Search.Card?
        public let base: ServerPB_Usearch_SearchResult
        public let contextID: String?

        public init(base: ServerPB_Usearch_SearchResult, contextID: String?) {
            self.base = base
            self.contextID = contextID

            self._title = SafeLazy { SearchAttributeString(searchHighlightedString: base.titleHighlighted).attributeText }
            self._summary = SafeLazy { SearchAttributeString(searchHighlightedString: base.summaryHighlighted).attributeText }
            self._extra = SafeLazy { SearchAttributeString(searchHighlightedString: base.extrasHighlighted).attributeText }
        }

        public var id: String { base.id }
        public var type: Search.Types { Search.Types(base.type) }
        public var avatarKey: String { base.avatarKey }
        public var avatarID: String? { base.resultMeta.typedMeta?.avatarID }
        @SafeLazy public var title: NSAttributedString
        public func title(by tag: String) -> NSAttributedString { title }
        @SafeLazy public var summary: NSAttributedString
        @SafeLazy public var extra: NSAttributedString
        public func extra(by tag: String) -> NSAttributedString { extra }
        public var meta: Search.Meta? { base.asSearchMeta() }
        public var icon: Basic_V1_Icon? {
            switch base.type {
            case .doc:
                let meta = base.resultMeta.docMeta
                return meta.hasIcon ? meta.icon.toV1Icon() : nil
            @unknown default: return nil
            }
        }
        public var imageURL: String {
            switch base.type {
            case .url:
                let meta = base.resultMeta.urlMeta
                if meta.hasIconURL, !meta.iconURL.isEmpty {
                    return meta.iconURL
                }
            case .slashCommand:
                let meta = base.resultMeta.slashCommandMeta
                if meta.hasImageURL, !meta.imageURL.isEmpty {
                    return meta.imageURL
                }
            default: break
            }
            return ""
        }

        public var tags: [Basic_V1_Tag] { [] }

        public var historyType: SearchHistoryType {
            switch base.type {
            case .user, .bot:
                return SearchHistoryType.chatter
            case .groupChat, .cryptoP2PChat:
                return SearchHistoryType.chat
            @unknown default:
                return SearchHistoryType.chat
            }
        }

        public var bid: String { "" }

        public var entityType: String { "" }

        public var isSpotlight: Bool = false
        public var extraInfos: [Search_V2_ExtraInfoBlock] = []
        public var extraInfoSeparator: String { "" }
    }
}

public extension ServerPB_Usearch_SearchResult {
    func asSearchMeta() -> Search.Meta? {
        switch resultMeta.typedMeta {
        case .userMeta(var meta):
            // 通用推荐默认是注册过的用户
            meta.isRegistered = true
            return .chatter(meta)
        case .botMeta(let meta): return .chatter(meta)
        case .groupChatMeta(let meta):
            guard !meta.isCrypto else {
                return nil
            }
            return .chat(meta)
//        case .cryptoP2PChatMeta(let meta): return .cryptoP2PChat(meta)
        case .messageMeta(let meta): return .message(meta)
//        case .oncallMeta(let meta): return .oncall(meta)
//        case .threadMeta(let meta): return .thread(meta)
//        case .urlMeta(let meta): return .link(meta)
//        case .qaCardMeta(let meta): return
//        case .appMeta(let meta): return .openApp(meta)
//        case .departmentMeta(let meta): return .department(meta)
//        case .docMeta(let meta): return .doc(meta)
//        case .wikiMeta(let meta): return .wiki(meta)
//        case .qaCardMeta(let meta): return .qaCard(meta)
//        case .slashCommandMeta(let meta): return .slash(meta)
//        case .customizationMeta(let meta): return .customization(meta)
//        case .sectionMeta(let meta):
//        case .resourceMeta(let meta):
        case .some(let meta):
            assertionFailure("unimplemented type \(self.type.rawValue) \(meta)")
            return nil
        case nil:
            return nil
        @unknown default:
            return nil
        }
    }
    // 仅用于转化会话类型筛选器的筛选项
    func transformFilterChatForwardItem(userService: PassportUserService?) -> ForwardItem? {
        guard self.type == .groupChat else { return nil }
        let item = ForwardItem(avatarKey: self.avatarKey,
                               name: self.title.string,
                               subtitle: self.summary.string,
                               description: "",
                               descriptionType: Chatter.DescriptionType.onDefault,
                               localizeName: self.title.string,
                               id: self.id,
                               chatId: self.id,
                               type: ForwardItemType.chat,
                               isCrossTenant: false,
                               isCrypto: false,
                               isThread: false,
                               doNotDisturbEndTime: 0,
                               hasInvitePermission: true,
                               userTypeObservable: userService?.state.map { $0.user.type } ?? .never(),
                               enableThreadMiniIcon: false,
                               isOfficialOncall: false)
        return item
    }
    var title: NSAttributedString {
        SearchAttributeString(searchHighlightedString: titleHighlighted.removeNewLines()).attributeText
    }
    var summary: NSAttributedString {
        SearchAttributeString(searchHighlightedString: summaryHighlighted.removeNewLines()).attributeText
    }
}

extension Search.Result: SearchHistoryModel {
    public var historyType: SearchHistoryType {
        switch type {
        case .chatter, .bot:
            return SearchHistoryType.chatter
        case .chat, .cryptoP2PChat, .shieldP2PChat:
            return SearchHistoryType.chat
        default:
            return SearchHistoryType.chat
        }
    }
}

extension UniversalRecommendSection {
    init(section: ServerPB_Search_urecommend_RecommendEntitySection) {
        self.init(style: section.layoutStyle,
                  title: section.title,
                  paginationToken: section.paginationToken,
                  enTitle: section.enTitle,
                  results: section.results.map { Search.UniversalRecommendResult(base: $0, contextID: nil) })
    }
}

extension Search.Result {

    var chatID: String {
        if case let .chat(meta) = meta {
            return meta.id
        } else if case let .chatter(meta) = meta {
            return meta.p2PChatID
        }
        return ""
    }

    var chatterID: String {
        return base.id
    }

    var description: String {
        if case let .chatter(meta) = meta {
            return meta.description_p
        }
        return ""
    }

    var descriptionFlag: Chatter.Description.TypeEnum {
        if case let .chatter(meta) = meta {
            return meta.descriptionFlag
        }
        return .onDefault
    }

    public func convertToChatPickerItem() -> SearchChatPickerItem? {
        switch meta {
        case .chat(let chat):
            return SearchChatPickerItem(id: id,
                                        name: name,
                                        chatID: chatID,
                                        chatterID: chatterID,
                                        avatarKey: avatarKey,
                                        avatarID: avatarID ?? "",
                                        description: description,
                                        descriptionFlag: descriptionFlag,
                                        extraInfo: .searchResult(meta: .chat(isCrossTenant: chat.isCrossTenant, isCrossWithKa: chat.isCrossWithKa, userCountText: chat.userCountText),
                                                                 subtitle: summary,
                                                                 title: title,
                                                                 extra: extra))
        case .chatter(let chatter):
            return SearchChatPickerItem(id: id,
                                        name: name,
                                        chatID: chatID,
                                        chatterID: chatterID,
                                        avatarKey: avatarKey,
                                        avatarID: avatarID ?? "",
                                        description: description,
                                        descriptionFlag: descriptionFlag,
                                        extraInfo: .searchResult(meta: .chatter(tenantID: chatter.tenantID), subtitle: summary, title: title, extra: extra),
                                        groupID: chatID)
        default: return nil
        }
    }
}

extension Search_V2_SearchResult.ResultMeta.OneOf_TypedMeta {
    public var avatarID: String? {
        switch self {
        case .threadMeta(let meta): return meta.channel.id
        case .groupChatMeta(let meta): return meta.id
        case .userMeta(let meta): return meta.id
        case .cryptoP2PChatMeta(let meta): return meta.chatterID
        case .shieldP2PChatMeta(let meta): return meta.chatterID
        case .botMeta(let meta): return meta.id
        case .oncallMeta(let meta): return meta.id
        case .mailContactMeta(let meta): return meta.id
        default: return nil
        }
    }
}

extension String {
    func removeNewLines() -> String {
        return self.replacingOccurrences(of: "\n",
                                         with: " ",
                                         options: .caseInsensitive,
                                         range: nil)
    }

}

extension Search_V2_ExtraInfoBlock {
    public static func mergeExtraInfoBlocks(blocks: [Search_V2_ExtraInfoBlock], separator: String) -> NSAttributedString {
        var infoTextHighlighted = ""
        for (index, item) in blocks.enumerated() {
            for segment in item.blockSegments {
                if segment.type == .timestamp {
                    let segmentTime = Int(segment.textHighlighted) ?? 0
                    infoTextHighlighted += Date.lf.getNiceDateString(TimeInterval(segmentTime))
                } else {
                    infoTextHighlighted += segment.textHighlighted
                }
            }
            if index != blocks.count - 1 {
                infoTextHighlighted += separator
            }
        }
        return SearchAttributeString(searchHighlightedString: infoTextHighlighted).attributeText
    }
}
