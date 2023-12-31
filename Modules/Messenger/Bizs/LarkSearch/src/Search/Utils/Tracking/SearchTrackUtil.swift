//
//  SearchTrackUtil.swift
//  LarkSearch
//
//  Created by ChalrieSu on 2018/8/10.
//

import UIKit
import ServerPB
import LarkModel
import LKCommonsTracker
import Homeric
import RxSwift
import LarkSearchCore
import LarkSDKInterface
import LarkAppConfig
import LarkSearchFilter
import RustPB
import Foundation
import LKCommonsLogging
import LarkContainer

extension SearchTrackUtil {
    enum ChatHistoryClickAction: String {
        case viewInChat = "view_in_chat"
        case openDocs = "open_docs"
        case openWiki = "open_wiki"
        case saveToDrive = "save_to_drive"
        case filePreview = "file_preview"
        case openFile = "open_file"
        case downloadFile = "download_file"
        case openImage = "open_image"
        case openURL = "open_links"
    }

    static func trackClickChatHistoryResults(
        type: SearchInChatType,
        isThread: Bool = false,
        isSearchResult: Bool,
        action: ChatHistoryClickAction,
        additionInfo: [String: Any] = [:]) {
        let category: String
        switch type {
        case .message:
            category = "message"
        case .file:
            category = "files"
        case .doc, .docWiki:
            category = "docs"
        case .image, .video:
            category = "image"
        case .url:
            category = "links"
        case .wiki:
            category = "wiki"
        }

        let param: [String: Any] = ["category": category,
                                    "chat_type": isThread ? "group_topic" : "chat",
                                    "is_search": isSearchResult ? "y" : "n",
                                    "action": action.rawValue].lf_update(additionInfo)
        track(Homeric.CLICK_CHAT_HISTORY_RESULTS, params: param)
    }

    public static func entity_id(result: SearchResult) -> String {
        /// 暂定所有id全部加密。业务id也可能被对应的API调用爬库获取到更多的信息..
        return encrypt(id: result.id)
    }

    // MARK: helper methods

    private static func currentTimestamp() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }

    // MARK: - 事件名：asl_search_time_dev 上报时机：搜索端到端耗时

    static func trackSearchTime(
        searchLocation: String,
        searchId: String,
        query: String,
        sceneType: String,
        imprID: String,
        searchTime: Int64,
        isSpotlight: Bool) {
            var trackInfo = [String: Any]()
            trackInfo["search_location"] = searchLocation
            trackInfo["query_length"] = query.count
            trackInfo["query_pattern"] = query.lf.dataMasking
            trackInfo["impr_id"] = imprID
            trackInfo["scene_type"] = sceneType
            trackInfo["search_id"] = searchId
            trackInfo["time"] = searchTime
            if isSpotlight {
                trackInfo["tag"] = "spotlight"
            }
            track(Homeric.ASL_SEARCH_TIME_DEV, params: trackInfo)
        }

    // MARK: - 事件名：asl_search_view 上报时机：打开搜索框

    static func trackSearchView(
        session: SearchSession,
        searchLocation: String,
        sceneType: String,
        chatId: String? = nil,
        chatType: Chat.TypeEnum? = nil,
        isThreadGroup: Bool? = nil,
        shouldReportSearchBar: Bool = true,
        applinkSource: String = "",
        entryAction: String? = nil,
        isCache: Bool? = nil
    ) {
        var trackInfo = [String: Any]()
        trackInfo["entry_action"] = "none"
        if shouldReportSearchBar {
            trackInfo["search_bar"] = session.sourceOfSearch?.trackRepresentation ?? "none"
        }
        trackInfo["search_location"] = searchLocation
        trackInfo["scene_type"] = sceneType
        trackInfo["search_session_id"] = session.session
        trackInfo["request_timestamp"] = currentTimestamp()
        if let chatId = chatId {
            trackInfo["chat_id"] = chatId
        }
        if let chatType = chatType {
            if isThreadGroup == true {
                trackInfo["chat_type"] = "topicGroup"
            } else {
                trackInfo["chat_type"] = chatType.trackRepresentation
            }
        }
        if !applinkSource.isEmpty {
            trackInfo["app_link_source"] = applinkSource
            trackInfo["is_applink"] = true
        }
        if let entryAction = entryAction {
            trackInfo["entry_action"] = entryAction
        }
        if let isCache = isCache {
            trackInfo["is_cache"] = isCache
        }
        track(Homeric.ASL_SEARCH_VIEW, params: trackInfo)
    }

    // MARK: - 事件名：asl_search_click （操作时）

    enum FilterStatus {
        case none
        case some(String)
    }

    // 上报时机：用户角度输入
    static func trackSearchReqeustClick(
        searchLocation: String,
        query: String,
        sceneType: String,
        sessionId: String,
        filterStatus: FilterStatus,
        selectedRecFilter: String?,
        sortBy: String? = nil,
        imprID: String,
        slashID: String?,
        chatId: String? = nil,
        chatType: Chat.TypeEnum? = nil,
        isThreadGroup: Bool? = nil,
        isCache: Bool? = nil
    ) {
        var trackInfo = [String: Any]()
        trackInfo["click"] = "search_request"
        trackInfo["target"] = "none"
        trackInfo["search_location"] = searchLocation
        trackInfo["query_length"] = query.count
        trackInfo["query_id"] = encrypt(id: query)
        if let sortBy = sortBy {
            trackInfo["sort_by"] = sortBy
        }
        switch filterStatus {
        case .none:
            trackInfo["is_filter"] = "False"
        case .some(let param):
            trackInfo["is_filter"] = "True"
            trackInfo["filter_status"] = param
        }
        if let selectedRecFilter = selectedRecFilter {
            trackInfo["selected_rec_filter"] = selectedRecFilter
        }
        trackInfo["impr_id"] = imprID
        trackInfo["scene_type"] = sceneType
        trackInfo["search_session_id"] = sessionId
        trackInfo["request_timestamp"] = currentTimestamp()
        if let slashID = slashID {
            trackInfo["slash_id"] = slashID
        }
        if let chatId = chatId {
            trackInfo["chat_id"] = chatId
        }
        if let chatType = chatType {
            if isThreadGroup == true {
                trackInfo["chat_type"] = "topicGroup"
            } else {
                trackInfo["chat_type"] = chatType.trackRepresentation
            }
        }
        if let isCache = isCache {
            trackInfo["is_cache"] = isCache
        }
        track(Homeric.ASL_SEARCH_CLICK, params: trackInfo)
    }

    enum SearchHistoryClickType {
        case history(String)
        case delete
    }

    // 上报时机：点击快捷搜索按钮
    static func trackQuickSearchClick(
        sessionId: String?,
        imprId: String?,
        searchLocation: String,
        clickType: SearchHistoryClickType,
        sceneType: String,
        isCache: Bool? = nil
    ) {
        var trackInfo = [String: Any]()
        trackInfo["click"] = "quick_search"
        trackInfo["target"] = "none"
        trackInfo["entry_action"] = "none"
        trackInfo["search_location"] = searchLocation
        switch clickType {
        case .history(let query):
            trackInfo["query_length"] = query.count
            trackInfo["query_id"] = encrypt(id: query)
            trackInfo["search_type"] = "search_history"
        case .delete:
            trackInfo["query_length"] = 0
            trackInfo["query_id"] = encrypt(id: "")
            trackInfo["search_type"] = "search_history_delete"
        }
        trackInfo["is_filter"] = "False"

        if let sessionId = sessionId {
            trackInfo["search_session_id"] = sessionId
        }
        if let imprId = imprId {
            trackInfo["impr_id"] = imprId
        }

        trackInfo["scene_type"] = sceneType
        trackInfo["request_timestamp"] = currentTimestamp()
        if let isCache = isCache {
            trackInfo["is_cache"] = isCache
        }
        track(Homeric.ASL_SEARCH_CLICK, params: trackInfo)
    }

    // 综搜切换tab
    static func trackTabClick(
        searchLocation: String,
        tabName: String,
        query: String,
        sceneType: String,
        tabTrackInfo: TrackInfoRepresentable?,
        slashIds: [String],
        chatId: String? = nil,
        chatType: Chat.TypeEnum? = nil,
        isThreadGroup: Bool? = nil
    ) {
        var trackInfo = [String: Any]()
        trackInfo["click"] = "tab"
        trackInfo["target"] = "none"
        trackInfo["search_location"] = searchLocation
        trackInfo["tab_name"] = tabName
        trackInfo["query_length"] = query.count
        trackInfo["query_id"] = encrypt(id: query)
        if let info = tabTrackInfo {
            trackInfo["impr_id"] = info.lastestSearchCapture.imprID
            trackInfo["search_session_id"] = info.lastestSearchCapture.session
            if info.currentFilters.withNoFilter {
                trackInfo["is_filter"] = "False"
            } else {
                trackInfo["is_filter"] = "True"
                trackInfo["filter_status"] = info.currentFilters.convertToFilterStatusParam()
            }
        }
        if !slashIds.isEmpty {
            trackInfo["slash_id"] = slashIds.joined(separator: ",")
        }
        if let chatId = chatId {
            trackInfo["chat_id"] = chatId
        }
        if let chatType = chatType {
            if isThreadGroup == true {
                trackInfo["chat_type"] = "topicGroup"
            } else {
                trackInfo["chat_type"] = chatType.trackRepresentation
            }
        }
        trackInfo["scene_type"] = sceneType
        trackInfo["request_timestamp"] = currentTimestamp()
        track(Homeric.ASL_SEARCH_CLICK, params: trackInfo)
    }

    // 会话内搜索切换tab
    static func trackTabClick(
        searchLocation: String,
        tabName: String,
        sceneType: String,
        requestInfo: SearcherState.RequestInfo?,
        slashIds: [String],
        chatId: String? = nil,
        chatType: Chat.TypeEnum? = nil,
        isThreadGroup: Bool? = nil,
        isCache: Bool? = nil
    ) {
        var trackInfo = [String: Any]()
        trackInfo["click"] = "tab"
        trackInfo["target"] = "none"
        trackInfo["search_location"] = searchLocation
        trackInfo["tab_name"] = tabName
        if let requestInfo = requestInfo {
            trackInfo["query_length"] = requestInfo.input.query.count
            trackInfo["query_id"] = encrypt(id: requestInfo.input.query)
            trackInfo["impr_id"] = requestInfo.capturedSession.imprID
            trackInfo["search_session_id"] = requestInfo.capturedSession.session
            if requestInfo.input.filters.withNoFilter {
                trackInfo["is_filter"] = "False"
            } else {
                trackInfo["is_filter"] = "True"
                trackInfo["filter_status"] = requestInfo.input.filters.convertToFilterStatusParam()
            }
        }
        if !slashIds.isEmpty {
            trackInfo["slash_id"] = slashIds.joined(separator: ",")
        }
        if let chatId = chatId {
            trackInfo["chat_id"] = chatId
        }
        if let chatType = chatType {
            if isThreadGroup == true {
                trackInfo["chat_type"] = "topicGroup"
            } else {
                trackInfo["chat_type"] = chatType.trackRepresentation
            }
        }
        trackInfo["scene_type"] = sceneType
        trackInfo["request_timestamp"] = currentTimestamp()
        if let isCache = isCache {
            trackInfo["is_cache"] = isCache
        }
        track(Homeric.ASL_SEARCH_CLICK, params: trackInfo)
    }

    // 联系人tab下点击展开部门/折叠部门
    static func trackFullDivisionClick(query: String,
                                       actionType: String,
                                       imprID: String,
                                       isCache: Bool? = nil) {
        var trackInfo = [String: Any]()
        trackInfo["click"] = "function"
        trackInfo["action_type"] = actionType
        trackInfo["search_location"] = "contacts"
        trackInfo["query_length"] = query.count
        trackInfo["query_id"] = encrypt(id: query)
        trackInfo["impr_id"] = imprID
        if let isCache = isCache {
            trackInfo["is_cache"] = isCache
        }
        track(Homeric.ASL_SEARCH_CLICK, params: trackInfo)
    }
    // 高级搜索点击埋点
    static func trackAdvancedSearchClick(query: String,
                                         sessionID: String,
                                         imprID: String,
                                         sceneType: String,
                                         searchLocation: String,
                                         slashID: String?,
                                         isCache: Bool? = nil) {
        SearchTrackUtil.trackForSearchClick(click: "function",
                                            actionType: "more_filters",
                                            query: query,
                                            sessionID: sessionID,
                                            imprID: imprID,
                                            sceneType: sceneType,
                                            searchLocation: searchLocation,
                                            slashID: slashID,
                                            isCache: isCache)
    }

    // 意图胶囊综搜更多tab按钮点击
    static func trackCapsuleMoreTabClick(query: String,
                                         sessionID: String,
                                         imprID: String,
                                         sceneType: String,
                                         searchLocation: String,
                                         slashID: String?,
                                         isCache: Bool? = nil) {
        SearchTrackUtil.trackForSearchClick(click: "function",
                                            actionType: "more_tab",
                                            query: query,
                                            sessionID: sessionID,
                                            imprID: imprID,
                                            sceneType: sceneType,
                                            searchLocation: searchLocation,
                                            slashID: slashID,
                                            isCache: isCache)
    }

    static func trackForSearchClick(click: String,
                             actionType: String,
                             query: String,
                             sessionID: String,
                             imprID: String,
                             sceneType: String,
                             searchLocation: String,
                             slashID: String?,
                             isCache: Bool? = nil) {
        var trackInfo = [String: Any]()
        trackInfo["click"] = click
        trackInfo["action_type"] = actionType
        trackInfo["search_location"] = searchLocation
        trackInfo["query_length"] = query.count
        trackInfo["query_id"] = encrypt(id: query)
        trackInfo["impr_id"] = imprID
        trackInfo["search_session_id"] = sessionID
        trackInfo["scene_type"] = sceneType
        if let _slashID = slashID {
            trackInfo["slash_id"] = _slashID
        }
        if let isCache = isCache {
            trackInfo["is_cache"] = isCache
        }
        track(Homeric.ASL_SEARCH_CLICK, params: trackInfo)
    }

    // 意图胶囊点击
    // 仅在启用非激活态胶囊或调整已激活胶囊取值时生效
    // 激活态胶囊均pos 均报0
    // 非激活的，按照非激活位置排序，从1开始
    static func trackCapsuleClick(query: String,
                                  sessionId: String,
                                  imprID: String,
                                  sceneType: String,
                                  searchLocation: String,
                                  capsulePos: Int,
                                  capsuleStatus: [String: Any],
                                  slashID: String?,
                                  isCache: Bool? = nil) {
        var trackInfo = [String: Any]()
        trackInfo["click"] = "recommend_capsule"
        trackInfo["search_location"] = searchLocation
        trackInfo["query_length"] = query.count
        trackInfo["query_id"] = encrypt(id: query)
        trackInfo["impr_id"] = imprID
        trackInfo["search_session_id"] = sessionId
        trackInfo["scene_type"] = sceneType
        trackInfo["capsule_pos"] = capsulePos
        trackInfo["capsule_status"] = capsuleStatus
        if let _slashID = slashID {
            trackInfo["slash_id"] = _slashID
        }
        if let isCache = isCache {
            trackInfo["is_cache"] = isCache
        }
        track(Homeric.ASL_SEARCH_CLICK, params: trackInfo)
    }

    enum RecommendCardFoldStatus: String {
        case fold
        case unfold

        var trackingDescription: String { return rawValue }
    }
    static func trackRecommendClick(
        sessionId: String?,
        searchLocation: String,
        resultType: String,
        query: String,
        entityId: String?,
        tag: String,
        position: Int?,
        sceneType: String,
        imprId: String,
        isCache: Bool? = nil
    ) {
        var trackInfo = [String: Any]()
        trackInfo["click"] = "result_click"
        trackInfo["search_session_id"] = sessionId ?? ""
        trackInfo["search_location"] = searchLocation
        trackInfo["query_length"] = query.count
        trackInfo["query_id"] = encrypt(id: query)
        if let entityId = entityId {
            trackInfo["entity_id"] = encrypt(id: entityId)
        }
        trackInfo["result_type"] = resultType
        trackInfo["tag"] = tag
        if let pos = position {
            trackInfo["pos"] = pos
        }
        trackInfo["scene_type"] = sceneType
        trackInfo["impr_id"] = imprId
        trackInfo["result_click_action"] = "none"
        if let isCache = isCache {
            trackInfo["is_cache"] = isCache
        }
        track(Homeric.ASL_SEARCH_CLICK, params: trackInfo)
    }

    // 上报时机：点击更多分类中搜索中-加载更多
    static func trackOpenSearchLoadMoreClick(click: String, target: String, actionType: String, isCache: Bool? = nil) {
        var trackInfo = [String: Any]()
        var tags = [String]()
        trackInfo["click"] = click
        trackInfo["target"] = target
        trackInfo["action_type"] = actionType
        if let isCache = isCache {
            trackInfo["is_cache"] = isCache
        }
        track(Homeric.ASL_SEARCH_CLICK, params: trackInfo)
    }
    // 上报时机：点击搜索结果
    // swiftlint:disable:next function_parameter_count
    static func trackSearchResultClick(
        viewModel: SearchCellViewModel,
        sessionId: String,
        searchLocation: String,
        isSmartSearch: Bool = false,
        isSpotlight: Bool = false,
        isSpotlightOnly: Bool = false,
        isSuggested: Bool = false,
        query: String,
        sceneType: String,
        filterStatus: FilterStatus,
        selectedRecFilter: String?,
        sortBy: String? = nil,
        imprID: String,
        at indexPath: IndexPath,
        in tableView: UITableView,
        bid: String = "",
        entityType: String = "",
        moreButton jumpMoreSum: [Int] = [],
        extraParam: [String: Any]? = nil,
        isCache: Bool? = nil
    ) {
        _trackSearchResultClick(sessionId: sessionId,
                                searchLocation: searchLocation,
                                isSmartSearch: isSmartSearch,
                                isSpotlight: isSpotlight,
                                isSpotlightOnly: isSpotlightOnly,
                                isSuggested: isSuggested,
                                query: query,
                                sceneType: sceneType,
                                filterStatus: filterStatus,
                                selectedRecFilter: selectedRecFilter,
                                sortBy: sortBy,
                                imprID: imprID,
                                at: indexPath,
                                in: tableView,
                                moreButton: jumpMoreSum,
                                shouldShowTagWhenEmpty: true,
                                bid: bid,
                                entityType: entityType) { trackInfo, tags in
            if let meta = viewModel.searchResult.meta {
                switch meta {
                case .message(let messageMeta):
                    let isRootMessage = messageMeta.threadMessageType == .threadRootMessage
                    let isReplyMessage = messageMeta.threadMessageType == .threadReplyMessage
                    trackInfo["is_thread"] = isRootMessage || isReplyMessage
                default: break
                }
            }
            trackInfo["target"] = "none"
            switch viewModel {
            case _ as DocsSearchViewModel:
                trackInfo["target"] = "ccm_docs_page_view"
            case let viewModel as AppSearchViewModel:
                // 点击区分未安装应用
                if case let .openApp(appInfo) = viewModel.searchResult.meta {
                    trackInfo["target"] = appInfo.isAvailable ? "none" : "openplatform_ecosystem_application_detail_view"
                    if !appInfo.isAvailable {
                        tags.append("uninstalled_app")
                    }
                }
            case _ as URLSearchViewModel:
                tags.append("link")
            case _ as OncallSearchViewModel:
                tags.append("helpdesk")
            case _ as ServiceCardSearchViewModel:
                if let tag = extraParam?["tag"] as? String {
                    tags.append(tag)
                }
            case _ as QACardSearchViewModel:
                if let tag = extraParam?["tag"] as? String {
                    tags.append(tag)
                }
            case _ as StoreCardSearchViewModel:
                if let tag = extraParam?["tag"] as? String {
                    tags.append(tag)
                }
            case let viewModel as OpenSearchViewModel:
                tags.append("slash_command_section")
                if case .slash(let meta) = viewModel.searchResult.meta, let slashID = (meta as? RustPB.Search_V2_SlashCommandMeta)?.dataSourceID {
                    trackInfo["slash_id"] = slashID
                }
            case let viewModel as OpenSearchJumpViewModel:
                tags.append(viewModel.resultTagInfo)
                if let appLink = (viewModel.searchResult as? OpenJumpResult)?.appLink,
                   let appLinkEncoded = appLink.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: appLinkEncoded),
                   let commandId = url.queryParameters.first(where: { $0.key == "commandId" })?.value {
                    trackInfo["slash_id"] = commandId
                }
            default:
                trackInfo["target"] = "none"
            }
            if case let .customization(meta) = viewModel.searchResult.meta {
                trackInfo["slash_id"] = meta.dataSourceID
                trackInfo["session_id"] = sessionId
            }
            trackInfo["result_type"] = viewModel.resultTypeInfo
            trackInfo["entity_id"] = encrypt(id: viewModel.searchResult.id)
            extraParam?.forEach({ (key: String, value: Any) in
                trackInfo[key] = value
            })
            if let isCache = isCache {
                trackInfo["is_cache"] = isCache
            }
        }
    }

    // 上报时机：点击section右上角的查看更多
    static func trackSearchMoreResultClick(action: SearchSectionAction,
                                           sessionId: String,
                                           searchLocation: String,
                                           isSmartSearch: Bool = false,
                                           isSpotlight: Bool = false,
                                           isSpotlightOnly: Bool = false,
                                           isSuggested: Bool = false,
                                           query: String,
                                           sceneType: String,
                                           filterStatus: FilterStatus,
                                           imprID: String,
                                           at indexPath: IndexPath = IndexPath(),
                                           in tableView: UITableView,
                                           slashId: String? = nil,
                                           bid: String = "",
                                           entityType: String = "",
                                           moreButton jumpMoreSum: [Int] = [],
                                           extraParam: [String: Any]? = nil,
                                           isCache: Bool? = nil) {
        _trackSearchResultClick(sessionId: sessionId,
                                searchLocation: searchLocation,
                                isSmartSearch: isSmartSearch,
                                isSpotlight: isSpotlight,
                                isSpotlightOnly: isSpotlightOnly,
                                isSuggested: isSuggested,
                                query: query,
                                sceneType: sceneType,
                                filterStatus: filterStatus,
                                imprID: imprID,
                                at: indexPath,
                                in: tableView,
                                moreButton: jumpMoreSum,
                                shouldShowTagWhenEmpty: true,
                                bid: bid,
                                entityType: entityType) { trackInfo, tags in
            trackInfo["target"] = "none"
            switch action {
            case .group:
                tags.append("groups_section")
            case .message:
                tags.append("messages_section")
            case .thread:
                tags.append("thread_section")
            case .topic:
                tags.append("topic_section")
            case .app:
                tags.append("apps_section")
            case .contacts:
                tags.append("contacts_section")
            case .doc, .wiki:
                trackInfo["target"] = "ccm_docs_page_view"
                tags.append("docs_section")
            case .oncall:
                tags.append("helpdesk_section")
            case .openSearch, .slashCommand:
                tags.append("slash_command_section")
                trackInfo["slash_id"] = slashId
            default:
                trackInfo["target"] = "none"
            }
            trackInfo["result_type"] = "more_results"
            trackInfo["entity_id"] = ""
            extraParam?.forEach({ (key: String, value: Any) in
                trackInfo[key] = value
            })
            if let isCache = isCache {
                trackInfo["is_cache"] = isCache
            }
        }

    }
    // 上报时机：点击会话内搜索上报-不包含图片/视频
    // swiftlint:disable:next function_parameter_count
    static func trackSearchResultClick(
        viewModel: SearchInChatCellViewModel?,
        sessionId: String,
        searchLocation: String,
        isSmartSearch: Bool = false,
        isSpotlight: Bool = false,
        isSpotlightOnly: Bool = false,
        isSuggested: Bool = false,
        query: String,
        sceneType: String,
        filterStatus: FilterStatus,
        selectedRecFilter: String?,
        sortBy: String? = nil,
        imprID: String,
        at indexPath: IndexPath,
        in tableView: UITableView,
        moreButton: [Int] = [],
        chatId: String?,
        chatType: Chat.TypeEnum?,
        isThreadGroup: Bool?,
        bid: String = "",
        entityType: String = "",
        resultType: SearchInChatType?,
        isEnterConversation: Bool = false
    ) {
        _trackSearchResultClick(sessionId: sessionId,
                                searchLocation: searchLocation,
                                isSmartSearch: isSmartSearch,
                                isSpotlight: isSpotlight,
                                isSpotlightOnly: isSpotlightOnly,
                                isSuggested: isSuggested,
                                query: query,
                                sceneType: sceneType,
                                filterStatus: filterStatus,
                                selectedRecFilter: selectedRecFilter,
                                sortBy: sortBy,
                                imprID: imprID,
                                at: indexPath,
                                in: tableView,
                                moreButton: moreButton,
                                shouldShowTagWhenEmpty: false,
                                bid: bid,
                                entityType: entityType) { trackInfo, tags in
            if let viewModel = viewModel,
               let meta = viewModel.data?.meta {
                switch meta {
                case .message(let messageMeta):
                    let isRootMessage = messageMeta.threadMessageType == .threadRootMessage
                    let isReplyMessage = messageMeta.threadMessageType == .threadReplyMessage
                    trackInfo["is_thread"] = isRootMessage || isReplyMessage
                default: break
                }
            }

            trackInfo["target"] = "none"
            if let type = resultType {
                trackInfo["result_type"] = type.trackRepresentation
            }
            if isEnterConversation { tags.append("enter_conversation") }
            var docType: SearchMetaDocType?
            if let chatId = chatId {
                trackInfo["chat_id"] = chatId
            }
            if let chatType = chatType {
                if isThreadGroup == true {
                    trackInfo["chat_type"] = "topicGroup"
                } else {
                    trackInfo["chat_type"] = chatType.trackRepresentation
                }
            }
            guard let viewModel = viewModel, let data = viewModel.data else { return }
            trackInfo["entity_id"] = encrypt(id: data.id)
            switch data.meta {
            case .doc(let type):
                trackInfo["target"] = "ccm_docs_page_view"
                docType = type
            case .wiki(let type):
                trackInfo["target"] = "ccm_docs_page_view"
                docType = type.docMetaType
            default: trackInfo["target"] = "none"
            }
            if let docType = docType {
                if docType.wikiInfo.isEmpty {
                    switch docType.type {
                    case .bitable:
                        trackInfo["result_type"] = "bitable"
                    case .doc:
                        trackInfo["result_type"] = "doc"
                    case .file:
                        trackInfo["result_type"] = "file"
                    case .mindnote:
                        trackInfo["result_type"] = "mindnote"
                    case .sheet:
                        trackInfo["result_type"] = "sheet"
                    case .slide:
                        trackInfo["result_type"] = "slide"
                    case .slides:
                        trackInfo["result_type"] = "slides"
                    case .docx:
                        trackInfo["result_type"] = "docx"
                    case .wiki:
                        trackInfo["result_type"] = "wiki"
                    case .folder:
                        trackInfo["result_type"] = "folder"
                    case .catalog:
                        trackInfo["result_type"] = "catalog"
                    case .shortcut:
                        trackInfo["result_type"] = "shortcut"
                    case .unknown:
                        trackInfo["result_type"] = "docs_unknown"
                    @unknown default:
                        assert(false, "new value")
                        trackInfo["result_type"] = "none"
                    }
                } else {
                    trackInfo["result_type"] = "wiki"
                }
            }
        }
    }
    // 上报时机：点击会话内图片/视频搜索上报
    // swiftlint:disable:next function_parameter_count
    static func trackSearchResultClick(
        sessionId: String,
        searchLocation: String,
        isSmartSearch: Bool = false,
        isSuggested: Bool = false,
        query: String,
        sceneType: String,
        filterStatus: FilterStatus,
        sortBy: String? = nil,
        imprID: String,
        at pos: Int,
        moreButton: [Int] = [],
        chatId: String?,
        chatType: Chat.TypeEnum?,
        resultType: SearchInChatType?,
        messageID: String,
        isEnterConversation: Bool = false,
        shouldShowTagWhenEmpty: Bool = false,
        isThreadGroup: Bool? = nil
    ) {
        var trackInfo = [String: Any]()
        var tags = [String]()
        trackInfo["click"] = "result_click"
        trackInfo["target"] = "none"
        if let type = resultType {
            trackInfo["result_type"] = type.trackRepresentation
        }

        if isEnterConversation { tags.append("enter_conversation") }
        if let chatId = chatId {
            trackInfo["chat_id"] = chatId
        }
        if let chatType = chatType {
            if isThreadGroup == true {
                trackInfo["chat_type"] = "topicGroup"
            } else {
                trackInfo["chat_type"] = chatType.trackRepresentation
            }
        }
        if isSuggested { tags.append("suggest") }
        if isSmartSearch { tags.append("guess") }
        trackInfo["pos"] = pos
        trackInfo["search_location"] = searchLocation
        trackInfo["result_click_action"] = "none"
        trackInfo["query_length"] = query.count
        trackInfo["query_id"] = encrypt(id: query)
        if let sortBy = sortBy {
            trackInfo["sort_by"] = sortBy
        }
        switch filterStatus {
        case .none:
            trackInfo["is_filter"] = "False"
        case .some(let param):
            trackInfo["is_filter"] = "True"
            trackInfo["filter_status"] = param
        }

        trackInfo["impr_id"] = imprID
        trackInfo["scene_type"] = sceneType
        trackInfo["search_session_id"] = sessionId
        trackInfo["request_timestamp"] = currentTimestamp()
        trackInfo["entity_id"] = encrypt(id: messageID)

        if shouldShowTagWhenEmpty {
            trackInfo["tag"] = tags.joined(separator: ",")
        } else if !tags.isEmpty {
            trackInfo["tag"] = tags.joined(separator: ",")
        }
        track(Homeric.ASL_SEARCH_CLICK, params: trackInfo)
    }

    //点击搜索-取消按钮
    static func trackSearchCancelClick(
        click: String,
        actionType: String,
        isCache: Bool? = nil
    ) {
        var trackInfo = [String: Any]()
        trackInfo["click"] = "function"
        trackInfo["action_type"] = "cancel_search"
        if let isCache = isCache {
            trackInfo["is_cache"] = isCache
        }
        track(Homeric.ASL_SEARCH_CLICK, params: trackInfo)
    }

    // swiftlint:disable:next function_parameter_count
    private static func _trackSearchResultClick(
        sessionId: String,
        searchLocation: String,
        isSmartSearch: Bool,
        isSpotlight: Bool,
        isSpotlightOnly: Bool,
        isSuggested: Bool,
        query: String,
        sceneType: String,
        filterStatus: FilterStatus,
        selectedRecFilter: String? = nil,
        sortBy: String? = nil,
        imprID: String,
        at indexPath: IndexPath,
        in tableView: UITableView,
        moreButton jumpMoreSum: [Int] = [],
        shouldShowTagWhenEmpty: Bool,
        bid: String,
        entityType: String,
        action: (inout [String: Any], inout [String]) -> Void = { _, _ in }) {
        var trackInfo = [String: Any]()
        var tags = [String]()
        trackInfo["click"] = "result_click"

        if isSuggested { tags.append("suggest") }
        if isSmartSearch { tags.append("guess") }
        if isSpotlight { tags.append("spotlight") }
        if isSpotlightOnly { tags.append("onlyspotlight") }
        let moreButtonInHeader = !SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled
        trackInfo["pos"] = tableView.clickSearchResultURLPosition(at: indexPath, moreButton: jumpMoreSum, moreButtonInHeader: moreButtonInHeader)
        trackInfo["search_location"] = searchLocation
        trackInfo["result_click_action"] = "none"
        if let selectedRecFilter = selectedRecFilter {
            trackInfo["selected_rec_filter"] = selectedRecFilter
        }
        trackInfo["query_length"] = query.count
        trackInfo["query_id"] = encrypt(id: query)
        if let sortBy = sortBy {
            trackInfo["sort_by"] = sortBy
        }
        switch filterStatus {
        case .none:
            trackInfo["is_filter"] = "False"
        case .some(let param):
            trackInfo["is_filter"] = "True"
            trackInfo["filter_status"] = param
        }
        if !bid.isEmpty, !entityType.isEmpty {
            trackInfo["Bid"] = bid
            trackInfo["EntityType"] = entityType
        }

        trackInfo["impr_id"] = imprID
        trackInfo["scene_type"] = sceneType
        trackInfo["search_session_id"] = sessionId
        trackInfo["request_timestamp"] = currentTimestamp()
        trackInfo["section_pos"] = indexPath.section + 1
        action(&trackInfo, &tags)
        if shouldShowTagWhenEmpty {
            trackInfo["tag"] = tags.joined(separator: ",")
        } else if !tags.isEmpty {
            trackInfo["tag"] = tags.joined(separator: ",")
        }
        track(Homeric.ASL_SEARCH_CLICK, params: trackInfo)
    }

    // 上报时机：搜索页面查看profile
    // swiftlint:disable:next function_parameter_count
    static func trackSearchProfileClick(
        userId: String,
        searchLocation: String,
        query: String,
        resultType: String,
        sceneType: String,
        sessionId: String?,
        imprId: String,
        filterStatus: FilterStatus,
        bid: String,
        entityType: String,
        sortBy: String? = nil,
        isCache: Bool? = nil
    ) {
        var trackInfo = [String: Any]()
        trackInfo["click"] = "profile"
        trackInfo["target"] = "none"
        trackInfo["search_location"] = searchLocation
        trackInfo["entity_id"] = encrypt(id: userId)
        trackInfo["query_length"] = query.count
        trackInfo["query_id"] = encrypt(id: query)
        switch filterStatus {
        case .none:
            trackInfo["is_filter"] = "False"
        case .some(let param):
            trackInfo["is_filter"] = "True"
            trackInfo["filter_status"] = param
        }
        trackInfo["impr_id"] = imprId
        if let sessionId = sessionId {
            trackInfo["search_session_id"] = sessionId
        }
        if !bid.isEmpty, !entityType.isEmpty {
            trackInfo["Bid"] = bid
            trackInfo["EntityType"] = entityType
        }
        trackInfo["scene_type"] = sceneType
        trackInfo["result_type"] = resultType
        trackInfo["request_timestamp"] = currentTimestamp()
        if let isCache = isCache {
            trackInfo["is_cache"] = isCache
        }
        track(Homeric.ASL_SEARCH_CLICK, params: trackInfo)
    }

    // 上报时机：大搜 消息 链接附件卡片点击
    // swiftlint:disable:next function_parameter_count
    static func trackSearchMessageURLAttachmentClick(
        searchLocation: String,
        query: String,
        sceneType: String,
        sessionId: String?,
        imprId: String,
        filterStatus: FilterStatus,
        bid: String,
        entityType: String,
        clickType: String,
        resultType: String,
        subResultType: String,
        attachmentType: String,
        isCache: Bool? = nil
    ) {
        var trackInfo = [String: Any]()
        trackInfo["search_location"] = searchLocation
        trackInfo["query_length"] = query.count
        trackInfo["query_id"] = encrypt(id: query)
        switch filterStatus {
        case .none:
            trackInfo["is_filter"] = "False"
        case .some(let param):
            trackInfo["is_filter"] = "True"
            trackInfo["filter_status"] = param
        }
        trackInfo["impr_id"] = imprId
        if let sessionId = sessionId {
            trackInfo["search_session_id"] = sessionId
        }
        if !bid.isEmpty, !entityType.isEmpty {
            trackInfo["Bid"] = bid
            trackInfo["EntityType"] = entityType
        }
        trackInfo["scene_type"] = sceneType
        trackInfo["click"] = clickType
        trackInfo["result_type"] = resultType
        trackInfo["sub_result_type"] = subResultType
        trackInfo["tag"] = attachmentType
        trackInfo["request_timestamp"] = currentTimestamp()
        if let isCache = isCache {
            trackInfo["is_cache"] = isCache
        }
        track(Homeric.ASL_SEARCH_CLICK, params: trackInfo)
    }

    // MARK: - 事件名：asl_search_show
    // swiftlint:disable:next function_parameter_count
    static func trackSearchShow(
        searchLocation: String,
        query: String,
        sceneType: String,
        sessionId: String,
        filterStatus: FilterStatus,
        recFilter: String?,
        sortBy: String? = nil,
        isResult: Bool,
        offset: Int,
        items: [SearchResultShowTrackMananger.Item],
        shouldShowIdList: Bool = true,
        isRecommend: Bool,
        imprID: String,
        timestamp: Int64,
        chatId: String? = nil,
        chatType: Chat.TypeEnum? = nil,
        isThreadGroup: Bool? = nil,
        isHasThread: Bool,
        isCache: Bool? = nil
    ) {
        var trackInfo = [String: Any]()
        trackInfo["is_has_thread"] = isHasThread
        trackInfo["search_location"] = searchLocation
        trackInfo["query_length"] = query.count
        trackInfo["query_id"] = encrypt(id: query)
        trackInfo["offset"] = offset
        if shouldShowIdList {
            if items.isEmpty {
                trackInfo["is_result"] = "False"
                trackInfo["feature"] = ""
                trackInfo["id_list"] = [String: Any]()
            } else {
                let params = items.convertToTrackParam()
                trackInfo["is_result"] = "True"
                trackInfo["feature"] = params.1
                trackInfo["id_list"] = params.0
            }
        } else {
            trackInfo["is_result"] = items.isEmpty ? "False" : "True"
        }
        if let sortBy = sortBy {
            trackInfo["sort_by"] = sortBy
        }
        if let recFilter = recFilter {
            trackInfo["rec_filter"] = recFilter
        }
        switch filterStatus {
        case .none:
            trackInfo["is_filter"] = "False"
        case .some(let param):
            trackInfo["is_filter"] = "True"
            trackInfo["filter_status"] = param
        }
        if isRecommend {
            trackInfo["impr_id"] = ""
        } else {
            trackInfo["impr_id"] = imprID
        }

        trackInfo["scene_type"] = sceneType
        trackInfo["search_session_id"] = sessionId
        trackInfo["request_timestamp"] = timestamp
        if let chatId = chatId {
            trackInfo["chat_id"] = chatId
        }
        if let chatType = chatType {
            if isThreadGroup == true {
                trackInfo["chat_type"] = "topicGroup"
            } else {
                trackInfo["chat_type"] = chatType.trackRepresentation
            }
        }
        if let isCache = isCache {
            trackInfo["is_cache"] = isCache
        }
        track(Homeric.ASL_SEARCH_SHOW, params: trackInfo)
    }

    // 上报时机：常用筛选器展示
    static func trackSearchCommonlyUsedFilterShow(
        sessionId: String,
        searchLocation: String,
        filterStatus: String,
        imprID: String
    ) {
        var trackInfo = [String: Any]()
        trackInfo["filter_status"] = filterStatus
        trackInfo["impr_id"] = imprID
        trackInfo["search_session_id"] = sessionId
        trackInfo["search_location"] = searchLocation
        track(Homeric.ASL_SEARCH_FILTER_SUGGEST_VIEW, params: trackInfo)
    }
    // 上报时机：常用筛选器点击
    static func trackSearchCommonlyUsedFilterClick(
        sessionId: String,
        searchLocation: String,
        filterStatus: String,
        imprID: String
    ) {
        var trackInfo = [String: Any]()
        trackInfo["click"] = "adopt"
        trackInfo["target"] = "none"
        trackInfo["filter_status"] = filterStatus
        trackInfo["impr_id"] = imprID
        trackInfo["search_session_id"] = sessionId
        trackInfo["search_location"] = searchLocation
        track(Homeric.ASL_SEARCH_FILTER_SUGGEST_CLICK, params: trackInfo)
    }
}

extension Chat.TypeEnum {
    var trackRepresentation: String {
        switch self {
        case .group: return "group"
        case .p2P: return "p2p"
        case .topicGroup: return "topicGroup"
        @unknown default:
            assertionFailure("unknow chat type")
            return "none"
        }
    }
}

extension SearchTab {
    var trackRepresentation: String {
        switch self {
        case .main: return "quick_search"
        case .message: return "messages"
        case .doc: return "docs"
        case .wiki: return "wiki"
        case .app: return "apps"
        case .chatter: return "contacts"
        case .chat: return "groups"
        case .email: return "emails"
        case .calendar: return "calendar"
        case .open:
            if isOpenSearchEmail {
                return "emails"
            }
            return "slash"
        case .pano: return "pano"
        case .oncall: return "helpdesk"
        case .topic, .thread: return "none"
        }
    }
    var isOpenSearch: Bool {
        switch self {
        case .open: return true
        default:    return false
        }
    }
}

// search_view_profile打点管理类
// （由于有多处使用， 因此抽成一个manager）
final class SearchProfileTrackManager {
    // search_view_profile打点map： 可能有多组
    // key为userId， value是打点的参数
    var trackDic: [String: [String: Any]] = [:]

    struct searchViewProfileTrackInfoMeta {
        var sessionID: String
        var queryLength: Int
        var resultPosition: String
    }

    func configSearchViewProfileTrackInfo(vm: ChatterSearchViewModel,
                                          getTrackMeta: @escaping () -> searchViewProfileTrackInfoMeta?) {
        vm.clickPersonCardButton = { (row, userId) in
            var info: [String: Any] = [:]
            guard let meta = getTrackMeta() else { return }
            info["search_location"] = meta.resultPosition
            info["search_session_ID"] = meta.sessionID
            info["query_length"] = meta.queryLength
            info["result_position"] = row
            info["user_id"] = userId
            // 一次搜索中多次触发相同一个人的点击只上报一次
            if self.trackDic[userId] == nil {
                self.trackDic[userId] = info
            }
        }
    }

    func tryToTrack() {
        if !self.trackDic.isEmpty {
            self.trackDic.forEach({ (_, dic) in
                Tracker.post(TeaEvent(Homeric.SEARCH_VIEW_PROFILE, params: dic))
            })
            self.trackDic.removeAll()
        }
    }
}

/// 管理曝光埋点 https://bytedance.feishu.cn/docs/doccnss6wKK7UpbVVEL8rhE7c7g
final class OnScreenItemManager {
    enum Action {
        case refresh, scroll
    }
    struct Item {
        var content: [String: Any]
        init(viewModel: SearchCellViewModel, imprID: String?, section_name: String, at indexPath: IndexPath, in tableView: UITableView) {
            assert(Thread.isMainThread, "should occur on main thread!")

            content = Self.commonContent(viewModel: viewModel, at: indexPath, in: tableView)
            content["impr_id"] = imprID ?? ""
            content["section_name"] = section_name
        }
        init(viewModel: SearchCellViewModel, searchResponse: SearchCallBack, openSearchID: String? = nil, at indexPath: IndexPath, in tableView: UITableView) {
            assert(Thread.isMainThread, "should occur on main thread!")

            content = Self.commonContent(viewModel: viewModel, at: indexPath, in: tableView)
            content["scene_type"] = searchResponse.searchScene.remoteRustScene.rawValue
            content["impr_id"] = searchResponse.imprID ?? ""
            if let openSearchID = openSearchID { content["open_search_tab_id"] = openSearchID }
        }
        static private func commonContent(viewModel: SearchCellViewModel, at indexPath: IndexPath, in tableView: UITableView) -> [String: Any] {
            [
                "search_id": viewModel.searchResult.contextID ?? "",
                "entity_id": SearchTrackUtil.encrypt(id: viewModel.searchResult.id),
                "result_location": indexPath.row + 1,
                "position": tableView.absolutePosition(at: indexPath),
                "entity_type": viewModel.searchClickInfo
            ]
        }
    }
    /// 首次曝光的Item
    var refreshItems: [Item] = []
    /// 滚动曝光的Item
    var scrollItems: [Item] = []

    var sawItems: Set<String> = []

    private var sessionID: String
    let location: String
    private let bag = DisposeBag()
    init(session: SearchSession, location: String) {
        self.sessionID = session.session
        self.location = location

        session.newSessionPublisher.subscribe(onNext: { [weak self] (session) in
          if Thread.isMainThread {
              self?.renew(session: session)
          } else {
              DispatchQueue.main.async { self?.renew(session: session) }
          }
        }).disposed(by: bag)
    }

    /// 曝光item，会根据id去重
    func willDisplay(id: String, item: () -> Item, action: Action) {
        assert(Thread.isMainThread, "should occur on main thread!")
        if !sawItems.insert(id).inserted {
            return // already exposed
        }
        let item = item()
        switch action {
        case .refresh:
            refreshItems.append(item)
        case .scroll:
            scrollItems.append(item)
        }
    }

    /// 刷新session
    func renew(session: SearchSession) {
        assert(Thread.isMainThread, "should occur on main thread!")
        track()
        self.sessionID = session.session
    }

    /// 上报并清空数据，注意会重新排重曝光
    func flush() {
        assert(Thread.isMainThread, "should occur on main thread!")
        track()
    }

    private func track() {
        func track(items: [Item], action: Int) {
            if items.isEmpty { return }

            var params = [String: Any]()
            params["search_session_ID"] = self.sessionID
            params["search_location"] = self.location
            DispatchQueue.global(qos: .utility).async {
                params["action"] = action
                params["data"] = items.map { $0.content }
                SearchTrackUtil.track(Homeric.SEARCH_ON_SCREEN, params: params)
            }
        }
        track(items: refreshItems, action: 0)
        track(items: scrollItems, action: 1)

        // clear after upload
        refreshItems = []
        scrollItems = []
        sawItems = []
    }

    deinit {
        track()
    }
}

final class SearchResultShowTrackMananger {

    struct ExtraJudgement: Hashable {
        var isSmartSearch: Bool?
        var isSpotlight: Bool?
        var isSpotlightOnly: Bool?
    }

    struct Item: Hashable {
        let id: String
        let resultType: String
        var tags: [String]
        var slashId: String?
        var pos: Int?
    }

    var searchTimestamp: Int64 {
        get {
            if _searchTimestamp == INT64_MAX {
                return Int64(Date().timeIntervalSince1970 * 1000)
            }
            return _searchTimestamp
        }
        set {
            if newValue < _searchTimestamp {
                _searchTimestamp = newValue
            }
        }
    }

    var captured: SearchSession.Captured?

    var isRecommend = false

    private var _searchTimestamp: Int64 = INT64_MAX

    private var sawItems: Set<Item> = []

    private var onScreenItems = [Item]()

    func track(searchLocation: String,
               query: String,
               sceneType: String,
               session: SearchSession,
               filterStatus: SearchTrackUtil.FilterStatus,
               recFilter: String? = nil,
               sortBy: String? = nil,
               offset: Int,
               isResult: Bool = true,
               shouldShowIdList: Bool = true,
               imprID: String? = nil,
               timestamp: Int64? = nil,
               chatId: String? = nil,
               chatType: Chat.TypeEnum? = nil,
               isThreadGroup: Bool? = nil,
               isHasThread: Bool = false,
               isCache: Bool? = nil) {
        if isResult && onScreenItems.isEmpty {
            return
        }

        SearchTrackUtil.trackSearchShow(searchLocation: searchLocation,
                                        query: query,
                                        sceneType: sceneType,
                                        sessionId: session.session,
                                        filterStatus: filterStatus,
                                        recFilter: recFilter,
                                        sortBy: sortBy,
                                        isResult: isResult,
                                        offset: offset,
                                        items: onScreenItems,
                                        shouldShowIdList: shouldShowIdList,
                                        isRecommend: isRecommend,
                                        imprID: imprID ?? captured?.imprID ?? session.imprID(seqID: session.seqID),
                                        timestamp: timestamp ?? searchTimestamp,
                                        chatId: chatId,
                                        chatType: chatType,
                                        isThreadGroup: isThreadGroup,
                                        isHasThread: isHasThread,
                                        isCache: isCache)
        onScreenItems = []
        sawItems = []
    }

    func track(searchLocation: String,
               query: String,
               sceneType: String,
               captured: SearchSession.Captured,
               filterStatus: SearchTrackUtil.FilterStatus,
               recFilter: String? = nil,
               sortBy: String? = nil,
               offset: Int,
               isResult: Bool = true,
               shouldShowIdList: Bool = true,
               timestamp: Int64? = nil,
               chatId: String? = nil,
               chatType: Chat.TypeEnum? = nil,
               isThreadGroup: Bool? = nil,
               isHasThread: Bool = false,
               isCache: Bool? = nil) {
        if isResult && onScreenItems.isEmpty {
            return
        }
        SearchTrackUtil.trackSearchShow(searchLocation: searchLocation,
                                        query: query,
                                        sceneType: sceneType,
                                        sessionId: captured.session,
                                        filterStatus: filterStatus,
                                        recFilter: recFilter,
                                        sortBy: sortBy,
                                        isResult: isResult,
                                        offset: offset,
                                        items: onScreenItems,
                                        shouldShowIdList: shouldShowIdList,
                                        isRecommend: isRecommend,
                                        imprID: captured.imprID,
                                        timestamp: timestamp ?? searchTimestamp,
                                        chatId: chatId,
                                        chatType: chatType,
                                        isThreadGroup: isThreadGroup,
                                        isHasThread: isHasThread,
                                        isCache: isCache)
        onScreenItems = []
        sawItems = []
    }

    func reset() {
        onScreenItems = []
        sawItems = []
    }

    /// 曝光item，会根据id去重
    func willDisplay(result: SearchResultType,
                     searchScene: SearchSceneSection? = nil,
                     at indexPath: IndexPath? = nil,
                     in tableView: UITableView? = nil,
                     extraJudgement: SearchResultShowTrackMananger.ExtraJudgement? = nil) {
        assert(Thread.isMainThread, "should occur on main thread!")
        var item = SearchResultShowTrackMananger.Item(result: result,
                                                      pos: tableView?.absolutePosition(at: indexPath ?? IndexPath(row: -1, section: 0)),
                                                      extraJudgement: extraJudgement)

        if !sawItems.insert(item).inserted {
            return // already exposed
        }
        if onScreenItems.count >= 60 {
            return // 上报限制为 60 条
        }
        onScreenItems.append(item)
    }

    func willDisplay(result: UniversalRecommendResult, tags: [String]) {
        assert(Thread.isMainThread, "should occur on main thread!")
        let item = SearchResultShowTrackMananger.Item(recommendResult: result, tags: tags)
        if !sawItems.insert(item).inserted {
            return // already exposed
        }
        if onScreenItems.count >= 60 {
            return // 上报限制为 60 条
        }
        onScreenItems.append(item)
    }

}

final class SearchTimeTrackManager {

    var startTime: CFTimeInterval?

    func track(endTime: CFTimeInterval,
               searchLocation: String,
               query: String,
               sceneType: String,
               imprID: String,
               searchId: String,
               isSpotlight: Bool) {
        guard let startTime = startTime else { return }
        SearchTrackUtil.trackSearchTime(searchLocation: searchLocation,
                                        searchId: searchId,
                                        query: query,
                                        sceneType: sceneType,
                                        imprID: imprID,
                                        searchTime: Int64((endTime - startTime) * 1000),
                                        isSpotlight: isSpotlight)
    }
    func trackForDuration(domain: String,
                          endTime: CFTimeInterval,
                          isSpotlight: Bool,
                          isLoadMore: Bool,
                          errorCode: SearchError?,
                          tabType: Any,
                          isInChat: Bool
    ) {
        guard SearchTrackUtil.enablePostTrack() else { return }
        guard let startTime = startTime else { return }
        var categoryParams: [String: Any] = [
            "is_spotlight": isSpotlight,
            "is_load_more": isLoadMore
        ]
        if let errorCode = errorCode, errorCode.rawValue != 0 {
            categoryParams["lark_error_code"] = errorCode.rawValue.description
        }
        if isInChat, let searchInChatType = tabType as? SearchInChatType {
            categoryParams["tab_name"] = searchInChatType.trackRepresentation
        } else if !isInChat, let searchType = tabType as? SearchTab {
            categoryParams["tab_name"] = searchType.trackRepresentation
            if case.open(let info) = searchType {
                categoryParams["search_app_id"] = info.id
            }
        }
        SearchTrackUtil.trackForStableWatcher(domain: domain,
                                              message: "asl_search_time",
                                              metricParams: ["duration": ceil((endTime - startTime) * 1000)],
                                              categoryParams: categoryParams)
    }
}

extension Array where Element == SearchResultShowTrackMananger.Item {

    func convertToTrackParam() -> ([[String: Any]], String) {
        var idList = [[String: Any]]()
        var features = Set<String>()
        for item in self {
            var param = [String: Any]()
            param["result_type"] = item.resultType
            param["entity_id"] = SearchTrackUtil.encrypt(id: item.id)
            param["slash_id"] = item.slashId
            param["tag"] = item.tags.joined(separator: ",")
            for tag in item.tags {
                features.insert(tag)
            }
            idList.append(param)
        }
        return (idList, features.joined(separator: ","))
    }

}

extension SearchResultShowTrackMananger.Item {

    init(result: SearchResultType, pos: Int? = nil, extraJudgement: SearchResultShowTrackMananger.ExtraJudgement? = nil) {
        var tags = [String]()
        var resultType = ""
        if let itemPos = pos {
            self.pos = itemPos
        }
        if extraJudgement?.isSmartSearch ?? false {
            tags.append("guess")
        }
        if extraJudgement?.isSpotlight ?? false {
            tags.append("spotlight")
        }
        if extraJudgement?.isSpotlightOnly ?? false {
            tags.append("onlyspotlight")
        }
        slashId = ""
        switch result.meta {
        case .openApp(let appInfo):
            if let ability = appInfo.appAbilities.first {
                switch ability {
                case .bot:
                    resultType = "app_bot"
                case .h5, .microApp, .localComponent:
                    resultType = "apps"
                case .unknown:
                    assert(false, "new value")
                    resultType = "unknown"
                @unknown default:
                    assert(false, "new value")
                    resultType = "unknown"
                }
            }
        case .box:
            resultType = "box"
        case .calendar:
            resultType = "calendar"
        case .chat:
            resultType = "groups"
        case .chatter(let chatterMeta):
            if chatterMeta.type == .bot {
                resultType = "single_bot"
            } else if chatterMeta.type == .ai {
                resultType = "myai"
            } else {
                resultType = "contacts"
            }
        case .cryptoP2PChat:
            resultType = "crypto_p2p_chat"
        case .shieldP2PChat:
            resultType = "shield_p2p_chat"
        case .doc(let docMeta):
            switch docMeta.type {
            case .bitable:
                resultType = "bitable"
            case .doc:
                resultType = "doc"
            case .file:
                resultType = "file"
            case .mindnote:
                resultType = "mindnote"
            case .sheet:
                resultType = "sheet"
            case .slide:
                resultType = "slide"
            case .slides:
                resultType = "slides"
            case .docx:
                resultType = "docx"
            case .wiki:
                resultType = "wiki"
            case .folder:
                resultType = "folder"
            case .catalog:
                resultType = "catalog"
            case .shortcut:
                resultType = "shortcut"
            case .unknown:
                resultType = "docs_unknown"
            @unknown default:
                assert(false, "new value")
                resultType = "none"
            }
        case .message(let meta):
            resultType = "messages"
            if let messageMeta = meta as? Search_V2_MessageMeta,
               messageMeta.attachmentCount > 0,
               SearchFeatureGatingKey.enableMessageAttachment.isEnabled {
                let urlAttachments = messageMeta.attachments.filter { attachment in
                    return attachment.attachmentType == .attachmentLink && attachment.attachmentRenderType == .card
                }
                if !urlAttachments.isEmpty {
                    tags.append("multimedia_card")
                }
            }
        case .link:
            resultType = "link"
            tags.append("link")
        case .oncall:
            resultType = "helpdesk"
            tags.append("helpdesk")
        case .slash(let meta):
            if let sourceID = (meta as? RustPB.Search_V2_SlashCommandMeta)?.dataSourceID {
                self.slashId = sourceID
            }
            resultType = result.type == .email ? "emails" : "slash_command"
            tags.append("slash_command_section")
        case .wiki(let wikiMeta):
            let docMeta = wikiMeta.docMetaType
            switch docMeta.type {
            case .bitable:
                resultType = "bitable"
            case .doc:
                resultType = "doc"
            case .file:
                resultType = "file"
            case .mindnote:
                resultType = "mindnote"
            case .sheet:
                resultType = "sheet"
            case .slide:
                resultType = "slide"
            case .slides:
                resultType = "slides"
            case .docx:
                resultType = "docx"
            case .wiki:
                resultType = "wiki"
            case .shortcut:
                resultType = "shortcut"
            case .unknown:
                resultType = "docs_unknown"
            case .folder:
                resultType = "folder"
            case .catalog:
                resultType = "catalog"
            @unknown default:
                assert(false, "new value")
                resultType = "none"
            }
        case .qaCard:
            resultType = "kg_card"
            tags.append("accurate_kg_staff_service_card")
        case .section(let meta):
            if let jsonData = meta.extras.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] {
                if let appId = json["appID"] as? String { slashId = appId }
                if let sectionType = json["sectionType"] as? String, sectionType == "SectionType_RECOMMEND" { tags.append("guess") }
            }
        case .customization(let meta):
            switch meta.dataSourceID {
            case "mobile-card-service":
                tags.append("fuzzy_kg_staff_service_card")
                resultType = "service_card"
            case "mobile-card-entity":
                resultType = "slash_command"
            default:
                resultType = "customization"
            }
            slashId = meta.dataSourceID
            tags.append("slash_command_card")
        default:
            resultType = "none"
        }

        if result is Search.CardResult {
            resultType = "kg_card"
            tags.append("fuzzy_kg_staff_service_card")
        }
        if result is OpenJumpResult {
            resultType = "more_result"
            tags.append("slash_command_section")
            if let appLink = (result as? OpenJumpResult)?.appLink,
               let appLinkEncoded = appLink.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: appLinkEncoded),
               let commandId = url.queryParameters.first(where: { $0.key == "commandId" })?.value {
                self.slashId = commandId
            }
        }

        self.id = result.id
        self.resultType = resultType
        self.tags = tags
    }

    init(recommendResult: UniversalRecommendResult, tags: [String]) {
        var resultType = ""
        switch recommendResult.resultMeta.typedMeta {
        case .appMeta(let appInfo):
            if let ability = appInfo.appAbility.first {
                switch ability {
                case .bot:
                    resultType = "app_bot"
                case .h5, .small, .localComponent:
                    resultType = "apps"
                @unknown default:
                    assert(false, "new value")
                    resultType = "unknown"
                }
            }
        case .groupChatMeta:
            resultType = "groups"
        case .userMeta(let chatterMeta):
            if chatterMeta.type == .bot {
                resultType = "single_bot"
            } else if chatterMeta.type == .ai {
                resultType = "myai"
            } else {
                resultType = "contacts"
            }
        case .docMeta(let docMeta):
            switch docMeta.type {
            case .bitable:
                resultType = "bitable"
            case .doc:
                resultType = "doc"
            case .file:
                resultType = "file"
            case .mindnote:
                resultType = "mindnote"
            case .sheet:
                resultType = "sheet"
            case .slide:
                resultType = "slide"
            case .docx:
                resultType = "docx"
            case .wiki:
                resultType = "wiki"
            case .unknownDocType:
                resultType = "docs_unknown"
            case .folder:
                resultType = "folder"
            case .slides:
                resultType = "slides"
            case .shortcut:
                resultType = "shortcut"
            case .catalog:
                fallthrough // use unknown default setting to fix warning
            @unknown default:
                assert(false, "new value")
                resultType = "none"
            }
        case .messageMeta:
            resultType = "messages"
        case .wikiMeta(let wikiMeta):
            switch wikiMeta.type {
            case .bitable:
                resultType = "bitable"
            case .doc:
                resultType = "doc"
            case .file:
                resultType = "file"
            case .mindnote:
                resultType = "mindnote"
            case .sheet:
                resultType = "sheet"
            case .slide:
                resultType = "slide"
            case .docx:
                resultType = "docx"
            case .wiki:
                resultType = "wiki"
            case .folder:
                resultType = "folder"
            case .slides:
                resultType = "slides"
            case .shortcut:
                resultType = "shortcut"
            case .unknownDocType:
                resultType = "docs_unknown"
            case .catalog:
                fallthrough // use unknown default setting to fix warning
            @unknown default:
                assert(false, "new value")
                resultType = "none"
            }
        // TODO: 剩余的如果需要再加
        default: resultType = "none"
        }
        self.id = recommendResult.id
        self.resultType = resultType
        self.tags = tags
    }

}

extension UniversalRecommendResult {
    var resultType: String {
        switch type {
        case .app:
            let appInfo = resultMeta.appMeta
            if let ability = appInfo.appAbility.first {
                switch ability {
                case .bot:
                    return "app_bot"
                case .h5, .small, .localComponent:
                    return "apps"
                @unknown default:
                    assert(false, "new value")
                    return "unknown"
                }
            }
            if !appInfo.isAvailable {
                // 未安装应用可能不吐abilities数据，默认为应用
                return "apps"
            }
            return "none"
        case .groupChat: return "groups"
        case .user:
            var clickTarget = ""
            if resultMeta.userMeta.type == .bot {
                clickTarget = "single_bot"
            } else if resultMeta.userMeta.type == .ai {
                clickTarget = "myai"
            } else {
                clickTarget = "contacts"
            }
            return clickTarget
        case .doc:
            let docMeta = resultMeta.docMeta
            switch docMeta.type {
            case .bitable:
                return "bitable"
            case .doc:
                return "doc"
            case .file:
                return "file"
            case .mindnote:
                return "mindnote"
            case .sheet:
                return "sheet"
            case .slide:
                return "slide"
            case .docx:
                return "docx"
            case .wiki:
                return "wiki"
            case .unknownDocType:
                return "docs_unknown"
            case .folder:
                return "folder"
            case .slides:
                return "slides"
            case .shortcut:
                return "shortcut"
            case .catalog:
                fallthrough // use unknown default setting to fix warning
            @unknown default:
                assert(false, "new value")
                return "none"
            }
        case .wiki:
            let wikiMeta = resultMeta.wikiMeta
            switch wikiMeta.type {
            case .bitable:
                return "bitable"
            case .doc:
                return "doc"
            case .file:
                return "file"
            case .mindnote:
                return "mindnote"
            case .sheet:
                return "sheet"
            case .slide:
                return "slide"
            case .docx:
                return "docx"
            case .wiki:
                return "wiki"
            case .unknownDocType:
                return "docs_unknown"
            case .folder:
                return "folder"
            case .slides:
                return "slides"
            case .shortcut:
                return "shortcut"
            case .catalog:
                fallthrough // use unknown default setting to fix warning
            @unknown default:
                assert(false, "new value")
                return "none"
            }
        case .message: return "message"
        // TODO: 暂时没有其他的类型，需要的话后边加
        default:
            return "none"
        }
    }
}
extension UITableView {
    public func clickSearchResultURLPosition(at indexPath: IndexPath, moreButton: [Int] = [], moreButtonInHeader: Bool = true) -> Int {
        var pos = 1
        let frontSection = (!moreButtonInHeader && indexPath.row == -1) ? indexPath.section : indexPath.section - 1
        var i = 0
        while i <= frontSection {
            pos += self.numberOfRows(inSection: i)
            i += 1
        }
        if !moreButtonInHeader && !moreButton.isEmpty && indexPath.section > 0 {
            pos += moreButton[safe: indexPath.section - 1] ?? 0
        } else if !moreButtonInHeader && !moreButton.isEmpty {
            pos += moreButton[indexPath.section]
        }
        if !moreButtonInHeader && indexPath.row == -1 {
            return pos
        } else {
            return pos + indexPath.row
        }
    }
}
