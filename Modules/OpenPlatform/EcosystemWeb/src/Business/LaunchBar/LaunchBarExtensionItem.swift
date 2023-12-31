//
//  LaunchBarExtensionItem.swift
//  EcosystemWeb
//
//  Created by ByteDance on 2023/5/30.
//

import Foundation
import Swinject
import TTMicroApp
import WebBrowser
import LarkContainer
import LarkOPInterface
import LarkQuickLaunchBar
import LarkQuickLaunchInterface
import LKCommonsLogging
import LarkWebViewContainer
import UniverseDesignIcon
import UniverseDesignToast
import LarkSetting
import LarkAIInfra
import RxSwift
import LarkRustClient
import ServerPB

// swiftlint:disable all
/// 底部快捷菜单 QuickLaunchBar
final public class WebLaunchBarExtensionItem: WebBrowserExtensionItemProtocol {
    
    public var itemName: String? = "WebLaunchBar"
    
    static let logger = Logger.ecosystemWebLog(WebLaunchBarExtensionItem.self, category: "WebLaunchBarExtensionItem")
    
    public weak var browser: WebBrowser?
    
    public var resolver: Resolver?
    
    private var launchBar: QuickLaunchBar?
    // 记录主端整体对LaunchBar的开关状态
    public var isLaunchBarEnable: Bool = true
    
    private var getWebContentJS: String = CommonComponentResourceManager().fetchJSWithSepcificKey(componentName: "my_ai_get_web_content") ?? ""
    
    /// https://bytedance.feishu.cn/sheets/shtcncTYngXV6omM6ltYTzccpOD
    public var bottomButtonIDList : [String] = []
    
    public lazy var browserDelegate: WebBrowserProtocol? = WebLaunchBarWebBrowserDelegate(item: self)
    
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = WebLaunchBarWebBrowserNavigationDelegate(item: self)
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = WebLaunchBarBrowserLifeCycle(item: self)
    
    private var titleObservation: NSKeyValueObservation?
    
    public init(browser: WebBrowser) {
        self.browser = browser
        self.resolver = browser.resolver
        let isAIServiceEnable = browser.isWebMyAIChatModeEnable()
        if isAIServiceEnable {
            Self.logger.info("[Web MyAI ChatMode] [WebContent] try to get online getWebContentScript")
            browser.getWebContentJS = getWebContentJS
        }
        guard let bar = createWebLaunchBar(browser: browser,enableAIItem: isAIServiceEnable) else {
            Self.logger.error("Create WebLaunchBar failed.")
            self.browser?.isWebLaunchBarEnable = false
            return
        }
        self.launchBar = bar
        self.browser?.launchBar = bar
    }
    
    deinit {
        Self.logger.info("deinit.")
    }
    
    private func createWebLaunchBar(browser: WebBrowser, enableAIItem: Bool) -> QuickLaunchBar? {
        guard let container = browser.resolver else {
            Self.logger.error("This WebBrowser has no resolver.")
            return nil
        }
        guard let aiQuickLaunchBarService = container.resolve(LarkOpenPlatformMyAIService.self) else {
            Self.logger.error("This container doesn't have LarkOpenPlatformMyAIService.")
            return nil
        }
        
        guard aiQuickLaunchBarService.isQuickLaunchBarEnable() else {
            self.isLaunchBarEnable = false
            Self.logger.info("aiQuickLaunchBarService.isQuickLaunchBarEnable() is false.")
            return nil
        }
        guard browser.isWebLaunchBarEnable else {
            Self.logger.info("Browser.isWebLaunchBarEnable is false.")
            return nil
        }
        if browser.configuration.scene != .normal && browser.configuration.scene != .temporaryTab  {
            Self.logger.info("isn't normal scene, stop create bar.")
            return nil
        }
        if browser.configuration.webBizType != .larkWeb {
            Self.logger.info("isn't normal larkWeb browser, stop create bar.")
            return nil
        }
        /// 创建 刷新 item
        let webRefreshBarItem = createRefreshLaunchBarItem()
        var items = [webRefreshBarItem]
        bottomButtonIDList.append("1011")
        /// 创建 分享 item
        if let webShareBarItem = createShareQuickLaunchBarItem() {
            items.append(webShareBarItem)
            Self.logger.info("Create webShareBarItem successfully.")
            bottomButtonIDList.append("1012")
        }
        // 创建 QuickLaunchBar
//        let bar = aiQuickLaunchBarService.createAIQuickLaunchBar(items: items, enableTitle: false, enableAIItem: false, quickLaunchBarEventHandler: {[weak self] extraItemType in
//            self?.didClickLaunchBarExtraItem(extraItemType: extraItemType)
//        }, aiBusinessInfoProvider: { [weak self] completionBlock  in
//            self?.getAIChatModeConfig(completionBlock: { modeConfig in
//                completionBlock(modeConfig)
//            })
//        }) as? QuickLaunchBar
        let bar = aiQuickLaunchBarService.createAIQuickLaunchBar(
                items: items,
                enableTitle: false,
                enableAIItem: enableAIItem,
                quickLaunchBarEventHandler: {[weak self] extraItemType in
                    self?.didClickLaunchBarExtraItem(extraItemType: extraItemType)}) as? QuickLaunchBar

        guard let bar else {
            Self.logger.error("LarkOpenPlatformMyAIService creates AIQuickLaunchBar failed.")
            return nil
        }
        bottomButtonIDList.append(contentsOf: ["1009","1010"])
        return bar
    }
    
    func createRefreshLaunchBarItem() -> QuickLaunchBarItem {
        /// 注意：显隐逻辑 和 执行逻辑 要和 WebRefreshMenuPlugin 保持一致
        let webRefreshTitle = BundleI18n.EcosystemWeb.Lark_Legacy_WebRefresh
        let webRefreshImage = UDIcon.refreshOutlined.ud.withTintColor(UIColor.ud.iconN2)
        let webRefreshAction: (QuickLaunchBarItem) -> Void = { [weak self] _ in
            self?.browser?.reload()
            let applicationID = self?.browser?.appInfoForCurrentWebpage?.id
            let buttonID = "1011"
//            OPMonitor("openplatform_web_container_menu_click")
//                .addCategoryValue("application_id", applicationID ?? "none")
//                .addCategoryValue("identify_status", applicationID?.isEmpty == false ? "web_app": "web")
//                .addCategoryValue("click", "button")
//                .addCategoryValue("target", "none")
//                .addCategoryValue("button_id", buttonID)
//                .setPlatform(.tea)
//                .flush()
            self?.reportbuttonClicked(buttonID: buttonID, applicationID: applicationID)
        }
        
        let webRefreshBarItem = QuickLaunchBarItem(name: webRefreshTitle, nomalImage: webRefreshImage, disableImage: webRefreshImage, action: webRefreshAction)
        return webRefreshBarItem
    }
   
    
    func createShareQuickLaunchBarItem() -> QuickLaunchBarItem? {
        /// 注意：显隐逻辑 和 执行逻辑 要和 WebShareMenuPlugin 保持一致
        guard let webBrowser = self.browser else {
            Self.logger.error("webBrowser is nil.")
            return nil
        }
        guard let container = webBrowser.resolver else {
            Self.logger.error("This WebBrowser has no resolver.")
            return nil
        }
        if container.resolve(EcosyetemWebDependencyProtocol.self)!.isOfflineMode(browser: webBrowser) {
            Self.logger.error("web offline app return nil")
            return nil
        }
        guard webBrowser.newFailingURL == nil else {
            Self.logger.info("WebShareMenuPlugin init failure because in error page")
            return nil
        }
        guard webBrowser.isDownloadPreviewMode() == false else {
            Self.logger.info("OPWDownload WebShareMenuPlugin init failure because download preview mode")
            return nil
        }
        var enable = true
        if let menuConfigExtensionItem = webBrowser.resolve(WebMetaMoreMenuConfigExtensionItem.self) {
            enable = !menuConfigExtensionItem.disabled(menuIdentifier: "share")
        }
        let webShareTitle = ""
        let webShareImage = UDIcon.forwardOutlined.ud.withTintColor(UIColor.ud.iconN2)
//        UDIcon.shareOutlined.ud.withTintColor(UIColor.ud.iconN2)
        let webShareDisableImage = UDIcon.shareOutlined.ud.withTintColor(UIColor.ud.iconDisabled)
        let webShareAction: (QuickLaunchBarItem) -> Void = { [weak self] _ in
            let applicationID = self?.browser?.appInfoForCurrentWebpage?.id
            let buttonID = "1012"
//            OPMonitor("openplatform_web_container_menu_click")
//                .addCategoryValue("application_id", applicationID ?? "none")
//                .addCategoryValue("identify_status", applicationID?.isEmpty == false ? "web_app": "web")
//                .addCategoryValue("click", "button")
//                .addCategoryValue("target", "none")
//                .addCategoryValue("button_id", buttonID)
//                .setPlatform(.tea)
//                .flush()
            self?.reportbuttonClicked(buttonID: buttonID, applicationID: applicationID)
            guard let strongBrowser = self?.browser else {
                Self.logger.error("No WebBrowser found.")
                return
            }
            Self.logger.info("did click launch bar share item when enable is：\(enable)")
            container.resolve(EcosyetemWebDependencyProtocol.self)!.shareH5(webVC: strongBrowser)
        }
        
        let webShareDisableAction: (QuickLaunchBarItem) -> Void = { [weak self] _ in
            let applicationID = self?.browser?.appInfoForCurrentWebpage?.id
            let buttonID = "1012"
//            OPMonitor("openplatform_web_container_menu_click")
//                .addCategoryValue("application_id", applicationID ?? "none")
//                .addCategoryValue("identify_status", applicationID?.isEmpty == false ? "web_app": "web")
//                .addCategoryValue("click", "button")
//                .addCategoryValue("target", "none")
//                .addCategoryValue("button_id", buttonID)
//                .setPlatform(.tea)
//                .flush()
            self?.reportbuttonClicked(buttonID: buttonID, applicationID: applicationID)
            guard let strongBrowser = self?.browser else {
                Self.logger.error("No WebBrowser found.")
                return
            }
            Self.logger.info("did click launch bar share item when enable is：\(enable)")
            UDToast.showTips(with: BundleI18n.EcosystemWeb.OpenPlatform_MoreAppFcns_DevDisabledFcns, on: strongBrowser.view, delay: 2.0)
        }
        
        let webShareBarItem = QuickLaunchBarItem(name: webShareTitle, isEnable: enable, nomalImage: webShareImage, disableImage: webShareDisableImage, action: webShareAction, disableAction: webShareDisableAction)
        return webShareBarItem
    }
    
    public func updateQuickLaunchBarItems(imPlugin: BusinessBarItemsForWeb?, docPlugin: BusinessBarItemsForWeb?){
        var items:[QuickLaunchBarItem] = []
        
        if let webBrowser = self.browser,
           webBrowser.isBusinessPluginsEnable,
           !webBrowser.configuration.offline,
           webBrowser.newFailingURL == nil {
            // 非离线应用，非错误页
            Self.logger.info("In updateQuickLaunchBarItems, not offlinemode, not error page.")
            if let imBarItem = imPlugin?.launchBarItem,
               imPlugin?.url == self.browser?.webview.url {
                items.append(imBarItem)
                Self.logger.info("In updateQuickLaunchBarItems, match latest url, Create imBarItem successfully.")
            }
            
            if let docBarItem = docPlugin?.launchBarItem,
               docPlugin?.url == self.browser?.webview.url {
                items.append(docBarItem)
                Self.logger.info("In updateQuickLaunchBarItems, match latest url, Create docBarItem successfully.")
            }
        }

        let webRefreshBarItem = createRefreshLaunchBarItem()
        items.append(webRefreshBarItem)
        
        if let webShareBarItem = createShareQuickLaunchBarItem() {
            items.append(webShareBarItem)
            Self.logger.info("In updateQuickLaunchBarItems, Create webShareBarItem successfully.")
        }
        
        var setAIItemEnable = false
        if self.browser?.isWebMyAIChatModeEnable() == true {
            // 错误页不展示 MyAI 分会话按钮
            setAIItemEnable = (self.browser?.newFailingURL == nil) ? true : false
            Self.logger.info("[Web MyAI ChatMode] In updateQuickLaunchBarItems, according to error page state, setAIItemEnable is \(setAIItemEnable).")
        }
        
        if let launchBarInterface = launchBar as? MyAIQuickLaunchBarInterface {
            launchBarInterface.reloadByItems(items)
            launchBarInterface.setAIItemEnable(setAIItemEnable)
            Self.logger.info("[Web MyAI ChatMode] Did update QuickLaunchBarItems.")
        } else {
            Self.logger.error("[Web MyAI ChatMode] Get launchBarInterface failed.")
        }
    }
    
    public func didClickLaunchBarExtraItem(extraItemType: LarkOPInterface.OPMyAIQuickLaunchBarExtraItemType) {
        var buttonID = ""
        switch extraItemType {
        case .ai:
            buttonID = "1009"
            Self.logger.info("[Web MyAI ChatMode] Did click MyAI LaunchBarItem.")
            self.browser?.launchMyAI()
        case .more:
            buttonID = "1010"
            Self.logger.info("Did click More LaunchBarItem.")
        @unknown default:
            break
        }
        let applicationID = self.browser?.appInfoForCurrentWebpage?.id
//        OPMonitor("openplatform_web_container_menu_click")
//            .addCategoryValue("application_id", applicationID ?? "none")
//            .addCategoryValue("identify_status", applicationID?.isEmpty == false ? "web_app": "web")
//            .addCategoryValue("click", "button")
//            .addCategoryValue("target", "none")
//            .addCategoryValue("button_id", buttonID)
//            .setPlatform(.tea)
//            .flush()
        reportbuttonClicked(buttonID: buttonID, applicationID: applicationID)
    }
    
    func reportbuttonClicked(buttonID: String, applicationID: String?) {
        OPMonitor("openplatform_web_container_click")
            .addCategoryValue("application_id", applicationID ?? "none")
            .addCategoryValue("click", "button")
            .addCategoryValue("button_id", buttonID)
            .addCategoryValue("click_location", "bottom")
            .addCategoryValue("container_open_type", "single_tab")
            .addCategoryValue("windows_type", "embedded_window")
            .setPlatform(.tea)
            .flush()
    }
    
    
    /// 导航栏title跟着document.title走
    func setupTitleObservable(browser: WebBrowser) {
        titleObservation = browser
            .webview
            .observe(
                \.title,
                options: [.old, .new],
                changeHandler: { [weak self, weak browser] (webView, change) in
                    guard let `self` = self, let browser = browser else { return }
                    self.updateTabVC()
                }
            )
    }
    
    func fetchWebPageInfo() {
        guard let webview = browser?.webview else {
            Self.logger.error("webview is null")
            return
        }
        var script = CommonComponentResourceManager().fetchJSWithSepcificKey(componentName: "js_for_web_getShareInfo") ?? ""
        if script.isEmpty {
            script = defaultFetchInfoScript
            Self.logger.info("Use defaultFetchInfoScript to fetch WebPageInfo.")
        }
        Self.logger.info("[superapp]: fetch web info start", additionalData: [:])
        webview.evaluateJavaScript(script) { (result, error) in
            guard error == nil else {
                Self.logger.error("evaluate js failed", error: error)
                return
            }
            guard let res = result as? [String: String] else {
                Self.logger.error("webInfo result exc")
                return
            }
            Self.logger.info("[superapp]: fetch web info successfully",
                        additionalData: ["faviconUrl": "\(res["faviconUrl"] ?? "")"])
            self.browser?.faviconURL = res["faviconUrl"]
            self.updateTabVC()
        }
    }
    
    func updateTabVC() {
        Self.logger.info("begin trying to updateTabVC")
        guard let browser = self.browser, browser.configuration.scene == .temporaryTab, let aiQuickLaunchBarService = self.resolver?.resolve(LarkOpenPlatformMyAIService.self) else {
            return
        }
        if browser.didExecuteRemoveTabVC {
            // 重定向自动关闭或者其他场景调用close可能会出现刚调用完关闭，恰好网页抓取信息脚本执行完回来刷新信息的场景
            // 这个时候会出现一个标签从tab区域先删除再加回来，其实预期就是关闭就关闭了，不需要再刷回来
            Self.logger.info("return because has close temporary tab")
            return
        }
        Self.logger.info("updateTabVC, traceid:\(browser.configuration.initTrace?.traceId)")
        aiQuickLaunchBarService.updateTabVC(browser)
    }
}

final public class WebLaunchBarWebBrowserDelegate: WebBrowserProtocol {
    
    private weak var item: WebLaunchBarExtensionItem?
    
    init(item: WebLaunchBarExtensionItem) {
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, didURLChanged url: URL?) {
        // 兼容单页应用
        item?.fetchWebPageInfo()
        item?.updateQuickLaunchBarItems(imPlugin: nil, docPlugin: nil)
        if let pageService = browser.myAIChatModePageService,
           pageService.isActive.value {
            // 分会话处于拉起状态，上报一次网页内容
            WebLaunchBarExtensionItem.logger.info("[Web MyAI ChatMode] url did change, aiChatMode is active, report web content")
            browser.getAndSendWebContent()
        }
    }
    
    public func browser(_ browser: WebBrowser, didHideMenuItemsChanged hideMuenItems: Array<String>?) {
        item?.updateQuickLaunchBarItems(imPlugin: browser.imBarItemsMap, docPlugin: browser.docBarItemsMap)
    }
    
    public func browser(_ browser: WebBrowser, didImBusinessPluginChanged imPlugin: BusinessBarItemsForWeb?, didDocBusinessPluginChanged docPlugin: BusinessBarItemsForWeb?) {
        item?.updateQuickLaunchBarItems(imPlugin: imPlugin, docPlugin: docPlugin)
    }
    
}

final public class WebLaunchBarWebBrowserNavigationDelegate: WebBrowserNavigationProtocol {
    private weak var item: WebLaunchBarExtensionItem?
    
    init(item: WebLaunchBarExtensionItem) {
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, didCommit navigation: WKNavigation!) {
        self.item?.fetchWebPageInfo()
    }

    public func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
//        self.item?.fetchWebPageInfo()
        if self.item?.browser?.faviconURL == nil {
            // faviconURL还是没有值就再尝试获取一次
            self.item?.fetchWebPageInfo()
        }
        if let pageService = browser.myAIChatModePageService,
            pageService.isActive.value {
            // 分会话处于拉起状态，再上报一次网页内容
            WebLaunchBarExtensionItem.logger.info("[Web MyAI ChatMode] didFinish loading, aiChatMode is active, report web content")
            browser.getAndSendWebContent()
        }
    }
}

final class WebLaunchBarBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    private weak var item: WebLaunchBarExtensionItem?
    
    init(item: WebLaunchBarExtensionItem) {
        self.item = item
    }
    
    func viewDidLoad(browser: WebBrowser) {
        item?.setupTitleObservable(browser: browser)
    }
    
    func webBrowserDeinit(browser: WebBrowser) {
        WebLaunchBarExtensionItem.logger.info("[Web MyAI ChatMode] in webBrowserDeinit, closeAIChat, and closeMyAIChatMode")
        browser.closeAIChat()
        browser.myAIChatModePageService?.closeMyAIChatMode(needShowAlert: true)
    }
}

// 旧版获取网页信息脚本
private let defaultFetchInfoScript = """
function getOGPInfo(prop) {
    var ogEle = [].slice.call(window.document.head.getElementsByTagName('meta')).find((a) =>a.getAttribute('property') === `og: $ {
        prop
    }`);
    return (ogEle && ogEle.getAttribute('content'));
}
function getTwitterInfo(prop) {
    var twitterEle = [].slice.call(window.document.head.getElementsByTagName('meta')).find((a) =>a.getAttribute('name') === `twitter: $ {
        prop
    }`);
    return (twitterEle && twitterEle.getAttribute('content'));
}
function getMetaDesc() {
    var descEle = [].slice.call(window.document.head.getElementsByTagName('meta')).find((a) =>a.getAttribute('name') === 'description');
    return (descEle && descEle.getAttribute('content'));
}
function getTitle() {
    var titleEle = [].slice.call(window.document.head.getElementsByTagName('title'))[0];
    return (titleEle && titleEle.innerText);
}
function getImg() {
    var min_image_size = 100;
    var imgs = window.document.querySelectorAll('body img');
    var icon = '';
    for (var i = 0; i < imgs.length; i++) {
        var img = imgs[i];
        if (img.naturalWidth > min_image_size && img.naturalHeight > min_image_size) {
            icon = img.src;
            return icon;
        }
    }
    return icon;
}
function getDesc() {
    return window.document.body.innerText.replace(/\\n/g, " ");
}
function getFaviconUrl() {
    const linkTags = document.querySelectorAll('link');
    let faviconUrl = '';
    for (let i = 0; i < linkTags.length; i++) {
        const linkTag = linkTags[i];
        const rel = linkTag.getAttribute('rel');
        if (rel === 'icon' || rel === 'shortcut icon') {
            faviconUrl = getAbsoluteUrl(linkTag.getAttribute('href'));
            break;
        }
    }
    return faviconUrl;
}
function getAbsoluteUrl(url) {
    var a = document.createElement('a');
    a.href = url;
    return a.href;
}
function getH5Info() {
    try {
        var title = getOGPInfo('title') || getTwitterInfo('title') || getTitle() || "ShareLink";
    } catch(error) {
        var title = "ShareLink";
    }
    try {
        var desc = getOGPInfo('description') || getTwitterInfo('description') || getMetaDesc() || getDesc() || window.location.href;
    } catch(error) {
        var desc = window.location.href;
    }
    try {
        var iconUrl = getOGPInfo('image') || getTwitterInfo('image') || getImg() || "";
    } catch(error) {
        var iconUrl = "";
    }
    try {
        var faviconUrl = getFaviconUrl()
    } catch(error) {
        var faviconUrl = ""
    }
    return {
        iconUrl: iconUrl,
        title: title.replace(/[\\r\\n\\t]/g, ""),
        desc: desc.replace(/\\r\\n/g, ""),
        faviconUrl: faviconUrl
    }
}
getH5Info();
"""

