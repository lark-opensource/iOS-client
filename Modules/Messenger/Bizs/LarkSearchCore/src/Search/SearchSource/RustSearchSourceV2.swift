//
//  RustSearchSourceV2.swift
//  LarkSearchCore
//
//  Created by SolaWing on 2020/12/9.
//

import Foundation
import RxSwift
import LarkModel
import RustPB
import LarkRustClient
import LarkSDKInterface
import LarkSearchFilter
import LarkContainer
import SuiteAppConfig
/// supported context: (搜索request.context)
/// SearchRequestIncludeOuterTenant.self
/// AuthPermissionsKey.self
/// SearchRequestExcludeTypes

public final class RustSearchSourceV2: SearchSource {
    public var identifier: String { "RustSearchSourceV2(\(scene))" }
    public var supportedFilters: [SearchFilter] = []

    let client: RustService
    /// 注意需要增加seqID, 如果调用方没加，Source会自增, 单一源的情况下有用
    public let session: SearchSession
    /// 场景提示字符串，推荐用SearchSceneSection的名字
    public let scene: String

    public let entityTypes: [Search_V2_BaseEntity.EntityItem]
    public let sourceKey: String?
    public let userResolver: LarkContainer.UserResolver
    /// config after default value, then context value
    public let config: (inout Search_V2_SearchCommonRequestHeader) -> Void
    let searchActionTabName: Search_Common_SearchTabName
    public init(
        client: RustService,
        scene: String,
        session: SearchSession,
        types: [Search_V2_BaseEntity.EntityItem],
        sourceKey: String? = nil,
        searchActionTabName: Search_Common_SearchTabName,
        resolver: LarkContainer.UserResolver,
        config: @escaping (inout Search_V2_SearchCommonRequestHeader) -> Void
    ) {
        self.client = client
        self.scene = scene
        self.session = session
        //        assert(!types.isEmpty)
        self.entityTypes = types
        self.config = config
        self.sourceKey = sourceKey
        self.userResolver = resolver
        self.searchActionTabName = searchActionTabName
    }
    var lastSeqID = UInt.max
    // NOTE: 外部可能不加这个seqID，所以source自动自增一下
    // 即使多个source，也会由第一个source负责自增，其他复用，所以应该能保证一致性
    func nextSeqID() -> UInt {
        var seqID = session.seqID
        if seqID == lastSeqID { // 外部没增加，source保证增加一下. 感觉还是应该上层封装透传下来, 需要区分这两种场景
            seqID = session.nextSeqID()
        }
        lastSeqID = seqID
        return seqID
    }
    var lastQuery: String = ""
    /// throws: InvokeAbnormalNotice, Rust Client Error
    // nolint: long_function 搜索业务逻辑较为复杂,暂不修改
    public func search(request: SearchRequest) -> Observable<SearchResponse> {
        let moreToken: MoreToken? = request.assertMoreToken()
        var seqID: UInt = 0

        let queryState: Search_V2_BaseEnum.QueryInputState = request.query.count > lastQuery.count ? .expand : .shrink
        defer { lastQuery = request.query }

        // 配置顺序：默认的(初始化) -> context里的 -> 用户设置的(filter) -> Source特殊设置
        var message = Search_V2_UniversalSearchRequest()
        message.header = tap(Search_V2_SearchCommonRequestHeader()) { message_header in
            // first is default value
            message_header.searchContext = tap(Search_V2_BaseEntity.SearchContext()) {
                $0.tagName = scene
                $0.entityItems = entityTypes
                if let sourceKey = sourceKey {
                    $0.sourceKey = sourceKey
                }
            }
            // then config value
            config(&message_header)

            // then private value
            message_header.query = request.query
            message_header.isForce = true // 无query过滤依赖上层拦截判断，这里始终请求
            message_header.timezone = NSTimeZone.system.identifier

            for pageInfo in request.pageInfos {
                var searchV2PagingInfo = Search_V2_SearchCommonRequestHeader.PagingInfo()
                searchV2PagingInfo.clusteringType = pageInfo.clusteringType
                searchV2PagingInfo.pageSize = pageInfo.pageSize
                message_header.pagingInfos.append(searchV2PagingInfo)
            }
            if let moreToken = moreToken {
                message_header.paginationToken = moreToken.paginationToken
                seqID = moreToken.lastSeqID // 加载更多不变
            } else {
                seqID = nextSeqID()
            }
            message_header.searchSession = session.session
            message_header.sessionSeqID = Int32(truncatingIfNeeded: seqID)
            message_header.extraParams.impressionID = session.imprID(seqID: seqID)
            message_header.extraParams.queryInputState = Int32(queryState.rawValue)
            message_header.extraParams.enableFolder = true
            message_header.extraParams.explanationTagEnable = true
            message_header.extraParams.renderDataEnable = SearchFeatureGatingKey.searchDynamicResult.isUserEnabled(userResolver: self.userResolver)
            message_header.extraParams.includeMyAi = SearchFeatureGatingKey.myAiMainSwitch.isUserEnabled(userResolver: self.userResolver)
            message_header.extraParams.enableMessageAttachment = SearchFeatureGatingKey.enableMessageAttachment.isUserEnabled(userResolver: userResolver)

            if let enableShortcut = request.context[SearchRequestEnableShortcut.self] {
                message_header.extraParams.enableShortcut = enableShortcut
            } else {
                message_header.extraParams.enableShortcut = false
            }
            // then user context value
            if let includeOuterTenant = request.context[SearchRequestIncludeOuterTenant.self] {
                message_header.searchContext.commonFilter.includeOuterTenant = includeOuterTenant
            }
            if let permissions = request.context[AuthPermissionsKey.self] {
                PickerLogger.shared.info(module: PickerLogger.Module.search, event: "search config", parameters: "permissions: \(permissions)")
                message_header.extraParams.chatterPermissions = tap(Search_V1_ChatterPermissionsRequest()) {
                    $0.actions = permissions
                }
            } else {
                PickerLogger.shared.info(module: PickerLogger.Module.search, event: "search config", parameters: "without permissions")
            }
            if request.context[SearchRequestExcludeTypes.chat] == true {
                message_header.searchContext.entityItems.removeAll {
                    switch $0.type {
                    case .groupChat: return true
                    @unknown default: return false
                    }
                }
            }
            if request.context[SearchRequestExcludeTypes.department] == true {
                message_header.searchContext.entityItems.removeAll {
                    switch $0.type {
                    case .department: return true
                    @unknown default: return false
                    }
                }
            }
            if request.context[SearchRequestExcludeTypes.local] == true {
                message_header.searchContext.entityItems = message_header.searchContext.entityItems.map {
                    var v = $0
                    v.mergePolicy = .serverOnly
                    return v
                }
            }
            if (self.searchActionTabName == .messageTab || self.searchActionTabName == .docsTab) &&
                (SearchFeatureGatingKey.enableCommonlyUsedFilter.isUserEnabled(userResolver: userResolver) ||
                 (SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: userResolver) &&
                  !AppConfigManager.shared.leanModeIsOn)
                ) {
                var searchAction = Search_V2_SearchAction()
                searchAction.tab = self.searchActionTabName
                searchAction.query = request.query
                if SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: userResolver) &&
                    !AppConfigManager.shared.leanModeIsOn {
                    searchAction.capsuleRecommendEnable = true
                }
                message_header.searchContext.searchAction = searchAction
            }
            message_header.isQueryTemplate = request.isQueryTemplate
            if request.count >= 1 {
                if request.count > Int(UInt32.max) {
                    assertionFailure("overflow")
                } else {
                    message_header.pageSize = Int32(request.count)
                }
            }
            if let op = request.context[SearchRequestOpAfterError.self] {
                message_header.op = op
            }
            // then filter configs
            request.filters.applyTo(filterParam: &message_header, userResolver: self.userResolver)
        }
        // MARK: Do Request And Handle Response
        let rustRequest = RequestPacket(message: message)
        let observable: Observable<ResponsePacket<Search_V2_UniversalSearchResponse>> = client.async(rustRequest)
        return observable.map { [imprID = message.header.extraParams.impressionID](packet) in
            let response = try packet.result.get()
            let responseHeader = response.header
            /// 异常情况直接报错。cancel情况抛出应该不影响
            if responseHeader.hasInvokeAbnormalNotice { throw responseHeader.invokeAbnormalNotice }

            var moreToken: Any? {
                return MoreToken(lastSeqID: seqID, paginationToken: responseHeader.paginationToken)
            }
            var results: [SearchResultType] = response.results.map {
                return Search.Result(base: $0, contextID: packet.contextID)
            }
            if let card = response.suggestionInfo.serviceCards.first, !card.renderContent.isEmpty {
                let cardResult = Search.CardResult(id: card.id, renderContent: card.renderContent, templateName: "service_card")
                results.append(cardResult)
            }
            var wrapper = BaseSearchResponse(results: results,
                                             moreToken: moreToken,
                                             hasMore: responseHeader.hasMore_p,
                                             searchError: SearchError(rawValue: response.header.larkErrorCode),
                                             suggestionInfo: response.suggestionInfo,
                                             secondaryStageSearchable: responseHeader.secondaryStageSearchable)
            if responseHeader.hasErrorInfo {
                wrapper.errorInfo = responseHeader.errorInfo
            }
            if responseHeader.hasErrorCode {
                wrapper.errorCode = responseHeader.errorCode
            }
            wrapper.context[SearchResponseContextID.self] = packet.contextID
            if !imprID.isEmpty {
                wrapper.context[SearchResponseImprID.self] = imprID
            }
            return wrapper
        }.catchError { (error) throws -> Observable<SearchResponse> in
            throw error
        }
    }
    // enable-lint: long_function

    struct MoreToken {
        var lastSeqID: UInt
        var paginationToken: String
    }
}

struct AuthPermissionsKey: SearchRequestContextKey {
    typealias Value = [RustPB.Basic_V1_Auth_ActionType]
}

public enum SearchResponseContextID: SearchResponseContextKey {
    public typealias Value = String
}
public enum SearchResponseImprID: SearchResponseContextKey {
    public typealias Value = String
}
public enum SearchRequestEnableShortcut: SearchRequestContextKey {
    public typealias Value = Bool
}
public enum SearchRequestIncludeOuterTenant: SearchRequestContextKey {
    public typealias Value = Bool
}
/// true to exclude Chat And department result
public enum SearchRequestExcludeTypes: SearchRequestContextKey {
    public typealias Value = Bool
    case chat, department, chatter, mailContact, bot
    case local // 本地请求结果, 本地支持后会去掉这个配置
}

public enum SearchRequestOpAfterError: SearchRequestContextKey {
    public typealias Value = Search_V2_OpAfterError
}

func tap<T>(_ value: T, action: (inout T) -> Void) -> T {
    var value = value
    action(&value)
    return value
}

extension Search_V2_SearchResult: SearchItem {
    public var identifier: String? { "\(self.type):\(self.id)" }
}

extension Search_V2_UniversalSearchResponse: SearchResponseContextKey {
    public typealias Value = Search_V2_UniversalSearchResponse
}
extension Search_V2_SearchCommonResponseHeader.InvokeAbnormalNotice: Error {}

extension Array where Element == SearchFilter {
    // nolint: long_function 搜索业务逻辑较为复杂,暂不修改
    public func applyTo(filterParam: inout Search_V2_SearchCommonRequestHeader, userResolver: LarkContainer.UserResolver) {
        if self.isEmpty { return }

        func apply(chatTypes: [ChatFilterType], to item: inout Search_V2_BaseEntity.EntityItem) {
            // TODO: 和v2接口的对应关系需要讨论一下..
            if chatTypes.isEmpty { return }
            switch item.type {
            case .groupChat:
                typealias ST = Search_V2_UniversalFilters.ChatFilter.SearchType
                item.entityFilter.groupChatFilter.searchTypes = chatTypes.compactMap {
                    switch $0 {
                    case .`private`: return Int32(ST.private.rawValue)
                    case .outer: return Int32(ST.crossTenant.rawValue)
                    case .publicJoin: return Int32(ST.public.rawValue | ST.joined.rawValue)
                    case .publicAbsent: return Int32(ST.public.rawValue | ST.unJoined.rawValue)
                    @unknown default: return nil
                    }
                }
            @unknown default: break
            }
        }
        filterParam.searchContext.entityItems = filterParam.searchContext.entityItems
            .filter { item in
                var isIncludedStates: [Bool] = []
                for filter in self {
                    switch filter {
                    case let .docWorkspaceIn(items):
                        guard !items.isEmpty else { break }
                        isIncludedStates.append(item.type != .doc)
                    case let .docFolderIn(items):
                        guard !items.isEmpty else { break }
                        isIncludedStates.append(item.type != .wiki)
                    case let .docType(type):
                        switch type {
                        case .all: break
                        case .wiki: isIncludedStates.append(item.type != .doc)
                        case .doc: isIncludedStates.append(item.type != .wiki)
                        }
                    default: break
                    }
                }
                if isIncludedStates.isEmpty { return true }
                if isIncludedStates.contains(true) { return true }
                return false
            }
            .map { item in
                var item = item
                for filter in self {
                    switch filter {
                    case .recommend: break
                    case let .commonFilter(commonFilter):
                        switch commonFilter {
                        case let .mainFrom(fromIds, _, _, _):
                            if fromIds.isEmpty { break }
                            filterParam.searchContext.commonFilter.fromUserIds = fromIds.map { $0.chatterID }
                        case let .mainWith(withIds):
                            if withIds.isEmpty { break }
                            filterParam.searchContext.commonFilter.withUserIds = withIds.map { $0.chatterID }
                        case let .mainIn(inIds):
                            if inIds.isEmpty { break }
                            filterParam.searchContext.commonFilter.inChatIds = inIds.map { $0.chatId ?? "" }
                        case .mainDate(let dateFilter):
                            guard let startEndTime = dateFilter else { break }
                            var time = Search_V2_UniversalFilters.TimeRange()
                            if let startTime = startEndTime.startDate {
                                time.startTime = Int64(startTime.timeIntervalSince1970)
                            }
                            if let endTime = startEndTime.endDate {
                                time.endTime = Int64(endTime.timeIntervalSince1970)
                            }
                            filterParam.searchContext.commonFilter.timeRange = time
                        }
                    case let .general(generalFilter):
                        if item.type == .customization { break }
                        switch generalFilter {
                        case let .user(info, fromIds):
                            if fromIds.isEmpty { break }
                            var filter = Search_V2_UniversalFilters.SlashCommandFilter.CommandFilter()
                            filter.filterID = info.id
                            filter.values = fromIds.map { $0.chatterID }
                            item.entityFilter.slashCommandFilter.filters.append(filter)
                        case let .date(info, dateFilter):
                            guard let startEndTime = dateFilter else { break }
                            var time = Search_V2_UniversalFilters.TimeRange()
                            if let startTime = startEndTime.startDate {
                                time.startTime = Int64(startTime.timeIntervalSince1970)
                            }
                            if let endTime = startEndTime.endDate {
                                time.endTime = Int64(endTime.timeIntervalSince1970)
                            }
                            var filter = Search_V2_UniversalFilters.SlashCommandFilter.CommandFilter()
                            filter.filterID = info.id
                            filter.timeRange = time
                            item.entityFilter.slashCommandFilter.filters.append(filter)
                        case let .multiple(info, options):
                            if options.isEmpty { break }
                            var filter = Search_V2_UniversalFilters.SlashCommandFilter.CommandFilter()
                            filter.filterID = info.id
                            filter.values = options.map { $0.id }
                            item.entityFilter.slashCommandFilter.filters.append(filter)
                        case let .single(info, option):
                            guard let option = option else { break }
                            var filter = Search_V2_UniversalFilters.SlashCommandFilter.CommandFilter()
                            filter.filterID = info.id
                            filter.values = [option.id]
                            item.entityFilter.slashCommandFilter.filters.append(filter)
                        case let .calendar(info, calendars):
                            if calendars.isEmpty { break }
                            var filter = Search_V2_UniversalFilters.SlashCommandFilter.CommandFilter()
                            filter.filterID = info.id
                            filter.values = calendars.map({ $0.id })
                            item.entityFilter.slashCommandFilter.filters.append(filter)
                        case let .userChat(info, pickers):
                            if pickers.isEmpty { break }
                            var filter = Search_V2_UniversalFilters.SlashCommandFilter.CommandFilter()
                            filter.filterID = info.id
                            filter.values = pickers.map({ $0.id })
                            item.entityFilter.slashCommandFilter.filters.append(filter)
                        case let .mailUser(info, pickers):
                            if pickers.isEmpty { break }
                            var filter = Search_V2_UniversalFilters.SlashCommandFilter.CommandFilter()
                            filter.filterID = info.id
                            filter.values = pickers.map({
                                switch $0.meta {
                                case .chatter(let chatterMeta):
                                    return chatterMeta.enterpriseMailAddress ?? ""
                                case .chat(let chatMeta):
                                    return chatMeta.enterpriseMailAddress ?? ""
                                case .mailUser(let mailUserMeta):
                                    return mailUserMeta.mailAddress ?? ""
                                default: break
                                }
                                return ""
                            }).filter({ !$0.isEmpty })
                            item.entityFilter.slashCommandFilter.filters.append(filter)
                        case let .inputTextFilter(info, texts):
                            if texts.isEmpty { break }
                            var filter = Search_V2_UniversalFilters.SlashCommandFilter.CommandFilter()
                            filter.filterID = info.id
                            filter.values = texts
                            item.entityFilter.slashCommandFilter.filters.append(filter)
                        }
                    case let .chat(_, chatItems):
                        if chatItems.isEmpty { break }
                        switch item.type {
                        case .message: item.entityFilter.messageFilter.chatIds = chatItems.map { $0.chatId ?? "" }
                        case .url: item.entityFilter.urlFilter.chatIds = chatItems.map { $0.chatId ?? "" }
                        default: break
                        }
                    case let .docPostIn(items):
                        if items.isEmpty { break }
                        switch item.type {
                        case .doc: item.entityFilter.docFilter.chatIds = items.map { $0.chatId ?? "" }
                        case .wiki: item.entityFilter.wikiFilter.chatIds = items.map { $0.chatId ?? "" }
                        default: break
                        }
                    case let .chatter(_, chatterItems, _, _, _):
                        if chatterItems.isEmpty { break }
                        switch item.type {
                        case .message: item.entityFilter.messageFilter.creatorIds = chatterItems.map { $0.chatterID }
                        case .url: item.entityFilter.urlFilter.creatorIds = chatterItems.map { $0.chatterID }
                        case .doc: item.entityFilter.docFilter.sharerIds = chatterItems.map { $0.chatterID }
                        case .wiki: item.entityFilter.wikiFilter.sharerIds = chatterItems.map { $0.chatterID }
                        case .messageFile: item.entityFilter.messageFileFilter.creatorIds = chatterItems.map { $0.chatterID }
                        default: break
                        }
                    case let .withUsers(chatterItems):
                        if chatterItems.isEmpty { break }
                        switch item.type {
                        case .message: item.entityFilter.messageFilter.withUserIds = chatterItems.map { $0.chatterID }
                        case .url: item.entityFilter.urlFilter.withUserIds = chatterItems.map { $0.chatterID }
                        default: break
                        }
                    case let .docSharer(docItems):
                        if docItems.isEmpty { break }
                        switch item.type {
                        case .doc: item.entityFilter.docFilter.sharerIds = docItems.map { $0.chatterID }
                        case .wiki:
                            item.entityFilter.wikiFilter.sharerIds = docItems.map { $0.chatterID }
                        default: break
                        }
                    case let .docFrom(fromIds, _, _, _):
                        if fromIds.isEmpty { break }
                        switch item.type {
                        case .doc:
                            item.entityFilter.docFilter.fromIds = fromIds.map { $0.chatterID }
                        case .wiki:
                            item.entityFilter.wikiFilter.fromIds = fromIds.map { $0.chatterID }
                        default: break
                        }
                    case let .docCreator(users, _):
                        if users.isEmpty { break }
                        switch item.type {
                        case .doc: item.entityFilter.docFilter.creatorIds = users.map { $0.chatterID }
                        case .wiki:
                            item.entityFilter.wikiFilter.creatorIds = users.map { $0.chatterID }
                        default: break
                        }
                    case let .docContentType(type):
                        switch item.type {
                        case .doc:
                            switch type {
                            case .fullContent: item.entityFilter.docFilter.searchContentTypes = [.fullContent]
                            case .onlyTitle:
                                item.entityFilter.docFilter.searchContentTypes = [.onlyTitle]
                            case .onlyComment:
                                item.entityFilter.docFilter.searchContentTypes = [.onlyComment]
                            }
                        case .wiki:
                            switch type {
                            case .fullContent: item.entityFilter.wikiFilter.searchContentTypes = [.fullContent]
                            case .onlyTitle:
                                item.entityFilter.wikiFilter.searchContentTypes = [.onlyTitle]
                            case .onlyComment:
                                item.entityFilter.wikiFilter.searchContentTypes = [.onlyComment]
                            }
                        default: break
                        }
                    case .docFolderIn(let items):
                        if items.isEmpty { break }
                        switch item.type {
                        case .doc:
                            item.entityFilter.docFilter.folderTokens = items.map { $0.id }
                            item.entityFilter.docFilter.types = RustPB.Basic_V1_Doc.TypeEnum.getAllSupportedTypes()
                        default: break
                        }
                    case .docWorkspaceIn(let items):
                        if items.isEmpty { break }
                        switch item.type {
                        case .wiki:
                            item.entityFilter.wikiFilter.spaceIds = items.map { $0.id }
                            item.entityFilter.wikiFilter.types = RustPB.Basic_V1_Doc.TypeEnum.getAllSupportedTypes()
                        default: break
                        }
                    case .date(let dateFilter, _):
                        guard let startEndTime = dateFilter else { break }
                        var time = Search_V2_UniversalFilters.TimeRange()
                        if let startTime = startEndTime.startDate {
                            time.startTime = Int64(startTime.timeIntervalSince1970)
                        }
                        if let endTime = startEndTime.endDate {
                            time.endTime = Int64(endTime.timeIntervalSince1970)
                        }
                        switch item.type {
                        case .message: item.entityFilter.messageFilter.timeRange = time
                        case .url: item.entityFilter.urlFilter.timeRange = time
                        case .doc: item.entityFilter.docFilter.reviewTimeRange = time
                        case .wiki: item.entityFilter.wikiFilter.reviewTimeRange = time
                        case .messageFile: item.entityFilter.messageFileFilter.timeRange = time
                        default: break
                        }
                    case let .chatMemeber(_, items):
                        if items.isEmpty { break }
                        switch item.type {
                        case .groupChat: item.entityFilter.groupChatFilter.chatMemberIds = items.map { $0.chatterID }
                        default: break
                        }
                        // chatKeyWord筛选器已下线
                    case .chatType(let types):
                        apply(chatTypes: types, to: &item)
                    case .threadType(let type): // 这个应该不会和chatType同时出现
                        apply(chatTypes: type.chatTypes, to: &item)
                    case .messageType(let type):
                        switch type {
                        case .file:
                            if case .message = item.type {
                                item.entityFilter.messageFilter.messageTypes = [.file]
                            }
                        case .all, .link: break
                        @unknown default:
                            assertionFailure("unimplemented code!!")
                        }
                    case .messageAttachmentType(let type):
                        guard item.type == .message else { break }
                        switch type {
                        case .attachmentFile:
                            item.entityFilter.messageFilter.includeAttachmentTypes = [.attachmentFile]
                        case .attachmentLink:
                            item.entityFilter.messageFilter.includeAttachmentTypes = [.attachmentLink]
                        case .attachmentImage:
                            item.entityFilter.messageFilter.includeAttachmentTypes = [.attachmentImage]
                        case .attachmentVideo:
                            item.entityFilter.messageFilter.includeAttachmentTypes = [.attachmentVideo]
                        case .unknownAttachmentType: break
                        @unknown default:
                            assertionFailure("unimplemented code!!")
                        }
                    case .messageMatch(let types):
                        guard item.type == .message else { break }
                        for type in types {
                            switch type {
                            case .excludeBot:
                                item.entityFilter.messageFilter.excludedFromTypes.append(.bot)
                            case .atMe:
                                item.entityFilter.messageFilter.includeAtUserIds = [userResolver.userID]
                            case .onlyBot:
                                item.entityFilter.messageFilter.excludedFromTypes.append(.user)
                            }
                        }
                    case .docOwnedByMe(let docOwnedByMe, let uid):
                        if docOwnedByMe && item.type == .doc { item.entityFilter.docFilter.creatorIds = [uid] }
                        if docOwnedByMe && item.type == .wiki { item.entityFilter.wikiFilter.creatorIds = [uid] }
                    case .docFormat(let docTypes, _):
                        if docTypes.isEmpty { break }
                        func rustDocTypes(docTypes: [DocFormatType]) -> [Basic_V1_Doc.TypeEnum] {
                            docTypes.compactMap {
                                switch $0 {
                                case .all: break // 前面处理了
                                case .doc:      return .doc
                                case .sheet:    return .sheet
                                case .slide:    return .slide
                                case .mindNote: return .mindnote
                                case .bitale:   return .bitable
                                case .file:     return .file
                                case .slides:   return .slides
                                @unknown default:
                                    assertionFailure("unimplemented code!!")
                                }
                                return nil
                            }
                        }
                        switch item.type {
                        case .wiki:
                            if docTypes.contains(.all) {
                                item.entityFilter.wikiFilter.types = RustPB.Basic_V1_Doc.TypeEnum.getAllSupportedTypes()
                            } else {
                                item.entityFilter.wikiFilter.types = rustDocTypes(docTypes: docTypes)
                            }
                        case .doc:
                            if docTypes.contains(.all) {
                                item.entityFilter.docFilter.types = RustPB.Basic_V1_Doc.TypeEnum.getAllSupportedTypes()
                            } else {
                                item.entityFilter.docFilter.types = rustDocTypes(docTypes: docTypes)
                            }
                        default: break
                        }
                    case .chatKeyWord(let keyword):
                        if keyword.isEmpty { break }
                        assert(false, "unsupported value \(filter)")
                    case let .wikiCreator(users):
                        switch item.type {
                        case .wiki: item.entityFilter.wikiFilter.creatorIds = users.map { $0.chatterID }
                        default: break
                        }
                    case .docSortType(let type):
                        switch item.type {
                        case .doc:
                            switch type {
                            case .mostRelated:
                                item.entityFilter.docFilter.sortType = .defaultType
                            case .mostRecentUpdated:
                                item.entityFilter.docFilter.sortType = .editTime
                            case .mostRecentCreated:
                                item.entityFilter.docFilter.sortType = .createTime
                            }
                        case .wiki:
                            switch type {
                            case .mostRelated:
                                item.entityFilter.wikiFilter.sortType = .defaultType
                            case .mostRecentUpdated:
                                item.entityFilter.wikiFilter.sortType = .editTime
                            case .mostRecentCreated:
                                item.entityFilter.wikiFilter.sortType = .createTime
                            }
                        default: break
                        }
                    case .groupSortType(let type):
                        if case let .groupChat = item.type {
                            switch type {
                            case .mostRelated: item.entityFilter.groupChatFilter.sortType = .groupDefaultSort
                            case .mostRecentCreated: item.entityFilter.groupChatFilter.sortType = .groupCreateTime
                            case .mostRecentUpdated: item.entityFilter.groupChatFilter.sortType = .groupUpdateTime
                            case .leastNumGroupMember: item.entityFilter.groupChatFilter.sortType = .groupNumMembers
                            }
                        }
                    case .messageChatType(let type):
                        guard item.type == .message else { break }
                        switch type {
                        case .groupChat: item.entityFilter.messageFilter.chatType = .groupChat
                        case .p2PChat: item.entityFilter.messageFilter.chatType = .p2PChat
                        default: break
                        }
                    case .docType: break
                    case .specificFilterValue(_, _, _): break
                    @unknown default:
                        assert(false, "unsupported value \(filter)")
                    }
                }
                // 这里补全DocFilter和Wikifilter的types字段，用户如果未激活筛选器，那需要把类型都补齐
                switch item.type {
                case .wiki:
                    if item.entityFilter.wikiFilter.types.isEmpty {
                        item.entityFilter.wikiFilter.types = RustPB.Basic_V1_Doc.TypeEnum.getAllSupportedTypes()
                    }
                case .doc:
                    if item.entityFilter.docFilter.types.isEmpty {
                        item.entityFilter.docFilter.types = RustPB.Basic_V1_Doc.TypeEnum.getAllSupportedTypes()
                    }
                default: break
                }
                return item
            }
        if filterParam.searchContext.hasSearchAction &&
            (SearchFeatureGatingKey.enableCommonlyUsedFilter.isUserEnabled(userResolver: userResolver) ||
             (SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: userResolver) &&
              !AppConfigManager.shared.leanModeIsOn)
            ) {
            var rustPBSearchActionFilters: [RustPBSearchActionFilter] = self.compactMap { filter in
                filter.convertToRustPBSearchActionFilter()
            }
            rustPBSearchActionFilters = rustPBSearchActionFilters.filter({ filter in
                filter.typedFilter != nil
            })
            filterParam.searchContext.searchAction.filters = rustPBSearchActionFilters
        }
    }
    // enable-lint: long_function
}

private extension RustPB.Basic_V1_Doc.TypeEnum {
    static func getAllSupportedTypes() -> [RustPB.Basic_V1_Doc.TypeEnum] {
        return [.doc, .sheet, .bitable, .mindnote, .file, .slides, .docx, .folder, .shortcut]
    }
}

public extension SearchSceneSection {
    public var name: String {
        switch self {
        case .searchPlatformFilter: return "SEARCH_PLATFORM_FILTER_SCENE"
        case .searchDocAndWiki: return "DocsPicker"
        case .searchUserAndGroupChat: return "SEARCH_GENERAL_USER_AND_CHAT_PICKER"
        default: return Self.name(scene: remoteRustScene)
        }
    }
    static func name(scene: SearchScene) -> String { scene.protobufName() }
}
