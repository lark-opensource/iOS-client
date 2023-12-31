//
//  WebAppPrefixAuthStrategy.swift
//  EcosystemWeb
//
//  Created by xiangyuanyuan on 2021/11/2.
//

import ECOProbe
import ECOInfra
import WebBrowser
import LarkSetting
import LarkFeatureGating
import LKCommonsLogging


/// 染色的鉴权方案
public final class WebAppPrefixAuthStrategy: WebAppAuthStrategyProtocol {
    static let logger = Logger.ecosystemWebLog(WebAppPrefixAuthStrategy.self, category: "WebAppPrefixAuthStrategy")
    public let webAppAuthStrategyType: WebAppAuthStrategyType = .prefix
    public var countOfAuthRecords: Int = 0
    
    struct WebPageInfo {
        var webAppInfo: WebAppInfo
        let url: URL
    }
    
    // 染色鉴权的列表
    var prefixWebPageList: [WebPageInfo] = []
    
    private lazy var isOfflineWebAppConfigOptimize = {
            return FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webapp.offline.configoptimize"))// user:global
    }()
    
    // 根据前缀匹配 查找到跟当前webPage匹配的已鉴权的webPage并返回
    public func getPrefixWebPageIndex(currentWebPage: WKBackForwardListItem) -> Int? {
        let currentWebPageWithoutQueryAndFragment = currentWebPage.url.withoutQueryAndFragment
        // 逆序遍历鉴权数组
        for webPageIndex in 0 ..< prefixWebPageList.count {
            let reverseWebPageIndex = prefixWebPageList.count - webPageIndex - 1
            let webPage = prefixWebPageList[reverseWebPageIndex]
            if currentWebPageWithoutQueryAndFragment.hasPrefix(webPage.url.withoutQueryAndFragment) {
                return reverseWebPageIndex
            }
        }
        return nil
    }
    
    // 根据前缀匹配 将新鉴权的webPage加入到已鉴权的webAppList中
    public func addPrefixWebPage(webInfo: WebAppInfo, currentWebPageUrl: URL) {
        let webPageInfo = WebPageInfo(webAppInfo: webInfo, url: currentWebPageUrl)
        prefixWebPageList.append(webPageInfo)
        countOfAuthRecords = prefixWebPageList.count
    }
    
    public func update(iconKey: String, webBrowser: WebBrowser?) {
        if let info = getAppInfoForCurrentWebpage(webBrowser: webBrowser), let page = webBrowser?.webview.backForwardList.currentItem {
            info.iconKey = iconKey
            if let prefixWebPageIndex = getPrefixWebPageIndex(currentWebPage: page) {
                prefixWebPageList[prefixWebPageIndex].webAppInfo = info
            }
        }
    }
    
    // 更新webinfo的iconurl
    public func update(iconURL: String, appID: String, webBrowser: WebBrowser?) {
        for webPageInfo in prefixWebPageList {
            if webPageInfo.webAppInfo.id == appID {
                webPageInfo.webAppInfo.iconURL = iconURL
            }
        }
    }
    
    public func setWebAppInfo(info: WebAppInfo, webpage: WKBackForwardListItem?, webBrowser: WebBrowser?) -> Bool {
        if let webpage = webpage {
            if let browser = webBrowser, isWebBrowserInOfflineMode(browser: browser) {
                // 离线应用在免鉴权白名单，直接设置免鉴权
                var authOfflineAppWhiteList:[String] = []
                do {
                    authOfflineAppWhiteList = try SettingManager.shared.setting(with: Array<String>.self, key: UserSettingKey.make(userKeyLiteral: "WebAppApiAuthPassList"))// user:global
                } catch {
                    authOfflineAppWhiteList = []
                }
                var components = URLComponents()
                components.scheme = webpage.url.scheme
                components.host = webpage.url.host
                if isOfflineWebAppConfigOptimize, let url = components.url {
                    addPrefixWebPage(webInfo: info, currentWebPageUrl: url)
                } else if !authOfflineAppWhiteList.isEmpty,
                   authOfflineAppWhiteList.contains(info.id),
                   let url = components.url{
                    addPrefixWebPage(webInfo: info, currentWebPageUrl: url)
                } else {
                    addPrefixWebPage(webInfo: info, currentWebPageUrl: webpage.url)
                }
            } else {
                addPrefixWebPage(webInfo: info, currentWebPageUrl: webpage.url)
            }
            return true
        } else {
            let msg = "WebApp has no WebPage"
            assertionFailure(msg)
            Self.logger.error(msg)
            return false
        }
    }
    
    public func setWebAppInfo(info: WebAppInfo, url: URL, webBrowser: WebBrowser?) -> Bool {
        if let browser = webBrowser {
            if isWebBrowserInOfflineMode(browser: browser) {
                // 离线应用在免鉴权白名单，直接设置免鉴权
                var authOfflineAppWhiteList:[String] = []
                do {
                    authOfflineAppWhiteList = try SettingManager.shared.setting(with: Array<String>.self, key: UserSettingKey.make(userKeyLiteral: "WebAppApiAuthPassList"))
                } catch {
                    authOfflineAppWhiteList = []
                }
                var components = URLComponents()
                components.scheme = url.scheme
                components.host = url.host
                if isOfflineWebAppConfigOptimize, let url = components.url {
                    addPrefixWebPage(webInfo: info, currentWebPageUrl: url)
                } else if !authOfflineAppWhiteList.isEmpty,
                   authOfflineAppWhiteList.contains(info.id),
                   let url = components.url{
                    addPrefixWebPage(webInfo: info, currentWebPageUrl: url)
                } else {
                    addPrefixWebPage(webInfo: info, currentWebPageUrl: url)
                }
            } else {
                addPrefixWebPage(webInfo: info, currentWebPageUrl: url)
            }
        } else {
            Self.logger.error("browser is nil")
            return false
        }
        return true
    }
    
    public func getAppInfoForCurrentWebpage(webBrowser: WebBrowser?) -> WebAppInfo? {
        if let webPage = webBrowser?.webview.backForwardList.currentItem {
            if let prefixWebPageIndex = getPrefixWebPageIndex(currentWebPage: webPage) {
                return prefixWebPageList[prefixWebPageIndex].webAppInfo
            }
        }
        return nil
    }
    public func getFirstAppInfoOfAuthRecords(webBrowser: WebBrowser?) -> WebAppInfo? {
        guard prefixWebPageList.count > 0 else {
            Self.logger.error("WebApp has no auth records")
            return nil
        }
        guard let firstAppInfo = prefixWebPageList.first?.webAppInfo else {
            Self.logger.error("WebApp first auth record has no appInfo")
            return nil
        }
        return firstAppInfo
    }
    
    // 返回让当前页面染色的url
    public func getPrefixUrlForCurrentWebpage(webBrowser: WebBrowser?) -> URL? {
        if let webPage = webBrowser?.webview.backForwardList.currentItem, let prefixPageIndex = getPrefixWebPageIndex(currentWebPage: webPage) {
            return prefixWebPageList[prefixPageIndex].url
        }
        return nil
    }
    
    public func getAppInfoForFirstWebpage(webBrowser: WebBrowser?) -> WebAppInfo? {
        var backListFirst = webBrowser?.webview.backForwardList.backList.first != nil  ?  webBrowser?.webview.backForwardList.backList.first : webBrowser?.webview.backForwardList.currentItem
        if let backListFirst = backListFirst {
            if let prefixWebPageIndex = getPrefixWebPageIndex(currentWebPage: backListFirst) {
                return prefixWebPageList[prefixWebPageIndex].webAppInfo
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    private func isWebBrowserInOfflineMode(browser : WebBrowser) -> Bool {
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.offline.v2")) {// user:global
            if browser.resolve(OfflineResourceExtensionItem.self) != nil {
                return true
            }
        }
        if browser.resolve(WebOfflineExtensionItem.self) != nil {
            return true
        }
        if browser.resolve(FallbackExtensionItem.self) != nil {
            return true
        }
        if browser.configuration.resourceInterceptConfiguration != nil {
            return true
        }
        if browser.configuration.offline {
            return true
        }
        return false
    }
}
