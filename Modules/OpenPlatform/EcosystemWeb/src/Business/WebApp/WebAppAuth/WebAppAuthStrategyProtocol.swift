//
//  WebAppAuthStrategyProtocol.swift
//  EcosystemWeb
//
//  Created by xiangyuanyuan on 2021/11/2.
//

import ECOProbe
import ECOInfra
import WebBrowser
import LKCommonsLogging

/// 鉴权方案需要依赖的协议
public protocol WebAppAuthStrategyProtocol: AnyObject {
    
    // 鉴权策略
    var webAppAuthStrategyType: WebAppAuthStrategyType { get }
    // 鉴权缓存中记录数量
    var countOfAuthRecords: Int { get set }
    
    // 更新webinfo的icon
    func update(iconKey: String, webBrowser: WebBrowser?)
    
    // 更新webinfo的iconurl
    func update(iconURL: String, appID: String, webBrowser: WebBrowser?)
    
    // 在页面中绑定webAppInfo（可能绑定在webBrowser或者绑定在webPage）返回布尔值判断webAppInfo是否更新
    func setWebAppInfo(info: WebAppInfo, webpage: WKBackForwardListItem?, webBrowser: WebBrowser?) -> Bool
    
    // 在页面中绑定webAppInfo（可能绑定在webBrowser或者绑定在webPage）返回布尔值判断webAppInfo是否更新
    func setWebAppInfo(info: WebAppInfo, url: URL, webBrowser: WebBrowser?) -> Bool
    
    // 获取当前页面对应的webAppInfo
    func getAppInfoForCurrentWebpage(webBrowser: WebBrowser?) -> WebAppInfo?
    
    // 获取网页容器鉴权缓存中的首个webAppInfo
    func getFirstAppInfoOfAuthRecords(webBrowser: WebBrowser?) -> WebAppInfo?
    
    // 获取网页容器中某个webpage的webappinfo
    func getAppInfoForFirstWebpage(webBrowser: WebBrowser?) -> WebAppInfo?
}
