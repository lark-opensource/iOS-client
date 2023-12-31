//
//  EcosystemWebDependency.swift
//  EcosystemWeb
//
//  Created by 新竹路车神 on 2021/9/4.
//

import LarkContainer
import LKLoadable
import WebBrowser

public protocol EcosyetemWebDependencyProtocol {
    // code from yiying
    /// 获取网页应用带Api授权机JSSDK
    /// - Parameters:
    ///   - appId: 应用ID
    ///   - apiHost: api实现方
    func getWebAppJsSDKWithAuthorization(appId: String, apiHost: WebBrowser) -> WebAppApiAuthJsSDKProtocol?
    /// 获取网页应用不带Api授权机JSSDK
    /// - Parameters:
    ///   - apiHost: api实现方
    func getWebAppJsSDKWithoutAuthorization(apiHost: WebBrowser) -> WebAppApiNoAuthProtocol?
    
    func appInfoForCurrentWebpage(browser: WebBrowser) -> WebAppInfo?
    
    func registerBusinessExtensions(browser: WebBrowser)
    
    func offlineEnable() -> Bool
    
    func generateWebAppLink(targetUrl: String, appId: String) -> URL?
    
    // 生成定制化的网页应用applink，targetUrl中的path、查询参数和fragment将被写入到新生成的applink中，目前是给离线应用使用，在线应用推荐使用generateWebAppLink
    func generateCustomPathWebAppLink(targetUrl: String, appId: String) -> URL?
    
    /// 发送到会话
    func shareH5(webVC: WebBrowser)
    /// 当前容器是否为网页应用离线模式
    func isOfflineMode(browser: WebBrowser) -> Bool
}

class EcosyetemWebDpInternal {
    static let shared = EcosyetemWebDpInternal()
    @Provider var dp: EcosyetemWebDependencyProtocol
    private init() {}
}

var ecosyetemWebDependency: EcosyetemWebDependencyProtocol! {
    EcosyetemWebDpInternal.shared.dp
}
