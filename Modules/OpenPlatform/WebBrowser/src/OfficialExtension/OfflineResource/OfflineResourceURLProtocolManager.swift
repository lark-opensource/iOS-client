//
//  OfflineResourceURLProtocolManager.swift
//  WebBrowser
//
//  Created by yinyuan on 2022/1/17.
//

import LarkWebViewContainer
import LKCommonsLogging
import Foundation

/**
 Web 离线化 URLProtocol 拦截管理器
 请在主线程调用
 */
final public class OfflineResourceURLProtocolManager {
    
    private class WeakWebBrowser {
        private(set) weak var value : WebBrowser?
        init (value: WebBrowser) {
            self.value = value
        }
    }
    
    static let logger = Logger.webBrowserLog(OfflineResourceURLProtocolManager.self, category: "OfflineResourceURLProtocolManager")
    
    /// 开启离线化业务的browser列表
    private var offlineBrowsers = [String: WeakWebBrowser]()
    
    /// 单例
    static let shared = OfflineResourceURLProtocolManager()
    
    /// 单例
    private init() {}
    
    /// 请在主线程调用。请使用方保障调用了start后一定要在准确时机调用stop，千万不要调用了start而不调用stop，否则需要revert代码，写case study，做复盘，承担事故责任
    func startOffline(with browser: WebBrowser) {
        assert(Thread.isMainThread, "please use OfflineResourceURLProtocolManager in main thread")
        let browserID = browser.configuration.webBrowserID
        guard !offlineBrowsers.keys.contains(browserID) else {
            Self.logger.info("has marked \(browserID) offline")
            return
        }
        if offlineBrowsers.isEmpty {
            Self.logger.info("offlineItemIDSet is empty, start register URLProtocol open ajax/fetch hook, and mark \(browserID) start offline")
            LarkWebView.register(scheme: "http")
            LarkWebView.register(scheme: "https")
            URLProtocol.registerClass(OfflineResourceURLProtocol.self)
            URLProtocol.registerClass(BodyRecoverURLProtocol.self)
            ajaxFetchHookFG = true
        } else {
            Self.logger.info("offlineItemIDSet is not empty, mark \(browserID) start offline")
        }
        offlineBrowsers[browserID] = WeakWebBrowser(value: browser)
    }
    
    /// 请在主线程调用
    func stopOffline(with browserID: String) {
        assert(Thread.isMainThread, "please use OfflineResourceURLProtocolManager in main thread")
        guard offlineBrowsers.keys.contains(browserID) else {
            Self.logger.info("offlineItemIDSet not contains \(browserID)")
            return
        }
        offlineBrowsers.removeValue(forKey: browserID)
        if offlineBrowsers.isEmpty {
            Self.logger.info("offlineItemIDSet is empty, unregister URLProtocol close ajax/fetch hook, and mark \(browserID) stop offline")
            LarkWebView.unregister(scheme: "http")
            LarkWebView.unregister(scheme: "https")
            URLProtocol.unregisterClass(OfflineResourceURLProtocol.self)
            URLProtocol.unregisterClass(BodyRecoverURLProtocol.self)
            ajaxFetchHookFG = false
        } else {
            Self.logger.info("offlineItemIDSet is not empty, mark \(browserID) stop offline")
        }
    }
    
    func offlineBrowser(by browserID: String) -> WebBrowser? {
        return offlineBrowsers[browserID]?.value
    }
}

