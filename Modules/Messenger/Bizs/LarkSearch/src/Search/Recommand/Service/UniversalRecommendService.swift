//
//  UniversalRecommendService.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/24.
//

import RxSwift
import RxCocoa
import ServerPB
import RustPB
import LarkSearchCore
import Foundation
import LKCommonsLogging
import LarkSearchFilter
import LarkModel
import LarkMessengerInterface
import LarkSDKInterface
import LarkAccountInterface
import LarkContainer
import LarkRustClient

typealias UniversalRecommendSearchHistory = ServerPB_Usearch_QueryHistoryInfo
typealias UniversalRecommendHotword = ServerPB_Search_reco_ActionRecommend
typealias UniversalRecommendResult = ServerPB_Usearch_SearchResult
typealias UniversalRecommendFilterParam = [ServerPB_Usearch_SearchActionFilter]

final class UniversalRecommendService: UniversalRecommendRepo {
    static let logger = Logger.log(UniversalRecommendService.self, category: "Module.IM.Search")
    let request: UniversalRecommendRequest
    let cacheKey: RecommendCacheKey

    let userResolver: UserResolver
    private lazy var dataQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "UniversalRecommendDataQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    private lazy var dataScheduler: OperationQueueScheduler = {
        let scheduler = OperationQueueScheduler(operationQueue: dataQueue)
        return scheduler
    }()

    init (userResolver: UserResolver, request: UniversalRecommendRequest, cacheKey: RecommendCacheKey) {
        self.userResolver = userResolver
        self.request = request
        self.cacheKey = cacheKey
    }
    func getRecommendSection(contentWidth: CGFloat) -> Driver<[UniversalRecommendSection]> {
        let sections = BehaviorRelay<[UniversalRecommendSection]>(value: RecommendCacheManager.shared.loadSections(cacheKey: self.cacheKey))
        let sectionsFromWeb = (try? userResolver.resolve(assert: RustService.self))?.sendPassThroughAsyncRequest(request, serCommand: .getUniversalRecommend)
            .map { (response: ServerPB_Search_urecommend_UniversalRecommendResponse) -> [UniversalRecommendSection] in
                var sections: [UniversalRecommendSection] = []
                for recommendSection in response.recommendSections {
                    switch recommendSection.sectionType {
                    case .actionRecommend:
                        let searchRelatedSection = recommendSection.recommendContent.searchRelatedSection
                        let chipSection = UniversalRecommendSection.ChipSection(userResolver: self.userResolver,
                                                                                title: searchRelatedSection.title,
                                                                                contentType: .hotword,
                                                                                items: searchRelatedSection.actionRecommends.actionRecommends)
                        if !searchRelatedSection.actionRecommends.actionRecommends.isEmpty {
                            sections.append(.chip(chipSection))
                        }
                    case .searchHistory:
                        let searchRelatedSection = recommendSection.recommendContent.searchRelatedSection
                        var items: [UniversalRecommendChipItem] = []
                        items = searchRelatedSection.searchHistories.queryHistories.filter { history in
                            let filterVisibility = history.searchAction.filters.flatMap { $0.filterVisibility }
                            return !history.query.isEmpty || filterVisibility.contains(true)
                            /// 去除query为空并且筛选器不支持展示的情况
                        }
                        let chipSection = UniversalRecommendSection.ChipSection(userResolver: self.userResolver,
                                                                                title: searchRelatedSection.title,
                                                                                contentType: .history,
                                                                                items: items)
                        if !searchRelatedSection.searchHistories.queryHistories.isEmpty {
                            sections.append(.chip(chipSection))
                        }
                    case .recommendEntity:
                        let entityRecommend = recommendSection.recommendContent.entityRecommend
                        for entitySection in entityRecommend.entitySections {
                            switch entitySection.layoutStyle.style {
                            case .cardStyle:
                                let iconStyle = entitySection.layoutStyle.cardStyle.iconStyle.recommendIconStyle
                                let totalRow = Int(entitySection.layoutStyle.cardStyle.expandRows)
                                let cardSection = UniversalRecommendSection.CardSection(userResolver: self.userResolver,
                                                                                        contentWidth: contentWidth,
                                                                                        title: entitySection.title,
                                                                                        itemPerRow: Int(entitySection.layoutStyle.cardStyle.cols),
                                                                                        totalRow: totalRow,
                                                                                        items: entitySection.results,
                                                                                        iconStyle: iconStyle,
                                                                                        defaultIsFold: !entitySection.layoutStyle.cardStyle.defualtIsExpand,
                                                                                        sectionTag: entitySection.enTitle)
                                if !entitySection.results.isEmpty {
                                    sections.append(.card(cardSection))
                                }
                            case .listStyle:
                                let listSection = UniversalRecommendSection.ListSection(title: entitySection.title,
                                                                                        items: entitySection.results,
                                                                                        iconStyle: entitySection.layoutStyle.cardStyle.iconStyle.recommendIconStyle,
                                                                                        sectionTag: entitySection.enTitle)
                                if !entitySection.results.isEmpty {
                                    sections.append(.list(listSection))
                                }
                            case .unknown:
                                assertionFailure("Unknown layout Style")
                            @unknown default:
                                assertionFailure("Unknown layout Style")
                            }
                        }
                    case .unknown:
                        assertionFailure("Unknown section Type")
                    @unknown default:
                        assertionFailure("Unknown section Type")
                    }
                }
                return sections
            }
        sectionsFromWeb?
            .observeOn(dataScheduler)
            .subscribe(onNext: { section in
                sections.accept(section)
            })
        return sections.asDriver(onErrorRecover: { _ in .empty() })
    }
}

public struct DigestData {
    let filter: SearchActionFilter
    let entities: SearchEntity
}

extension UniversalRecommendSearchHistory: UniversalRecommendChipItem {
    var title: String { return query }
    var iconStyle: UniversalRecommend.IconStyle {
        if query.isEmpty && !searchAction.filters.isEmpty {
            return .noQuery
        } else {
            return .rectangle
        }
    }

    func getDigestData() -> [DigestData] {
        guard self.searchAction.filters.count == self.entities.count,
              !self.searchAction.filters.isEmpty else { return [] }
        var digestDataArray: [DigestData] = []
        for index in 0..<self.searchAction.filters.count {
            guard searchAction.filters[index].filterVisibility else {
                return []
            }
            digestDataArray.append(DigestData(filter: searchAction.filters[index],
                                              entities: self.entities[index]))
        }
        return digestDataArray
    }

    var noQueryDigest: String {
        let digestDataArray = getDigestData()
        var digestString = digestDataArray.map { (data) -> String in
            var filterName: String
            let currentUid = Container.shared.getCurrentUserResolver().userID
            if case .docsOwner(let meta) = data.filter.typedFilter, meta.userIds == [currentUid] {
                filterName = BundleI18n.LarkSearch.Lark_Search_DocsOwnedByMeFilter_Option
            } else {
                filterName = data.filter.filterTitle
                filterName += !filterName.isEmpty ? "：" : ""
            }
            var entitiesName = ""
            if data.filter.hasEntityProps { // 如果该filter有实体，例如chat，chatter等，从props的name中取值
                entitiesName = data.entities.props.map { prop -> String in
                    return prop.name
                }.reduce("") { text, name in "\(text)、\(name)" }
                if !entitiesName.isEmpty {
                    entitiesName.removeFirst()
                }
            } else { // 否则通过映射关系从filter中获取
                entitiesName = data.filter.filterDescription
            }

            return filterName + entitiesName
        }.reduce("") { text, name in "\(text)，\(name)" }

        if !digestString.isEmpty {
            digestString.removeFirst()
        }
        return digestString
    }
    var content: UniversalRecommendChipItemContent { .history(self) }
}

extension UniversalRecommendHotword: UniversalRecommendChipItem {
    var title: String { return body }
    var iconStyle: UniversalRecommend.IconStyle { .rectangle }
    var content: UniversalRecommendChipItemContent { .hotword(self) }
}

extension ServerPB_Usearch_SearchResult: UniversalRecommendCardItem, Equatable {
    var avatarId: String { resultMeta.typedMeta?.avatarID ?? "" }
    var title: String { titleHighlighted }
}

extension ServerPB_Search_urecommend_IconStyle {
    var recommendIconStyle: UniversalRecommend.IconStyle {
        switch self {
        case .circle: return .circle
        case .rectangle: return .rectangle
        @unknown default:
            assertionFailure("Unknown icon style")
            return .circle
        }
    }
}
// swiftlint:disable all
public extension DigestData {
    func convertToFilterDate(startTime: Int64, endTime: Int64) -> SearchFilter.FilterDate {
        let startTime = startTime > 0 ? startTime : nil
        let startDate = startTime.flatMap { Date(timeIntervalSince1970: TimeInterval($0)) }
        let endDate = Date(timeIntervalSince1970: TimeInterval(endTime))
        return SearchFilter.FilterDate(startDate: startDate, endDate: endDate)
    }

    func convertToFilter(userResovler: UserResolver, chatMap: [String: Chat], chatterMap: [String: Chatter]) -> SearchFilter? {
        guard let typedFilter = filter.typedFilter else { return SearchFilter.chatType([]) }
        switch typedFilter {
        case .smartSearchTimeRange(let meta):
            let date = convertToFilterDate(startTime: meta.customizedStartTime,
                                           endTime: meta.customizedEndTime)
            return .commonFilter(.mainDate(date: date))
        case .smartSearchFromUser(let meta):
            let chatters = meta.userIds.compactMap { chatterMap[$0] }
            return .commonFilter(.mainFrom(fromIds: chatters.map { SearchChatterPickerItem.chatter($0) },
                                           recommends: [],
                                           fromType: .user,
                                           isRecommendResultSelected: false))
        case .smartSearchInChat(let meta):
            let chats = meta.groupChatIds.compactMap { chatMap[$0] }
            return .commonFilter(.mainIn(inIds: chats.map { ForwardItem(chat: $0) }))
        case .messageTimeRange(let meta):
            let date = convertToFilterDate(startTime: meta.customizedStartTime,
                                           endTime: meta.customizedEndTime)
            return .commonFilter(.mainDate(date: date))
        case .messageFromUser(let meta):
            let chatters = meta.userIds.compactMap { chatterMap[$0] }
            return .chatter(mode: .unlimited,
                            picker: chatters.map { SearchChatterPickerItem.chatter($0) },
                            recommends: [],
                            fromType: .user,
                            isRecommendResultSelected: false)
        case .messageWithUser(let meta):
            let chatters = meta.userIds.compactMap { chatterMap[$0] }
            return .withUsers(chatters.map { SearchChatterPickerItem.chatter($0) })
        case .smartSearchWithUser(let meta):
            /// 综合搜索 -会话成员
            let chatters = meta.userIds.compactMap { chatterMap[$0] }
            return .commonFilter(.mainWith(chatters.map { SearchChatterPickerItem.chatter($0) }))
        case .messageInChat(let meta):
            let chats = meta.groupChatIds.compactMap { chatMap[$0] }
            return .chat(mode: .unlimited,
                         picker: chats.map { ForwardItem(chat: $0) })
        case .messageType(let meta):
            switch meta.messageType {
            case .file: return .messageType(.file)
            case .link: return .messageType(.link)
            @unknown default: return .messageType(.all)
            }
        case .messageAttachment(let meta):
            if let type = meta.includeAttachmentTypes.first {
                switch type {
                case .attachmentFile: return .messageAttachmentType(.attachmentFile)
                case .attachmentLink: return .messageAttachmentType(.attachmentLink)
                case .attachmentImage: return .messageAttachmentType(.attachmentImage)
                case .attachmentVideo: return .messageAttachmentType(.attachmentVideo)
                case .unknownAttachmentType: return .messageAttachmentType(.unknownAttachmentType)
                case .attachmentFolder: return nil
                @unknown default: return nil
                }
            } else {
                return nil
            }
        case .chatTypeFilter(let meta):
            switch meta.chatFilterType {
            case .groupChat: return .messageChatType(.groupChat)
            case .p2PChat: return .messageChatType(.p2PChat)
            @unknown default: return .messageChatType(.all)
            }
        case .messageMatchScope(let meta):
            let scopeTypes = meta.scopeTypes.map { (type) -> SearchFilter.MessageContentMatchType in
                switch type {
                case .atMe: return .atMe
                case .blockBotMessage: return .excludeBot
                case .blockUserMessage: return .onlyBot
                @unknown default: return .atMe
                }
            }
            return .messageMatch(scopeTypes)
        case .groupChatSearchType(let meta):
            let searchTypes = meta.searchType.map { (type) -> ChatFilterType in
                switch type {
                case .crossTenant: return .outer
                case .private: return .private
                case .publicJoined: return .publicJoin
                case .publicNotJoined: return .publicAbsent
                case .default: return .unknowntab
                }
            }
            return .chatType(searchTypes)
        case .groupChatIncludeUser(let meta):
            let chatters = meta.userIds.compactMap { chatterMap[$0] }
            return .chatMemeber(mode: .unlimited,
                                picker: chatters.map { SearchChatterPickerItem.chatter($0) })
        case .groupChatSortType(let meta):
            switch meta.sortType {
            case .groupCreateTime: return .groupSortType(.mostRecentCreated)
            case .groupUpdateTime: return .groupSortType(.mostRecentUpdated)
            case .groupNumMembers: return .groupSortType(.leastNumGroupMember)
            case .groupDefaultSort: return .groupSortType(.mostRelated)
            @unknown default:
                assertionFailure("unknown case")
                return nil
            }
        case .docsFromUser(let meta):
            let chatters = meta.userIds.compactMap { chatterMap[$0] }
            return .docFrom(fromIds: chatters.map { SearchChatterPickerItem.chatter($0) },
                            recommends: [],
                            fromType: .user,
                            isRecommendResultSelected: false)
        case .docsOwner(let meta):
            let currentID = userResovler.userID
            if meta.userIds == [currentID] {
                return .docOwnedByMe(true, currentID)
            } else {
                let chatters = meta.userIds.compactMap { chatterMap[$0] }
                return .docCreator(chatters.map { SearchChatterPickerItem.chatter($0) }, userResovler.userID)
            }
        case .docsSharer(let meta):
            let chatters = meta.userIds.compactMap { chatterMap[$0] }
            return .docSharer(chatters.map { SearchChatterPickerItem.chatter($0) })
        case .docsContainerType(let meta):
            switch meta.containerType {
            case .docs: return .docType(.doc)
            case .wiki: return .docType(.wiki)
            case .default : return .docType(.all)
            @unknown default:
                assertionFailure("unknown case")
                return nil
            }
        case .docsObjectType(let meta):
            let objectTypes = meta.objectTypes.map { (type) -> DocFormatType in
                switch type {
                case .doc: return .doc
                case .bitable: return .bitale
                case .file: return .file
                case .mindnote: return .mindNote
                case .sheet: return .sheet
                case .slide: return .slide
                case .slides: return .slides
                default: return .all
                }
            }
            return .docFormat(objectTypes, .main)
        case .docsOpenTimeRange(let meta):
            let date = convertToFilterDate(startTime: meta.customizedStartTime,
                                           endTime: meta.customizedEndTime)
            return .commonFilter(.mainDate(date: date))
        case .docsMatchType(let meta):
            switch meta.matchType {
            case .onlyComment: return .docContentType(.onlyComment)
            case .onlyTitle: return .docContentType(.onlyTitle)
            @unknown default: return .docContentType(.fullContent)
            }
        case .docsInChat(let meta):
            let chats = meta.groupChatIds.compactMap { chatMap[$0] }
            return .docPostIn(chats.map { ForwardItem(chat: $0) })
        case .docsSorter(let meta):
            switch meta.sortByField {
            case .createTime: return .docSortType(.mostRecentCreated)
            case .editTime: return .docSortType(.mostRecentUpdated)
            @unknown default: return .docSortType(.mostRelated)
            }
        case .docsInFolder(let meta):
            guard meta.folderTokens.count == entities.props.count,
                  !meta.folderTokens.isEmpty else { return .docFolderIn([]) }
            var items: [ForwardItem] = []
            for index in 0..<meta.folderTokens.count {
                items.append(ForwardItem(avatarKey: "", name: entities.props[index].name, subtitle: "", description: entities.props[index].description_p, descriptionType: .onDefault, localizeName: "", id: meta.folderTokens[index], type: .unknown, isCrossTenant: false, isCrypto: false, isThread: false, doNotDisturbEndTime: 0, hasInvitePermission: true, userTypeObservable: nil, enableThreadMiniIcon: false, isOfficialOncall: false, isShardFolder: entities.props[index].meta.docFolderMeta.isShareFolder))
            }
            return .docFolderIn(items)
        case .wikisInWikiSpace(let meta):
            guard meta.spaceIds.count == entities.props.count,
                  !meta.spaceIds.isEmpty else { return .docWorkspaceIn([]) }
            var items: [ForwardItem] = []
            for index in 0..<meta.spaceIds.count {
                items.append(ForwardItem(avatarKey: "", name: entities.props[index].name, subtitle: "", description: entities.props[index].description_p, descriptionType: .onDefault, localizeName: "", id: meta.spaceIds[index], type: .unknown, isCrossTenant: false, isCrypto: false, isThread: false, doNotDisturbEndTime: 0, hasInvitePermission: true, userTypeObservable: nil, enableThreadMiniIcon: false, isOfficialOncall: false))
            }
            return .docWorkspaceIn(items)
        default:
            return nil
        }
    }
}
// swiftlint:enable all
