//
//  DocsWebViewV2+Ext.swift
//  SKUIKit
//
//  Created by lijuyou on 2023/7/12.
//

import SKFoundation
import WebKit

//_cancelTouchEventGestureRecognizer
private let cancelTouchEventMethod = "_cancelTouchEventGestureRecognizer"
//_killWebContentProcessAndResetState
private let killWebProcessMethod = "_killWebContentProcessAndResetState"
//_UISecondaryClickDriverGestureRecognizer
public let secondaryClickMethod = "_UISecondaryClickDriverGestureRecognizer"

extension DocsWebViewV2 {
    
    /// Cancel UIWebTouchEventsGestureRecognizer
    @discardableResult
    public func cancelWebTouchEventGestureRecognizer() -> Bool {
        let selector = NSSelectorFromString(cancelTouchEventMethod)
        if self.contentView?.responds(to: selector) ?? false {
            self.contentView?.perform(selector)
            return true
        }
        return false
    }
    
    @discardableResult
    public func killProcess() -> Bool {
        let selector = NSSelectorFromString(killWebProcessMethod)
        if self.responds(to: selector) {
            self.perform(selector)
            return true
        }
        return false
    }
    
    @discardableResult
    public func killNetworkProcess() -> Bool {
#if BETA || ALPHA || DEBUG
        if #available(iOS 15, *) {
            let selector = NSSelectorFromString("_terminateNetworkProcess")
            let websiteDataStore = self.configuration.websiteDataStore
            if websiteDataStore.responds(to: selector) {
                websiteDataStore.perform(selector)
                DocsLogger.warning("kill WebView Network Process")
                return true
            }
        }
#endif
        return false
    }
    
    @discardableResult
    public func killAllContentProcess() -> Bool {
#if BETA || ALPHA || DEBUG
        let selector = NSSelectorFromString("_terminateAllWebContentProcesses")
        let processPool = self.configuration.processPool
        if processPool.responds(to: selector) {
            let pid = processPool.perform(selector)
            DocsLogger.warning("kill All WebView Process")
            return true
        }
#endif
        return false
    }
    
    
    public class func clearWKCache(_ complete: ((Int) -> Void)?) {
        var count = 0
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) {
            records in
            count = records.count
            records.forEach { record in
                DocsLogger.info("WKWebsiteDataStore record: \(record)")
            }
        }
        DocsLogger.warning("WKWebsiteDataStore remove \(count) items")
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date(timeIntervalSince1970: 0)) {
            complete?(count)
        }
    }
}
