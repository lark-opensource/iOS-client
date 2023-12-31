//
//  OfflineResourceURLProtocol.swift
//  WebBrowser
//
//  Created by yinyuan on 2022/1/17.
//

import Foundation
import LKCommonsLogging
import Foundation

private let logger = Logger.webBrowserLog(OfflineResourceURLProtocol.self, category: "OfflineResourceURLProtocol")

/**
 离线化Web应用请求拦截
 只适用于WebBrowser离线化URLProtocol mpass方案
 */
public final class OfflineResourceURLProtocol: URLProtocol {
    
    override public class func canInit(with request: URLRequest) -> Bool {
        guard let userAgent = userAgentFromURLRequest(request: request) else {
            return false
        }
        guard let browserID = browserIDFromUserAgent(userAgent: userAgent) else {
            return false
        }
        guard let browser = browserFromBrowserID(browserID: browserID) else {
            return false
        }
        guard let delegate = browser.extensionManager.resolve(OfflineResourceExtensionItem.self)?.delegate else {
            return false
        }
        return delegate.browserCanIntercept(browser: browser, request: request)
    }
    
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override public func startLoading() {
        guard let userAgent = OfflineResourceURLProtocol.userAgentFromURLRequest(request: request) else {
            return
        }
        guard let browserID = OfflineResourceURLProtocol.browserIDFromUserAgent(userAgent: userAgent) else {
            return
        }
        guard let browser = OfflineResourceURLProtocol.browserFromBrowserID(browserID: browserID) else {
            return
        }
        guard let delegate = browser.extensionManager.resolve(OfflineResourceExtensionItem.self)?.delegate else {
            return
        }
        delegate.browserFetchResources(browser: browser, request: request) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let responseAndData):
                self.client?.urlProtocol(self, didReceive: responseAndData.0, cacheStoragePolicy: .notAllowed)
                self.client?.urlProtocol(self, didLoad: responseAndData.1)
                self.client?.urlProtocolDidFinishLoading(self)
            case .failure(let error):
                self.client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }
    
    override public func stopLoading() {
        //  do nothing
    }
}

extension OfflineResourceURLProtocol {
    
    private static func userAgentFromURLRequest(request: URLRequest) -> String? {
        return request.allHTTPHeaderFields?["User-Agent"] ?? request.allHTTPHeaderFields?["user-agent"]
    }
    
    private static func browserIDFromUserAgent(userAgent: String) -> String? {
        var browserID: String?
        userAgent.split(separator: " ").forEach {
            if $0.contains(LKBrowserIdentifier) {
                let result = $0.split(separator: "/")
                if (result.count == 2) {
                    browserID = String(result[1])
                }
            }
        }
        return browserID
    }
    
    private static func browserFromBrowserID(browserID: String) -> WebBrowser? {
        return OfflineResourceURLProtocolManager.shared.offlineBrowser(by: browserID)
    }
}
