//
//  WAContainerPreloader.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/22.
//

import SKFoundation
import WebKit
import LarkWebViewContainer
import LKCommonsLogging
import RunloopTools
import LarkContainer


/// 容器预加载
public final class WAContainerPreloader {
    static let logger = Logger.log(WAContainerPreloader.self, category: WALogger.TAG)
    private var waitingPreloadTask = Set<String>()
    private let userResolver: UserResolver
    let pool = ContainerPool()
    
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    /// 尝试预加载容器
    /// 时机：CPU闲时
    /// 数量：目前每个业务最多只支持一个
    public func tryPreload(for config: WebAppConfig, userResolver: UserResolver) {
        guard !MobileClassify.isLow else {
            Self.logger.info("cannot preload in low device, \(config.appName)", tag: LogTag.open.rawValue)
            return
        }
        DispatchQueue.safetyAsyncMain { [weak self] in
            guard let self else { return }
            if self.waitingPreloadTask.contains(config.appName) {
                Self.logger.info("preload task is waiting, \(config.appName)", tag: LogTag.open.rawValue)
                return
            }
            self.waitingPreloadTask.insert(config.appName)
            Self.logger.info("add preload task for:\(config.appName)", tag: LogTag.open.rawValue)
            RunloopDispatcher.shared.addTask(priority: .medium) { [weak self] in
                Self.logger.info("start preload task for:\(config.appName)", tag: LogTag.open.rawValue)
                self?.preloadIfNeed(for: config, userResolver: userResolver)
                self?.waitingPreloadTask.remove(config.appName)
            }.waitCPUFree()
        }
    }
    
    private func preloadIfNeed(for config: WebAppConfig, userResolver: UserResolver) {
        Self.logger.info("try preload for \(config.appName)")
        if pool.getItem(for: config.appName) != nil {
            Self.logger.info("already has a cacheWebView", tag: LogTag.open.rawValue)
            return
        }
        guard let containerView = createPreloadContainer(for: config, userResolver: userResolver) else {
            return
        }
        pool.pushToPool(containerView)
        pool.setItem(containerView, for: config.appName)
        Self.logger.info("cache webview finish:\(config.appName)", tag: LogTag.open.rawValue)
    }
    
    
    func createPreloadContainer(for config: WebAppConfig, userResolver: UserResolver) -> WAContainerView? {
        guard let preloadConfig = config.preloadConfig, preloadConfig.policy != .none else {
            Self.logger.info("disable prelad by policy", tag: LogTag.open.rawValue)
            return nil
        }
        let containerView = WAContainerView(frame: .zero, config: config, userResolver: userResolver)
        switch preloadConfig.policy {
        case .preloadBlank:
            Self.logger.info("start preload blank html webview", tag: LogTag.open.rawValue)
            containerView.webview.loadHTMLString(Self.blankHtml, baseURL: nil)
        case .preloadTemplate:
            Self.logger.info("start preload Template webview", tag: LogTag.open.rawValue)
            containerView.viewModel.preloadTemplate()
        default:
            return nil
        }
        return containerView
    }
    
    /// 获取一个可用的容器
    /// - Parameters:
    ///   - config: 配置
    ///   - mustPreload: 如果没有可用的，是否预加载后返回一个
    func getAvailableContainer(for config: WebAppConfig,
                                      userResolver: UserResolver,
                                      mustPreload: Bool = false) -> WAContainerView? {
        if !Thread.isMainThread {
            spaceAssertionFailure("must call in mainthread")
            return nil
        }
        var availableContainer: WAContainerView?
        if let cacheItem = pool.getItem(for: config.appName) {
            if cacheItem.canResue {
                Self.logger.info("hit cache and get a resuable item", tag: LogTag.open.rawValue)
                availableContainer = cacheItem
            } else {
                Self.logger.info("item isn't resuable", tag: LogTag.open.rawValue)
                if mustPreload {
                    Self.logger.info("preload newItem and return", tag: LogTag.open.rawValue)
                    availableContainer = createPreloadContainer(for: config, userResolver: userResolver)
                }
            }
        } else {
            if mustPreload {
                Self.logger.info("preload and add To cache", tag: LogTag.open.rawValue)
                preloadIfNeed(for: config, userResolver: userResolver)
                availableContainer = pool.getItem(for: config.appName)
            }
        }
      
        if let availableContainer {
            pool.popFromPool(availableContainer)
        } else {
            Self.logger.info("has no avaliable item", tag: LogTag.open.rawValue)
        }
        return availableContainer
    }
}

extension WAContainerPreloader {
    class func checkCookieFor(_ url: String, checkCookies: [String]?) -> Bool {
        guard let checkCookies = checkCookies, !checkCookies.isEmpty else {
            return true //为空不用检查cookies
        }
        if let url = URL(string: url),
           let cookies = HTTPCookieStorage.shared.cookies(for: url) {
            let containKeyCookie =  checkCookies.allSatisfy({ cName in
                var hasCookie = false
                for cookie in cookies {
                    if cookie.name == cName, !cookie.value.isEmpty {
                        hasCookie = true
                        break
                    }
                }
                Self.logger.info("check cookie \(cName):\(hasCookie)", tag: LogTag.open.rawValue)
                return hasCookie
            })
            return containKeyCookie
        }
        return false
    }
    
    private static let blankHtml = """
    <!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"><title></title></head><body></body></html>
    """
}
