//
//  SearchFilter+AdvancedSearch.swift
//  LarkSearchFilter
//
//  Created by wangjingcan on 2023/6/30.
//

import Foundation
import LarkSetting

extension SearchFilter {

    // 筛选器原始名称
    // 拷贝自title方法，去除选中筛选器后的变化
    public var name: String {
        switch self {
        case let .recommend(filter):
            return filter.title
        case let .specificFilterValue(filter, frontTitle, _):
            return specificFilterValueTitle(filter: filter, frontTitle: frontTitle)
        case let .commonFilter(commonFilter):
            switch commonFilter {
            case .mainFrom:
                return BundleI18n.LarkSearchFilter.Lark_ASL_NewFilter_FromUserFilterPortal
            case .mainWith:
                return BundleI18n.LarkSearchFilter.Lark_Search_IMAndDocsFilters_GroupChatParticipantFilter_FieldName
            case .mainIn:
                return BundleI18n.LarkSearchFilter.Lark_ASL_NewFilter_InChat
            case .mainDate(_):
                return BundleI18n.LarkSearchFilter.Lark_Search_MobileSearchTimeFilter
            }
        case let .chatter(mode, _, _, _, _):
            switch mode {
            case .thread:
                return BundleI18n.LarkSearchFilter.Lark_Search_SearchChannelsMemberFilter
            default:
                return BundleI18n.LarkSearchFilter.Lark_ASL_NewFilter_FromUserFilterPortal
            }
        case .withUsers:
            return BundleI18n.LarkSearchFilter.Lark_Search_IMAndDocsFilters_GroupChatParticipantFilter_FieldName
        case let .chat(mode, _):
            switch mode {
            case .thread:
                return BundleI18n.LarkSearchFilter.Lark_Search_SearchChannelsFilter
            default:
                return BundleI18n.LarkSearchFilter.Lark_Search_SearchChatFilter
            }
        case .date(_, let source):
            switch source {
            case .message, .commonFilter:
                return BundleI18n.LarkSearchFilter.Lark_Search_MobileSearchTimeFilter
            case .doc:
                return BundleI18n.LarkSearchFilter.Lark_NewSearch_SecondarySearch_Docs_TimeRangeFilter_DateViewed
            }
        case .docOwnedByMe:
            return BundleI18n.LarkSearchFilter.Lark_Search_DocsOwnedByMeFilter_Option
        case .docPostIn:
            return BundleI18n.LarkSearchFilter.Lark_Search_SearchSpaceSharedIn
        case .docFrom:
            return BundleI18n.LarkSearchFilter.Lark_ASL_NewFilter_FromUserFilterPortal
        case .docFormat(_, let source):
            switch source {
            case .main:
                let docWikiFilterEnabled = FeatureGatingManager.shared.featureGatingValue(with: "lark.search.doc.wiki.filter")
                if docWikiFilterEnabled {
                    return BundleI18n.LarkSearchFilter.Lark_Search_DocFormat
                } else {
                    return BundleI18n.LarkSearchFilter.Lark_Search_DocType
                }
            case .inChat:
                return BundleI18n.LarkSearchFilter.Lark_Search_DocTypeFilter
            }
        case .docType(_):
            return BundleI18n.LarkSearchFilter.Lark_NewSearch_SecondarySearch_Docs_RangeFilter_Source
        case .docCreator, .wikiCreator:
            return BundleI18n.LarkSearchFilter.Lark_Search_DocOwnerFilter
        case .docSharer:
            return BundleI18n.LarkSearchFilter.Lark_Search_ResultTagShared
        case .docSortType(_):
            return BundleI18n.LarkSearchFilter.Lark_DocsAndGroupSearch_Rank
        case .docFolderIn(_):
            return BundleI18n.LarkSearchFilter.Lark_ASLSearch_DocsTabFilters_InFolder_Filter
        case .docWorkspaceIn(_):
            return BundleI18n.LarkSearchFilter.Lark_ASLSearch_DocsTabFilters_InWorkspace_Filter
        case let .chatMemeber(mode, _):
            switch mode {
            case .thread:
                return BundleI18n.LarkSearchFilter.Lark_Search_SearchChannelsByIncludedMembers
            default:
                return BundleI18n.LarkSearchFilter.Lark_Search_IMAndDocsFilters_GroupChatParticipantFilter_FieldName
            }
        case .chatKeyWord(_):
            return BundleI18n.LarkSearchFilter.Lark_Search_SearchGroupByMessage
        case .chatType(_):
            return BundleI18n.LarkSearchFilter.Lark_Search_SearchGroupByGroupType
        case .groupSortType(_):
            return BundleI18n.LarkSearchFilter.Lark_DocsAndGroupSearch_Rank
        case .threadType(_):
            return BundleI18n.LarkSearchFilter.Lark_Search_SearchChannelsByChannelType
        case .messageType(_):
            return BundleI18n.LarkSearchFilter.Lark_Search_MessageType
        case .messageMatch(_):
            return BundleI18n.LarkSearchFilter.Lark_MessageSearch_MatchObject
        case .messageChatType(_):
            return BundleI18n.LarkSearchFilter.Lark_ASL_SearchMessagesFilters_FilterChatType
        case .docContentType(_):
            return BundleI18n.LarkSearchFilter.Lark_DocsSearch_MatchContent
        case .general(let generalFilter):
            return generalFilter.name
        case .messageAttachmentType(_):
            return BundleI18n.LarkSearchFilter.Lark_MessageSearch_TypeOfMessage
        }
    }

    public var content: String {
        guard !self.isEmpty else { return "" }
        switch self {
        case let .recommend(filter):
            return filter.title
        case let .specificFilterValue(filter, frontTitle, _):
            return specificFilterValueTitle(filter: filter, frontTitle: frontTitle)
        case let .commonFilter(commonFilter):
            switch commonFilter {
            case let .mainFrom(fromIds, _, _, _):
                return self.getMoreTextByFilter(prefix: fromIds.first?.name, count: fromIds.count)
            case let .mainWith(withIds):
                return self.getMoreTextByFilter(prefix: withIds.first?.name, count: withIds.count)
            case let .mainIn(items):
                return self.getMoreTextByFilter(prefix: items.first?.name, count: items.count)
            case .mainDate(let date):
                return self.getDateStr(date)
            }
        case let .chatter(_, pickers, _, _, _):
            return self.getMoreTextByFilter(prefix: pickers.first?.name, count: pickers.count)
        case let .withUsers(pickers):
            return self.getMoreTextByFilter(prefix: pickers.first?.name, count: pickers.count)
        case let .chat(_, pickers):
            return self.getMoreTextByFilter(prefix: pickers.first?.name, count: pickers.count)
        case let .date(date, _):
            return self.getDateStr(date)
        case .docOwnedByMe:
            return BundleI18n.LarkSearchFilter.Lark_Search_DocsOwnedByMeFilter_Option
        case let .docPostIn(items):
            return self.getMoreTextByFilter(prefix: items.first?.name, count: items.count)
        case let .docFrom(fromIds, _, _, _):
            return self.getMoreTextByFilter(prefix: fromIds.first?.name, count: fromIds.count)
        case .docFormat(let docFilter, let source):
            switch source {
            case .main:
                return docFilter.map({ $0.title }).joined(separator: "、")
            case .inChat:
                return docFilter.map { $0.title }.joined()
            }
        case .docType(let type):
            return type.name
        case let .docCreator(items, _), let .wikiCreator(items):
            return self.getMoreTextByFilter(prefix: items.first?.name, count: items.count)
        case let .docSharer(items):
            return self.getMoreTextByFilter(prefix: items.first?.name, count: items.count)
        case .docSortType(let docSortType):
            return docSortType.title
        case .docFolderIn(let items):
            return self.getMoreTextByFilter(prefix: items.first?.name, count: items.count)
        case .docWorkspaceIn(let items):
            return self.getMoreTextByFilter(prefix: items.first?.name, count: items.count)
        case let .chatMemeber(_, pickers):
            return self.getMoreTextByFilter(prefix: pickers.first?.name, count: pickers.count)
        case let .chatKeyWord(keyWord):
            return keyWord
        case .chatType(let types):
            return types.map({ $0.name }).joined(separator: "、")
        case let .groupSortType(groupSortType):
            return groupSortType.title
        case let .threadType(type):
            return "\(type.title)"
        case let .messageType(type):
            switch type {
            case .all:
               return ""
            case .link:
                return BundleI18n.LarkSearchFilter.Lark_Search_Link
            case .file:
                return BundleI18n.LarkSearchFilter.Lark_Search_FileSearchFilter
            @unknown default:
                return ""
            }
        case .messageMatch(let types):
            return types.map({ $0.name }).joined(separator: "、")
        case .messageChatType(let types):
            return types.name
        case .docContentType(let type):
            return type.name
        case .general(let generalFilter):
            return generalFilter.content
        case .messageAttachmentType(let type):
            switch type {
            case .attachmentLink:
                return BundleI18n.LarkSearchFilter.Lark_Search_Link
            case .attachmentFile:
                return BundleI18n.LarkSearchFilter.Lark_Search_FileSearchFilter
            case .attachmentImage:
                return BundleI18n.LarkSearchFilter.Lark_Search_Image
            case .attachmentVideo:
                return BundleI18n.LarkSearchFilter.Lark_Search_Video
            default:
                return ""
            }
        }
    }

    private func getDateStr(_ date: FilterDate?) -> String {
        if let date = date {
            return getTimeRangeString(date: date)
        } else {
            return BundleI18n.LarkSearchFilter.Lark_Search_MobileSearchTimeFilter
        }
    }

    private func getMoreTextByFilter(prefix: String?, count: Int) -> String {
        guard let prefix = prefix else { return "\(count)" }
        return prefix
    }

}
