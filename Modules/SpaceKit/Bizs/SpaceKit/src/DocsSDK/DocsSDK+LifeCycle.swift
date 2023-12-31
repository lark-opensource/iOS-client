//
//  DocsSDK+LifeCycle.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/7/20.
//  


import Foundation
import SKCommon
import SKSpace
import SKBrowser
import SKFoundation
import SKInfra

// MARK: - LifeCycle

extension DocsSDK: LifeCycle {
    public func willEnterForeground(_ notify: NSNotification) {
        SpaceNoticeHandler.shared.handleAppWillEnterForeground()
        resolver.resolve(ManuOfflineRNWatcherAPI.self)?.isInForground = true
        resolver.resolve(DocsOfflineSyncManager.self)?.isInForground = true
        DocGlobalTimer.shared.resume()
    }
    public func appDidBecomeActive(_ notify: NSNotification) {
        let isUsingProxy = NetUtil.shared.isUsingProxyFor(OpenAPI.docs.baseUrl)
        if isUsingProxy {
            DocsTracker.shared.forbiddenTrackerReason.insert(.useSystemProxy)
        } else {
            DocsTracker.shared.forbiddenTrackerReason.remove(.useSystemProxy)
        }
        DocsLogger.info("isUsing proxy: \(isUsingProxy)", component: LogComponents.net)
        EditorManager.shared.appDidBecomeActive(notify)
    }

    public func appDidEnterBackground(_ notify: NSNotification) {
        EditorManager.shared.appDidEnterBackground(notify)
        resolver.resolve(ManuOfflineRNWatcherAPI.self)?.isInForground = false
        resolver.resolve(DocsOfflineSyncManager.self)?.isInForground = false
        DocGlobalTimer.shared.pause()
    }

    public func appDidReceiveMemoryWarning(_ notify: NSNotification) {
        EditorManager.shared.appdidReceiveMemoryWarning(notify)
    }
}
