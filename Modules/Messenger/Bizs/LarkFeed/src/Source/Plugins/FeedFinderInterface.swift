//
//  FindeUnreadProtocal.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/7/20.
//

import Foundation
import RustPB

protocol FeedFinderInterface {
    func finder(item: FeedFinderItem) -> Bool
}

enum FeedFinderItemPosition {
    case tab(Feed_V1_FeedFilter.TypeEnum)
    case position(IndexPath)
}

protocol FeedFinderProviderInterface {
    func getFilterType() -> Feed_V1_FeedFilter.TypeEnum

    func getUnreadCount(type: Feed_V1_FeedFilter.TypeEnum) -> Int?

    func getMuteUnreadCount(type: Feed_V1_FeedFilter.TypeEnum) -> Int?

    func getAllItems() -> [[FeedFinderItem]]

    var isAtBottom: Bool { get }

    var defaultTab: Feed_V1_FeedFilter.TypeEnum { get }

    var getShowMute: Bool { get }
}

protocol FindUnreadDelegate: AnyObject {
    func preLoadNextItems()
}
