//
//  PadExtensionItem.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2021/8/22.
//

import LarkSceneManager
import LarkUIKit
import LKCommonsLogging
import WebKit
import LarkSplitViewController
import LarkSetting

/// 区分多Scene Web相关业务的key
private let WebSceneKey = "Web"

final public class PadExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "PadExtension"
    static let logger = Logger.webBrowserLog(PadExtensionItem.self, category: "PadExtensionItem")
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = PadWebBrowserLifeCycle(item: self)
    
    weak private var browser: WebBrowser?
    
    /// iPad辅Scene使用的关闭按钮
    lazy var supportSceneCloseItem: LKBarButtonItem = {
        let supportSceneCloseItem = FeatureGatingKey.webBrowserProfileCloseBtnGap.fgValue() ? WebBrowserBarItem.makeIconButton(.closeOutlined) : LKBarButtonItem(image: LarkUIKit.Resources.navigation_close_outlined)// user:global
        supportSceneCloseItem.webButtonID = "1008"
        supportSceneCloseItem.addTarget(self, action: #selector(closeScene), for: .touchUpInside)
        return supportSceneCloseItem
    }()
    @objc private func closeScene() {
        guard let browser = browser else { return }
        Self.logger.info("supportSceneCloseItem clicked")
        /// 关闭辅助窗口
        SceneManager.shared.deactive(from: browser)    //  code from lilun 网页支持多Scene Change-Id: If31486d9c54ba55de6d2f9f455ab3037237e4d70
        
        supportSceneCloseItem.webReportClick(applicationID: browser.currrentWebpageAppID())
    }
    
    /// iPad辅Scene新窗口的入口按钮
    private lazy var supportSceneOpenItem: LKBarButtonItem = {
        let SceneOpenItem = SceneButtonItem(
            clickCallBack: { [weak self] (sender) in
                self?.openNewScene()
            },
            sceneKey: WebSceneKey, sceneId: getSceneId()
        )
        if WebMetaNavigationBarExtensionItem.isNavBgAndFgColorEnabled() {
            SceneOpenItem.tintColorEnable = true
        }
        let supportSceneOpenItem = LKBarButtonItem()
        supportSceneOpenItem.webButtonID = "1008"
        SceneOpenItem.snp.makeConstraints { (maker) in
            maker.height.width.equalTo(24)
        }
        supportSceneOpenItem.customView = SceneOpenItem
        supportSceneOpenItem.setProperty(alignment: .center)
        return supportSceneOpenItem
    }()

    @objc private func openNewScene() {
        guard let browser = browser else { return }
        Self.logger.info("supportSceneOpenItem clicked")
        openCurrentUrlInNewScene(browser: browser)
        
        supportSceneOpenItem.webReportClick(applicationID: browser.currrentWebpageAppID())
    }
    
    public init(browser: WebBrowser) {
        self.browser = browser
    }
    
    private var titleObservation: NSKeyValueObservation?
    /// 导航栏title跟着document.title走
    func setupTitleObservable(browser: WebBrowser) {
        titleObservation = browser
            .webview
            .observe(
                \.title,
                options: [.old, .new],
                changeHandler: { [weak self, weak browser] (webView, change) in
                    guard let `self` = self, let browser = browser else { return }
                    Self.logger.info("webview title changed from {\(change.oldValue)} to {\(change.newValue)}")
                    var title = ""
                    if let newTitlt = change.newValue, let t = newTitlt {
                        title = t
                    }
                    if self.supportMutilScene() {
                        SceneManager.shared.updateSceneIfNeeded(title: title, from: browser)
                        Self.logger.info("update scene title \(title)")
                    }
                }
            )
    }
    
    func tryGetSupportSceneCloseItem(browser: WebBrowser) -> UIBarButtonItem? {
        if #available(iOS 13.4, *),
            /// 当前应用支持多窗口
           supportMutilScene(),
            /// 必须在辅助窗口中
           !(currentSceneIsMainScene(browser: browser) ?? true),
            /// 当前的VC是导航中唯一的VC
           currentIsRootController(browser: browser),
            /// 当前VC是window的根VC
           currentIsTopController(browser: browser) {
            return supportSceneCloseItem
        } else {
            return nil
        }
    }
    
    func tryGetSceneButton(browser: WebBrowser) -> UIBarButtonItem? {
        if needInsertSceneButton(browser: browser) {
            return supportSceneOpenItem
        } else {
            return nil
        }
    }
    
}

// 下述代码 code from lilun.ios commit msg:多 Scene支持
extension PadExtensionItem {
    /// 是否支持mutil scene
    private func supportMutilScene() -> Bool {
        var supportMutilScene = false
        if Display.pad,
           #available(iOS 13.4, *) {
            supportMutilScene = SceneManager.shared.supportsMultipleScenes
        }
        return supportMutilScene
    }
    
    /// 当前是否处在主Scene中
    private func currentSceneIsMainScene(browser: WebBrowser) -> Bool? {
        if #available(iOS 13.0, *) {
            guard let window = browser.view.window else {
                Self.logger.warn("currentSceneIsMainScene called failed view.window is nil")
                return nil
            }
            guard let windowScene = window.windowScene else {
                Self.logger.warn("currentSceneIsMainScene called failed view.window.windowScene is nil")
                return nil
            }
            return windowScene.sceneInfo.isMainScene()
        } else {
            Self.logger.info("currentSceneIsMainScene called failed for os version less than 13.0")
            return false
        }
    }
    /// 是否是根VC
    private func currentIsRootController(browser: WebBrowser) -> Bool {
        let isRootNavi = browser.view.window?.rootViewController == browser.navigationController
            && browser.navigationController != nil
        let isRootVC = browser.view.window?.rootViewController == browser
        return isRootNavi || isRootVC
    }
    /// 是否是最顶部的VC
    private func currentIsTopController(browser: WebBrowser) -> Bool {
        return browser == browser.navigationController?.viewControllers.first
    }
    /// 是否需要展示多Scene入口, 在VC创建之后没有添加到window时，可能返回nil，调用方需要注意时序
    /// 返回nil之后，调用方需要根据需要决定采用true还是false的逻辑
    private func needInsertSceneButton(browser: WebBrowser) -> Bool {
        guard supportMutilScene() else {
            return false
        }
        guard let isMainScene = currentSceneIsMainScene(browser: browser), isMainScene else {
            return false
        }
        if isOfflineVirtualDomain(url: browser.browserURL) && !offlineNewSceneEnable() {
            return false
        }
        return true
    }
    
    private func isOfflineVirtualDomain(url: URL?) -> Bool {
        
        guard let finalUrl = url, let finalHost = finalUrl.host else {
            return false
        }
        
        let offline = browser?.configuration.offline ?? false
        Self.logger.info("final host is \(finalHost), offline:\(offline)")
        return offline
    }
    
    private func getSceneId() -> String{
        var sceneId = browser?.browserURL?.absoluteString ?? ""
        if isOfflineVirtualDomain(url: browser?.browserURL) && offlineNewSceneEnable() {
            sceneId = browser?.configuration.applinkURLString ?? ""
        }
        return sceneId
    }
    /// 使用当前的url打开新的多Scene窗口
    private func openCurrentUrlInNewScene(browser: WebBrowser) {
        /// sceneInfo.id 为新窗口打开的网页的地址，同时这个地址作为Web多scene业务下面区分某一个窗口的key
        /// LarkScene的框架会以这个id为key，来区分寻查找历史存在的同一个地址创建的window
        guard let urlString = browser.browserURL?.absoluteString else { return }
        var targetUrlString = urlString
        
        var isAppLink = "0"
        if isOfflineVirtualDomain(url: browser.browserURL) && offlineNewSceneEnable() {
            isAppLink = "1"
            targetUrlString = self.generateAppLink(currentUrl: browser.browserURL, appId: browser.configuration.appId ?? "")?.absoluteString ?? ""
            if targetUrlString.isEmpty {
                targetUrlString = browser.configuration.applinkURLString
            }
        }
        /// windowType 网页新窗口类型；createWay 创建方式，当前是通过点击
        /// https://bytedance.feishu.cn/sheets/shtcn6wwfuGNzK40A4erVjr4df2?sheet=PSMGuf
        let scene = LarkSceneManager.Scene(key: WebSceneKey,
                                           id: targetUrlString,
                                           title: browser.title,
                                           needRestoration: true,
                                           userInfo: ["is_app_link": isAppLink],
                                           windowType: "web_app",
                                           createWay: "window_click")
            
        SceneManager.shared.active(scene: scene, from: browser) { [weak browser] (_, error) in
            guard error == nil else {
                Self.logger.error("open \(urlString) in new scene failed", error: error)
                return
            }
            browser?.goBackOrClose()
        }
    }
        
    private func generateAppLink(currentUrl: URL?, appId: String) -> URL? {
        
        if appId.isEmpty {
            Self.logger.error("appId is nil")
            return nil
        }
        
        guard let applinkDomain = DomainSettingManager.shared.currentSetting["applink"]?.first else {
            Self.logger.error("invalid applink domain settings")
            assertionFailure("invalid applink domain settings")
            return nil
        }
        
        guard let currentUrl = currentUrl else {
            Self.logger.error("currentUrl is nil")
            return nil
        }
        
        let applinkString = "https://\(applinkDomain)/client/web_app/open?appId=\(appId)"
        guard let url = URL(string: applinkString) else {
            Self.logger.error("init url fail: \(applinkString)")
            return nil
        }
        
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Self.logger.error("init urlComponents fail: \(url)")
            return nil
        }
        
        //applink的path、fragment、query处理
        var queryItems = urlComponents.queryItems ?? []
        let currentPath = currentUrl.path
        if currentPath.count > 0 {
            let pathQuery = URLQueryItem(name: "path", value: currentPath)
            queryItems.append(pathQuery)
        }
        
        let currentFragment = currentUrl.fragment ?? ""
        if currentFragment.count > 0 {
            let fragmentQuery = URLQueryItem(name: "lk_fragment", value: currentFragment)
            queryItems.append(fragmentQuery)
        }
        urlComponents.queryItems = queryItems
        var targetUrl = urlComponents.url
        
        let currentQueryParameters = currentUrl.queryParameters
        if !currentQueryParameters.isEmpty {
            targetUrl = targetUrl?.append(parameters: currentQueryParameters, forceNew: false)
        }
        return targetUrl
    }
    
    private func offlineNewSceneEnable() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webbrowser.offline.newscene.enable"))
    }
}

final public class PadWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    
    private weak var item: PadExtensionItem?
    
    init(item: PadExtensionItem) {
        self.item = item
    }
    
    public func viewDidLoad(browser: WebBrowser) {
        item?.setupTitleObservable(browser: browser)
        // 设置当前 webVC 支持全屏
        browser.supportSecondaryOnly = true
        // 设置当前 全屏 scene
        browser.fullScreenSceneBlock = { "web" }

        // 设置支持手势全屏，参见：https://bytedance.feishu.cn/wiki/wikcnzg4Sru5vLv5Q5cdiYW5Rh5
        browser.supportSecondaryPanGesture = true
        PadExtensionItem.logger.info("enableFullScreenGesture enable")
        // 设置支持快捷键全屏，参见：https://bytedance.feishu.cn/wiki/wikcnGo3EuGUVBWufAE6oNA3rtg#
        browser.keyCommandToFullScreen = true
        PadExtensionItem.logger.info("enableFullScreenCommanKey enable")
    }
}
