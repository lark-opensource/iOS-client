//
//  SearchSourceMaker.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/23.
//

import UIKit
import Foundation
import LarkRustClient
import LarkSDKInterface
import LarkSearchCore
import RustPB
import EEAtomic
import ServerPB
import RxSwift
import LarkContainer
import SuiteAppConfig

/// 大搜, 高级搜索, 群内搜索场景等搜索直接接管场景的source maker
final class SearchSourceMaker {
    struct OpenSearchInfo {
        let commandId: String
        let extras: [String]
        let bizKey: ServerPB_Usearch_SearchTab.BizKey?
        let resultType: ServerPB_Usearch_SearchTab.ResultType?
    }
    let searchSession: SearchSession
    let sourceKey: String?
    let shouldRequestBasedOnResult: Bool
    let recommendFilterTypes: [FilterInTab]
    let openSearchInfo: OpenSearchInfo?

    let inChatID: String? // 群内搜索对应的ID
    let userResolver: LarkContainer.UserResolver

    //搜索的view的宽度
    var searchViewWidthGetter: (() -> CGFloat)?

    init(searchSession: SearchSession,
         sourceKey: String? = nil,
         shouldRequestBasedOnResult: Bool = false,
         recommendFilterTypes: [FilterInTab] = [],
         openSearchInfo: OpenSearchInfo? = nil,
         inChatID: String? = nil,
         resolver: LarkContainer.UserResolver) {
        self.searchSession = searchSession
        self.sourceKey = sourceKey
        self.shouldRequestBasedOnResult = shouldRequestBasedOnResult
        self.recommendFilterTypes = recommendFilterTypes
        self.openSearchInfo = openSearchInfo
        self.inChatID = inChatID
        self.userResolver = resolver
    }

    // nolint: long_function
    func makeSearchSource(for sceneSection: SearchSceneSection, userResolver: UserResolver) -> SearchSource? {
        var types = [Search_V2_BaseEntity.EntityItem]()
        var highlightType: TitleLayoutBenchmark.TypeEnum?
        guard let client = try? userResolver.resolve(assert: RustService.self) else { return nil }
        func make(type: Search_V2_SearchEntityType, action: (inout Search_V2_BaseEntity.EntityItem) -> Void = { _ in }) -> Search_V2_BaseEntity.EntityItem {
            var item = Search_V2_BaseEntity.EntityItem()
            item.type = type
            action(&item)
            return item
        }
        func make(types: [Search_V2_SearchEntityType], except exceptedType: Search_V2_SearchEntityType? = nil) -> [Search_V2_BaseEntity.EntityItem] {
            var items = [Search_V2_BaseEntity.EntityItem]()
            for type in types {
                if let exceptedType = exceptedType, exceptedType == type { continue }
                if type == .groupChat {
                    /// 搜索群额外处理下，支持搜索解散群聊
                    var chatItem = make(type: type)
                    chatItem.entityFilter.groupChatFilter.needFrozenChat = true
                    items.append(chatItem)
                } else {
                    items.append(make(type: type))
                }
            }
            return items
        }
        let scene = sceneSection.remoteRustScene
        var sceneString = scene.protobufName()
        switch sceneSection {
        case .searchServiceCard:
            sceneString = "SEARCH_CARDS"
            // QA Card
            var qaEntityItem = make(type: .qaCard)
            var qaEntitySelector = RustPB.Search_V2_BaseEntity.EntitySelector()
            qaEntitySelector.qaCardSelector = Search_V2_UniversalSelectors.QaCardSelector()
            qaEntitySelector.qaCardSelector.renderType = .jsonRaw
            qaEntityItem.entitySelector = qaEntitySelector
            types.append(qaEntityItem)
            // Customization
            var entityItem = make(type: .customization)
            var entitySelector = RustPB.Search_V2_BaseEntity.EntitySelector()
            entitySelector.customizationSelector = Search_V2_UniversalSelectors.CustomizationSelector()
            entitySelector.customizationSelector.renderType = .asCard
            entityItem.entitySelector = entitySelector
            types.append(entityItem)
        case .searchResourceInChat:
            sceneString = "IN_CHAT_PICTURES"
            var searchInChatItem = make(type: .resource)
            var entitySelector = RustPB.Search_V2_BaseEntity.EntitySelector()
            entitySelector.messageSelector = RustPB.Search_V2_UniversalSelectors.MessageSelector()
            entitySelector.messageSelector.accessAuth = SearchFeatureGatingKey.searchInChatPreviewPremission.isEnabled
            entitySelector.messageSelector.needColdHotMode = SearchFeatureGatingKey.searchOneYearData.isEnabled
            searchInChatItem.entitySelector = entitySelector
            types.append(searchInChatItem)
        case .spotlight:
            sceneString = "SPOTLIGHT"
            types.append(make(type: .user, action: { user in
                typealias UserType = Search_V2_UniversalFilters.UserFilter.SearchType
                user.entityFilter.userFilter.searchType = [Int32(UserType.resigned.rawValue | UserType.unTalked.rawValue)]
                user.entityFilter.userFilter.exclude = true
                var spotlightStrategy = Search_V2_BaseEntity.SpotlightStrategy()
                spotlightStrategy.enableSingleRank = true
                user.spotlightStrategy = spotlightStrategy
                user.mergePolicy = .localOnly
            }))
            types.append(make(type: .groupChat, action: { groupChat in
                var spotlightStrategy = Search_V2_BaseEntity.SpotlightStrategy()
                spotlightStrategy.enableSingleRank = true
                groupChat.spotlightStrategy = spotlightStrategy
                groupChat.mergePolicy = .localOnly
            }))
        case .spotlightChat:
            sceneString = "SPOTLIGHT_CHAT"
            types.append(make(type: .groupChat, action: { _chat in
                var spotlightStrategy = Search_V2_BaseEntity.SpotlightStrategy()
                spotlightStrategy.enableSingleRank = false
                _chat.spotlightStrategy = spotlightStrategy
                _chat.mergePolicy = .localOnly
            }))
            types.append(make(type: .user, action: { user in
                typealias UserType = Search_V2_UniversalFilters.UserFilter.SearchType
                user.entityFilter.userFilter.searchType = [Int32(UserType.resigned.rawValue | UserType.unTalked.rawValue)]
                user.entityFilter.userFilter.exclude = true
                var spotlightStrategy = Search_V2_BaseEntity.SpotlightStrategy()
                spotlightStrategy.enableSingleRank = false
                user.spotlightStrategy = spotlightStrategy
                user.mergePolicy = .localOnly
            }))
        case .spotlightChatter:
            sceneString = "SPOTLIGHT_CHATTER"
            types.append(make(type: .user, action: { _user in
                typealias UserType = Search_V2_UniversalFilters.UserFilter.SearchType
                _user.entityFilter.userFilter.searchType = [Int32(UserType.resigned.rawValue | UserType.unTalked.rawValue)]
                _user.entityFilter.userFilter.exclude = true
                var spotlightStrategy = Search_V2_BaseEntity.SpotlightStrategy()
                spotlightStrategy.enableSingleRank = false
                _user.spotlightStrategy = spotlightStrategy
                _user.mergePolicy = .localOnly
            }))
        case .spotlightApp:
            sceneString = "SPOTLIGHT"
            types.append(make(type: .facility, action: { facility in
                facility.mergePolicy = .localOnly
                var spotlightStrategy = Search_V2_BaseEntity.SpotlightStrategy()
                spotlightStrategy.enableSingleRank = false
                facility.spotlightStrategy = spotlightStrategy
            }))
        default:
            switch scene {
            case .searchChatters, .searchChattersInAdvanceScene:
                let user = make(type: .user, action: { user in
                    typealias UserType = Search_V2_UniversalFilters.UserFilter.SearchType
                    user.entityFilter.userFilter.searchType = [Int32(UserType.resigned.rawValue | UserType.unTalked.rawValue)]
                    user.entityFilter.userFilter.exclude = true
                })
                types.append(user)
                types.append(make(type: .cryptoP2PChat)) // 密聊
                if SearchFeatureGatingKey.myAiMainSwitch.isEnabled {
                    types.append(make(type: .myAi)) // My AI
                }
                if SearchFeatureGatingKey.isSupportShieldChat.isEnabled {
                    types.append(make(type: .shieldP2PChat)) // 密盾单聊
                }
            case .searchChats, .searchChatsInAdvanceScene:
                highlightType = .mainSearch
                var chat = make(type: .groupChat)
                chat.entityFilter.groupChatFilter.searchShield = SearchFeatureGatingKey.isSupportShieldChat.isEnabled
                chat.entityFilter.groupChatFilter.needFrozenChat = true
                assert(sceneSection.chatFilterModes?.first == nil, "现在不支持chat单搜thread，FG都关掉了")
                types.append(chat)
            case .searchThreadScene:
                highlightType = .mainSearch
                types.append(make(type: .thread))
            case .searchMessages:
                if inChatID != nil {
                    highlightType = .chat
                } else {
                    highlightType = .mainSearch
                }
                types.append(make(type: .message) { item in
                    item.entitySelector.messageSelector.needColdHotMode = SearchFeatureGatingKey.searchOneYearData.isEnabled
                })
            case .searchFileScene:
                highlightType = .mainSearch
                if inChatID != nil, SearchFeatureGatingKey.enableSearchSubFile.isEnabled {
                    /// FG范围内的会话内搜索使用新实体
                    var fileItem = make(type: .messageFile)
                    fileItem.entitySelector.messageFileSelector.needColdHotMode = SearchFeatureGatingKey.searchOneYearData.isEnabled
                    fileItem.entitySelector.messageFileSelector.accessAuth = SearchFeatureGatingKey.searchInChatPreviewPremission.isEnabled
                    types.append(fileItem)
                } else {
                    var message = make(type: .message)
                    message.entityFilter.messageFilter.messageTypes = [.file]
                    if inChatID != nil {
                        message.entityFilter.messageFilter.messageTypes.append(.folder)
                    }
                    var entitySelector = RustPB.Search_V2_BaseEntity.EntitySelector()
                    entitySelector.messageSelector = RustPB.Search_V2_UniversalSelectors.MessageSelector()
                    entitySelector.messageSelector.accessAuth = SearchFeatureGatingKey.searchInChatPreviewPremission.isEnabled
                    entitySelector.messageSelector.needColdHotMode = SearchFeatureGatingKey.searchOneYearData.isEnabled
                    message.entitySelector = entitySelector
                    types.append(message)
                }
            case .searchLinkScene:
                highlightType = .mainSearch
                var linkSearch = make(type: .url)
                var entitySelector = RustPB.Search_V2_BaseEntity.EntitySelector()
                entitySelector.messageSelector = RustPB.Search_V2_UniversalSelectors.MessageSelector()
                entitySelector.urlSelector = RustPB.Search_V2_UniversalSelectors.URLSelector()
                entitySelector.urlSelector.needColdHotMode = SearchFeatureGatingKey.searchOneYearData.isEnabled
                linkSearch.entitySelector = entitySelector
                types.append(linkSearch)
            case .searchOncallScene:
                highlightType = .mainSearch
                types.append(make(type: .oncall))
            case .searchDoc:
                highlightType = .mainSearch
                types.append(make(type: .doc))
                types.append(make(type: .wiki))
            case .searchDocsInChatScene:
                highlightType = .docInchat
                types.append(make(type: .doc))
            case .searchDocsWikiInChatScene:
                highlightType = .docInchat
                types.append(make(type: .doc))
                types.append(make(type: .wiki))
            case .searchWikiScene:
                highlightType = .mainSearch
                types.append(make(type: .wiki))
            case .searchOpenAppScene:
                highlightType = .mainSearch
                types.append(make(type: .app))
                types.append(make(type: .bot))
            case .searchOpenSearchScene:
                highlightType = .mainSearch
                var openSearch = make(type: .slashCommand)
                if let bizKey = openSearchInfo?.bizKey, bizKey == .email, let enableConversation = (try? userResolver.resolve(assert: SearchDependency.self))?.isConversationModeEnable() {
                    highlightType = .emailOpenSearch
                    openSearch.extras = ["IsConversationModeEnable": enableConversation.stringValue]
                }
                if let commandId = openSearchInfo?.commandId, let extras = openSearchInfo?.extras {
                    openSearch.entityFilter.slashCommandFilter.commandID = commandId
                    openSearch.entityFilter.slashCommandFilter.extras = extras
                }
                //enableSlashCommandFilter 恒为false
                openSearch.entityFilter.slashCommandFilter.enableSlashCommandFilter = false
                types.append(openSearch)
                var customization = make(type: .customization)
                var entitySelector = RustPB.Search_V2_BaseEntity.EntitySelector()
                entitySelector.customizationSelector = Search_V2_UniversalSelectors.CustomizationSelector()
                entitySelector.customizationSelector.renderType = .asCard
                customization.entitySelector = entitySelector
                types.append(customization)
            case .smartSearch:
                highlightType = .mainSearch
                types.append(make(type: .user, action: { user in
                    typealias UserType = Search_V2_UniversalFilters.UserFilter.SearchType
                    user.entityFilter.userFilter.searchType = [Int32(UserType.resigned.rawValue | UserType.unTalked.rawValue)]
                    user.entityFilter.userFilter.exclude = true
                }))
                if AppConfigManager.shared.leanModeIsOn {
                    types.append(contentsOf: make(types: [.groupChat, .section]))
                } else {
                    types.append(contentsOf: make(types: Search_V2_SearchEntityType.smartSearchCases, except: .user))
                    // QA Card
                    var qaEntityItem = make(type: .qaCard)
                    var qaEntitySelector = RustPB.Search_V2_BaseEntity.EntitySelector()
                    qaEntitySelector.qaCardSelector = Search_V2_UniversalSelectors.QaCardSelector()
                    qaEntitySelector.qaCardSelector.renderType = .jsonRaw
                    qaEntityItem.entitySelector = qaEntitySelector
                    types.append(qaEntityItem)
                    // Customization
                    var entityItem = make(type: .customization)
                    var entitySelector = RustPB.Search_V2_BaseEntity.EntitySelector()
                    entitySelector.customizationSelector = Search_V2_UniversalSelectors.CustomizationSelector()
                    entitySelector.customizationSelector.renderType = .asCard
                    entityItem.entitySelector = entitySelector
                    types.append(entityItem)
                }
            @unknown default:
                assertionFailure("unimplemented code!!")
                return nil
            }
        }
        assert(!types.isEmpty)

        let v2SearchSource = RustSearchSourceV2(client: client,
                                                scene: sceneString,
                                                session: self.searchSession,
                                                types: types,
                                                sourceKey: sourceKey,
                                                searchActionTabName: sceneSection.searchActionTabName,
                                                resolver: self.userResolver) { [weak self, inChatID] header in
            guard let self = self else { return }
            header.searchContext.commonFilter.includeOuterTenant = true
            if let type = highlightType, let searchViewWidth = self.searchViewWidthGetter?() {
                switch type {
                case .docInchat:
                    header.titleLayout.width = Int32(TitleLayoutBenchmark().titleCountForDocInChat(searchViewWidth: searchViewWidth))
                    header.summaryLayout.width = Int32(TitleLayoutBenchmark().subtitleCountForDocInChat(searchViewWidth: searchViewWidth))
                case .chat:
                    header.titleLayout.width = Int32(TitleLayoutBenchmark().titleCountForChat(searchViewWidth: searchViewWidth))
                    header.summaryLayout.width = Int32(TitleLayoutBenchmark().subtitleCountForChat(searchViewWidth: searchViewWidth))
                case .mainSearch:
                    header.titleLayout.width = Int32(TitleLayoutBenchmark().titleCountForMessage(searchViewWidth: searchViewWidth))
                    header.summaryLayout.width = Int32(TitleLayoutBenchmark().subtitleCountForMessage(searchViewWidth: searchViewWidth))
                case .emailOpenSearch:
                    header.titleLayout.width = Int32(TitleLayoutBenchmark().titleCountForEmailOpenSearch(searchViewWidth: searchViewWidth))
                    header.summaryLayout.width = Int32(TitleLayoutBenchmark().subtitleCountForEmailOpenSearch(searchViewWidth: searchViewWidth))
                }
            }
            if let inChatID = inChatID { header.searchContext.commonFilter.chatID = inChatID }
            var suggestionItems = [Search_V2_BaseEntity.SuggestionItem]()
            if sceneSection == .searchServiceCard {
                var suggestItem = Search_V2_BaseEntity.SuggestionItem()
                var suggestionSelector = Search_V2_BaseEntity.SuggestionSelector()
                var serviceCardSelector = Search_V2_UniversalSelectors.ServiceCardSelector()
                serviceCardSelector.renderType = .jsonRaw
                suggestionSelector.serviceCardSelector = serviceCardSelector
                suggestItem.type = .serviceCard
                suggestItem.selector = suggestionSelector
                suggestionItems.append(suggestItem)
            }
            self.recommendFilterTypes.forEach { filterInTab in
                var suggestItem = Search_V2_BaseEntity.SuggestionItem()
                suggestItem.type = .recommendedFilter
                var suggestionSelector = Search_V2_BaseEntity.SuggestionSelector()
                var recommendFilterSelector = Search_V2_UniversalSelectors.RecommendFilterSelector()
                var recommendFilterInfos: [Search_V2_UniversalSelectors.RecommendFilterSelector.FilterInfos] = []
                var fromQueryFilterInfo = Search_V2_UniversalSelectors.RecommendFilterSelector.FilterInfos()
                if SearchFeatureGatingKey.resultBasedFilterRecommend.isEnabled, self.shouldRequestBasedOnResult {
                    var fromResultFilterInfo = Search_V2_UniversalSelectors.RecommendFilterSelector.FilterInfos()
                    fromResultFilterInfo.filterInTab = filterInTab
                    fromResultFilterInfo.recommendFilterStrategy = .basedOnSearchResults
                    recommendFilterInfos.append(fromResultFilterInfo)
                }
                fromQueryFilterInfo.filterInTab = filterInTab
                fromQueryFilterInfo.recommendFilterStrategy = .basedOnQuery
                recommendFilterInfos.append(fromQueryFilterInfo)
                recommendFilterSelector.recommendFilterInfos = recommendFilterInfos
                suggestionSelector.recommendFilterSelector = recommendFilterSelector
                suggestItem.selector = suggestionSelector
                suggestionItems.append(suggestItem)
            }
            header.searchContext.suggestionItems = suggestionItems
        }

        return v2SearchSource
    }
    // enable-lint: long_function
}

extension SearchSourceMaker.OpenSearchInfo {
    init(openSearchInfo: SearchTab.OpenSearch) {
        self.commandId = openSearchInfo.id
        self.extras = []
        self.bizKey = openSearchInfo.bizKey
        self.resultType = openSearchInfo.resultType
    }
}
