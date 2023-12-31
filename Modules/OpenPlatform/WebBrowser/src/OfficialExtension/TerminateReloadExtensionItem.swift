//
//  TerminateReloadExtensionItem.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2021/8/3.
//

import ECOProbe
import Foundation
import LarkSetting
import LKCommonsLogging
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignTheme
import WebKit

/// 崩溃重试类型
enum TerminateReloadType: String {
    /// 前台恢复
    case foreground
    /// 后台切换前台恢复 后台的概念包括（view不可见，飞书在后台）
    case background_to_foreground
}

/// 渲染进程崩溃自动重试扩展
final public class TerminateReloadExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "TerminateReload"
    static let logger = Logger.webBrowserLog(TerminateReloadExtensionItem.self, category: "TerminateReloadExtensionItem")
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = TerminateReloadWebBrowserLifeCycle(item: self)
    
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = TerminateReloadWebBrowserNavigation(item: self)
    
    public var hasShownTerminateReloadView = false
    
    weak var browser: WebBrowser?
    
    public init(browser: WebBrowser) {
        self.browser = browser
    }
    
    private lazy var terminateReloadView: UIView = {
        let bgview = UIView()
        bgview.backgroundColor = UIColor.ud.bgBody
        let empty = UDEmpty(
            config: .init(
                title: .init(titleText: BundleI18n.WebBrowser.Lark_OpenPlatform_CantOpenTtl),
                description: .init(descriptionText: BundleI18n.WebBrowser.Lark_OpenPlatform_RestartDesc()),
                type: .loadingFailure,
                primaryButtonConfig: (BundleI18n.WebBrowser.Lark_Legacy_WebRefresh, { [weak self] (_) in
                    guard let self = self, let browser = self.browser else { return }
                    Self.logger.info("tap terminateReloadView to reload")
                    self.reloadForRecover(browser: browser, type: .foreground)
                    
                })
            )
        )
        bgview.addSubview(empty)
        empty.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        return bgview
    }()
    
    //  广义的后台切换前台时，是否需要reload以修复Terminate导致的白屏
    var shouldReloadAfterTerminateWhenBecomeForeground = false
    
    //  崩溃reload的次数
    var currentReloadCount = 0
    
    /// 崩溃恢复监听添加
    func terminateAddObserver() {
        NotificationCenter
            .default
            .addObserver(
                self,
                selector: #selector(backgroundToForeground),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
    }
    
    /// 后台切换到前台，后台的概念包括（view不可见，飞书在后台）
    @objc
    public func backgroundToForeground() {
        guard let browser = browser else { return }
        guard browser.webview.isVisible() else { return }
        currentReloadCount = 0
        if !shouldReloadAfterTerminateWhenBecomeForeground {
            return
        }
        shouldReloadAfterTerminateWhenBecomeForeground = false
        reloadForRecover(browser: browser, type: .background_to_foreground)
    }
    
    /// 崩溃重试 Reload
    /// - Parameter type: 崩溃重试类型
    func reloadForRecover(browser: WebBrowser, type: TerminateReloadType) {
        Self.logger.info("reloadForRecover, type: \(type.rawValue), webview address: \(browser.webview)")
        currentReloadCount += 1
        browser.reload()
        OPMonitor(terminateReloadEvent)
            .setReloadType(type)
            .setCurrentReloadCount(currentReloadCount)
            .tracing(browser.webview.trace)
            .flush()
    }
    
    /// 展示崩溃重试失败页面
    func showErrorPageIfNeeded(browser: WebBrowser) {
        showTerminateReloadView(browser: browser)
        self.hasShownTerminateReloadView = true
    }
    
    /// 显示失败视图
    func showTerminateReloadView(browser: WebBrowser) {
        if terminateReloadView.superview != nil {
            Self.logger.error("terminateReloadView has superview, don't add twice, webView address: \(browser.webview)")
            return
        }
        Self.logger.error("add terminateReloadView, webView address: \(browser.webview)")
        browser.view.addSubview(terminateReloadView)
        terminateReloadView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if browser.enableDarkModeOptimization {
            let canOptimizeCommit = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.optimizecommit.enable"))// user:global
            if canOptimizeCommit {
                browser.webview.isHidden = WebBrowser.isDarkMode()
            }else{
                browser.webview.removeFromSuperview()
            }
        }
    }

    /// 移除失败视图
    func removeTerminateReloadView(browser: WebBrowser) {
        Self.logger.info("remove terminate reload view, webView address: \(browser.webview)")
        terminateReloadView.removeFromSuperview()
        self.hasShownTerminateReloadView = false
    }
}

final public class TerminateReloadWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    private weak var item: TerminateReloadExtensionItem?
    init(item: TerminateReloadExtensionItem) {
        self.item = item
    }
    
    public func viewDidLoad(browser: WebBrowser) {
        //  注册崩溃重试监听
        item?.terminateAddObserver()
    }
    
    public func viewDidAppear(browser: WebBrowser, animated: Bool) {
        //  崩溃重试触发
        //  优化时机，相同资源损耗提高恢复量
        item?.backgroundToForeground()
    }
}

final public class TerminateReloadWebBrowserNavigation: WebBrowserNavigationProtocol {
    var optimizeNavigationPolicyEnbale : Bool = {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.optimizenavigationpolicy.enable"))// user:global
      
    }()
    private weak var item: TerminateReloadExtensionItem?
    init(item: TerminateReloadExtensionItem) {
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, decidePolicyFor navigationAction: WKNavigationAction) -> WKNavigationActionPolicy {
        if(self.optimizeNavigationPolicyEnbale){
            if (self.item?.hasShownTerminateReloadView == true){
                item?.removeTerminateReloadView(browser: browser)
            }
        }else{
            item?.removeTerminateReloadView(browser: browser)
        }
        return .allow
    }
    
    public func browserWebContentProcessDidTerminate(_ browser: WebBrowser) {
        guard let item = item else { return }
        let feishuIsBackground = UIApplication.shared.applicationState == .background
        if !browser.webview.isVisible() || feishuIsBackground {
            item.shouldReloadAfterTerminateWhenBecomeForeground = true
            OPMonitor(submitReloadTaskEvent)
                .tracing(browser.webview.trace)
                .flush()
            return
        }
        if item.currentReloadCount > 3 {
            OPMonitor(terminateOverReloadEvent)
                .tracing(browser.webview.trace)
                .flush()
            item.showErrorPageIfNeeded(browser: browser)
            return
        }
        item.reloadForRecover(browser: browser, type: .foreground)
    }
}

// MARK: - 崩溃重试相关埋点Event 和 key 定义
/// 非前台提交了重试任务，回到前台执行
private let submitReloadTaskEvent = "webvc_webview_submit_reload_task"
/// 重试次数大于三次，展示重试页面
private let terminateOverReloadEvent = "webvc_webview_terminate_over_reload"
/// 崩溃重试
private let terminateReloadEvent = "webvc_webview_terminate_reload"

private let reloadTypeKey = "reload_type"
private let currentReloadCountKey = "current_reload_count"


extension OPMonitor {
    /// 设置重试类型
    func setReloadType(_ value: TerminateReloadType) -> OPMonitor {
        addCategoryValue(reloadTypeKey, value.rawValue)
    }
    
    /// 设置重试次数
    func setCurrentReloadCount(_ value: Int) -> OPMonitor {
        addCategoryValue(currentReloadCountKey, value)
    }
}
