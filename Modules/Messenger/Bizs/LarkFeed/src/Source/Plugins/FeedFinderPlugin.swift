//
//  FeedFindUnreadPlugin.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/7/14.
//

import Foundation
import RustPB
import RxSwift
import LarkOpenFeed
import LarkContainer
import LarkModel
import LarkFeedBase

protocol FeedFinderItem {
    var isRemind: Bool { get }
    var unreadCount: Int { get }
}

final class UnMuteFinder: FeedFinderInterface {
    func finder(item: FeedFinderItem) -> Bool {
        return item.isRemind && item.unreadCount > 0
    }
}

final class MuteFinder: FeedFinderInterface {
    func finder(item: FeedFinderItem) -> Bool {
        return !item.isRemind && item.unreadCount > 0
    }
}

final class FeedFinderPlugin {
    weak var delegate: FindUnreadDelegate?
    init(delegate: FindUnreadDelegate) {
        self.delegate = delegate
    }

    func getNextUnreadFeedPosition(provider: FeedFinderProviderInterface, fromPosition: IndexPath, logInfo: inout [String: Any]) -> FeedFinderItemPosition? {
        let currentTab = provider.getFilterType()
        logInfo["nowFilter"] = currentTab
        logInfo["position"] = "position:" + String(fromPosition.row) + ",section:" + String(fromPosition.section)
        logInfo["isAtBottom"] = provider.isAtBottom
        logInfo["showTabMuteBadge"] = FeedBadgeBaseConfig.showTabMuteBadge
        logInfo["isShowMute"] = provider.getShowMute
        if let unreadCount = provider.getUnreadCount(type: currentTab) {
            logInfo["unreadCount"] = unreadCount
        }
        if let unreadCount = provider.getMuteUnreadCount(type: currentTab) {
            logInfo["muteUnreadCount"] = unreadCount
        }
        pullNextUnread(provider: provider, fromPosition: fromPosition)
        // todo:
        // 若当前列表中没有unmute但是消息列表中有unmute，
        // 理想状态下上双击一次tab就直接跳转至消息列表中的unmute消息，
        // 但是现在双击一次只能跳转至message，再次双击才能跳转至unmute消息
        // 当前分组中是否有没有定位到的unmute消息
        let hasRedBadgeInCurrentList = (provider.getUnreadCount(type: provider.defaultTab) ?? 0) > 0
        if hasRedBadgeInCurrentList {
            return getNextUnmuteFeed(provider: provider, fromPosition: fromPosition, isAtBottom: provider.isAtBottom)
        } else {
            return getNextMuteFeed(provider: provider, fromPosition: fromPosition, isAtBottom: provider.isAtBottom)
        }
    }

    private func getNextUnmuteFeed(provider: FeedFinderProviderInterface, fromPosition: IndexPath, isAtBottom: Bool) -> FeedFinderItemPosition? {
        let currentTab = provider.getFilterType()
        let state = FinderEngine.findNextUnread(provider.getAllItems(), fromPosition: fromPosition, finder: UnMuteFinder())
        switch state {
        case .found(let position): //有就跳转
            return .position(position)
        case .notFound:
            if currentTab == provider.defaultTab { // 如果在消息列表就循环找unmute消息
                return getFirstUnreadFeed(provider: provider, finder: UnMuteFinder())
            } else {
                // 跳转至消息列表
                return .tab(provider.defaultTab)
            }
        }
    }

    private func getFirstUnreadFeed(provider: FeedFinderProviderInterface, finder: FeedFinderInterface) -> FeedFinderItemPosition? {
        let position = IndexPath(row: FindUnreadConfig.firstFeed, section: 0)
        let state = FinderEngine.findNextUnread(provider.getAllItems(), fromPosition: position, finder: finder)
        switch state {
        case .found(let position):
            return .position(position)
        case .notFound:
            return nil
        }
    }

    private func getNextMuteFeed(provider: FeedFinderProviderInterface, fromPosition: IndexPath, isAtBottom: Bool) -> FeedFinderItemPosition? {
        let currentTab = provider.getFilterType()
        let hasGreyBadgeInCurrentList = (provider.getMuteUnreadCount(type: .inbox) ?? 0) > 0
        if hasGreyBadgeInCurrentList {
            let state = FinderEngine.findNextUnread(provider.getAllItems(), fromPosition: fromPosition, finder: MuteFinder(), isAtBottom: provider.isAtBottom)
            //当前列表中是否有mute未读
            switch state {
            case .found(let position): //有就跳转
                return .position(position)
            case .notFound:
                if !provider.getShowMute {
                    // 未开启免打扰分组，不向免打扰分组跳转
                    if currentTab == provider.defaultTab { //当前处于全部消息分组中，循环查找未读mute
                        return getFirstUnreadFeed(provider: provider, finder: MuteFinder())
                    } else { // 当前不处于全部消息分组中， 跳转至全部消息分组
                        return .tab(provider.defaultTab)
                    }
                } else if FeedBadgeBaseConfig.showTabMuteBadge { //开启免打扰分组
                    if let muteFilterBadge = provider.getMuteUnreadCount(type: .mute), muteFilterBadge > 0 {
                        if currentTab != .mute {
                            return .tab(.mute)
                        }
                    }
                }
            }
        }
        return .tab(provider.defaultTab)
    }

    //todo: rust接口需要明确，增加拉取未读的消息类型
    private func pullNextUnread(provider: FeedFinderProviderInterface, fromPosition: IndexPath) {
        var finder: FeedFinderInterface
        var filterType = provider.getFilterType()
        if let unreadCount = provider.getUnreadCount(type: filterType), unreadCount > 0 {
            finder = UnMuteFinder()
        } else if let unreadCount = provider.getMuteUnreadCount(type: filterType), unreadCount > 0 {
            finder = MuteFinder()
        } else {
            return
        }
        if FinderEngine.isNeedPullNextUnread(provider.getAllItems(), fromPosition: fromPosition, finder: finder) {
            if let delegate = self.delegate {
                delegate.preLoadNextItems()
            }
        }
    }
}
