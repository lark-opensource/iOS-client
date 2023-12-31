//
//  LarkWebViewCache.swift
//  LarkWebViewContainer
//
//  Created by houjihu on 2020/8/13.
//

import Foundation
import WebKit
import ECOInfra

/// callback for load template webview
public typealias GetWebViewCallback = (LarkWebView) -> Void
/// WebView Pool
@objcMembers
final class LarkWebViewPool: NSObject {
    public static let shared = LarkWebViewPool()

    var subPoolMgrDic: [String: SubPoolManager] = [:]

    override private init() {
        assert(Thread.current.isMainThread)
        super.init()
    }

    /// Init your sub pool with a webview config and pool config
    /// - parameter webviewConfig: The config that use to create webview
    /// - parameter poolConfig: The config that defines how the pool works
    public func registerWebView(webviewConfig: LarkWebViewConfig, poolConfig: LarkWebviewPoolConfig) {
        assert(Thread.current.isMainThread)
        guard subPoolMgrDic[poolConfig.identifier] == nil else {
            OPError.error(monitorCode: PoolMonitorCode.registerExistingIdentifier)
            assertionFailure("existing_id")
            return
        }
        subPoolMgrDic[poolConfig.identifier] = SubPoolManager(config: webviewConfig, poolConfig: poolConfig)
    }

    /// Init your sub pool with a webview config and pool config
    /// - parameter webviewConfig: The config that use to create webview
    /// - parameter identifier: The id that binds with your sub pool
    public func updateWebViewConfig(webviewConfig: LarkWebViewConfig, identifier: String) {
        guard let subPoolMgr = subPoolMgrDic[identifier] else {
            OPError.error(monitorCode: PoolMonitorCode.identifierNotExist)
            return
        }
        let poolConfig = subPoolMgr.poolConfig
        unregisterWebView(identifier: identifier)
        registerWebView(webviewConfig: webviewConfig, poolConfig: poolConfig)
    }

    /// Unregister you sub pool in the webview pool, this function will also cleanup all the webview instances that bind with this identifier
    /// - parameter identifier: The id that binds with your sub pool
    public func unregisterWebView(identifier: String) {
        assert(Thread.current.isMainThread)
        subPoolMgrDic[identifier] = nil
    }

    /// Get a webview from the pool
    /// - parameter identifier: The id that binds with your sub pool
    /// - returns: A larkwebview instance
    public func dequeueWebView(identifier: String) -> LarkWebView? {
        assert(Thread.current.isMainThread)
        return subPoolMgrDic[identifier]?.dequeueWebView()
    }

    /// Get a template ready webview from the pool
    /// - parameter identifier: The id that binds with your sub pool
    public func dequeueTemplateReadyWebView(identifier: String, completion: @escaping GetWebViewCallback) {
        assert(Thread.current.isMainThread)
        guard let subPoolMgr = subPoolMgrDic[identifier] else {
            assertionFailure("must not dequeue webview before register")
            return
        }
        guard subPoolMgr.poolConfig is LarkWebviewRequestTemplatePoolConfig
            || subPoolMgr.poolConfig is LarkWebviewFileTemplatePoolConfig else {
            assertionFailure("type error in pool config")
            return
        }
        subPoolMgr.dequeueTemplateReadyWebView(completion: completion)
    }

    /// Reclaim the webview into the pool
    /// - parameter webview: The webview instance you want to reclaim
    /// - parameter identifier: The id that binds with your sub pool
    /// - returns: indicate that the instance is successfully reclaimed by pool or not
    @discardableResult
    public func reclaim(webview: LarkWebView, identifier: String) -> Bool {
        assert(Thread.current.isMainThread)
        guard let subPoolMgr = subPoolMgrDic[identifier] else { return false }
        subPoolMgr.reclaim(webview: webview)
        return true
    }

    /// Clean up the entire pool
    public func drainPool() {
        assert(Thread.current.isMainThread)
        subPoolMgrDic.removeAll()
    }
}
