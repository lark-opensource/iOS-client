//
//  WebAppWebPageAuthStrategy.swift
//  EcosystemWeb
//
//  Created by xiangyuanyuan on 2021/11/2.
//

import ECOProbe
import ECOInfra
import WebBrowser
import LKCommonsLogging


/// webPage级别的鉴权方案
public final class WebAppWebPageAuthStrategy: WebAppAuthStrategyProtocol {
    static let logger = Logger.ecosystemWebLog(WebAppWebPageAuthStrategy.self, category: "WebAppWebPageAuthStrategy")
    public let webAppAuthStrategyType: WebAppAuthStrategyType = .url
    public var countOfAuthRecords = 0
    
    public func update(iconKey: String, webBrowser: WebBrowser?) {
        if let info = getAppInfoForCurrentWebpage(webBrowser: webBrowser), let page = webBrowser?.webview.backForwardList.currentItem {
            info.iconKey = iconKey
            if(objc_getAssociatedObject(page, &webAppObjcKey) == nil){
                countOfAuthRecords = countOfAuthRecords + 1
            }
            addWebAppInfoToWebPage(webPage: page, webAppInfo: info)
        }
    }
    
    // 更新webinfo的iconurl
    public func update(iconURL: String, appID: String, webBrowser: WebBrowser?) {
        if let info = getAppInfoForCurrentWebpage(webBrowser: webBrowser), let page = webBrowser?.webview.backForwardList.currentItem {
            info.iconURL = iconURL
            if(objc_getAssociatedObject(page, &webAppObjcKey) == nil){
                countOfAuthRecords = countOfAuthRecords + 1
            }
            addWebAppInfoToWebPage(webPage: page, webAppInfo: info)
        }
    }
    
    public func setWebAppInfo(info: WebAppInfo, webpage: WKBackForwardListItem?, webBrowser: WebBrowser?) -> Bool {
        if let webpage = webpage {
            addWebAppInfoToWebPage(webPage: webpage, webAppInfo: info)
            return true
        } else{
            let msg = "WebApp has no WebPage"
            assertionFailure(msg)
            Self.logger.error(msg)
            return false
        }
    }
    
    public func setWebAppInfo(info: WebAppInfo, url: URL, webBrowser: WebBrowser?) -> Bool {
        return false
    }
    
    public func getAppInfoForCurrentWebpage(webBrowser: WebBrowser?) -> WebAppInfo? {
        if let webPage = webBrowser?.webview.backForwardList.currentItem {
            return getWebAppInfoFromWebPage(webPage: webPage)
        }
        return nil
    }
    
    public func getFirstAppInfoOfAuthRecords(webBrowser: WebBrowser?) -> WebAppInfo? {
        return nil
    }
    
    public func getAppInfoForFirstWebpage(webBrowser: WebBrowser?) -> WebAppInfo? {
        var backListFirst = webBrowser?.webview.backForwardList.backList.first != nil  ?  webBrowser?.webview.backForwardList.backList.first : webBrowser?.webview.backForwardList.currentItem
        if let backListFirst = backListFirst {
            return getWebAppInfoFromWebPage(webPage: backListFirst)
        } else {
            return nil
        }
    }
    
    func addWebAppInfoToWebPage(webPage: WKBackForwardListItem?, webAppInfo: WebAppInfo?){
        objc_setAssociatedObject(webPage, &webAppObjcKey, webAppInfo, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func getWebAppInfoFromWebPage(webPage: WKBackForwardListItem?) -> WebAppInfo? {
        objc_getAssociatedObject(webPage, &webAppObjcKey) as? WebAppInfo
    }
}
