//
//  WebAppContainerAuthStrategy.swift
//  EcosystemWeb
//
//  Created by xiangyuanyuan on 2021/11/2.
//

import ECOProbe
import ECOInfra
import WebBrowser
import LKCommonsLogging

/// 容器级别的鉴权方案
public final class WebAppContainerAuthStrategy: WebAppAuthStrategyProtocol {
    static let logger = Logger.ecosystemWebLog(WebAppContainerAuthStrategy.self, category: "WebAppContainerAuthStrategy")
    public var webAppAuthStrategyType: WebAppAuthStrategyType = .container
    public var countOfAuthRecords = 0
    
    public func update(iconKey: String, webBrowser: WebBrowser?) {
        if let info = getAppInfoForCurrentWebpage(webBrowser: webBrowser) {
            info.iconKey = iconKey
            addWebAppInfoToWebBrowser(webBrowser: webBrowser, webAppInfo:info)
        }
    }
    
    public func update(iconURL: String, appID: String, webBrowser: WebBrowser?) {
        if let info = getAppInfoForCurrentWebpage(webBrowser: webBrowser) {
            info.iconURL = iconURL
            addWebAppInfoToWebBrowser(webBrowser: webBrowser, webAppInfo:info)
        }
    }
    
    public func setWebAppInfo(info: WebAppInfo, webpage: WKBackForwardListItem?, webBrowser: WebBrowser?) -> Bool {
        if let browser = webBrowser {
            var currentWebpageAppInfo = getAppInfoForCurrentWebpage(webBrowser: webBrowser)
            if currentWebpageAppInfo == nil {
                countOfAuthRecords = countOfAuthRecords + 1
                addWebAppInfoToWebBrowser(webBrowser: browser, webAppInfo:info)
                return true
            } else if currentWebpageAppInfo?.apiAuthenStatus == .notDetermined && info.apiAuthenStatus == .authened {
                // 若鉴权通过 只更新当前容器AppInfo的鉴权状态 不更新AppInfo的其他数据
                currentWebpageAppInfo?.apiAuthenStatus = .authened
                addWebAppInfoToWebBrowser(webBrowser: browser, webAppInfo: currentWebpageAppInfo)
            }
            return false
        } else{
            let msg = "WebApp has no WebBrowser"
            assertionFailure(msg)
            Self.logger.error(msg)
            return false
        }
    }
    
    public func setWebAppInfo(info: WebAppInfo, url: URL, webBrowser: WebBrowser?) -> Bool {
        return setWebAppInfo(info: info, webpage: nil, webBrowser: webBrowser)
    }
    
    public func getAppInfoForCurrentWebpage(webBrowser: WebBrowser?) -> WebAppInfo? {
        if let browser = webBrowser {
            return getWebAppInfoFromWebBrowser(webBrowser: browser)
        }
        return nil
    }
    
    public func getFirstAppInfoOfAuthRecords(webBrowser: WebBrowser?) -> WebAppInfo? {
        if let browser = webBrowser {
            return getWebAppInfoFromWebBrowser(webBrowser: browser)
        }
        return nil
    }
    
    public func getAppInfoForFirstWebpage(webBrowser: WebBrowser?) -> WebAppInfo? {
        if let browser = webBrowser {
            return getWebAppInfoFromWebBrowser(webBrowser: browser)
        }
        return nil
    }
    
    func addWebAppInfoToWebBrowser(webBrowser: WebBrowser?, webAppInfo: WebAppInfo?){
        objc_setAssociatedObject(webBrowser, &webAppObjcKey, webAppInfo, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func getWebAppInfoFromWebBrowser(webBrowser: WebBrowser?) -> WebAppInfo? {
        objc_getAssociatedObject(webBrowser, &webAppObjcKey) as? WebAppInfo
    }
}
