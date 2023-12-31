//
//  SmartSearchSceneConfig.swift
//  LarkSearch
//
//  Created by SolaWing on 2021/1/5.
//

import UIKit
import Foundation
import LarkModel
import RustPB
import LarkMessengerInterface
import LarkSDKInterface
import LarkAccountInterface
import LarkSearchCore
import LKCommonsLogging
import LarkContainer

struct SmartSearchSceneConfig: SearchSceneConfig {
    static let logger = Logger.log(SmartSearchSceneConfig.self, category: "Module.IM.Search")
    var searchScene: SearchSceneSection { .rustScene(.smartSearch) }
    var searchDisplayTitle: String { "" }
    var searchDisplayImage: UIImage? { nil }
    var searchLocation: String { "smart" }
    var newSearchLocation: String { "quick_search" }

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    /// 对应场景是否包含对应类型的model，用于去重
    func isScene(_ scene: SearchSceneSection, include model: SearchResultType, botInApp: Bool) -> Bool {
        switch model.type {
        case .chatter, .cryptoP2PChat, .shieldP2PChat, .bot:
            if botInApp, case let .chatter(meta) = model.meta, meta.type == .bot {
                return scene == .rustScene(.searchOpenAppScene)
            }
            return scene == .rustScene(.searchChatters)
        case .chat:
            return ([.rustScene(.searchChats), .searchThreadOnly, .searchChatOnly] as Set).contains(scene)
        case .thread:
            return ([.rustScene(.searchThreadScene), .searchTopicInAdvanceOnly, .searchTopicOnly] as Set).contains(scene)
        case .message:
            return ([.rustScene(.searchMessages), .searchMessageOnly] as Set).contains(scene)
        case .oncall:
            return scene == .rustScene(.searchOncallScene)
        case .openApp:
            return scene == .rustScene(.searchOpenAppScene)
        case .doc:
            return scene == .rustScene(.searchDoc)
        case .wiki:
            return scene == .rustScene(.searchDoc)
        case .box:
            return scene == .rustScene(.searchBoxScene)
        case .external:
            return scene == .rustScene(.searchExternalScene)
        default:
            return false
        }
    }

    func handler(model: SearchResultType) -> MainSearchCellFactory? {
        switch model.type {
        case .chatter, .cryptoP2PChat, .shieldP2PChat, .bot:
            // FIXME: bot使用AppSearchViewModelFactory
            return ChatterSearchViewModelFactory(userResolver: userResolver)
        case .chat:
            return CommonChatSearchViewModelFactory(userResolver: userResolver)
        case .thread:
            return CommonTopicSearchViewModelFactory(userResolver: userResolver)
        case .message:
            return CommonMessageSearchViewModelFactory(userResolver: userResolver)
        case .oncall:
            return OncallSearchViewModelFactory(userResolver: userResolver)
        case .openApp:
            return AppSearchViewModelFactory(userResolver: userResolver)
        case .doc:
            return DocsSearchViewModelFactory(userResolver: userResolver, source: .main)
        case .wiki:
            return WikiSearchViewModelFactory(userResolver: userResolver)
        case .box:
            return BoxSearchViewModelFactory(userResolver: userResolver)
        case .external:
            return ExternalSearchViewModelFactory(userResolver: userResolver)
        case .QACard:
            return ServiceCardSearchViewModelFactory(userResolver: userResolver)
        case .customization:
            return ServiceCardSearchViewModelFactory(userResolver: userResolver)
        case .link:
            return URLSearchViewModelFactory(userResolver: userResolver, chatMode: .unlimited)
        case .slashCommand:
            return OpenSearchSceneConfig(userResolver: userResolver, info: SearchTab.OpenSearch(id: "", label: "", icon: nil, resultType: .slashCommand, filters: []))
        case .openSearchJumpMore:
            return OpenSearchJumpViewModelFactory(userResolver: userResolver)
        default:
            return nil
        }
    }

    func delegateFactory(model: SearchResultType) -> MainSearchCellFactory {
        if let v = handler(model: model) { return v }

        assertionFailure("unreachable code!!")
        Self.logger.error("unreachable code!!")
        return ChatterSearchViewModelFactory(userResolver: userResolver)
    }

    func createViewModel(searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        delegateFactory(model: searchResult).createViewModel(searchResult: searchResult, context: context)
    }

    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        delegateFactory(model: item.searchResult).cellType(for: item)
    }

    var recommendFilterTypes: [FilterInTab] { return [.smartUser] }
}
