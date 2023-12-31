//
//  WAContainerViewModel.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/14.
//

import Foundation
import LarkWebViewContainer
import LKCommonsLogging
import LarkContainer

public protocol WAContainerUIDelegate: UIViewController {
    func onLoadStatusChange(old: WALoadStatus, new: WALoadStatus)
    func openUrl(_ url: URL)
    func closePage()
    func refreshPage()
    func goBackPage()
    func updateTitleBar(_ titleBarConfig: WATitleBarConfig, target: AnyObject, selector: Selector)
    func updateTitle(_ title: String?)
}

class WAContainerViewModel {
    static let logger = Logger.log(WAContainerViewModel.self, category: WALogger.TAG)
    
    weak var webView: WAWebView?
    weak var delegate: WAContainerUIDelegate?
    let config: WebAppConfig
    var timing = WAPerformanceTiming()
    let bridge: WABridge
    let pluginManager: WAPluginManager
    let lifeCycleObserver = WAContainerLifeCycleObserver()
    private(set) var loader: WALoader?
    let offlineManager: WAOfflineManager?
    let userResolver: UserResolver
    let tracker: WATracker
    
    var isReadyForReuse: Bool {
        //如果出现过加载错误侧不再复用
        if self.loader?.preloadStatus.value.isReady == true, self.loader?.loadStatus.isError == false {
            return true
        }
        return false
    }
    
    private(set) var currentURL: URL? {
        didSet {
            Self.logger.info("update currentURL:\(currentURL?.urlForLog ?? "")", tag: LogTag.open.rawValue)
        }
    }
    private(set) var preloadURL: URL?{
        didSet {
            Self.logger.info("update preloadURL:\(preloadURL?.urlForLog ?? "")", tag: LogTag.open.rawValue)
        }
    }
    
    init(config: WebAppConfig, webView: WAWebView, userResolver: UserResolver) {
        self.config = config
        self.webView = webView
        self.userResolver = userResolver
        self.bridge = WABridge(webview: webView)
        self.pluginManager = WAPluginManager()
        self.tracker = WATracker(config: config)
        if let resCfg = config.resConfig {
            self.offlineManager = WAOfflineManager(config: config,
                                                   resConfig: resCfg)
        } else {
            self.offlineManager = nil
        }
        setup()
    }
    
    private func setup() {
        self.webView?.container = self
        self.offlineManager?.container = self
        self.bridge.setup(context: self)
        self.pluginManager.setup(container: container)
        if config.supportOffline {
            self.loader = WAOfflineLoader(self)
        } else {
            self.loader = WALoader(self)
        }
        reigisterBasePlugins()
        offlineManager?.checkOfflinePackageIfNeed()
        self.tracker.container = self
    }
    
    func attachToVC(_ vc: WAContainerViewController) {
        self.delegate = vc
        self.lifeCycleObserver.containerAttachToPage()
        reigisterUIPlugins()
    }
    
    func dettachFromVC() {
        self.delegate = nil
        self.loader?.onClear()
        self.lifeCycleObserver.containerDettachFromPage()
        self.timing = WAPerformanceTiming()
    }
    
    func load(urlString: String) {
        guard let newUrl = URL(string: urlString) else {
            return
        }
        self.currentURL = newUrl
        self.lifeCycleObserver.container(self.container, onChangeUrl: newUrl)
        self.loader?.load()
    }
    
    func refresh() {
        Self.logger.info("refresh..., url: \(currentURL?.urlForLog ?? "")", tag: LogTag.open.rawValue)
        guard currentURL != nil else {
            return
        }
        self.loader?.load(forceLoadUrl: true)
    }
    
    func preloadTemplate() {
        guard let preloadUrl = config.getPreloadURL() else {
            Self.logger.error("preloadurl is invalid", tag: LogTag.open.rawValue)
            return
        }
        self.preloadURL = preloadUrl
        self.loader?.preload(preloadUrl)
    }
}
