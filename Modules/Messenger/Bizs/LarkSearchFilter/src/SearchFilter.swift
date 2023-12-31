//
//  SearchFilter.swift
//  LarkSearch
//
//  Created by SuPeng on 4/18/19.
//

import Foundation
import LarkModel
import RxSwift
import LarkSDKInterface
import ServerPB
import RustPB
import LarkSetting
import ByteWebImage
import LarkMessengerInterface
import LarkAccountInterface
import Swinject
import UIKit
import LarkBizAvatar
import LarkCore

protocol ChatFilterTypeConvertable {
    func toChatFilterType() -> ChatFilterType
}

public extension ChatFilterType {
    func toV1ChatFilterType() -> Search_V1_ChatFilterParam.ChatType {
        switch self {
        case .outer: return .outer
        case .private: return .private
        case .publicAbsent: return .publicAbsent
        case .publicJoin: return .publicJoin
        case .unknowntab: return .unknowntab
        @unknown default: return .unknowntab
        }
    }
}

extension ChatFilterParam.ChatType: ChatFilterTypeConvertable {
    func toChatFilterType() -> ChatFilterType {
        switch self {
        case .outer: return .outer
        case .private: return .private
        case .publicAbsent: return .publicAbsent
        case .publicJoin: return .publicJoin
        case .unknowntab: return .unknowntab
        @unknown default: return .unknowntab
        }
    }
}

extension ServerPB_Searches_ChatFilterParam.ChatType: ChatFilterTypeConvertable {
    func toChatFilterType() -> ChatFilterType {
        switch self {
        case .outer: return .outer
        case .private: return .private
        case .publicAbsent: return .publicAbsent
        case .publicJoin: return .publicJoin
        case .unknowntab: return .unknowntab
        @unknown default: return .unknowntab
        }
    }
}

public extension DocContentType {
    var name: String {
        switch self {
        case .fullContent: return BundleI18n.LarkSearchFilter.Lark_DocsSearch_MatchContent
        case .onlyTitle: return BundleI18n.LarkSearchFilter.Search_Filter_Doc_OnlyTitle
        case .onlyComment: return BundleI18n.LarkSearchFilter.Lark_Search_FilterMatchComment
        }
    }
}

func getTimeRangeString(date: SearchFilter.FilterDate) -> String {
    let startYear = date.startDate?.year ?? Date().year
    let endYear = date.endDate?.year ?? Date().year
    let showYear: Bool = !(startYear == endYear && startYear == Date().year)

    let dateFormatter: (Date) -> String = { date in
        if !showYear {
            return "\(date.month)/\(date.day)"
        } else {
            return "\(date.year)/\(date.month)/\(date.day)"
        }
    }
    let startDateString = date.startDate.flatMap { dateFormatter($0) } ?? BundleI18n.LarkSearchFilter.Lark_Search_AnyTime
    let endDateString = date.endDate.flatMap { dateFormatter($0) } ?? BundleI18n.LarkSearchFilter.Lark_Search_AnyTime
    return " \(startDateString)-\(endDateString)"
}

public struct MainSearchCalendarItem: Equatable {
    public var id: String
    public var title: String
    public var isSelected: Bool // 搜索用户是否选中
    public var isOwner: Bool
    // swiftlint:disable init_color_with_token
    public var color: UIColor
    // swiftlint:enable init_color_with_token
    public init(id: String, title: String, color: UIColor, isOwner: Bool, isSelected: Bool) {
        self.id = id
        self.title = title
        self.color = color
        self.isSelected = isSelected
        self.isOwner = isOwner
    }
    public static func == (lhs: MainSearchCalendarItem, rhs: MainSearchCalendarItem) -> Bool {
        return lhs.id.elementsEqual(rhs.id)
    }

    public static func sortCalendarItems(items: [MainSearchCalendarItem]) -> [MainSearchCalendarItem] {
        let selectedItems = items.filter { item in
            item.isSelected
        }.sorted { lItem, rItem in
            switch (lItem.isOwner, rItem.isOwner) {
            case(true, false):
                return true
            case(false, true):
                return false
            default:
                return true
            }
        }
        let unSelectedItems = items.filter { item in
            !item.isSelected
        }.sorted { lItem, rItem in
            switch (lItem.isOwner, rItem.isOwner) {
            case(true, false):
                return true
            case(false, true):
                return false
            default:
                return true
            }
        }
        return selectedItems + unSelectedItems
    }
}

public enum SearchFilter {
    public enum AdvancedSyntaxFilterType: String {
        case fromFilter = "from"
        case withFilter = "with"
        case inFilter = "in"
        public var title: String {
            switch self {
            case .fromFilter:
                return BundleI18n.LarkSearchFilter.Lark_ASL_NewFilter_FromUserFilterPortal
            case .withFilter:
                return BundleI18n.LarkSearchFilter.Lark_Search_IMAndDocsFilters_GroupChatParticipantFilter_FieldName
            case .inFilter:
                return BundleI18n.LarkSearchFilter.Lark_ASL_NewFilter_InChat
            }
        }
    }
    public enum Source: Equatable, CaseIterable {
        case main, inChat
    }
    public enum DocType: Equatable, CaseIterable {
        case wiki, doc, all
        public var name: String {
            let capsuleEnable = Container.shared.getCurrentUserResolver().fg.staticFeatureGatingValue(with: "search.redesign.capsule")
            switch self {
            case .all:
                if capsuleEnable {
                    return BundleI18n.LarkSearchFilter.Lark_NewSearch_SecondarySearch_Docs_RangeFilter_Source
                } else {
                    return BundleI18n.LarkSearchFilter.Lark_Search_DocType
                }
            case .doc:
                if capsuleEnable {
                    return BundleI18n.LarkSearchFilter.Lark_NewSearch_SecondarySearch_Docs_RangeFilter_NoWiki
                } else {
                    return BundleI18n.LarkSearchFilter.Lark_Search_SearchDoc
                }
            case .wiki:
                if capsuleEnable {
                    return BundleI18n.LarkSearchFilter.Lark_NewSearch_SecondarySearch_Docs_RangeFilter_WikiOnly
                } else {
                    return BundleI18n.LarkSearchFilter.Lark_Search_SearchWiki
                }
            }
        }
    }
    public enum FromType {
        case user, recommended

        var trackingRepresentation: String {
            switch self {
            case .user: return "none"
            case .recommended: return "recommend"
            }
        }
    }
    public enum RecommendSourceType: String {
        case fromQuery, fromResults
        var trackingRepresentation: String { rawValue }
    }
    public enum DocSortType: Equatable, CaseIterable {
        case mostRelated
        case mostRecentUpdated
        case mostRecentCreated
        public var title: String {
            switch self {
            case .mostRelated: return BundleI18n.LarkSearchFilter.Lark_DocsAndGroupSearch_Rank
            case .mostRecentUpdated: return BundleI18n.LarkSearchFilter.Lark_DocsAndGroupSearch_RankByUpdateTime
            case .mostRecentCreated: return BundleI18n.LarkSearchFilter.Lark_DocsAndGroupSearch_Rank_CreationTime
            }
        }

        public var name: String {
            switch self {
            case .mostRelated: return BundleI18n.LarkSearchFilter.Lark_DocsAndGroupSearch_RankByRelevance
            case .mostRecentUpdated: return BundleI18n.LarkSearchFilter.Lark_DocsAndGroupSearch_RankByUpdateTime
            case .mostRecentCreated: return BundleI18n.LarkSearchFilter.Lark_DocsAndGroupSearch_Rank_CreationTime
            }
        }
        public var trackingRepresentation: String {
            switch self {
            case .mostRelated: return "most_relevant"
            case .mostRecentUpdated: return "recently_updated"
            case .mostRecentCreated: return "recently_created"
            }
        }
    }
    public enum GroupSortType: Equatable, CaseIterable {
        case mostRelated
        case mostRecentUpdated
        case mostRecentCreated
        case leastNumGroupMember
        public var title: String {
            switch self {
            case .mostRelated: return BundleI18n.LarkSearchFilter.Lark_DocsAndGroupSearch_Rank
            case .mostRecentUpdated: return BundleI18n.LarkSearchFilter.Lark_DocsAndGroupSearch_RankByUpdateTime
            case .mostRecentCreated: return BundleI18n.LarkSearchFilter.Lark_DocsAndGroupSearch_Rank_CreationTime
            case .leastNumGroupMember: return BundleI18n.LarkSearchFilter.Lark_ASL_SearchGroupLeastMember_Filter
            }
        }

        public var name: String {
            switch self {
            case .mostRelated: return BundleI18n.LarkSearchFilter.Lark_DocsAndGroupSearch_RankByRelevance
            case .mostRecentUpdated: return BundleI18n.LarkSearchFilter.Lark_DocsAndGroupSearch_RankByUpdateTime
            case .mostRecentCreated: return BundleI18n.LarkSearchFilter.Lark_DocsAndGroupSearch_Rank_CreationTime
            case .leastNumGroupMember: return BundleI18n.LarkSearchFilter.Lark_ASL_SearchGroupLeastMember_Filter
            }
        }

        public var trackingRepresentation: String {
            switch self {
            case .mostRelated: return "most_relevant"
            case .mostRecentUpdated: return "recently_updated"
            case .mostRecentCreated: return "recently_created"
            case .leastNumGroupMember: return "least_member"
            }
        }
    }

    public struct FilterDate: Equatable {
        public var startDate: Date?
        public var endDate: Date?

        public init(startDate: Date?, endDate: Date?) {
            self.startDate = startDate
            self.endDate = endDate
        }

        public static func == (lhs: FilterDate, rhs: FilterDate) -> Bool {
            var sameStart: Bool = false
            var sameEnd: Bool = false
            if let lhsStart = lhs.startDate, let rhsStart = rhs.startDate {
                sameStart = lhsStart.ls.compare(date: rhsStart) == .orderedSame
            } else if lhs.startDate == nil, rhs.startDate == nil {
                sameStart = true
            }
            if let lhsEnd = lhs.endDate, let rhsEnd = rhs.endDate {
                sameEnd = lhsEnd.ls.compare(date: rhsEnd) == .orderedSame
            } else if lhs.endDate == nil, rhs.endDate == nil {
                sameEnd = true
            }
            return sameStart && sameEnd
        }
    }

    public enum MessageContentMatchType: Equatable, CaseIterable {
        case atMe, excludeBot, onlyBot

        public var name: String {
            switch self {
            case .excludeBot: return BundleI18n.LarkSearchFilter.Lark_ASL_SearchMessagesFilters_OptionOnlyContacts
            case .atMe: return BundleI18n.LarkSearchFilter.Search_Filter_Message_Atme
            case .onlyBot: return BundleI18n.LarkSearchFilter.Lark_ASL_SearchMessagesFilters_OptionOnlyBots
            }
        }

        public var trackingRepresentation: String {
            switch self {
            case .excludeBot: return "mustNotFromTypes"
            case .atMe: return "chatAtUserIds"
            case .onlyBot: return "only_bot"
            }
        }
    }

    /// 会话类型： 单聊、群聊
    public enum MessageChatFilterType: Equatable, CaseIterable {
        case groupChat, p2PChat, all
        public var name: String {
            switch self {
            case .all: return BundleI18n.LarkSearchFilter.Lark_ASL_SearchMessagesFilters_FilterChatType
            case .groupChat: return BundleI18n.LarkSearchFilter.Lark_ASL_SearchMessagesFilters_OptionGroupChats
            case .p2PChat: return BundleI18n.LarkSearchFilter.Lark_ASL_SearchMessagesFilters_OptionPrivateChats
            }
        }

        public var trackingRepresentation: String {
            return "chatTypes"
        }
    }
    public enum DateSource: Equatable, CaseIterable {
        case message, doc, commonFilter
    }
    public enum CommonFilter {
        case mainFrom(fromIds: [SearchChatterPickerItem], recommends: [SearchResultType], fromType: FromType, isRecommendResultSelected: Bool)
        /// 会话成员
        case mainWith([SearchChatterPickerItem])
        case mainIn(inIds: [ForwardItem])
        // 时间过滤器
        case mainDate(date: FilterDate?)
    }
    public typealias CustomFilterInfo = ServerPB.ServerPB_Searches_PlatformSearchFilter.CustomFilterInfo
    public enum GeneralFilter {
        public enum Option {
            case searchable(ForwardItem)
            case predefined(SearchChatterPickerItem.GeneralFilterOption)
        }
        case multiple(CustomFilterInfo, [Option])
        case single(CustomFilterInfo, Option?)
        case user(CustomFilterInfo, [SearchChatterPickerItem])
        case date(CustomFilterInfo, FilterDate?)
        case calendar(CustomFilterInfo, [MainSearchCalendarItem])
        case userChat(CustomFilterInfo, [ForwardItem])
        case mailUser(CustomFilterInfo, [LarkModel.PickerItem])
        case inputTextFilter(CustomFilterInfo, [String])
    }
    // 推荐筛选器
    indirect case recommend(SearchFilter)
    // 筛选项, 某个有具体值对筛选器 其文案是经过特殊异化的,大体对齐历史记录，但不完全对齐
    indirect case specificFilterValue(_ filter: SearchFilter, _ frontTitle: String, _ isSelected: Bool)
    // 综合筛选器
    case commonFilter(CommonFilter)
    // 通用筛选器
    case general(GeneralFilter)
    // 消息发布者
    case chatter(mode: ChatFilterMode, picker: [SearchChatterPickerItem], recommends: [SearchResultType], fromType: FromType, isRecommendResultSelected: Bool)
    /// with筛选器
    case withUsers([SearchChatterPickerItem])
    // 消息所在会话
    case chat(mode: ChatFilterMode, picker: [ForwardItem])
    case date(date: FilterDate?, source: DateSource)
    // Doc 相关
    case docOwnedByMe(Bool, String)
    case docType(DocType)
    case docFrom(fromIds: [SearchChatterPickerItem], recommends: [SearchResultType], fromType: FromType, isRecommendResultSelected: Bool)
    case docPostIn([ForwardItem])
    case docFormat([DocFormatType], Source)
    case docCreator([SearchChatterPickerItem], String)
    case docContentType(DocContentType)
    case docSharer([SearchChatterPickerItem])
    case wikiCreator([SearchChatterPickerItem])
    case docSortType(DocSortType)
    case docFolderIn([ForwardItem])
    case docWorkspaceIn([ForwardItem])
    // 包含成员
    case chatMemeber(mode: ChatFilterMode, picker: [SearchChatterPickerItem])
    case chatKeyWord(String)
    case groupSortType(GroupSortType)
    // 群组类型
    case chatType([ChatFilterType])
    // 小组类型
    case threadType(ThreadFilterType)
    // 消息类型：仅链接、仅文件、全部
    case messageType(MessageFilterType)
    // 消息包含附件类型：仅链接、仅文件、仅图片、仅视频
    case messageAttachmentType(MessageAttachmentFilterType)
    case messageMatch([MessageContentMatchType])
    /// 会话类型： 单聊、群聊
    case messageChatType(MessageChatFilterType)
}

public extension SearchFilter {
    var breakedTitle: (String, String) {
        func breakup(_ template: String, with str: String) -> (String, String) {
            guard let range = template.range(of: str) else {
                return ("", "")
            }
            let left = range.lowerBound
            let right = range.upperBound
            let leftPart = template.substring(to: left)
            let rightPart = template.substring(from: right)
            return (leftPart, rightPart)
        }

        switch self {
        case let .recommend(filter):
            let (left, right) = breakup(BundleI18n.LarkSearchFilter.__Lark_ASL_NewFilter_Search_ShowResultsFrom, with: "{{name}}")
            switch filter {
            case let .chatter(_, picker: items, _, _, _):
                guard let first = items.first else {
                    return (left, right)
                }
                let rightWithName = first.name + right
                return (left, rightWithName)
            case let .docFrom(fromIds, _, _, _):
                guard let first = fromIds.first else {
                    return (left, right)
                }
                let rightWithName = first.name + right
                return (left, rightWithName)
            case let .commonFilter(.mainFrom(fromIds, _, _, _)):
                guard let first = fromIds.first else {
                    return (left, right)
                }
                let rightWithName = first.name + right
                return (left, rightWithName)
            default: return (filter.title, "")
            }
        default: return (title, "")
        }
    }

    func dateTitle(date: FilterDate?, source: DateSource) -> String {
        let capsuleEnable = Container.shared.getCurrentUserResolver().fg.staticFeatureGatingValue(with: "search.redesign.capsule")
        if let date = date {
            if capsuleEnable, source == .doc {
                return BundleI18n.LarkSearchFilter.Lark_NewSearch_SecondarySearch_Docs_TimeRangeFilter_DateViewed + getTimeRangeString(date: date)
            } else {
                return BundleI18n.LarkSearchFilter.Lark_Search_MobileSearchTimeFilter + getTimeRangeString(date: date)
            }
        } else {
            switch source {
            case .message:
                return BundleI18n.LarkSearchFilter.Lark_Search_MobileSearchTimeFilter
            case .doc:
                if capsuleEnable {
                    return BundleI18n.LarkSearchFilter.Lark_NewSearch_SecondarySearch_Docs_TimeRangeFilter_DateViewed
                } else {
                    return BundleI18n.LarkSearchFilter.Lark_Search_ViewedTimeFilter
                }
            case .commonFilter:
                return BundleI18n.LarkSearchFilter.Lark_Search_MobileSearchTimeFilter
            }
        }
    }

    //specificFilterValue 推荐筛选器文案异化，单改
    var title: String {
        let capsuleEnable = Container.shared.getCurrentUserResolver().fg.staticFeatureGatingValue(with: "search.redesign.capsule")
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
            case .mainDate(let date):
                return dateTitle(date: date, source: .commonFilter)
            }
        case let .chatter(mode, _, _, _, _):
            switch mode {
            case .thread:
                return BundleI18n.LarkSearchFilter.Lark_Search_SearchChannelsMemberFilter
            @unknown default:
                return BundleI18n.LarkSearchFilter.Lark_ASL_NewFilter_FromUserFilterPortal
            }
        case .withUsers:
            return BundleI18n.LarkSearchFilter.Lark_Search_IMAndDocsFilters_GroupChatParticipantFilter_FieldName
        case let .chat(mode, _):
            switch mode {
            case .thread:
                return BundleI18n.LarkSearchFilter.Lark_Search_SearchChannelsFilter
            @unknown default:
                return BundleI18n.LarkSearchFilter.Lark_Search_SearchChatFilter
            }
        case .date(let date, let source):
            return dateTitle(date: date, source: source)
        case .docOwnedByMe:
            return BundleI18n.LarkSearchFilter.Lark_Search_DocsOwnedByMeFilter_Option
        case .docPostIn:
            return BundleI18n.LarkSearchFilter.Lark_Search_SearchSpaceSharedIn
        case .docFrom:
            return BundleI18n.LarkSearchFilter.Lark_ASL_NewFilter_FromUserFilterPortal
        case .docFormat(let docFilter, let source):
            switch source {
            case .main:
                let docWikiFilterEnabled = Container.shared.getCurrentUserResolver().fg.staticFeatureGatingValue(with: "lark.search.doc.wiki.filter")
                let placeHolder: String
                if docWikiFilterEnabled {
                    placeHolder = BundleI18n.LarkSearchFilter.Lark_Search_DocFormat
                } else {
                    placeHolder = BundleI18n.LarkSearchFilter.Lark_Search_DocType
                }
                if docFilter.isEmpty {
                    return placeHolder
                } else if docFilter.count == 1 {
                    return docFilter[0].title
                } else {
                    return placeHolder + " \(docFilter.count)"
                }
            case .inChat:
                if docFilter.isEmpty {
                    return BundleI18n.LarkSearchFilter.Lark_Search_DocTypeFilter
                } else {
                    return BundleI18n.LarkSearchFilter.Lark_Search_SelectDocTypeFilter + docFilter.map { $0.title }.joined()
                }
            }
        case .docType(let type):
            return type.name
        case .docCreator, .wikiCreator:
            return BundleI18n.LarkSearchFilter.Lark_Search_DocOwnerFilter
        case .docSharer:
            return BundleI18n.LarkSearchFilter.Lark_Search_ResultTagShared
        case .docSortType(let docSortType):
            return docSortType.title
        case .docFolderIn(let items):
            if let firstItemName = items.first?.name, !capsuleEnable {
                return firstItemName
            } else {
                return BundleI18n.LarkSearchFilter.Lark_ASLSearch_DocsTabFilters_InFolder_Filter
            }
        case .docWorkspaceIn(let items):
            if let firstItemName = items.first?.name, !capsuleEnable {
                return firstItemName
            } else {
                return BundleI18n.LarkSearchFilter.Lark_ASLSearch_DocsTabFilters_InWorkspace_Filter
            }
        case let .chatMemeber(mode, _):
            switch mode {
            case .thread:
                return BundleI18n.LarkSearchFilter.Lark_Search_SearchChannelsByIncludedMembers
            @unknown default:
                return BundleI18n.LarkSearchFilter.Lark_Search_IMAndDocsFilters_GroupChatParticipantFilter_FieldName
            }
        case .chatKeyWord(let keyWord):
            if keyWord.isEmpty {
                return BundleI18n.LarkSearchFilter.Lark_Search_SearchGroupByMessage
            } else {
                return BundleI18n.LarkSearchFilter.Lark_Search_SearchGroupByMessage
                    + BundleI18n.LarkSearchFilter.Lark_Legacy_Colon
                    + keyWord
            }
        case .chatType(let types):
            if types.isEmpty {
                return BundleI18n.LarkSearchFilter.Lark_Search_SearchGroupByGroupType
            } else if types.count == 1 {
                return types[0].name
            } else {
                return BundleI18n.LarkSearchFilter.Lark_Search_SearchGroupByGroupType + " \(types.count)"
            }
        case .groupSortType(let groupSortType):
            return groupSortType.title
        case .threadType(let type):
            if type == .all {
                return BundleI18n.LarkSearchFilter.Lark_Search_SearchChannelsByChannelType
            } else {
                return BundleI18n.LarkSearchFilter.Lark_Search_SearchChannelsByChannelType + "：\(type.title)"
            }
        case .messageType(let type):
            switch type {
            case .all:
               return BundleI18n.LarkSearchFilter.Lark_MessageSearch_TypeOfMessage
            case .link:
                return BundleI18n.LarkSearchFilter.Lark_Search_Link
            case .file:
                return BundleI18n.LarkSearchFilter.Lark_Search_FileSearchFilter
            @unknown default:
                return BundleI18n.LarkSearchFilter.Lark_Search_MessageType
            }
        case .messageAttachmentType(let type):
            switch type {
            case .unknownAttachmentType:
                return BundleI18n.LarkSearchFilter.Lark_MessageSearch_TypeOfMessage
            case .attachmentLink:
                return BundleI18n.LarkSearchFilter.Lark_Search_Link
            case .attachmentFile:
                return BundleI18n.LarkSearchFilter.Lark_Search_FileSearchFilter
            case .attachmentImage:
                return BundleI18n.LarkSearchFilter.Lark_Search_Image
            case .attachmentVideo:
                return BundleI18n.LarkSearchFilter.Lark_Search_Video
            @unknown default:
                return ""
            }
        case .messageMatch(let types):
            if types.isEmpty {
                return BundleI18n.LarkSearchFilter.Lark_MessageSearch_MatchObject
            } else if types.count == 1 {
                return types[0].name
            } else {
                return BundleI18n.LarkSearchFilter.Lark_MessageSearch_MatchObject + " \(types.count)"
            }
        case .messageChatType(let types):
            return types.name
        case .docContentType(let type):
            return type.name
        case .general(let generalFilter):
            return generalFilter.title
        }
    }

    func specificFilterValueTitle(filter: SearchFilter, frontTitle: String) -> String {
        var latterPart: String
        switch filter {
        //人，群，文件夹，wiki空间等实体，只会有一个
        case .chat(_, let pickers):
            latterPart = SearchFilter.specificFilterValueTitleLimit(pickers.first?.name ?? "", limit: 10)
        case .withUsers(let pickers):
            latterPart = SearchFilter.specificFilterValueTitleLimit(pickers.first?.name ?? "", limit: 10)
        case .chatter(_, let pickers, _, _, _):
            let currentID = Container.shared.getCurrentUserResolver().userID
            if let chatterID = pickers.first?.chatterID, chatterID.elementsEqual(currentID) {
                return BundleI18n.LarkSearchFilter.Lark_Search_FIlters_FrequentlyUsedFilters_MessagesFromMe
            } else {
                latterPart = SearchFilter.specificFilterValueTitleLimit(pickers.first?.name ?? "", limit: 10)
            }
        case .date(let date, _):
            if let _date = date {
                latterPart = getTimeRangeString(date: _date)
            } else {
                latterPart = ""
            }
        case .messageType(let type):
            switch type {
            case .all:
                latterPart = BundleI18n.LarkSearchFilter.Lark_Legacy_MessageFragmentTitle
            case .file:
                latterPart = BundleI18n.LarkSearchFilter.Lark_Search_FileSearchFilter
            case .link:
                latterPart = BundleI18n.LarkSearchFilter.Lark_Search_Link
            @unknown default:
                latterPart = ""
            }
        case .messageAttachmentType(let type):
            switch type {
            case .unknownAttachmentType:
                latterPart = BundleI18n.LarkSearchFilter.Lark_MessageSearch_TypeOfMessage
            case .attachmentLink:
                latterPart = BundleI18n.LarkSearchFilter.Lark_Search_Link
            case .attachmentFile:
                latterPart = BundleI18n.LarkSearchFilter.Lark_Search_FileSearchFilter
            case .attachmentImage:
                latterPart = BundleI18n.LarkSearchFilter.Lark_Search_Image
            case .attachmentVideo:
                latterPart = BundleI18n.LarkSearchFilter.Lark_Search_Video
            @unknown default:
                latterPart = ""
            }
        case .messageMatch(let types):
            if types.isEmpty {
                latterPart = BundleI18n.LarkSearchFilter.Lark_MessageSearch_MatchObject
            } else if let type = types.first {
                latterPart = type.name
            } else {
                latterPart = ""
            }
        case .messageChatType(let type):
            switch type {
            case .all: return BundleI18n.LarkSearchFilter.Lark_ASL_SearchMessagesFilters_FilterChatType
            case .groupChat: return BundleI18n.LarkSearchFilter.Lark_ASL_SearchMessagesFilters_OptionGroupChats
            case .p2PChat: return BundleI18n.LarkSearchFilter.Lark_ASL_SearchMessagesFilters_OptionPrivateChats
            }
        case .docSortType(let type):
            latterPart = type.name
        case .docType(let type):
            latterPart = type.name
        case .docFrom(let pickers, _, _, _):
            let currentID = Container.shared.getCurrentUserResolver().userID
            if let chatterID = pickers.first?.chatterID, chatterID.elementsEqual(currentID) {
                return BundleI18n.LarkSearchFilter.Lark_Search_FIlters_FrequentlyUsedFilters_MessagesFromMe
            } else {
                latterPart = SearchFilter.specificFilterValueTitleLimit(pickers.first?.name ?? "", limit: 10)
            }
        case .docPostIn(let pickers):
            latterPart = SearchFilter.specificFilterValueTitleLimit(pickers.first?.name ?? "", limit: 10)
        case .docFolderIn(let pickers):
            latterPart = SearchFilter.specificFilterValueTitleLimit(pickers.first?.name ?? "", limit: 10)
        case .docWorkspaceIn(let pickers):
            latterPart = SearchFilter.specificFilterValueTitleLimit(pickers.first?.name ?? "", limit: 10)
        case .docFormat(let type, _):
            latterPart = type.first?.title ?? ""
        case .docContentType(let type):
            latterPart = type.name
        case .docCreator(let pickers, _):
            latterPart = SearchFilter.specificFilterValueTitleLimit(pickers.first?.name ?? "", limit: 10)
        case .docSharer(let pickers):
            latterPart = SearchFilter.specificFilterValueTitleLimit(pickers.first?.name ?? "", limit: 10)
        case .docOwnedByMe:
            return BundleI18n.LarkSearchFilter.Lark_Search_DocsOwnedByMeFilter_Option
        default:
            latterPart = ""
        }
        return frontTitle + latterPart
    }

    static func specificFilterValueTitleLimit(_ title: String, limit: Int) -> String {
        var result = title
        if result.count > limit + 1 {
            result = result.substring(to: limit) + "..."
        }
        return result
    }

    var trackingRepresentation: String {
        switch self {
        case .recommend(let filter): return filter.trackingRepresentation
        case .specificFilterValue(let filter, _, _): return filter.trackingRepresentation
        case .commonFilter(.mainFrom): return "fromUserIds"
        case .commonFilter(.mainIn): return "inChatIds"
        case .commonFilter(.mainWith): return "withIds"
        case .commonFilter(.mainDate(let date)):
            if date?.startDate != nil { return "startTime,endTime" }
            return "endTime"
        case .chatter: return "fromIds"
        case .withUsers: return "messageWithId"
        case .chat: return "chatIds"
        case .date(let date, _):
            if date?.startDate != nil { return "startTime,endTime" }
            return "endTime"
        case .chatMemeber: return "chatMemberIds"
        case .chatType: return "chatTypes"
        case .messageType: return "messageTypes"
        case .messageAttachmentType: return "messageAttachmentType"
        case .chatKeyWord: return "chatMessageKey"
        case .docFormat: return "docTypes"
        case .docType: return "docTypes"
        case .docCreator: return "docsAuthor"
        case .docSharer: return "docShares"
        case .docPostIn: return "docsChatIds"
        case .docOwnedByMe: return "docMyown"
        case .docContentType: return "docSearchType"
        case .docFrom: return "docFromIds"
        case .docSortType: return "docSortType"
        case .messageChatType: return "chatTypes"
        case .docFolderIn: return "docsFolder"
        case .docWorkspaceIn: return "docsWorkspace"
        case .groupSortType: return "groupSortType"
        case .messageMatch(let types):
            return types.map { $0.trackingRepresentation }.joined(separator: ",")
        default: return "none"
        }
    }

    var isRecommendFilter: Bool {
        switch self {
        case .recommend: return true
        default: return false
        }
    }

    var isSelectedBasedOnQueryRecommend: Bool {
        switch self {
        case .recommend: return false
        case let .commonFilter(.mainFrom(_, _, fromType, _)):
            return fromType == .recommended
        case let .chatter(_, _, _, fromType, _):
            return fromType == .recommended
        case let .docFrom(_, _, fromType, _):
            return fromType == .recommended
        default: return false
        }
    }

    var advancedSyntaxFilterType: SearchFilter.AdvancedSyntaxFilterType? {
        switch self {
        case .commonFilter(.mainFrom), .chatter, .docFrom:
            return .fromFilter
        case .general(.user(let customInfo, _)):
            if customInfo.associatedSmartFilter == .smartUser {
                return .fromFilter
            }
            break
        case .commonFilter(.mainWith), .withUsers, .chatMemeber:
            return .withFilter
        case .commonFilter(.mainIn), .docPostIn, .chat:
            return .inFilter
        default:
            break
        }
        return nil
    }

    var isSelectedBasedOnResultRecommend: Bool {
        switch self {
        case .recommend: return false
        case let .commonFilter(.mainFrom(_, _, _, isRecommendResultSelected)):
            return isRecommendResultSelected
        case let .chatter(_, _, _, _, isRecommendResultSelected):
            return isRecommendResultSelected
        case let .docFrom(_, _, _, isRecommendResultSelected):
            return isRecommendResultSelected
        default: return false
        }
    }

    var basedOnResultRecommendList: [SearchResultType] {
        switch self {
        case let .commonFilter(.mainFrom(_, recommends, _, _)):
            return recommends
        case let .chatter(_, _, recommends, _, _):
            return recommends
        case let .docFrom(_, recommends, _, _):
            return recommends
        default: return []
        }
    }

    var isEmpty: Bool {
        switch self {
        case let .recommend(filter): return true
        case let .specificFilterValue(_, _, isSelected): return !isSelected
        case let .commonFilter(commonFilter): return commonFilter.isEmpty
        case let .general(generalFilter): return generalFilter.isEmpty
        case let .chatter(_, chatters, _, _, _):
            return chatters.isEmpty
        case let .withUsers(chatters):
            return chatters.isEmpty
        case let .chat(_, chats):
            return chats.isEmpty
        case let .docPostIn(items):
            return items.isEmpty
        case .date(let date, _):
            return date == nil
        case .docFormat(let docFilter, _):
            return docFilter.isEmpty
        case .docType(let type):
            return type == .all
        case let .docFrom(fromIds, _, _, _):
            return fromIds.isEmpty
        case .docCreator(let creators, _):
            return creators.isEmpty
        case .wikiCreator(let creators):
            return creators.isEmpty
        case .docSharer(let sharer):
            return sharer.isEmpty
        case .docSortType(let docSortType):
            return docSortType == .mostRelated
        case .docFolderIn(let folders):
            return folders.isEmpty
        case .docWorkspaceIn(let workspaces):
            return workspaces.isEmpty
        case let .chatMemeber(_, items):
            return items.isEmpty
        case .chatKeyWord(let keyWord):
            return keyWord.isEmpty
        case .chatType(let types):
            return types.isEmpty
        case .threadType(let type):
            return  type == .all
        case .messageType(let type):
            return type == .all
        case .messageAttachmentType(let type):
            return type == .unknownAttachmentType
        case .messageChatType(let type):
            return type == .all
        case .messageMatch(let types): return types.isEmpty
        case .docOwnedByMe(let docOwnedByMe, _): return !docOwnedByMe
        case .docContentType(let docContentType): return docContentType == .fullContent
        case .groupSortType(let groupSortType):
            return groupSortType == .mostRelated
        }
    }

    func reset() -> SearchFilter {
        switch self {
        case let .recommend(filter): return .recommend(filter)
        case let .specificFilterValue(filter, frontTitle, _): return .specificFilterValue(filter, frontTitle, false)
        case let .commonFilter(commonFilter):
            switch commonFilter {
            case .mainFrom:
                return .commonFilter(.mainFrom(fromIds: [], recommends: [], fromType: .user, isRecommendResultSelected: false))
            case .mainWith:
                return .commonFilter(.mainWith([]))
            case .mainIn:
                return .commonFilter(.mainIn(inIds: []))
            case .mainDate(_):
                return .commonFilter(.mainDate(date: nil))
            }
        case let .general(generalFilter):
            switch generalFilter {
            case let .date(info, _): return .general(.date(info, nil))
            case let .user(info, _): return .general(.user(info, []))
            case let .single(info, _): return .general(.single(info, nil))
            case let .multiple(info, _): return .general(.multiple(info, []))
            case let .calendar(info, _): return .general(.calendar(info, []))
            case let .userChat(info, _): return .general(.userChat(info, []))
            case let .mailUser(info, _): return .general(.mailUser(info, []))
            case let .inputTextFilter(info, _): return .general(.inputTextFilter(info, []))
            }
        case .chatter(let mode, _, _, _, _):
            return .chatter(mode: mode, picker: [], recommends: [], fromType: .user, isRecommendResultSelected: false)
        case .withUsers:
            return .withUsers([])
        case .chat(let mode, _):
            return .chat(mode: mode, picker: [])
        case .date(_, let source):
            return .date(date: nil, source: source)
        case .docFormat(_, let isMainSearch):
            return .docFormat([], isMainSearch)
        case .docType(let type):
            return .docType(.all)
        case .docFrom:
            return .docFrom(fromIds: [], recommends: [], fromType: .user, isRecommendResultSelected: false)
        case .docPostIn:
            return .docPostIn([])
        case .docCreator:
            return .docCreator([], Container.shared.getCurrentUserResolver().userID)
        case .wikiCreator:
            return .wikiCreator([])
        case .docSharer:
            return .docSharer([])
        case .docSortType:
            return .docSortType(.mostRelated)
        case .docFolderIn:
            return .docFolderIn([])
        case .docWorkspaceIn:
            return .docWorkspaceIn([])
        case .chatMemeber(let mode, _):
            return .chatMemeber(mode: mode, picker: [])
        case .chatKeyWord:
            return .chatKeyWord("")
        case .chatType:
            return .chatType([])
        case .threadType:
            return  .threadType(.all)
        case .messageType:
            return .messageType(.all)
        case .messageAttachmentType:
            return .messageAttachmentType(.unknownAttachmentType)
        case .messageMatch:
            return .messageMatch([])
        case .docOwnedByMe:
            return .docOwnedByMe(false, Container.shared.getCurrentUserResolver().userID)
        case .docContentType:
            return .docContentType(.fullContent)
        case .messageChatType:
            return .messageChatType(.all)
        case .groupSortType:
            return .groupSortType(.mostRelated)
        }
    }

    func sameType(with filter: SearchFilter) -> Bool {
        switch self {
        case let .recommend: if case .recommend = filter { return true }
        case let .specificFilterValue(_commonly, _, _):
            if case let .specificFilterValue(_filter, _, _) = filter {
                return _commonly.sameType(with: _filter)
            }
        case let .commonFilter(commonFilter):
            switch commonFilter {
            case .mainFrom: if case .commonFilter(.mainFrom) = filter { return true }
            case .mainWith: if case .commonFilter(.mainWith) = filter { return true }
            case .mainIn: if case .commonFilter(.mainIn) = filter { return true }
            case .mainDate: if case .commonFilter(.mainDate) = filter { return true }
            }
        case let .general(generalFilter):
            switch generalFilter {
            case let .multiple(lInfo, _):
                if case let .general(.multiple(rInfo, _)) = filter {
                    return lInfo.id == rInfo.id
                }
            case let .single(lInfo, _):
                if case let .general(.single(rInfo, _)) = filter {
                    return lInfo.id == rInfo.id
                }
            case let .user(lInfo, _):
                if case let .general(.user(rInfo, _)) = filter {
                    return lInfo.id == rInfo.id
                }
            case let .date(lInfo, _):
                if case let .general(.date(rInfo, _)) = filter {
                    return lInfo.id == rInfo.id
                }
            case let .calendar(lInfo, _):
                if case let .general(.calendar(rInfo, _)) = filter {
                    return lInfo.id == rInfo.id
                }
            case let .userChat(lInfo, _):
                if case let .general(.userChat(rInfo, _)) = filter {
                    return lInfo.id == rInfo.id
                }
            case let .mailUser(lInfo, _):
                if case let .general(.mailUser(rInfo, _)) = filter {
                    return lInfo.id == rInfo.id
                }
            case let .inputTextFilter(lInfo, _):
                if case let .general(.inputTextFilter(rInfo, _)) = filter {
                    return lInfo.id == rInfo.id
                }
            }
        case .chatter: if case .chatter = filter { return true }
        case .withUsers: if case .withUsers = filter { return true }
        case .chat: if case .chat = filter { return true }
        case .date: if case .date = filter { return true }
        case .docFormat: if case .docFormat = filter { return true }
        case .docType: if case .docType = filter { return true }
        case .docFrom: if case .docFrom = filter { return true }
        case .docCreator: if case .docCreator = filter { return true }
        case .wikiCreator: if case .wikiCreator = filter { return true }
        case .docSharer: if case .docSharer = filter { return true }
        case .chatMemeber: if case .chatMemeber = filter { return true }
        case .chatKeyWord: if case .chatKeyWord = filter { return true }
        case .chatType: if case .chatType = filter { return true }
        case .threadType: if case .threadType = filter { return true }
        case .messageType: if case .messageType = filter { return true }
        case .messageAttachmentType: if case .messageAttachmentType = filter { return true }
        case .messageMatch: if case .messageMatch = filter { return true }
        case .docOwnedByMe: if case .docOwnedByMe = filter { return true }
        case .docContentType: if case .docContentType = filter { return true }
        case .docPostIn: if case .docPostIn = filter { return true }
        case .docSortType: if case .docSortType = filter { return true }
        case .messageChatType: if case .messageChatType = filter { return true }
        case .docFolderIn: if case .docFolderIn = filter { return true }
        case .docWorkspaceIn: if case .docWorkspaceIn = filter { return true }
        case .groupSortType: if case .groupSortType = filter { return true }
        }
        return false
    }

    //普通筛选器与常用筛选器之间的联动
    //变化的是initiativeOne，结果是passivityOne应该变成的样子
    static func mergeCommonlyUsedResponse(initiativeOne: SearchFilter, passivityOne: SearchFilter) -> SearchFilter? {
        //默认是单选，直接覆盖不容易出错
        func isSingleFilter(filter: SearchFilter) -> Bool {
            switch filter {
            case let .specificFilterValue(_commonly, _, _):
                return isSingleFilter(filter: _commonly)
            case .chatter, .withUsers, .chat, .docFormat, .docFrom, .docCreator, .docSharer, .messageMatch, .docPostIn, .docFolderIn, .docWorkspaceIn:
                return false
            case .docType, .messageType, .messageAttachmentType, .docOwnedByMe, .docContentType, .docSortType, .date:
                return true
            default:
                return true
            }
        }

        func merge<T>(idList: [T], lastId: T, isSelected: Bool, compare: ((_ item: T, _ lastOne: T) -> Bool)) -> (idListResult: [T], include: Bool) {
            var result = Array(idList)
            let include = result.contains { item in
                compare(item, lastId)
            }
            if !include && isSelected {
                result.append(lastId)
            } else if include && !isSelected {
                result = result.filter({ item in
                    !compare(item, lastId)
                })
            }
            return (result, include)
        }

        func theFirstIncludeTheLast(_ first: SearchFilter, _ last: SearchFilter, _ isSelected: Bool) -> (result: SearchFilter, include: Bool?) {
            guard first.sameType(with: last) else { return(first, nil) }
            switch (first, last) {
            case (.chatter(let _0, let firstfromIds, let _1, let _2, let _3), .chatter(_, let lastfromIds, _, _, _)):
                guard let lastID = lastfromIds.first else { return (first, nil) }
                let result = merge(idList: firstfromIds, lastId: lastID, isSelected: isSelected) { item, lastOne in
                    item.chatterID == lastOne.chatterID
                }
                return (.chatter(mode: _0, picker: result.idListResult, recommends: _1, fromType: _2, isRecommendResultSelected: _3), result.include)
            case (.withUsers(let firstfromIds), .withUsers(let lastfromIds)):
                guard let lastID = lastfromIds.first else { return (first, nil) }
                let result = merge(idList: firstfromIds, lastId: lastID, isSelected: isSelected) { item, lastOne in
                    item.chatterID == lastOne.chatterID
                }
                return (.withUsers(result.idListResult), result.include)
            case (.chat(let _0, let firstInIds), .chat(_, let lastInIds)):
                guard let lastID = lastInIds.first else { return (first, nil) }
                let result = merge(idList: firstInIds, lastId: lastID, isSelected: isSelected) { item, lastOne in
                    item.id == lastOne.id
                }
                return (.chat(mode: _0, picker: result.idListResult), result.include)
            case (.docFormat(let firstFormats, let _0), .docFormat(let lastFormats, _)):
                guard let lastID = lastFormats.first else { return (first, nil) }
                let result = merge(idList: firstFormats, lastId: lastID, isSelected: isSelected) { item, lastOne in
                    item == lastOne
                }
                return (.docFormat(result.idListResult, _0), result.include)
            case (.docFrom(let firstfromIds, let _0, let _1, let _2), .docFrom(let lastfromIds, _, _, _)):
                guard let lastID = lastfromIds.first else { return (first, nil) }
                let result = merge(idList: firstfromIds, lastId: lastID, isSelected: isSelected) { item, lastOne in
                    item.chatterID == lastOne.chatterID
                }
                return (.docFrom(fromIds: result.idListResult, recommends: _0, fromType: _1, isRecommendResultSelected: _2), result.include)
            case (.docCreator(let firstPickItems, let lhsUid), .docCreator(let lastPickItems, let rhsUid)):
                guard let lastID = lastPickItems.first, lhsUid == rhsUid else { return (first, nil) }
                let result = merge(idList: firstPickItems, lastId: lastID, isSelected: isSelected) { item, lastOne in
                    item.chatterID == lastOne.chatterID
                }
                return (.docCreator(result.idListResult, lhsUid), result.include)
            case (.docSharer(let firstPickItems), .docSharer(let lastPickItems)):
                guard let lastID = lastPickItems.first else { return (first, nil) }
                let result = merge(idList: firstPickItems, lastId: lastID, isSelected: isSelected) { item, lastOne in
                    item.chatterID == lastOne.chatterID
                }
                return (.docSharer(result.idListResult), result.include)
            case (.messageMatch(let firstTypes), .messageMatch(let lastTypes)):
                guard let lastID = lastTypes.first else { return (first, nil) }
                let result = merge(idList: firstTypes, lastId: lastID, isSelected: isSelected) { item, lastOne in
                    item == lastOne
                }
                return (.messageMatch(result.idListResult), result.include)
            case (.docPostIn(let firstInIds), .docPostIn(let lastInIds)):
                guard let lastID = lastInIds.first else { return (first, nil) }
                let result = merge(idList: firstInIds, lastId: lastID, isSelected: isSelected) { item, lastOne in
                    item.id == lastOne.id
                }
                return (.docPostIn(result.idListResult), result.include)
            case (.docFolderIn(let firstPickItems), .docFolderIn(let lastPickItems)):
                guard let lastID = lastPickItems.first else { return (first, nil) }
                let result = merge(idList: firstPickItems, lastId: lastID, isSelected: isSelected) { item, lastOne in
                    item.id == lastOne.id
                }
                return (.docFolderIn(result.idListResult), result.include)
            case (.docWorkspaceIn(let firstPickItems), .docWorkspaceIn(let lastPickItems)):
                guard let lastID = lastPickItems.first else { return (first, nil) }
                let result = merge(idList: firstPickItems, lastId: lastID, isSelected: isSelected) { item, lastOne in
                    item.id == lastOne.id
                }
                return (.docWorkspaceIn(result.idListResult), result.include)
            default:
                return(first, nil)
            }
        }

        if case let .specificFilterValue(filter, _, isSelected) = initiativeOne, filter.sameType(with: passivityOne) {
            if isSingleFilter(filter: filter) {
                if isSelected {
                    return filter
                } else {
                    return filter.reset()
                }
            } else {
                let result = theFirstIncludeTheLast(passivityOne, filter, isSelected)
                guard result.include != nil else { return nil }
                return result.result
            }
        } else if case let .specificFilterValue(filter, title, isSelected) = passivityOne, filter.sameType(with: initiativeOne) {
            if isSingleFilter(filter: filter) {
                let isSelected = (filter == initiativeOne)
                return .specificFilterValue(filter, title, isSelected)
            } else {
                let result = theFirstIncludeTheLast(initiativeOne, filter, isSelected)
                guard let include = result.include else { return nil }
                return .specificFilterValue(filter, title, include)
            }
        } else {
            return nil
        }
    }
}

extension SearchFilter.CommonFilter: Equatable {
    public static func == (lhs: SearchFilter.CommonFilter, rhs: SearchFilter.CommonFilter) -> Bool {
        switch (lhs, rhs) {
        case (let .mainFrom(lhsFromIds, _, lhsFromType, _), let .mainFrom(rhsFromIds, _, rhsFromType, _)):
            return lhsFromIds == rhsFromIds && lhsFromType == rhsFromType
        case (let .mainWith(lhsWithIds), let .mainWith(rhsWithIds)):
            return lhsWithIds == rhsWithIds
        case (let .mainIn(lhsInIds), let .mainIn(rsInIds)):
            return lhsInIds == rsInIds
        case (.mainDate(let lhsDate), .mainDate(let rhsDate)):
            if let lhsDate = lhsDate, let rhsDate = rhsDate {
                return lhsDate == rhsDate
            } else if lhsDate == nil, rhsDate == nil {
                return true
            } else {
                return false
            }
        default:
            return false
        }
    }
}

public extension SearchFilter.GeneralFilter.Option {
    var id: String {
        switch self {
        case let .predefined(info): return info.id
        case let .searchable(item): return item.id
        }
    }
    var name: String {
        switch self {
        case let .predefined(info): return info.name
        case let .searchable(item): return item.name
        }
    }
}

public extension SearchFilter.GeneralFilter {
    var info: SearchFilter.CustomFilterInfo {
        switch self {
        case let .date(info, _): return info
        case let .multiple(info, _): return info
        case let .single(info, _): return info
        case let .user(info, _): return info
        case let .calendar(info, _): return info
        case let .userChat(info, _): return info
        case let .mailUser(info, _): return info
        case let .inputTextFilter(info, _): return info
        }
    }
    var isEmpty: Bool {
        switch self {
        case let .user(_, ids): return ids.isEmpty
        case let .date(_, date): return date == nil
        case let .single(_, value): return value == nil
        case let .multiple(_, values): return values.isEmpty
        case let .calendar(_, values): return values.isEmpty
        case let .userChat(_, values): return values.isEmpty
        case let .mailUser(_, values): return values.isEmpty
        case let .inputTextFilter(_, values): return values.filter { !$0.isEmpty }.isEmpty
        }
    }
    var avatarKeys: [String] {
        switch self {
        case let .user(_, ids): return ids.map { $0.avatarKey }
        case let .userChat(_, pickers): return pickers.map { $0.avatarKey }
        default: return []
        }
    }

    var avatarInfos: [SearchFilterView.AvatarInfo] {
        switch self {
        case let .user(_, ids): return ids.map { SearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.chatterID) }
        case let .userChat(_, pickers): return pickers.map { SearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.id) }
        case let .mailUser(_, pickers): return pickers.compactMap {
            switch $0.meta {
            case .chat(let chatMate):
                return SearchFilterView.AvatarInfo(avatarKey: chatMate.avatarKey ?? "", avatarID: chatMate.id )
            case .chatter(let chatterMate):
                return SearchFilterView.AvatarInfo(avatarKey: chatterMate.avatarKey ?? "", avatarID: chatterMate.id )
            // 仅用作计数
            case .mailUser(let mailUserMate):
                return SearchFilterView.AvatarInfo(avatarKey: "", avatarID: mailUserMate.id )
            default: return nil
            }
        }
        default: return []
        }
    }

    var name: String {
        switch self {
        case .date(_, _):
            if !info.displayName.isEmpty {
                return info.displayName
            }
            return BundleI18n.LarkSearchFilter.Lark_Search_MobileSearchTimeFilter
        default: return info.displayName
        }
    }

    var content: String {
        switch self {
        case let .date(_, date):
            if let date = date {
                return getTimeRangeString(date: date)
            } else {
                return ""
            }
        case let .multiple(_, options):
            if options.isEmpty {
                return ""
            } else {
                return options.map({ $0.name }).joined(separator: "、")
            }
        case let .single(_, option):
            guard let option = option else {
                return ""
            }
            return option.name
        case let .user(_, pickers):
            if let name = pickers.first?.name {
                return name
            } else {
                return ""
            }
        case let .calendar(_, calendars):
            if calendars.isEmpty {
                return ""
            } else {
                return calendars.map({ $0.title }).joined(separator: "、")
            }
        case let .userChat(_, pickers):
            if let name = pickers.first?.name {
                return name
            } else {
                return ""
            }
        case let .mailUser(_, pickers):
            if pickers.isEmpty {
                return ""
            } else {
                switch pickers[0].meta {
                case .chatter(let chatterMeta):
                    return chatterMeta.localizedRealName ?? ""
                case .chat(let chatMeta):
                    return chatMeta.name ?? ""
                case .mailUser(let mailUserMeta):
                    return mailUserMeta.mailAddress ?? ""
                default:
                    return ""
                }
            }
        case let .inputTextFilter(_, texts):
            if let text = texts.first {
                return text
            } else {
                return ""
            }
        }
    }

    var title: String {
        switch self {
        case let .date(_, date):
            var title = !info.displayName.isEmpty ? info.displayName : BundleI18n.LarkSearchFilter.Lark_Search_MobileSearchTimeFilter
            if let _date = date {
                title += getTimeRangeString(date: _date)
            }
            return title
        case let .multiple(_, options):
            if options.isEmpty {
                return info.displayName
            } else if options.count == 1 {
                return options.first?.name ?? (info.displayName + " \(options.count)")
            } else {
                return info.displayName + " \(options.count)"
            }
        case let .single(_, option):
            guard let option = option else {
                return info.displayName
            }
            return option.name
        case let .calendar(info, calendars):
            if calendars.isEmpty {
                return info.displayName
            } else if calendars.count == 1, let firstTitle = calendars.first?.title {
                return SearchFilter.specificFilterValueTitleLimit(firstTitle, limit: 10)
            } else {
                return info.displayName + " \(calendars.count)"
            }
        case let .inputTextFilter(info, texts):
            if texts.isEmpty {
                return info.displayName
            } else {
                let countStr: String = texts.count > 1 ? "+\(texts.count - 1)" : ""
                let textStr = SearchFilter.specificFilterValueTitleLimit((texts.first ?? ""), limit: 10)
                return info.displayName + " " + textStr + countStr
            }
        default: return info.displayName
        }
    }

    var canReplaceByCommonUserFilter: Bool {
        if case let .user(customFilterInfo, _) = self {
            return customFilterInfo.hasAssociatedSmartFilter && customFilterInfo.associatedSmartFilter == .smartUser
        }
        return false
    }

    var canReplaceByCommonDate: Bool {
        if case let .date(customFilterInfo, _) = self {
            return customFilterInfo.hasAssociatedSmartFilter && customFilterInfo.associatedSmartFilter == .smartTime
        }
        return false
    }
}

public extension SearchFilter.CommonFilter {
    var isEmpty: Bool {
        switch self {
        case let .mainFrom(fromIds, _, _, _):
            return fromIds.isEmpty
        case let .mainWith(withIds):
            return withIds.isEmpty
        case let .mainIn(inIds):
            return inIds.isEmpty
        case .mainDate(let date):
            return date == nil
        }
    }
}

extension SearchFilter.GeneralFilter.Option: Equatable {
    public static func == (lhs: SearchFilter.GeneralFilter.Option, rhs: SearchFilter.GeneralFilter.Option) -> Bool {
        switch (lhs, rhs) {
        case (.searchable(let lhs), .searchable(let rhs)):
            return lhs == rhs
        case (.predefined(let lhs), .predefined(let rhs)):
            return lhs.id == rhs.id && lhs.name == rhs.name
        default:
            return false
        }
    }
}

extension SearchFilter.GeneralFilter: Equatable {
    public static func == (lhs: SearchFilter.GeneralFilter, rhs: SearchFilter.GeneralFilter) -> Bool {
        switch (lhs, rhs) {
        case (.multiple(let lhsInfo, let lhsOptions), .multiple(let rhsInfo, let rhsOptions)):
            return lhsInfo == rhsInfo && lhsOptions == rhsOptions
        case (.single(let lhsInfo, let lhsOption), .single(let rhsInfo, let rhsOption)):
            return lhsInfo == rhsInfo && lhsOption == rhsOption
        case (.user(let lhsInfo, let lhsItems), .user(let rhsInfo, let rhsItems)):
            return lhsInfo == rhsInfo && lhsItems == rhsItems
        case (.date(let lhsInfo, let lhsDate), .date(let rhsInfo, let rhsDate)):
            guard lhsInfo == rhsInfo else { return false }
            if let _lhsDate = lhsDate, let _rhsDate = rhsDate {
                return _lhsDate == _rhsDate
            } else if lhsDate == nil, rhsDate == nil {
                return true
            } else {
                return false
            }
        case (.calendar(let lhsInfo, let lhsCalendars), .calendar(let rhsInfo, let rhsCalendars)):
            guard lhsInfo == rhsInfo else { return false }
            let leftEqualToRight = lhsCalendars.allSatisfy(rhsCalendars.contains)
            let rightEqualToLeft = rhsCalendars.allSatisfy(lhsCalendars.contains)
            return leftEqualToRight && rightEqualToLeft
        case (.userChat(let lhsInfo, let lhsPickers), .userChat(let rhsInfo, let rhsPickers)):
            guard lhsInfo == rhsInfo, lhsPickers.count == rhsPickers.count else { return false }
            for lhsPicker in lhsPickers {
                if !rhsPickers.contains(where: { picker in
                    picker.id.elementsEqual(lhsPicker.id)
                }) {
                    return false
                }
            }
            return true
        case (.mailUser(let lhsInfo, let lhsPickers), .mailUser(let rhsInfo, let rhsPickers)):
            guard lhsInfo == rhsInfo, lhsPickers.count == rhsPickers.count else { return false }
            for lhsPicker in lhsPickers {
                if !rhsPickers.contains(where: { picker in
                    picker.id.elementsEqual(lhsPicker.id)
                }) {
                    return false
                }
            }
            return true
        case (.inputTextFilter(let lhsInfo, let lhsTexts), .inputTextFilter(let rhsInfo, let rhsTexts)):
            guard lhsInfo == rhsInfo, lhsTexts.count == rhsTexts.count else { return false }
            for lhsText in lhsTexts {
                if !rhsTexts.contains(where: { rhsText in
                    rhsText.elementsEqual(lhsText)
                }) {
                    return false
                }
            }
            return true
        default:
            return false
        }
    }
}

extension SearchFilter: Equatable {
    public static func == (lhs: SearchFilter, rhs: SearchFilter) -> Bool {
        switch (lhs, rhs) {
        case (let .commonFilter(lhsCommonFilter), let .commonFilter(rhsCommonFilter)):
            return lhsCommonFilter == rhsCommonFilter
        case (let .specificFilterValue(lhsFilter, _, lhsIsSelected), let .specificFilterValue(rhsFilter, _, rhsIsSelected)):
            return lhsFilter == rhsFilter
        case (let .chatter(lmode, lhsItems, _, _, _), let .chatter(rmode, rhsItems, _, _, _)):
            return lhsItems == rhsItems && lmode == rmode
        case (let .withUsers(lhsItems), let .withUsers(rhsItems)):
            return lhsItems == rhsItems
        case (let .chat(lmode, lhsItems), let .chat(rmode, rhsItems)):
            return lhsItems == rhsItems && lmode == rmode
        case (.date(let lhsDate, _), .date(let rhsDate, _)):
            if let _lhsDate = lhsDate, let _rhsDate = rhsDate {
                return _lhsDate == _rhsDate
            } else if lhsDate == nil, rhsDate == nil {
                return true
            } else {
                return false
            }
        case (.docFormat(let lhsTypes), .docFormat(let rhsTypes)):
            return lhsTypes == rhsTypes
        case (.docType(let lhsTypes), .docType(let rhsTypes)):
            return lhsTypes == rhsTypes
        case (let .docFrom(lhsFromIds, _, lhsFromType, _), let .docFrom(rhsFromIds, _, rhsFromType, _)):
            return lhsFromIds == rhsFromIds && lhsFromType == rhsFromType
        case (let .docPostIn(lhsInIds), let .docPostIn(rhsInIds)):
            return lhsInIds == rhsInIds
        case (.docCreator(let lhsItems, let lhsUid), .docCreator(let rhsItems, let rhsUid)):
            return lhsItems == rhsItems && lhsUid == rhsUid
        case (.wikiCreator(let lhsItems), .wikiCreator(let rhsItems)):
            return lhsItems == rhsItems
        case (.docSharer(let lhsItems), .docSharer(let rhsItems)):
            return lhsItems == rhsItems
        case (let .chatMemeber(lmode, lhsItems), let .chatMemeber(rmode, rhsItems)):
            return lhsItems == rhsItems && lmode == rmode
        case (.chatKeyWord(let lhsKeyWord), .chatKeyWord(let rhsKeyWord)):
            return lhsKeyWord == rhsKeyWord
        case (.chatType(let lhsTypes), .chatType(let rhsTypes)):
            return lhsTypes == rhsTypes
        case (.threadType(let lhsItems), .threadType(let rhsItems)):
            return lhsItems == rhsItems
        case (.messageType(let lhsType), .messageType(let rhsType)):
            return lhsType == rhsType
        case (.messageAttachmentType(let lhsType), .messageAttachmentType(let rhsType)):
            return lhsType == rhsType
        case (.messageMatch(let lhs), .messageMatch(let rhs)):
            return lhs == rhs
        case (.messageChatType(let lhs), .messageChatType(let rhs)):
            return lhs == rhs
        case (.docOwnedByMe(let lhs, let lhsUid), .docOwnedByMe(let rhs, let rhsUid)):
            return lhs == rhs && lhsUid == rhsUid
        case (.docContentType(let lhs), .docContentType(let rhs)):
            return lhs == rhs
        case (.docSortType(let lhs), .docSortType(let rhs)):
            return lhs == rhs
        case (.docFolderIn(let lhsItems), .docFolderIn(let rhsItems)):
            return lhsItems == rhsItems
        case (.docWorkspaceIn(let lhsItems), .docWorkspaceIn(let rhsItems)):
            return lhsItems == rhsItems
        case (.groupSortType(let lhs), .groupSortType(let rhs)):
            return lhs == rhs
        case (.general(let lhs), .general(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

public extension SearchFilter {
    var avatarKeys: [String] {
        switch self {
        case let .recommend(filter):
            return filter.avatarKeys
        case let .specificFilterValue(filter, _, _):
            return filter.avatarKeys
        case let .general(generalFilter):
            return generalFilter.avatarKeys
        case let .commonFilter(commonFilter):
            switch commonFilter {
            case let .mainFrom(fromIds, _, _, _):
                return fromIds.map { $0.avatarKey }
            case let .mainWith(withIds):
                return withIds.map { $0.avatarKey }
            case let .mainIn(inIds):
                return inIds.map { $0.avatarKey }
            case .mainDate:
                return []
            }
        case let .chatter(_, pickItems, _, _, _):
            return pickItems.map { $0.avatarKey }
        case let .withUsers(pickItems):
            return pickItems.map { $0.avatarKey }
        case let .chat(_, pickItems):
            return pickItems.map { $0.avatarKey }
        case let .docPostIn(items):
            return items.map { $0.avatarKey }
        case .docFormat, .docType, .date:
            return []
        case let .docFrom(fromIds, _, _, _):
            return fromIds.map { $0.avatarKey }
        case .docCreator(let pickItems, _):
            return pickItems.map { $0.avatarKey }
        case .wikiCreator(let pickItems):
            return pickItems.map { $0.avatarKey }
        case .docSharer(let pickItems):
            return pickItems.map { $0.avatarKey }
        case .docFolderIn(let pickItems):
            return pickItems.map { $0.avatarKey }
        case .docWorkspaceIn(let pickItems):
            return pickItems.map { $0.avatarKey }
        case let .chatMemeber(_, chatMemebers):
            return chatMemebers.map { $0.avatarKey }
        case .chatType, .chatKeyWord, .threadType, .messageType, .messageAttachmentType, .messageMatch, .docContentType, .docOwnedByMe, .groupSortType, .docSortType, .messageChatType:
            return []
        }
    }

    var avatarInfos: [SearchFilterView.AvatarInfo] {
        switch self {
        case let .recommend(filter):
            return filter.avatarInfos
        case let .specificFilterValue(filter, _, _):
            return filter.avatarInfos
        case let .commonFilter(commonFilter):
            switch commonFilter {
            case let .mainFrom(fromIds, _, _, _):
                return fromIds.map { SearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.chatterID) }
            case let .mainWith(withIds):
                return withIds.map { SearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.chatterID) }
            case let .mainIn(inIds):
                return inIds.map { SearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.id) }
            case .mainDate:
                return []
            }
        case let .general(generalFilter):
            return generalFilter.avatarInfos
        case let .chatter(_, pickItems, _, _, _):
            return pickItems.map { SearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.chatterID) }
        case let .withUsers(pickItems):
            return pickItems.map { SearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.chatterID) }
        case let .chat(_, pickItems):
            return pickItems.map { SearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.id) }
        case let .docSharer(items):
            return items.map { SearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.chatterID) }
        case let .docPostIn(items):
            return items.map { SearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.id) }
        case .docType, .docFormat, .docContentType, .docOwnedByMe, .date:
            return []
        case let .docFrom(fromIds, _, _, _):
            return fromIds.map { SearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.chatterID) }
        case .docCreator(let pickItems, _):
            return pickItems.map { SearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.chatterID) }
        case .docFolderIn(let pickItems):
            return pickItems.map { SearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.id) }
        case .docWorkspaceIn(let pickItems):
            return pickItems.map { SearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.id) }
        case .wikiCreator(let pickItems):
            return pickItems.map { SearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.chatterID) }
        case let .chatMemeber(_, chatMemebers):
            return chatMemebers.map { SearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.chatterID) }
        case .chatType, .chatKeyWord, .threadType, .messageType, .messageAttachmentType, .messageMatch, .groupSortType, .docSortType, .messageChatType:
            return []
        }
    }
    func getAvatarViews(avatarWidth: CGFloat = 16, blueCircleWidth: CGFloat = 2) -> [UIView]? {
        switch self {
        case .docFolderIn(let items):
            let displayItem = [items.first].compactMap { $0 }
            if !displayItem.isEmpty {
                return displayItem
                    .map { (item) -> UIView in
                        if let isShardFolder = item.isShardFolder, isShardFolder {
                            return RoundAvatarView(avatarImage: Resources.doc_sharefolder_circle,
                                                   avatarWidth: avatarWidth,
                                                   showBgColor: false,
                                                   blueCircleWidth: blueCircleWidth)
                        } else {
                            return RoundAvatarView(avatarImage: Resources.doc_folder_circle,
                                                   avatarWidth: avatarWidth,
                                                   showBgColor: false,
                                                   blueCircleWidth: blueCircleWidth)
                        }
                    }
            } else { return nil }
        case .docWorkspaceIn(let items):
            let displayItem = [items.first].compactMap { $0 }
            if !displayItem.isEmpty {
                return displayItem
                    .map { (_) -> UIView in
                        return RoundAvatarView(avatarImage: Resources.wikibook_circle,
                                               avatarWidth: avatarWidth,
                                               showBgColor: false,
                                               blueCircleWidth: blueCircleWidth)
                    }
            } else { return nil }
        case .general(.mailUser(_, let pickers)):
            if let picker = pickers.first {
                switch picker.meta {
                case .chat(let chatMate):
                    let avatarInfo = SearchFilterView.AvatarInfo(avatarKey: chatMate.avatarKey ?? "", avatarID: chatMate.id )
                    return [RoundAvatarView(avatarInfo: avatarInfo,
                                                  avatarWidth: avatarWidth,
                                                  showBgColor: false,
                                                  blueCircleWidth: blueCircleWidth)]
                case .chatter(let chatterMate):
                    let avatarInfo = SearchFilterView.AvatarInfo(avatarKey: chatterMate.avatarKey ?? "", avatarID: chatterMate.id )
                    return [RoundAvatarView(avatarInfo: avatarInfo,
                                                  avatarWidth: avatarWidth,
                                                  showBgColor: false,
                                                  blueCircleWidth: blueCircleWidth)]
                case .mailUser(let mailUserMate):
                    if let mailAddress = mailUserMate.mailAddress, let imageURL = mailUserMate.imageURL {
                        let placeholderImage: UIImage? = SearchFilterImageUtils.generateAvatarImage(withNameString: mailAddress, length: 2)
                        return [RoundAvatarView(avatarImageURL: imageURL,
                                                avatarWidth: avatarWidth,
                                                showBgColor: false,
                                                blueCircleWidth: blueCircleWidth,
                                                placeholderImage: placeholderImage)]
                    } else {
                        return nil
                    }
                default: return nil
                }
            } else {
                return nil
            }
        default:
            let avatarInfos = [self.avatarInfos.first].compactMap { $0 }
            if !avatarInfos.isEmpty {
                return avatarInfos
                    .map { return RoundAvatarView(avatarInfo: $0,
                                                  avatarWidth: avatarWidth,
                                                  showBgColor: false,
                                                  blueCircleWidth: blueCircleWidth)
                    }
            } else { return nil }
        }
    }
}
public typealias SearchActionFilter = ServerPB_Usearch_SearchActionFilter
public typealias RustPBSearchActionFilter = Search_V2_SearchActionFilter
public typealias SearchEntityProps = ServerPB_Usearch_SearchEntity.Props
public typealias SearchEntity = ServerPB_Usearch_SearchEntity
public extension SearchFilter {
    func convertToServerPBSearchActionFilter() -> SearchActionFilter {
        var searchActionFilter = SearchActionFilter()
        switch self {
        case .recommend(let searchFilter):
            return searchFilter.convertToServerPBSearchActionFilter()
        case .specificFilterValue(let searchFilter, _, _):
            return searchFilter.convertToServerPBSearchActionFilter()
        case .commonFilter(let commonFilter):
            switch commonFilter {
            case .mainFrom(let fromIds, _, _, _):
                if fromIds.isEmpty { break }
                searchActionFilter.smartSearchFromUser.userIds = fromIds.map { $0.chatterID }
            case .mainWith(let withIds):
                if withIds.isEmpty { break }
                searchActionFilter.smartSearchWithUser.userIds = withIds.map { $0.chatterID }
            case .mainIn(let inIds):
                if inIds.isEmpty { break }
                searchActionFilter.smartSearchInChat.groupChatIds = inIds.map { $0.chatId ?? "" }
            case .mainDate(let date):
                guard let date = date else { break }
                if let startDate = date.startDate {
                    searchActionFilter.smartSearchTimeRange.customizedStartTime = Int64(startDate.timeIntervalSince1970)
                }
                if let endDate = date.endDate {
                    searchActionFilter.smartSearchTimeRange.customizedEndTime = Int64(endDate.timeIntervalSince1970)
                }
            }
        case .general: break
        case .date(let date, let source):
            guard let date = date else { break }
            if let startDate = date.startDate, let endDate = date.endDate {
                switch source {
                case .message:
                    searchActionFilter.messageTimeRange.customizedStartTime = Int64(startDate.timeIntervalSince1970)
                    searchActionFilter.messageTimeRange.customizedEndTime = Int64(endDate.timeIntervalSince1970)
                case .doc:
                    searchActionFilter.docsOpenTimeRange.customizedStartTime = Int64(startDate.timeIntervalSince1970)
                    searchActionFilter.docsOpenTimeRange.customizedEndTime = Int64(endDate.timeIntervalSince1970)
                case .commonFilter: break
                }
            }
        case .chatter(_, let fromIds, _, _, _):
            if fromIds.isEmpty { break }
            searchActionFilter.messageFromUser.userIds = fromIds.map { $0.chatterID }
        case .withUsers(let fromIds):
            if fromIds.isEmpty { break }
            searchActionFilter.messageWithUser.userIds = fromIds.map { $0.chatterID }
        case .chat(_, let inIds):
            if inIds.isEmpty { break }
            searchActionFilter.messageInChat.groupChatIds = inIds.map { $0.chatId ?? "" }
        case .messageType(let messageFilterType):
            switch messageFilterType {
            case .file: searchActionFilter.messageType.messageType = .file
            case .link: searchActionFilter.messageType.messageType = .link
            case .all: break
            @unknown default:
                break
            }
        case .messageAttachmentType(let type):
            switch type {
            case .attachmentFile: searchActionFilter.messageAttachment.includeAttachmentTypes = [.attachmentFile]
            case .attachmentLink: searchActionFilter.messageAttachment.includeAttachmentTypes = [.attachmentLink]
            case .attachmentImage: searchActionFilter.messageAttachment.includeAttachmentTypes = [.attachmentImage]
            case .attachmentVideo: searchActionFilter.messageAttachment.includeAttachmentTypes = [.attachmentVideo]
            case .unknownAttachmentType: break
            @unknown default: break
            }
        case .messageMatch(let types):
            if types.isEmpty { break }
            searchActionFilter.messageMatchScope.scopeTypes = types.map({ type in
                switch type {
                case .atMe: return .atMe
                case .excludeBot: return .blockBotMessage
                case .onlyBot: return .blockUserMessage
                }
            })
        case .docOwnedByMe(let docOwnedByMe, let uid):
            if docOwnedByMe { searchActionFilter.docsOwner.userIds = [uid] }
        case .docType(let docType):
            switch docType {
            case .all: break
            case .doc: searchActionFilter.docsContainerType.containerType = .docs
            case .wiki: searchActionFilter.docsContainerType.containerType = .wiki
            }
        case .docFrom(let fromIds, _, _, _):
            if fromIds.isEmpty { break }
            searchActionFilter.docsFromUser.userIds = fromIds.map { $0.chatterID }
        case .docPostIn(let inIds):
            if inIds.isEmpty { break }
            searchActionFilter.docsInChat.groupChatIds = inIds.map { $0.chatId ?? "" }
        case .docFormat(let formats, _):
            if formats.isEmpty { break }
            searchActionFilter.docsObjectType.objectTypes = formats.map({ type in
                switch type {
                case .doc: return .doc
                case .bitale: return .bitable
                case .file: return .file
                case .mindNote: return .mindnote
                case .sheet: return .sheet
                case .slide: return .slide
                case .slides: return .slides
                case .all: return .unknownDocType
                }
            })
        case .docCreator(let ids, _):
            if ids.isEmpty { break }
            searchActionFilter.docsOwner.userIds = ids.map { $0.chatterID }
        case .docContentType(let docContentType):
            switch docContentType {
            case .fullContent: break
            case .onlyComment: searchActionFilter.docsMatchType.matchType = .onlyComment
            case .onlyTitle: searchActionFilter.docsMatchType.matchType = .onlyTitle
            }
        case .docSharer(let ids):
            if ids.isEmpty { break }
            searchActionFilter.docsSharer.userIds = ids.map { $0.chatterID }
        case .docSortType(let docSortType):
            switch docSortType {
            case .mostRecentCreated: searchActionFilter.docsSorter.sortByField = .createTime
            case .mostRecentUpdated: searchActionFilter.docsSorter.sortByField = .editTime
            case .mostRelated: break
            }
        case .messageChatType(let type):
            switch type {
            case .all: break
            case .groupChat: searchActionFilter.chatTypeFilter.chatFilterType = .groupChat
            case .p2PChat: searchActionFilter.chatTypeFilter.chatFilterType = .p2PChat
            }
        case .docFolderIn(let items):
            if items.isEmpty { break }
            searchActionFilter.docsInFolder.folderTokens = items.map({ item in
                return item.id
            })
        case .docWorkspaceIn(let items):
            if items.isEmpty { break }
            searchActionFilter.wikisInWikiSpace.spaceIds = items.map({ item in
                return item.id
            })
        case .chatMemeber(_, let memebers):
            if memebers.isEmpty { break }
            searchActionFilter.groupChatIncludeUser.userIds = memebers.map { $0.chatterID }
        case .groupSortType(let groupSortType):
            switch groupSortType {
            case .mostRelated: break
            case .mostRecentUpdated: searchActionFilter.groupChatSortType.sortType = .groupUpdateTime
            case .mostRecentCreated: searchActionFilter.groupChatSortType.sortType = .groupCreateTime
            case .leastNumGroupMember: searchActionFilter.groupChatSortType.sortType = .groupNumMembers
            }
        case .chatType(let types):
            if types.isEmpty { break }
            searchActionFilter.groupChatSearchType.searchType = types.map({ type in
                switch type {
                case .outer: return .crossTenant
                case .private: return .private
                case .publicAbsent: return .publicNotJoined
                case .publicJoin: return .publicJoined
                case .unknowntab: return .default // 之前已经处理过
                }
            })
        case .chatKeyWord, .threadType, .wikiCreator:
            break
        }
        return searchActionFilter
    }
    func convertToRustPBSearchActionFilter() -> RustPBSearchActionFilter {
        var searchActionFilter = RustPBSearchActionFilter()
        switch self {
        case .date(let date, let source):
            guard let date = date else { break }
            if let startDate = date.startDate, let endDate = date.endDate {
                switch source {
                case .message:
                    searchActionFilter.messageTimeRange.timeRangeType = .customized
                    searchActionFilter.messageTimeRange.customizedStartTime = Int64(startDate.timeIntervalSince1970)
                    searchActionFilter.messageTimeRange.customizedEndTime = Int64(endDate.timeIntervalSince1970)
                case .doc:
                    searchActionFilter.docsOpenTimeRange.timeRangeType = .customized
                    searchActionFilter.docsOpenTimeRange.customizedStartTime = Int64(startDate.timeIntervalSince1970)
                    searchActionFilter.docsOpenTimeRange.customizedEndTime = Int64(endDate.timeIntervalSince1970)
                case .commonFilter: break
                }
            }
        case .chatter(_, let fromIds, _, _, _):
            if fromIds.isEmpty { break }
            searchActionFilter.messageFromUser.userIds = fromIds.map { $0.chatterID }
        case .withUsers(let fromIds):
            if fromIds.isEmpty { break }
            searchActionFilter.messageWithUser.userIds = fromIds.map { $0.chatterID }
        case .chat(_, let inIds):
            if inIds.isEmpty { break }
            searchActionFilter.messageInChat.groupChatIds = inIds.map { $0.chatId ?? "" }
        case .messageType(let messageFilterType):
            switch messageFilterType {
            case .file: searchActionFilter.messageType.messageType = .file
            case .link:
                //由于RustPB使用的结构与IM耦合，不能随便加类型，否则会产生大量的IM侧适配工作量，所以链接类型走异化
                searchActionFilter.messageType.messageType = .unknown
                searchActionFilter.messageType.isURL = true
            case .all: break
            @unknown default:
                break
            }
        case .messageAttachmentType(let type):
            switch type {
            case .attachmentFile: searchActionFilter.messageAttachment.includeAttachmentTypes = [.attachmentFile]
            case .attachmentLink: searchActionFilter.messageAttachment.includeAttachmentTypes = [.attachmentLink]
            case .attachmentImage: searchActionFilter.messageAttachment.includeAttachmentTypes = [.attachmentImage]
            case .attachmentVideo: searchActionFilter.messageAttachment.includeAttachmentTypes = [.attachmentVideo]
            case .unknownAttachmentType: break
            @unknown default: break
            }
        case .messageMatch(let types):
            if types.isEmpty { break }
            searchActionFilter.messageMatchScope.scopeTypes = types.map({ type in
                switch type {
                case .atMe: return .atMe
                case .excludeBot: return .blockBotMessage
                case .onlyBot: return .blockUserMessage
                }
            })
        case .messageChatType(let type):
            switch type {
            case .all: break
            case .groupChat: searchActionFilter.chatTypeFilter.chatFilterType = .groupChat
            case .p2PChat: searchActionFilter.chatTypeFilter.chatFilterType = .p2PChat
            }
        case .docOwnedByMe(let docOwnedByMe, let uid):
            if docOwnedByMe { searchActionFilter.docsOwner.userIds = [uid] }
        case .docType(let docType):
            switch docType {
            case .all: break
            case .doc: searchActionFilter.docsContainerType.containerType = .docs
            case .wiki: searchActionFilter.docsContainerType.containerType = .wiki
            }
        case .docFrom(let fromIds, _, _, _):
            if fromIds.isEmpty { break }
            searchActionFilter.docsFromUser.userIds = fromIds.map { $0.chatterID }
        case .docPostIn(let inIds):
            if inIds.isEmpty { break }
            searchActionFilter.docsInChat.groupChatIds = inIds.map { $0.chatId ?? "" }
        case .docFormat(let formats, _):
            if formats.isEmpty { break }
            searchActionFilter.docsObjectType.objectTypes = formats.map({ type in
                switch type {
                case .doc: return .doc
                case .bitale: return .bitable
                case .file: return .file
                case .mindNote: return .mindnote
                case .sheet: return .sheet
                case .slide: return .slide
                case .slides: return .slides
                case .all: return .unknown
                }
            })
        case .docCreator(let ids, _):
            if ids.isEmpty { break }
            searchActionFilter.docsOwner.userIds = ids.map { $0.chatterID }
        case .docContentType(let docContentType):
            switch docContentType {
            case .fullContent: break
            case .onlyComment: searchActionFilter.docsMatchType.matchType = .onlyComment
            case .onlyTitle: searchActionFilter.docsMatchType.matchType = .onlyTitle
            }
        case .docSharer(let ids):
            if ids.isEmpty { break }
            searchActionFilter.docsSharer.userIds = ids.map { $0.chatterID }
        case .docSortType(let docSortType):
            switch docSortType {
            case .mostRecentCreated: searchActionFilter.docsSorter.sortByField = .createTime
            case .mostRecentUpdated: searchActionFilter.docsSorter.sortByField = .editTime
            case .mostRelated: break
            }
        case .docFolderIn(let items):
            if items.isEmpty { break }
            searchActionFilter.docsInFolder.folderTokens = items.map({ item in
                return item.id
            })
        case .docWorkspaceIn(let items):
            if items.isEmpty { break }
            searchActionFilter.wikisInWikiSpace.spaceIds = items.map({ item in
                return item.id
            })
        default: break
        }
        return searchActionFilter
    }
    func convertToSearchEntity() -> ServerPB_Usearch_SearchEntity {
        func getSearchEntity<T>(items: T) -> [SearchEntityProps] {
            if let items = items as? [ForwardItem] {
                let props = items.map({ (item) -> SearchEntityProps in
                                var prop = ServerPB_Usearch_SearchEntity.Props()
                                prop.name = item.name
                                prop.description_p = item.description
                                if self.sameType(with: .docFolderIn([])) {
                                    var docMeta = ServerPB_Usearch_SearchEntity.DocFolderMeta()
                                    docMeta.isShareFolder = item.isShardFolder ?? false
                                    docMeta.type = .folder
                                    docMeta.updateTime = 0
                                    prop.meta.typedMeta = .docFolderMeta(docMeta)
                                }
                                return prop
                            })
                return props
            } else if let items = items as? [SearchChatterPickerItem] {
                let props = items.map({ (item) -> SearchEntityProps in
                                var prop = ServerPB_Usearch_SearchEntity.Props()
                                prop.name = item.name
                                return prop
                            })
                return props
            }
            return []
        }

        var entity = ServerPB_Usearch_SearchEntity()
        switch self {
        case .recommend(let searchFilter):
            return searchFilter.convertToSearchEntity()
        case .specificFilterValue(let searchFilter, _, _):
            return searchFilter.convertToSearchEntity()
        case let .general(generalFilter):
            switch generalFilter {
            case let .multiple(info, _):
                var prop = ServerPB_Usearch_SearchEntity.Props()
                prop.name = info.displayName
                entity.props = [prop]
            case let .single(info, _):
                var prop = ServerPB_Usearch_SearchEntity.Props()
                prop.name = info.displayName
                entity.props = [prop]
            case let .date(_, date):
                if let date = date {
                    var prop = ServerPB_Usearch_SearchEntity.Props()
                    prop.name = getTimeRangeString(date: date)
                    entity.props = [prop]
                }
            case let .user(_, ids):
                entity.props = getSearchEntity(items: ids)
            case let .calendar(info, _):
                var prop = ServerPB_Usearch_SearchEntity.Props()
                prop.name = info.displayName
                entity.props = [prop]
            case let .userChat(info, _):
                var prop = ServerPB_Usearch_SearchEntity.Props()
                prop.name = info.displayName
                entity.props = [prop]
            case let .mailUser(info, _):
                var prop = ServerPB_Usearch_SearchEntity.Props()
                prop.name = info.displayName
                entity.props = [prop]
            case let .inputTextFilter(info, _):
                var prop = ServerPB_Usearch_SearchEntity.Props()
                prop.name = info.displayName
                entity.props = [prop]
            }
        case .commonFilter(let commonFilter):
            switch commonFilter {
            case .mainFrom(let fromIds, _, _, _):
                entity.props = getSearchEntity(items: fromIds)
            case .mainWith(let withIds):
                entity.props = getSearchEntity(items: withIds)
            case .mainIn(let inIds):
                entity.props = getSearchEntity(items: inIds)
            case .mainDate(let date):
                guard let date = date else { break }
                var prop = ServerPB_Usearch_SearchEntity.Props()
                prop.name = getTimeRangeString(date: date)
                entity.props = [prop]
            }
        case .date(let date, _):
            guard let date = date else { break }
            var prop = ServerPB_Usearch_SearchEntity.Props()
            prop.name = getTimeRangeString(date: date)
            entity.props = [prop]
        case .chatter(_, let fromIds, _, _, _):
            entity.props = getSearchEntity(items: fromIds)
        case .withUsers(let fromIds):
            entity.props = getSearchEntity(items: fromIds)
        case .chat(_, let inIds):
            entity.props = getSearchEntity(items: inIds)
        case .messageType(let messageFilterType):
            var prop = ServerPB_Usearch_SearchEntity.Props()
            prop.name = messageFilterType.name
            entity.props = [prop]
        case .messageAttachmentType(let type):
            var prop = ServerPB_Usearch_SearchEntity.Props()
            prop.name = type.name
            entity.props = [prop]
        case .messageMatch(let types):
            entity.props = types.map({ (type) -> SearchEntityProps in
                var prop = ServerPB_Usearch_SearchEntity.Props()
                prop.name = type.name
                return prop
            })
        case .docType(let docType):
            var prop = ServerPB_Usearch_SearchEntity.Props()
            prop.name = docType.name
            entity.props = [prop]
        case .docFrom(let fromIds, _, _, _):
            entity.props = getSearchEntity(items: fromIds)
        case .docPostIn(let inIds):
            entity.props = getSearchEntity(items: inIds)
        case .docFormat(let formats, _):
            entity.props = formats.map({ (format) -> SearchEntityProps in
                var prop = ServerPB_Usearch_SearchEntity.Props()
                prop.name = format.title
                return prop
            })
        case .docCreator(let fromIds, let uid):
            let metaIds = fromIds.map { $0.chatterID }
            if metaIds != [uid] {
                entity.props = getSearchEntity(items: fromIds)
            }
        case .docContentType(let docContentType):
            var prop = ServerPB_Usearch_SearchEntity.Props()
            prop.name = docContentType.name
            entity.props = [prop]
        case .docSharer(let fromIds):
            entity.props = getSearchEntity(items: fromIds)
        case .docSortType(let docSortType):
            var prop = ServerPB_Usearch_SearchEntity.Props()
            prop.name = docSortType.name
            entity.props = [prop]
        case .docFolderIn(let items):
            entity.props = getSearchEntity(items: items)
        case .docWorkspaceIn(let items):
            entity.props = getSearchEntity(items: items)
        case .messageChatType(let chatType):
            var prop = ServerPB_Usearch_SearchEntity.Props()
            prop.name = chatType.name
            entity.props = [prop]
        case .chatMemeber(_, let memebers):
            entity.props = getSearchEntity(items: memebers)
        case .groupSortType(let groupSortType):
            var prop = ServerPB_Usearch_SearchEntity.Props()
            prop.name = groupSortType.name
            entity.props = [prop]
        case .chatType(let types):
            entity.props = types.map({ (type) -> SearchEntityProps in
                var prop = ServerPB_Usearch_SearchEntity.Props()
                prop.name = type.name
                return prop
            })
        case .chatKeyWord, .threadType, .wikiCreator, .docOwnedByMe: entity.props = []
            // docOwnedByMe只需要标题，所以返回空的entity
        }
        return entity
    }
}

public extension Array where Element == SearchFilter {

    // MARK: - 统计字段: https://bytedance.feishu.cn/docs/doccnVV4PvuLHkJFV7Haui9Spmd#AuBOZz

    func convertToFilterStatusParam() -> String {
        var status = [String]()
        for filter in self where !filter.isEmpty {
            status.append(filter.trackingRepresentation)
        }
        return status.joined(separator: ",")
    }

    func convertToFilterStatusParamWithoutEmpty() -> String {
        var status = [String]()
        for filter in self {
            status.append(filter.trackingRepresentation)
        }
        return status.joined(separator: ",")
    }

    func convertToSelectedRecommendFilterTrackingInfo() -> String? {
        guard !withNoFilter else { return nil }
        var trackingInfos = [String]()
        for filter in self {
            if filter.isSelectedBasedOnQueryRecommend {
                trackingInfos.append(makeFilterParam(withFilter: filter, fromSource: .fromQuery))
            }
            if filter.isSelectedBasedOnResultRecommend {
                trackingInfos.append(makeFilterParam(withFilter: filter, fromSource: .fromResults))
            }
        }
        return trackingInfos.joined(separator: ",")
    }

    func convertToRecommendFilterTrackingInfo() -> String? {
        var trackingInfos = [String]()
        for filter in self {
            if filter.isRecommendFilter {
                trackingInfos.append(makeFilterParam(withFilter: filter, fromSource: .fromQuery))
            }
            if !filter.basedOnResultRecommendList.isEmpty {
                trackingInfos.append(makeFilterParam(withFilter: filter, fromSource: .fromResults))
            }
        }
        guard !trackingInfos.isEmpty else { return nil }
        return trackingInfos.joined(separator: ",")
    }

    private func makeFilterParam(withFilter filter: SearchFilter, fromSource source: SearchFilter.RecommendSourceType) -> String {
        return ["filter": filter.trackingRepresentation, "source": source.trackingRepresentation].description
    }

    func convertToSelectedAdvanceSyntaxFilterTrackingInfo() -> String? {
        guard !withNoFilter else { return nil }
        var trackingInfos = [String]()
        for filter in self {
            if let type = filter.advancedSyntaxFilterType {
                trackingInfos.append(makeAdvancedSyntaxFilterParam(withFilter: filter, fromSource: type))
            }
        }
        return trackingInfos.joined(separator: ",")
    }

    private func makeAdvancedSyntaxFilterParam(withFilter filter: SearchFilter, fromSource source: SearchFilter.AdvancedSyntaxFilterType) -> String {
        return ["filter": filter.trackingRepresentation, "source": source.rawValue].description
    }

    var currentSortType: String? {
        for filter in self {
            switch filter {
            case .groupSortType(let type): return type.trackingRepresentation
            case .docSortType(let type): return type.trackingRepresentation
            default: continue
            }
        }
        return nil
    }

    var withNoFilter: Bool {
        for filter in self where !filter.isEmpty {
            return false
        }
        return true
    }

}

public extension ServerPB_Searches_IntegrationSearchRequest.FilterParam {
    func convert(chatMap: [String: Chat], chatterMap: [String: Chatter]) -> [SearchFilter] {
        let chats = chatIds.compactMap { chatMap[$0] }
        var mode: ChatFilterMode = .unlimited
        if chatFilterParam.chatModes == [.thread] {
            mode = .thread
        }
        if chatFilterParam.chatModes == [.normal] {
            mode = .normal
        }
        let chatFilter = SearchFilter.chat(mode: mode, picker: chats.map { ForwardItem(chat: $0) })

        // chatter
        let messageCreators = messageCreatorIds.compactMap { chatterMap[$0] }
        let chatterFilter = SearchFilter.chatter(mode: mode, picker: messageCreators.map { SearchChatterPickerItem.chatter($0) }, recommends: [], fromType: .user, isRecommendResultSelected: false)
        let withUserFilter = SearchFilter.withUsers(messageCreators.map { SearchChatterPickerItem.chatter($0) })

        // date
        let messageStartTime = (self.messageStartTime > 0) ? self.messageStartTime : nil
        let startDate = messageStartTime.flatMap { Date(timeIntervalSince1970: TimeInterval($0)) }
        let messageEndTime = (self.messageEndTime > 0) ? self.messageEndTime : nil
        let endDate = messageEndTime.flatMap { Date(timeIntervalSince1970: TimeInterval($0)) }
        let dateFilter: SearchFilter
        if let endDate = endDate {
            dateFilter = .date(date: SearchFilter.FilterDate(startDate: startDate, endDate: endDate), source: .message)
        } else {
            dateFilter = .date(date: nil, source: .message)
        }

        // doc
        let docFilter = SearchFilter.docFormat(DocFormatType.filterTypes(with: docTypes), .main)

        let docPostIn = SearchFilter.docPostIn(chats.map { ForwardItem(chat: $0) })

        var newDocType: SearchFilter.DocType = .all
        switch docType {
        case .wiki: newDocType = .wiki
        case .doc: newDocType = .doc
        default: break
        }
        let docTypeFilter = SearchFilter.docType(newDocType)

        // docCreateor
        let docCreators = docCreatorIds.compactMap { chatterMap[$0] }
        let docCreatorsFilter = SearchFilter.docCreator(docCreators.map { SearchChatterPickerItem.chatter($0) }, Container.shared.getCurrentUserResolver().userID)

        // chatMemeber
        let chatMemeber = chatFilterParam.chatMemberIds.compactMap { chatterMap[$0] }
        let chatMemeberFilter = SearchFilter.chatMemeber(mode: mode, picker: chatMemeber.map { SearchChatterPickerItem.chatter($0) })

        // chatKeyWord
        let chatKeyWord = SearchFilter.chatKeyWord(chatFilterParam.chatMessageKey)

        // chatTypes
        var chatType = SearchFilter.chatType([])
        var threadType = SearchFilter.threadType(.all)

        switch mode {
        case .thread:
            threadType = SearchFilter.threadType(chatFilterParam.chatTypes.threadFilterType)
        @unknown default:
            chatType = .chatType(chatFilterParam.chatTypes.map { $0.toChatFilterType() })
        }
        var filters = [chatFilter,
                       chatterFilter,
                       withUserFilter,
                       dateFilter,
                       docFilter,
                       docPostIn,
                       docTypeFilter,
                       docCreatorsFilter,
                       chatMemeberFilter,
                       chatKeyWord,
                       chatType,
                       threadType]
        if messageFilterParam.mustNotFromTypes.contains(.bot) {
            filters.append(.messageMatch([.excludeBot]))
        }
        if messageFilterParam.mustFromTypes.contains(.bot) {
            filters.append(.messageMatch([.onlyBot]))
        }
        return filters
    }
}

public extension SearchActionFilter {
    func convertToDateDescription(startTime: Int64, endTime: Int64) -> String {
        let startTime = startTime > 0 ? startTime : nil
        let startDate = startTime.flatMap { Date(timeIntervalSince1970: TimeInterval($0)) }
        let endDate = Date(timeIntervalSince1970: TimeInterval(endTime))
        let date = SearchFilter.FilterDate(startDate: startDate, endDate: endDate)
        return getTimeRangeString(date: date)
    }

    var filterTitle: String { // 不能直接复用SearchFilter里的title，因为有些title包含了筛选器数据的信息
        guard let typedFilter = typedFilter else { return "" }
        switch typedFilter {
        case .smartSearchFromUser: return BundleI18n.LarkSearchFilter.Lark_ASL_NewFilter_FromUserFilterPortal
        case .smartSearchWithUser:
            /// 综合页面，所在会话过滤器
            return BundleI18n.LarkSearchFilter.Lark_Search_IMAndDocsFilters_GroupChatParticipantFilter_FieldName
        case .smartSearchInChat: return BundleI18n.LarkSearchFilter.Lark_ASL_NewFilter_InChat
        case .smartSearchTimeRange: return BundleI18n.LarkSearchFilter.Lark_Search_MobileSearchTimeFilter
        case .messageTimeRange: return BundleI18n.LarkSearchFilter.Lark_Search_MobileSearchTimeFilter
        case .messageFromUser: return BundleI18n.LarkSearchFilter.Lark_ASL_NewFilter_FromUserFilterPortal
        case .messageInChat: return BundleI18n.LarkSearchFilter.Lark_Search_SearchChatFilter
        case .messageType: return BundleI18n.LarkSearchFilter.Lark_MessageSearch_TypeOfMessage
        case .messageAttachment: return BundleI18n.LarkSearchFilter.Lark_MessageSearch_TypeOfMessage
        case .chatTypeFilter:  return BundleI18n.LarkSearchFilter.Lark_ASL_SearchMessagesFilters_FilterChatType
        case .messageMatchScope: return BundleI18n.LarkSearchFilter.Lark_MessageSearch_MatchObject
        case .groupChatSearchType: return BundleI18n.LarkSearchFilter.Lark_Search_SearchGroupByGroupType
        case .groupChatIncludeUser: return BundleI18n.LarkSearchFilter.Lark_Search_IMAndDocsFilters_GroupChatParticipantFilter_FieldName
        case .groupChatSortType: return BundleI18n.LarkSearchFilter.Lark_DocsAndGroupSearch_Rank
        case .docsFromUser: return BundleI18n.LarkSearchFilter.Lark_ASL_NewFilter_FromUserFilterPortal
        case .docsOwner: return BundleI18n.LarkSearchFilter.Lark_Search_DocOwnerFilter
        case .docsSharer: return BundleI18n.LarkSearchFilter.Lark_Search_ResultTagShared
        case .docsContainerType:
            let capsuleEnable = Container.shared.getCurrentUserResolver().fg.staticFeatureGatingValue(with: "search.redesign.capsule")
            if capsuleEnable {
                return BundleI18n.LarkSearchFilter.Lark_NewSearch_SecondarySearch_Docs_RangeFilter_Source
            } else {
                return BundleI18n.LarkSearchFilter.Lark_Search_DocType
            }
        case .docsObjectType:
            let docWikiFilterEnabled = Container.shared.getCurrentUserResolver().fg.staticFeatureGatingValue(with: "lark.search.doc.wiki.filter")
            if docWikiFilterEnabled {
                return BundleI18n.LarkSearchFilter.Lark_Search_DocFormat
            } else {
                return BundleI18n.LarkSearchFilter.Lark_Search_DocType
            }
        case .docsOpenTimeRange:
            let capsuleEnable = Container.shared.getCurrentUserResolver().fg.staticFeatureGatingValue(with: "search.redesign.capsule")
            if capsuleEnable {
                return BundleI18n.LarkSearchFilter.Lark_NewSearch_SecondarySearch_Docs_TimeRangeFilter_DateViewed
            } else {
                return BundleI18n.LarkSearchFilter.Lark_Search_ViewedTimeFilter
            }
        case .docsMatchType: return BundleI18n.LarkSearchFilter.Lark_DocsSearch_MatchContent
        case .docsInChat: return BundleI18n.LarkSearchFilter.Lark_Search_SearchSpaceSharedIn
        case .docsSorter: return BundleI18n.LarkSearchFilter.Lark_DocsAndGroupSearch_Rank
        case .docsInFolder: return BundleI18n.LarkSearchFilter.Lark_ASLSearch_DocsTabFilters_InFolder_Filter
        case .wikisInWikiSpace: return BundleI18n.LarkSearchFilter.Lark_ASLSearch_DocsTabFilters_InWorkspace_Filter
        case .messageWithUser(_):
            return BundleI18n.LarkSearchFilter.Lark_Search_IMAndDocsFilters_GroupChatParticipantFilter_FieldName
        case .enableExtendedSearch: return ""
        @unknown default:
            return ""
        }
    }

    /// 判断是否支持展示筛选器。
    /// 主要处理以下case：1. 新增筛选器之后Fg之外不应展示搜索历史； 2.新增筛选器后，旧版本的飞书包不展示新筛选器的搜索历史
    var filterVisibility: Bool {
        guard let typedFilter = typedFilter else { return false }
        let userResolver = Container.shared.getCurrentUserResolver()
        switch typedFilter {
        case .smartSearchFromUser, .smartSearchInChat, .smartSearchTimeRange, .messageTimeRange, .messageFromUser, .messageInChat, .messageType, .chatTypeFilter, .messageMatchScope,
                .groupChatSearchType, .groupChatIncludeUser, .groupChatSortType, .docsFromUser, .docsOwner, .docsSharer, .docsContainerType, .docsObjectType, .docsOpenTimeRange, .docsMatchType,
                .docsInChat, .docsSorter, .docsInFolder, .wikisInWikiSpace, .enableExtendedSearch:
            return true
        case .messageWithUser: return userResolver.fg.staticFeatureGatingValue(with: "search.filter.messgae.with")
        case .smartSearchWithUser: return userResolver.fg.staticFeatureGatingValue(with: "search.filter.quick_search.with")
        case .messageAttachment: return userResolver.fg.staticFeatureGatingValue(with: "search.message_filter.message_type.link_card")
        @unknown default: return false
        }
    }

    //大部分对齐历史记录的文案（即filterTitle）, 但是部分有差异
    //https://bytedance.feishu.cn/docx/NnrjdfZBqoXu38xMFPpcsqkvnPb?scene=multi_page&sub_scene=message
    var specificFilterActionTitle: String {
        var result = self.filterTitle
        guard let typedFilter = typedFilter else { return result }
        switch typedFilter {
        case .messageType, .messageAttachment, .chatTypeFilter, .messageMatchScope:
            result = ""
        case .docsSorter, .docsContainerType, .docsObjectType, .docsMatchType:
            result = ""
        case .docsOwner(let meta):
            let currentUid = Container.shared.getCurrentUserResolver().userID
            if meta.userIds == [currentUid] {
                result = ""
            }
        default:
            break
        }
        //加空格
        return result + (!result.isEmpty ? " " : "")
    }

    // swiftlint:disable all
    var hasEntityProps: Bool {
        switch self.typedFilter {
        case .smartSearchFromUser, .smartSearchWithUser, .smartSearchInChat, .messageFromUser, .messageInChat, .groupChatIncludeUser, .docsFromUser, .docsOwner, .docsSharer, .docsInChat, .docsInFolder, .wikisInWikiSpace, .messageWithUser:
            return true
        case .smartSearchTimeRange, .messageTimeRange, .messageType, .messageAttachment, .chatTypeFilter, .messageMatchScope, .groupChatSearchType, .groupChatSortType, .docsContainerType, .docsObjectType, .docsOpenTimeRange, .docsMatchType, .docsSorter:
            return false
        case .enableExtendedSearch: // 不使用的字段
            return false
        default: return false
        }
    }
    // swiftlint:enable all

    var filterDescription: String {
        switch self.typedFilter {
        case .smartSearchTimeRange(let meta):
            return convertToDateDescription(startTime: meta.customizedStartTime, endTime: meta.customizedEndTime)
        case .messageTimeRange(let meta):
            return convertToDateDescription(startTime: meta.customizedStartTime, endTime: meta.customizedEndTime)
        case .docsOpenTimeRange(let meta):
            return convertToDateDescription(startTime: meta.customizedStartTime, endTime: meta.customizedEndTime)
        case .messageType(let meta):
            switch meta.messageType {
            case .file: return MessageFilterType.file.name
            case .link: return MessageFilterType.link.name
            @unknown default: return MessageFilterType.all.name
            }
        case .messageAttachment(let meta):
            if let type = meta.includeAttachmentTypes.first {
                switch type {
                case .attachmentFile: return MessageAttachmentFilterType.attachmentFile.name
                case .attachmentLink: return MessageAttachmentFilterType.attachmentLink.name
                case .attachmentImage: return MessageAttachmentFilterType.attachmentImage.name
                case .attachmentVideo: return MessageAttachmentFilterType.attachmentVideo.name
                case .unknownAttachmentType: return MessageAttachmentFilterType.unknownAttachmentType.name
                case .attachmentFolder: return ""
                @unknown default: return ""
                }
            } else {
                return ""
            }
        case .chatTypeFilter(let meta):
            switch meta.chatFilterType {
            case .groupChat: return SearchFilter.MessageChatFilterType.groupChat.name
            case .p2PChat: return SearchFilter.MessageChatFilterType.p2PChat.name
            @unknown default: return SearchFilter.MessageChatFilterType.all.name
            }
        case .messageMatchScope(let meta):
            var typesName = meta.scopeTypes.map { type -> String in
                switch type {
                case .atMe: return SearchFilter.MessageContentMatchType.atMe.name
                case .blockBotMessage: return SearchFilter.MessageContentMatchType.excludeBot.name
                case .blockUserMessage: return SearchFilter.MessageContentMatchType.onlyBot.name
                @unknown default: return SearchFilter.MessageContentMatchType.atMe.name
                }
            }.reduce("") { text, name in "\(text)，\(name)" }
            if !typesName.isEmpty {
                typesName.removeFirst()
            }
            return typesName
        case .groupChatSearchType(let meta):
            var typesName = meta.searchType.map { type -> String in
                switch type {
                case .crossTenant: return ChatFilterType.outer.name
                case .private: return ChatFilterType.private.name
                case .publicJoined: return ChatFilterType.publicJoin.name
                case .publicNotJoined: return ChatFilterType.publicAbsent.name
                case .default: return ChatFilterType.unknowntab.name
                }
            }.reduce("") { text, name in "\(text)，\(name)" }
            if !typesName.isEmpty {
                typesName.removeFirst()
            }
            return typesName
        case .groupChatSortType(let meta):
            switch meta.sortType {
            case .groupCreateTime: return SearchFilter.GroupSortType.mostRecentCreated.name
            case .groupUpdateTime: return SearchFilter.GroupSortType.mostRecentUpdated.name
            case .groupNumMembers: return SearchFilter.GroupSortType.leastNumGroupMember.name
            case .groupDefaultSort: return SearchFilter.GroupSortType.mostRelated.name
            @unknown default:
                return ""
            }
        case .docsContainerType(let meta):
            switch meta.containerType {
            case .docs: return SearchFilter.DocType.doc.name
            case .wiki: return SearchFilter.DocType.wiki.name
            case .default: return SearchFilter.DocType.all.name
            }
        case .docsObjectType(let meta):
            var typesName = meta.objectTypes.map { type -> String in
                switch type {
                case .doc: return DocFormatType.doc.title
                case .bitable: return DocFormatType.bitale.title
                case .file: return DocFormatType.file.title
                case .mindnote: return DocFormatType.mindNote.title
                case .sheet: return DocFormatType.sheet.title
                case .slide: return DocFormatType.slide.title
                case .slides: return DocFormatType.slides.title
                @unknown default: return DocFormatType.all.title
                }
            }.reduce("") { text, name in "\(text)，\(name)" }
            if !typesName.isEmpty {
                typesName.removeFirst()
            }
            return typesName
        case .docsMatchType(let meta):
            switch meta.matchType {
            case .onlyComment: return DocContentType.onlyComment.name
            case .onlyTitle: return DocContentType.onlyTitle.name
            @unknown default: return DocContentType.fullContent.name
            }
        case .docsSorter(let meta):
            switch meta.sortByField {
            case .createTime: return SearchFilter.DocSortType.mostRecentCreated.name
            case .editTime: return SearchFilter.DocSortType.mostRecentUpdated.name
            @unknown default: return SearchFilter.DocSortType.mostRelated.name
            }
        case .smartSearchFromUser, .smartSearchInChat, .messageFromUser, .messageInChat, .groupChatIncludeUser, .docsFromUser, .docsOwner, .docsSharer, .docsInChat, .docsInFolder, .wikisInWikiSpace:
            return ""
        case .enableExtendedSearch: // 不使用的字段
            return ""
        default: return ""
        }
    }
}

// TODO: - 通用推荐全量后下掉
public extension SearchFilterParam {
    func convert(chatMap: [String: Chat], chatterMap: [String: Chatter]) -> [SearchFilter] {
        let chats = chatIds.compactMap { chatMap[$0] }
        var mode: ChatFilterMode = .unlimited
        if chatFilterParam.chatModes == [.thread] {
            mode = .thread
        }
        if chatFilterParam.chatModes == [.normal] {
            mode = .normal
        }
        let chatFilter = SearchFilter.chat(mode: mode, picker: chats.map { ForwardItem(chat: $0) })

        // chatter
        let messageCreators = messageCreatorIds.compactMap { chatterMap[$0] }
        let chatterFilter = SearchFilter.chatter(mode: mode, picker: messageCreators.map { SearchChatterPickerItem.chatter($0) }, recommends: [], fromType: .user, isRecommendResultSelected: false)
        let withUserFilter = SearchFilter.withUsers(messageCreators.map { SearchChatterPickerItem.chatter($0) })
        // date
        let messageStartTime = (self.messageStartTime > 0) ? self.messageStartTime : nil
        let startDate = messageStartTime.flatMap { Date(timeIntervalSince1970: TimeInterval($0)) }
        let messageEndTime = (self.messageEndTime > 0) ? self.messageEndTime : nil
        let endDate = messageEndTime.flatMap { Date(timeIntervalSince1970: TimeInterval($0)) }
        let dateFilter: SearchFilter
        if let endDate = endDate {
            dateFilter = .date(date: SearchFilter.FilterDate(startDate: startDate, endDate: endDate), source: .message)
        } else {
            dateFilter = .date(date: nil, source: .message)
        }

        // doc
        let docFilter = SearchFilter.docFormat(DocFormatType.filterTypes(with: docTypes), .main)

        // docCreateor
        let docCreators = messageCreatorIds.compactMap { chatterMap[$0] }
        let docCreatorsFilter = SearchFilter.docCreator(docCreators.map { SearchChatterPickerItem.chatter($0) }, Container.shared.getCurrentUserResolver().userID)

        // chatMemeber
        let chatMemeber = chatFilterParam.chatMemberIds.compactMap { chatterMap[$0] }
        let chatMemeberFilter = SearchFilter.chatMemeber(mode: mode, picker: chatMemeber.map { SearchChatterPickerItem.chatter($0) })

        // chatKeyWord
        let chatKeyWord = SearchFilter.chatKeyWord(chatFilterParam.chatMessageKey)

        // chatTypes
        var chatType = SearchFilter.chatType([])
        var threadType = SearchFilter.threadType(.all)

        switch mode {
        case .thread:
            threadType = SearchFilter.threadType(chatFilterParam.chatTypes.threadFilterType)
        default:
            chatType = .chatType(chatFilterParam.chatTypes.map { $0.toChatFilterType() })
        }
        var filters = [chatFilter,
                chatterFilter,
                withUserFilter,
                dateFilter,
                docFilter,
                docCreatorsFilter,
                chatMemeberFilter,
                chatKeyWord,
                chatType,
                threadType]
        if messageFilterParam.mustNotFromTypes.contains(.bot) {
            filters.append(.messageMatch([.excludeBot]))
        }
        if messageFilterParam.mustFromTypes.contains(.bot) {
            filters.append(.messageMatch([.onlyBot]))
        }
        return filters
    }
}

public extension ThreadFilterType {
    var title: String {
        switch self {
        case .private:
            return BundleI18n.LarkSearchFilter.Lark_Search_ChannelTypePrivateChannel
        case .public:
            return BundleI18n.LarkSearchFilter.Lark_Search_ChannelTypePublicChannel
        default:
            return BundleI18n.LarkSearchFilter.Lark_Legacy_All
        }
    }

    var trackInfo: String {
        switch self {
        case .private:
            return "private"
        case .public:
            return "public"
        default:
            return "all"
        }
    }
}

extension NSMutableAttributedString {
    func addImageAttachment(image: UIImage, font: UIFont) {
        let textAttributes: [NSAttributedString.Key: Any] = [.font: font]

        let attachment = NSTextAttachment()
        attachment.image = image.withRenderingMode(.alwaysTemplate)
        let attachmentString = NSMutableAttributedString(attachment: attachment)
        attachment.bounds = CGRect(x: 0, y: CGFloat(roundf(Float(font.capHeight - image.size.height))) / 2.0, width: image.size.width, height: image.size.height)
        attachmentString.addAttributes(
            textAttributes,
            range: NSRange(location: 0, length: attachmentString.length)
        )
        self.append(attachmentString)
    }
}
