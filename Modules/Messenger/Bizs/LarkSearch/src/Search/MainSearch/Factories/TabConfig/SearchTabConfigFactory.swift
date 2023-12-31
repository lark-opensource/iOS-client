//
//  SearchTabConfigFactory.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/7/13.
//

import Foundation
import LarkMessengerInterface
import LarkContainer

public final class SearchTabConfigFactory {
    static func createConfig(resolver: LarkContainer.UserResolver,
                             tab: SearchTab,
                             sourceOfSearch: SourceOfSearch) -> SearchTabConfigurable? {
        switch tab {
        case .main:
            return SearchMainTopResultsTabConfig(resolver: resolver, sourceOfSearch: sourceOfSearch, tab: tab)
        case .message:
            return SearchMainMessageTabConfig(chatMode: .unlimited, tab: tab)
        case .doc:
            return SearchMainDocTabConfig(tab: tab)
        case .app:
            return SearchMainAppTabConfig(resolver: resolver, tab: tab)
        case .chatter:
            return SearchMainChatterTabConfig(tab: tab)
        case .chat:
            return SearchMainChatTabConfig(chatMode: .unlimited, tab: tab)
        case .oncall:
            return SearchOncallTabConfig(tab: tab)
        case let .open(openSearch):
            return SearchOpenTabConfig(info: openSearch, tab: tab)
        default:
            return nil
        }
    }
}
