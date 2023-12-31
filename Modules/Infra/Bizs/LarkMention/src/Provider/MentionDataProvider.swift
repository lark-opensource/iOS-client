//
//  MentionDataProvider.swift
//  LarkMention
//
//  Created by Yuri on 2022/5/24.
//

import Foundation
import RxSwift
import LarkSearchCore
import LarkCore
import LarkSDKInterface
import UIKit
import LarkRustClient
import LarkContainer
import RustPB
import LarkFeatureGating
import LarkSearchFilter
import EEAtomic
import LarkAccountInterface

public final class MentionDataProvider: MentionDataProviderType, SearchResultViewListBindDelegate, MentionDataConvertable {
    var showDocumentOwner: Bool
    var showChatterMail: Bool
    
    var currentTenantId: String {
        return AccountServiceAdapter.shared.currentTenant.tenantId
    }
    
    public typealias Item = SearchResultType
    
    public var results: [Item] = []
    
    public var resultView: SearchResultView = SearchResultView(tableStyle: .plain)
    
    public var listvm: ListVM { searchVM.result }
    
    public var listState: SearchListStateCases?
    public var didEventHandler: ((MentionLoadEvent) -> Void)?
    
    var searchParameters: MentionSearchParameters
    
    public var items = PublishSubject<[PickerOptionType]>()
    
    public func search(text: String) {
        searchVM.query.text.accept(text)
    }

    public let userResolver: LarkContainer.UserResolver
    public init(resolver: LarkContainer.UserResolver, parameters: MentionSearchParameters) {
        self.userResolver = resolver
        self.searchParameters = parameters
        self.showDocumentOwner = parameters.document?.showDocumentOwner ?? false
        self.showChatterMail = parameters.chatter?.showChatterMail ?? false
        self.bindResultView()
    }
    
    public var searchLocation: String { "Mention" }
    lazy var searchVM: SearchSimpleVM<Item> = {
        let vm = SearchSimpleVM(result: makeListVM())
        configure(vm: vm)
        return vm
    }()
    func configure(vm: SearchSimpleVM<Item>) {
        var context = vm.query.context.value
        context[SearchRequestIncludeOuterTenant.self] = searchParameters.chatter?.includeOuter
//        if !permissions.isEmpty {
//            context[AuthPermissionsKey.self] = permissions
//        }
        vm.query.context.accept(context)
    }
    
    func makeListVM() -> SearchListVM<Item> {
        SearchListVM<Item>(source: makeSource(), pageCount: 20)
    }
    
    func makeSource() -> SearchSource {
        // note subclass override
        var maker = MentionSearchSourceMaker(resolver: self.userResolver,
                                             scene: .rustScene(.addChatChatters),
                                             parameters: searchParameters)
        maker.doNotSearchResignedUser = true
        return maker.makeAndReturnProtocol()
    }
    
    public func on(state: ListVM.State, results: [Item], event: ListVM.Event) {
        if case let .fail(error) = event {
            didEventHandler?(.fail(error.error))
            return
        }
        switch state.state {
        case .normal:
            didEventHandler?(.load(.init(items: convert(results: results), hasMore: state.hasMore)))
        case .empty:
            didEventHandler?(.empty)
        case .reloading:
            didEventHandler?(.reloading(state.lastestRequest?.query ?? ""))
        case .loadingMore:
            didEventHandler?(.loadingMore(.init(items: convert(results: results), hasMore: state.hasMore)))
        default:
            break
        }
    }
    
    public func loadMore() {
        searchVM.result.loadMore()
    }
}

// MARK: - RustSearchSourceMaker
/// 负责创建一个调用底层Rust的Search Source. 兼容各个版本的Source和V2迁移
/// make方法可多次调用创建多个不同的source
public struct MentionSearchSourceMaker {
    @Injected var rustService: RustService

    public var scene: SearchSceneSection
    public var supportedFilters: [SearchFilter] = []

    public var session: SearchSession
    public var authPermissions: [RustPB.Basic_V1_Auth_ActionType] = []

    public var externalID: String?
    
    var searchParameters: MentionSearchParameters

    public var needSearchOuterTenant: Bool = true
    public var doNotSearchResignedUser: Bool = true
    public var inChatID: String?
    public var chatFilterMode: [ChatFilterMode]?
    /// calendar use, only true or nil, v2始终会带上这个标记
    public var includeMeetingGroup: Bool = true


    // 加在 commonFilter 中
    public var chatID: String?

    /// v1的local不太稳定，暂时只给历史遗留的使用。新代码迁移到v2, 不使用v1 local兜底了..
    public var v1LocalEnabled = true

    public let userResolver: LarkContainer.UserResolver
    public init(resolver: LarkContainer.UserResolver,
                scene: SearchSceneSection,
                parameters: MentionSearchParameters,
                session: SearchSession = SearchSession()) {
        self.userResolver = resolver
        self.scene = scene
        self.session = session
        self.searchParameters = parameters
    }

    /// maker不持有Source, Source持有maker来提供配置参数
    /// NOTE: 这个返回的是v2或者v1的模型，使用的地方需要新增对v2模型的支持
    /// 现在临时用这个名字, 全量后再来调整方法名
    public func makeAndReturnProtocol() -> SearchSource {
        /// NOTE: 需要避免捕获self，外部可能动态改变config并创建新的source.
        /// 动态改config的需求通过request的context解决..
        var types: [Search_V2_BaseEntity.EntityItem] = []

        if let chatter = searchParameters.chatter {
            switch chatter.type {
            case .normal:
                types.append(userEntity)
            case .mail:
                types.append(userEntity)
                types.append(mailContactEntity)
            }
        }
        if searchParameters.chat != nil {
            types.append(chatEntity)
        }
        if let document = searchParameters.document {
            var docEntity = makeEntity(type: .doc)
            docEntity.entityFilter.docFilter.searchContentTypes = [.onlyTitle]

            var wikiSelector = Search_V2_UniversalSelectors.WikiSelector()
            // 不设置，默认wiki不带ownerName，设置一下WikiSelector
            if let searchDocument = searchParameters.document {
                wikiSelector.needOwner = searchDocument.showDocumentOwner
            }
            var wikiEntity = makeEntity(type: .wiki)
            wikiEntity.entitySelector.wikiSelector = wikiSelector
            wikiEntity.entityFilter.wikiFilter.searchContentTypes = [.onlyTitle]

            typealias RustType = RustPB.Basic_V1_Doc.TypeEnum
            var rustTypes: [RustType] = []
            if let types = document.types {
                for type in types {
                    guard let rustType = RustType(rawValue: type.rawValue) else {
                        continue
                    }
                    rustTypes.append(rustType)
                }
                docEntity.entityFilter.docFilter.types = rustTypes
                wikiEntity.entityFilter.wikiFilter.types = rustTypes
            }
            if let creatorIds = document.creatorIds,
               !creatorIds.isEmpty {
                docEntity.entityFilter.docFilter.creatorIds = creatorIds
                wikiEntity.entityFilter.wikiFilter.creatorIds = creatorIds
            }
            types.append(contentsOf: [docEntity, wikiEntity])
        }

        let source = RustSearchSourceV2(
            client: rustService,
            scene: scene.remoteRustScene.protobufName(),
            session: SearchSession(),
            types: types,
            searchActionTabName: scene.searchActionTabName,
            resolver: self.userResolver,
            config: { header in // swiftlint:disable:this all
                header.searchContext.commonFilter.includeOuterTenant = searchParameters.chatter?.includeOuter ?? false
            })
        return source
    }
    
    var userEntity: Search_V2_BaseEntity.EntityItem {
        makeEntity(type: .user) { (en) in
            typealias SearchType = Search_V2_UniversalFilters.UserFilter.SearchType
            var searchTypeTemp: Int32 = 0
            guard let chatterParam = searchParameters.chatter else { return }
            if chatterParam.isWork {
                searchTypeTemp = searchTypeTemp | Int32(SearchType.unResigned.rawValue)
            }
            if chatterParam.isResigned {
                searchTypeTemp = searchTypeTemp | Int32(SearchType.resigned.rawValue)
            }
            en.entityFilter.userFilter.searchType = [searchTypeTemp]
            en.mergePolicy = .serverOnly
        }
    }
    
    var mailContactEntity: Search_V2_BaseEntity.EntityItem {
        makeEntity(type: .mailContact) { (en) in
            typealias SearchType = Search_V2_UniversalFilters.UserFilter.SearchType
            var searchTypeTemp: Int32 = 0
            guard let chatterParam = searchParameters.chatter else { return }
            if chatterParam.isWork {
                searchTypeTemp = searchTypeTemp | Int32(SearchType.unResigned.rawValue)
            }
            if chatterParam.isResigned {
                searchTypeTemp = searchTypeTemp | Int32(SearchType.resigned.rawValue)
            }
            en.entityFilter.userFilter.searchType = [searchTypeTemp]
            en.mergePolicy = .serverOnly
        }
    }
    
    var chatEntity: Search_V2_BaseEntity.EntityItem {
        makeEntity(type: .groupChat) { (en) in
            typealias SearchType = Search_V2_UniversalFilters.ChatFilter.SearchType
            en.mergePolicy = .serverOnly
            guard let chatParam = searchParameters.chat else { return }
            var searchTypeTemp: Int32 = 0
            if chatParam.isJoined {
                searchTypeTemp = searchTypeTemp | Int32(SearchType.joined.rawValue)
            }
            if chatParam.isNotJoined {
                searchTypeTemp = searchTypeTemp | Int32(SearchType.unJoined.rawValue)
            }
            if chatParam.isPublic {
                searchTypeTemp = searchTypeTemp | Int32(SearchType.public.rawValue)
            }
            if chatParam.isPrivate {
                searchTypeTemp = searchTypeTemp | Int32(SearchType.private.rawValue)
            }
            if chatParam.isInner {
                searchTypeTemp = searchTypeTemp | Int32(SearchType.unCrossTenant.rawValue)
            }
            if chatParam.isOuter {
                searchTypeTemp = searchTypeTemp | Int32(SearchType.crossTenant.rawValue)
            }
            en.entityFilter.groupChatFilter.searchTypes = [searchTypeTemp]
            if let creatorIds = chatParam.includeMemberIds,
               !creatorIds.isEmpty {
                en.entityFilter.groupChatFilter.chatMemberIds = creatorIds
            }
            
        }
    }
    
    func makeEntity(type: Search_V2_SearchEntityType, config: (inout Search_V2_BaseEntity.EntityItem) -> Void = { _ in }) -> Search_V2_BaseEntity.EntityItem {
        var en = Search_V2_BaseEntity.EntityItem()
        en.type = type
        en.mergePolicy = .serverOnly
        config(&en)
        return en
    }
}
