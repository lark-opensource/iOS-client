//
//  IMMentionSearchSourceMaker.swift
//  LarkIMMention
//
//  Created by Yuri on 2022/12/13.
//

import Foundation
import LarkContainer
import LarkRustClient
import LarkSDKInterface
import RustPB
import LarkSearchCore
import EEAtomic
import LarkSearchFilter
// MARK: - RustSearchSourceMaker
/// 负责创建一个调用底层Rust的Search Source. 兼容各个版本的Source和V2迁移
/// make方法可多次调用创建多个不同的source
public struct IMMentionSearchSourceMaker {
    @Injected var rustService: RustService

    public var scene: SearchSceneSection
    public var supportedFilters: [SearchFilter] = []

    public var session: SearchSession
    public var authPermissions: [RustPB.Basic_V1_Auth_ActionType] = []

    public var externalID: String?
    
    var searchParameters: IMMentionSearchParameters

    public var needSearchOuterTenant: Bool = true
    public var doNotSearchResignedUser: Bool = false
    public var inChatID: String?
    public var chatFilterMode: [ChatFilterMode]?
    /// calendar use, only true or nil, v2始终会带上这个标记
    public var includeMeetingGroup: Bool = true


    // 加在 commonFilter 中
    public var chatID: String?
    let userResolver: LarkContainer.UserResolver

    /// v1的local不太稳定，暂时只给历史遗留的使用。新代码迁移到v2, 不使用v1 local兜底了..
    public var v1LocalEnabled = true

    init(resolver: LarkContainer.UserResolver,
         scene: SearchSceneSection,
         parameters: IMMentionSearchParameters,
         session: SearchSession = SearchSession(),
         chatID: String? = nil) {
        self.userResolver = resolver
        self.chatID = chatID
        self.scene = scene
        self.session = session
        self.searchParameters = parameters
    }

    /// 现在临时用这个名字, 全量后再来调整方法名
    public func makeAndReturnProtocol() -> SearchSource {
        /// NOTE: 需要避免捕获self，外部可能动态改变config并创建新的source.
        /// 动态改config的需求通过request的context解决..
        var types: [Search_V2_BaseEntity.EntityItem] = []

        if let _ = searchParameters.chatter {
            types.append(userEntity)
            types.append(botEntity)
        }
        if let document = searchParameters.document {
            var docEntity = makeEntity(type: .doc)
            docEntity.entityFilter.docFilter.searchContentTypes = [.onlyTitle]
            docEntity.entitySelector.docSelector.relationTag = true
            var wikiSelector = Search_V2_UniversalSelectors.WikiSelector()
            wikiSelector.relationTag = true
            // 不设置，默认wiki不带ownerName，设置一下WikiSelector
            if let _ = searchParameters.document {
                wikiSelector.needOwner = true
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
                header.isForce = true
                header.searchContext.tagName = "CHAT_MENTION_SCENE"
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
            en.entitySelector.userSelector.relationTag = true
            en.mergePolicy = .serverOnly
//            inChatID.flatMap { inChatID in
//                en.entitySelector.userSelector.isInChatID = inChatID
//            }
        }
    }
    
    var botEntity: Search_V2_BaseEntity.EntityItem {
        makeEntity(type: .bot) { (en) in
            typealias SearchType = Search_V2_UniversalFilters.BotFilter.SearchType
            en.entityFilter.botFilter.searchType = [Int32(SearchType.all.rawValue)]
            en.entitySelector.userSelector.relationTag = true
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
