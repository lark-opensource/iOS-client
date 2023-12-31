//
//  SearchCommonlyUsedFilterStore.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/3/27.
//

import Foundation
import UIKit
import LarkModel
import RxSwift
import RxCocoa
import ServerPB
import LarkSearchCore
import LarkSDKInterface
import LKCommonsLogging
import LarkSearchFilter
import LarkMessengerInterface
import LarkAccountInterface
import LarkSetting
import LarkFeatureGating
import LarkListItem
import LarkContainer

typealias CommonlyUsedFilterDataList = ServerPB_Usearch_PullRecommendFilterDataResponse.DataList
typealias CommonlyUsedFilterDataItem = ServerPB_Usearch_PullRecommendFilterDataResponse.DataItem

final class SearchCommonlyUsedFilterStore {
    static let logger = Logger.log(SearchCommonlyUsedFilterStore.self, category: "SearchCommonlyUsedFilterStore")
    private let disposeBag = DisposeBag()
    public var commonlyUsedFilters: [ServerPB_Usearch_SearchTabName: [SearchFilter]] = [:]

    let userResolver: UserResolver
    init(userResolver: UserResolver, commonlyUsedFiltersDataList: [CommonlyUsedFilterDataList]) {
        self.userResolver = userResolver
        update(commonlyUsedFiltersDataList)
    }

    func update(_ commonlyUsedFiltersDataLists: [CommonlyUsedFilterDataList]) {
        commonlyUsedFilters = [:]
        guard SearchFeatureGatingKey.enableCommonlyUsedFilter.isEnabled else { return }
        if commonlyUsedFiltersDataLists.isEmpty {
            return
        }
        for list in commonlyUsedFiltersDataLists {
            self.commonlyUsedFilters.updateValue(convertToLists(dataItemList: list.data), forKey: list.tab)
        }
    }

    func convertToLists(dataItemList: [CommonlyUsedFilterDataItem]) -> [SearchFilter] {
        var filters: [SearchFilter] = []
        for dataItem in dataItemList {
            if let filter = SearchActionFilterPBTransform.converToFilter(actionFilter: dataItem.searchFilter,
                                                                         filterEntity: dataItem.filterEntities.first,
                                                                         shouldIncludeValue: true,
                                                                         userResolver: userResolver) {
                filters.append(.specificFilterValue(filter, dataItem.searchFilter.specificFilterActionTitle, false))
            }
        }
        return filters
    }
}

final class SearchActionFilterPBTransform {
    static let logger = Logger.log(SearchActionFilterPBTransform.self, category: "SearchActionFilterPBTransform")
    // 常用筛选器和推荐筛选项 必须有具体的筛选值 shouldIncludeValue
    static func converToFilter(actionFilter: ServerPB_Usearch_SearchActionFilter,
                               filterEntity: ServerPB_Usearch_SearchResult?,
                               shouldIncludeValue: Bool,
                               userResolver: UserResolver) -> SearchFilter? {
        let userService = try? userResolver.resolve(assert: PassportUserService.self)
        func transformChatterPickerItem(filterEntity: ServerPB_Usearch_SearchResult?) -> [SearchChatterPickerItem] {
            guard let searchResult = filterEntity else { return [] }
            var pickers: [SearchChatterPickerItem] = []
            let recommendResult = Search.UniversalRecommendResult(base: searchResult, contextID: nil)
            let picker = SearchChatterPickerItem.searchResultType(recommendResult)
            pickers.append(picker)
            return pickers
        }

        func transformForwardItem(filterEntity: ServerPB_Usearch_SearchResult?) -> [ForwardItem] {
            guard let searchResult = filterEntity, let item = searchResult.transformFilterChatForwardItem(userService: userService) else { return [] }
            return [item]
        }

        guard let typedFilter = actionFilter.typedFilter else { return nil }
        switch typedFilter {
        case .messageFromUser:
            let pickers = transformChatterPickerItem(filterEntity: filterEntity)
            if pickers.isEmpty && shouldIncludeValue {
                return nil
            }
            return .chatter(mode: .unlimited,
                            picker: pickers,
                            recommends: [],
                            fromType: .user,
                            isRecommendResultSelected: false)
        case .messageWithUser:
            guard SearchFeatureGatingKey.messageWithFilter.isUserEnabled(userResolver: userResolver) else { return nil }
            let pickers = transformChatterPickerItem(filterEntity: filterEntity)
            if pickers.isEmpty && shouldIncludeValue {
                return nil
            }
            return .withUsers(pickers)
        case .messageInChat:
            let pickers = transformForwardItem(filterEntity: filterEntity)
            if pickers.isEmpty && shouldIncludeValue {
                return nil
            }
            return .chat(mode: .unlimited, picker: pickers)
        case .messageTimeRange(let meta):
            let date = Self.convertToFilterDate(startTime: meta.customizedStartTime,
                                           endTime: meta.customizedEndTime)
            return .date(date: date, source: .message)
        case .messageType(let meta):
            guard !SearchFeatureGatingKey.enableMessageAttachment.isEnabled else { return nil }
            switch meta.messageType {
            case .file: return .messageType(.file)
            //由于RustPB使用的结构与IM耦合，不能随便加类型，否则会产生大量的IM侧适配工作量，所以链接类型走异化
            //上报走RustPB，下发走ServerPB，所以ServerPB也需要做适配
            case .unknown:
                if meta.isURL {
                    return .messageType(.link)
                } else {
                    fallthrough
                }
            case .link: return .messageType(.link)
            default:
                if shouldIncludeValue {
                    Self.logger.info("search commonlyUsed filter messageType is illegal")
                    return nil
                } else {
                    return .messageType(.all)
                }
            }
        case .messageAttachment(let meta):
            if let type = meta.includeAttachmentTypes.first, SearchFeatureGatingKey.enableMessageAttachment.isEnabled {
                switch type {
                case .attachmentFile: return .messageAttachmentType(.attachmentFile)
                case .attachmentLink: return .messageAttachmentType(.attachmentLink)
                case .attachmentImage: return .messageAttachmentType(.attachmentImage)
                case .attachmentVideo: return .messageAttachmentType(.attachmentVideo)
                case .unknownAttachmentType: return .messageAttachmentType(.unknownAttachmentType)
                default:
                    if shouldIncludeValue {
                        Self.logger.info("search commonlyUsed filter messageType is illegal")
                        return nil
                    } else {
                        return .messageAttachmentType(.unknownAttachmentType)
                    }
                }
            } else {
                return nil
            }
        case .messageMatchScope(let meta):
            if meta.scopeTypes.contains(.default) {
                if shouldIncludeValue {
                    Self.logger.info("search commonlyUsed filter messageMatchScope has default")
                    return nil
                } else {
                    return .messageMatch([])
                }
            }
            let scopeTypes = meta.scopeTypes.compactMap({ (type) -> SearchFilter.MessageContentMatchType? in
                switch type {
                case .atMe:
                    return .atMe
                case .blockBotMessage:
                    return .excludeBot
                case .blockUserMessage:
                    return .onlyBot
                default:
                    return nil
                }
            })
            if shouldIncludeValue && scopeTypes.isEmpty {
                Self.logger.info("search commonlyUsed filter messageMatchScope has default")
                return nil
            } else {
                return .messageMatch(scopeTypes)
            }
        case .chatTypeFilter(let meta):
            var chatFilterType: SearchFilter.MessageChatFilterType
            switch meta.chatFilterType {
            case .p2PChat:
                chatFilterType = .p2PChat
            case .groupChat:
                chatFilterType = .groupChat
            default:
                chatFilterType = .all
            }
            if shouldIncludeValue, chatFilterType == .all {
                return nil
            }
            return .messageChatType(chatFilterType)
        case .docsSorter(let meta):
            switch meta.sortByField {
            case .createTime: return .docSortType(.mostRecentCreated)
            case .editTime: return .docSortType(.mostRecentUpdated)
            default:
                if shouldIncludeValue {
                    Self.logger.info("search commonlyUsed filter docsSorter is illegal")
                    return nil
                } else {
                    return .docSortType(.mostRelated)
                }
            }
        case .docsOwner(let meta):
            let currentID = userResolver.userID
            if meta.userIds == [currentID] {
                return .docOwnedByMe(true, currentID)
            } else {
                let pickers = transformChatterPickerItem(filterEntity: filterEntity)
                if pickers.isEmpty && shouldIncludeValue {
                    return nil
                }
                return .docCreator(pickers, userResolver.userID)
            }
        case .docsInChat:
            let pickers = transformForwardItem(filterEntity: filterEntity)
            if pickers.isEmpty && shouldIncludeValue {
                return nil
            }
            return .docPostIn(pickers)
        case .docsInFolder(let meta):
            //推荐筛选器都只会有一个结果，不会有多选
            guard let entity = filterEntity,
                  case .docMeta(let doc) = entity.resultMeta.typedMeta,
                  let id = meta.folderTokens.first
            else {
                if shouldIncludeValue {
                    Self.logger.info("search commonlyUsed filter docsInFolder meta illegal")
                    return nil
                } else {
                    return .docFolderIn([])
                }
            }
            let name = entity.title
            let description = BundleI18n.LarkSearch.Lark_ASL_EntryLastUpdated(Date.lf.getNiceDateString(TimeInterval(doc.updateTime)))
            let isShardFolder = doc.isShareFolder
            let item = ForwardItem(avatarKey: "", name: name, subtitle: "", description: description, descriptionType: .onDefault,
                                   localizeName: "", id: id, type: .unknown, isCrossTenant: false, isCrypto: false, isThread: false,
                                   doNotDisturbEndTime: 0, hasInvitePermission: true, userTypeObservable: nil,
                                   enableThreadMiniIcon: false, isOfficialOncall: false, isShardFolder: isShardFolder)
            return .docFolderIn([item])
        case .wikisInWikiSpace(let meta):
            //推荐筛选器都只会有一个结果，不会有多选
            guard let entity = filterEntity,
                  case .wikiSpace = entity.type,
                  let id = meta.spaceIds.first
            else {
                if shouldIncludeValue {
                    Self.logger.info("search commonlyUsed filter wikisInWikiSpace meta illegal")
                    return nil
                } else {
                    return .docWorkspaceIn([])
                }
            }
            let name = entity.title
            let item = ForwardItem(avatarKey: "", name: name, subtitle: "", description: "", descriptionType: .onDefault,
                                   localizeName: "", id: id, type: .unknown, isCrossTenant: false, isCrypto: false, isThread: false,
                                   doNotDisturbEndTime: 0, hasInvitePermission: true, userTypeObservable: nil,
                                   enableThreadMiniIcon: false, isOfficialOncall: false)
            return .docWorkspaceIn([item])
        case .docsObjectType(let meta):
            let objectTypes = meta.objectTypes.compactMap { (type) -> DocFormatType? in
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
            if objectTypes.contains(.all) {
                if shouldIncludeValue {
                    Self.logger.info("search commonlyUsed filter docsObjectType meta illegal")
                    return nil
                } else {
                    return .docFormat([], .main)
                }
            }
            return .docFormat(objectTypes, .main)
        case .docsMatchType(let meta):
            switch meta.matchType {
            case .onlyComment: return .docContentType(.onlyComment)
            case .onlyTitle: return .docContentType(.onlyTitle)
            @unknown default:
                if shouldIncludeValue {
                    Self.logger.info("search commonlyUsed filter docsMatchType is illegal")
                    return nil
                } else {
                    return .docContentType(.fullContent)
                }
            }
        case .docsOpenTimeRange(let meta):
            let date = Self.convertToFilterDate(startTime: meta.customizedStartTime,
                                           endTime: meta.customizedEndTime)
            let resultFilter = SearchFilter.date(date: date, source: .doc)
            return resultFilter.isEmpty && shouldIncludeValue ? nil : resultFilter
        case .docsContainerType(let meta):
            guard SearchFeatureGatingKey.docWikiFilter.isEnabled else { return nil }
            switch meta.containerType {
            case .docs: return .docType(.doc)
            case .wiki: return .docType(.wiki)
            default:
                if shouldIncludeValue {
                    Self.logger.info("search commonlyUsed filter docsContainerType is illegal")
                    return nil
                } else {
                    return .docType(.all)
                }
            }
        case .docsFromUser:
            guard SearchFeatureGatingKey.mainFilter.isEnabled else { return nil }
            let pickers = transformChatterPickerItem(filterEntity: filterEntity)
            if pickers.isEmpty && shouldIncludeValue {
                return nil
            }
            return .docFrom(fromIds: pickers,
                            recommends: [],
                            fromType: .user,
                            isRecommendResultSelected: false)
        case .docsSharer:
            guard SearchFeatureGatingKey.docFilterSharer.isEnabled else { return nil }
            let pickers = transformChatterPickerItem(filterEntity: filterEntity)
            if pickers.isEmpty && shouldIncludeValue {
                return nil
            }
            return .docSharer(pickers)
        default:
            Self.logger.info("search commonlyUsed filter not contain")
            return nil
        }
    }

    static func convertToFilterDate(startTime: Int64, endTime: Int64) -> SearchFilter.FilterDate {
        let startTime = startTime > 0 ? startTime : nil
        let startDate = startTime.flatMap { Date(timeIntervalSince1970: TimeInterval($0)) }
        let endDate = Date(timeIntervalSince1970: TimeInterval(endTime))
        return SearchFilter.FilterDate(startDate: startDate, endDate: endDate)
    }
}
