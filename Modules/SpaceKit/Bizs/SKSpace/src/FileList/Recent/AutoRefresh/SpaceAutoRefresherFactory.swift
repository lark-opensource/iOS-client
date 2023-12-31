//
//  SpaceAutoRefresherFactory.swift
//  SKECM
//
//  Created by Weston Wu on 2020/7/28.
//

import Foundation
import SKCommon
import Swinject
import SKFoundation
import SKInfra

public protocol SpaceRefreshPresenter: AnyObject {
    func showRefreshTips(callback: @escaping () -> Void)
    func dismissRefreshTips(result: Result<Void, Error>)
}

protocol SpaceRefresherListProvider: AnyObject {
    var listEntries: [SpaceEntry] { get }
    func fetchCurrentList(size: Int, handler: @escaping SpaceListAutoRefresher.RefreshDataHandler)
}

struct SpaceAutoRefresherFactory {

    let resolver: Resolver

    func createRecentListRefresher(userID: String, listProvider: SpaceRefresherListProvider) -> SpaceListAutoRefresher {
        guard DocsConfigManager.isfetchFullDataOfSpaceList else {
            DocsLogger.info("recent.refresher.factory --- using empty impl in lean mode")
            return EmptyListAutoRefresher()
        }
        DocsLogger.info("recent.refresher.factory --- space new refresher is on, using native implementation")
        return SpaceRecentListAutoRefresher(listProvider: listProvider, refreshInterval: SpaceAutoRefresherFactory.remoteConfig.refreshInterval)
    }
}

extension SpaceAutoRefresherFactory {
    static var remoteConfig: SpaceRustPushConfig {
        guard let settingsConfig = SettingConfig.spaceRustPushConfig else {
            DocsLogger.info("recent.refresher.setting --- get settings failed, use default config")
            return .default
        }
        return settingsConfig
    }
}
