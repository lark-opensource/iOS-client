//
//  ContainerPool.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/12/6.
//

import SKFoundation
import WebKit
import LarkWebViewContainer
import LKCommonsLogging
import RunloopTools
import LarkContainer

public final class ContainerPool {
    static let logger = Logger.log(ContainerPool.self, category: WALogger.TAG)
    private var cacheWebViewMap = [String: WAContainerView]()
    
    public init() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarning(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    @objc
    func didReceiveMemoryWarning(_ notify: NSNotification) {
        Self.logger.info("preload didReceiveMemoryWarning")
        self.clear()
    }
    
    func getItem(for appName: String) -> WAContainerView? {
        return self.cacheWebViewMap[appName]
    }
    
    func setItem(_ item: WAContainerView?, for appName: String) {
        Self.logger.info("update cache item for \(appName), \(item?.identifier ?? "")", tag: LogTag.open.rawValue)
        self.cacheWebViewMap[appName] = item
    }
    
    func removeItem(for appName: String) {
        Self.logger.info("remove webview cache,\(appName)", tag: LogTag.open.rawValue)
        cacheWebViewMap[appName] = nil
    }
    
    func clear() {
        Self.logger.info("clear webview cache", tag: LogTag.open.rawValue)
        cacheWebViewMap.removeAll()
    }
    
    func popFromPool(_ item: WAContainerView) {
        Self.logger.info("popFromPool, \(item.identifier)")
        item.increaseUseCount()
        item.inPool = false
        item.stopCheckAlive()
    }
    
    @discardableResult
    func pushToPool(_ item: WAContainerView) -> Bool {
        guard item.viewModel.config.supportWebViewReuse else {
            Self.logger.info("not support WebView Reuse, \( item.appName)")
            return false
        }
        if cacheWebViewMap[item.appName] != nil, cacheWebViewMap[item.appName] !== item {
            Self.logger.info("pushToPool failed, pool already has item:\(cacheWebViewMap[item.appName]?.identifier ?? ""), \(item.identifier)")
            return false
        }
        let maxReuseTimes = item.viewModel.config.maxReuseTimes
        if item.usedCount >= item.viewModel.config.maxReuseTimes {
            Self.logger.info("pushToPool failed,reach maxReuseTimes, \(item.identifier)")
            self.removeItem(for: item.appName)
            return false
        }
        Self.logger.info("pushToPool ok, (\(item.usedCount)/\(maxReuseTimes)) \(item.identifier)")
        item.inPool = true
        item.startCheckAlive()
        return true
    }
    
    func destoryFromPool(_ item: WAContainerView) {
        if cacheWebViewMap[item.appName] === item {
            Self.logger.info("destoryFromPool ok, \(item.appName), \(item.identifier)")
            cacheWebViewMap.removeValue(forKey: item.appName)
        } else {
            Self.logger.info("destoryFromPool but not in cache, \(item.appName), \(item.identifier)")
        }
    }
}
