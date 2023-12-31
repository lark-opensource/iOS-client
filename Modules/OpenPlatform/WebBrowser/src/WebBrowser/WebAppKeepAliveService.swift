//
//  WebAppKeepAliveProtocol.swift
//  WebBrowser
//
//  Created by ByteDance on 2023/9/28.
//

import Foundation
import LarkQuickLaunchInterface

public struct WebAppKeepAliveAppConfig: Decodable {
    public let appId: String
    public let duration: Int64
    public let priority: Int64?
}

public struct WebAppKeepAliveConfig: Decodable {
    public let maxCount : Int64
    public let list : [WebAppKeepAliveAppConfig]
}

public final class WebAppKeepAliveCache {
    
    public let createTime : Int64 = Int64(Date().timeIntervalSince1970)
    public let identifier: String
    public let appId: String
    public let webAppBrowser: WebBrowser
    
    public init(identifier:String, appId: String, browser:WebBrowser) {
        self.identifier = identifier
        self.appId = appId
        self.webAppBrowser = browser
    }
}

/// 网页应用保活协议
public protocol WebAppKeepAliveService {
    // 是否开启保活功能，fg + setting 都配置上才认为开启
    func isWebAppKeepAliveEnable() -> Bool
    
    // iPhone端是否独立关闭
    func isWebAppKeepAliveIPhoneDisable() -> Bool
    
    // iPad c视图是否独立关闭
    func isWebAppKeepAliveIPadCDisable() -> Bool
    
    /// 通过browser创建保活唯一标识，内部调用createKeepAliveIdentifier(fromScene:scene:appId:url:isCollapsed)
    /// - Parameter browser: 浏览器vc
    /// - Returns: 唯一标识
    func createKeepAliveIdentifier(browser: WebBrowser) -> String
    
    
    /// 创建保活唯一标识
    /// - Parameters:
    ///   - fromScene: 来源业务场景
    ///   - scene: 浏览器当前场景
    ///   - appId: 应用ID
    ///   - url: URL
    ///   - isCollapsed: 是否是iPad C视图
    /// - Returns: 唯一标识
    func createKeepAliveIdentifier(fromScene: WebBrowserFromScene, scene: WebBrowserScene, appId: String?, url: URL?, isCollapsed: Bool, tabContainableIdentifier: String?) -> String
    
    /// 创建保活场景值,内部调用createKeepAliveScene(fromScene:scene:appId:url:isCollapsed:)
    /// - Parameter browser: 浏览器vc
    /// - Returns: 保活场景值
    func createKeepAliveScene(browser: WebBrowser) -> PageKeeperScene
    
    /// 创建保活场景值
    /// - Parameters:
    ///   - fromScene: 来源业务场景
    ///   - scene: 浏览器当前场景
    ///   - appId: 应用ID
    ///   - url: URL
    ///   - isCollapsed: 是否是iPad C视图
    /// - Returns: 保活场景值
    func createKeepAliveScene(fromScene: WebBrowserFromScene, scene: WebBrowserScene, appId: String?, url: URL?, isCollapsed: Bool, tabContainableIdentifier: String?) -> PageKeeperScene
    
    
    /// 获取缓存vc，优先拿tab唯一标识去匹配，匹配不到时再拿唯一标识去匹配
    /// - Parameters:
    ///   - identifier: 唯一标识
    ///   - scene: 保活场景值
    ///   - temporaryUniququeId: tab唯一标识
    /// - Returns: 缓存vc，可能为空
    func getWebAppBrowser(identifier: String, scene: PageKeeperScene, tabContainableIdentifier: String?) -> WebBrowser?
    
    /// 保存vc到缓存队列中
    /// - Parameter browser: vc
    func cacheBrowsers(browser: WebBrowser)
    
    /// 移除缓存vc
    /// - Parameter browser: vc
    func removeWebAppBrowser(browser: WebBrowser)
    
    /// 当前应用ID是否在白名单中，iPhone 和 iPad C视图仅保活白名单应用
    /// - Parameter appId: 应用ID
    /// - Returns: 应用是否在白名单
    func isAppInKeppAliveConfigList(appId:String) -> Bool
}
