//
//  WebBrowserView.swift
//  SKBrowser
//
//  Created by chenhuaguan on 2021/7/5.
//
import LarkWebViewContainer
import SKFoundation
import SKUIKit
import SKCommon
import Foundation
import SKResource
import SpaceInterface
import SKInfra
import LarkContainer

public final class WebBrowserView: BrowserView {

    public var webLoader: WebLoader?
    public var webView: DocsWebViewProtocol
    var ssrWebContainer: SSRWebViewContainer?
    public var webScrollViewProxy: EditorScrollViewProxy
    public var webViewGestureProxy: WebViewGestureProxy
    private var webViewActionHandler: DocsBrowserWebViewActionHandler!
    var leakAvoider: LeakAvoider!
    var isWebViewTerminated = false
    lazy var terminateErrorView: EmptyListPlaceholderView = {
        let errorPage = EmptyListPlaceholderView(frame: .zero)
        errorPage.backgroundColor = UIColor.ud.N00
        errorPage.isHidden = true
        errorPage.delegate = self
        addSubview(errorPage)
        errorPage.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return errorPage
    }()
    /// 为了修复app黑暗模式与系统不一致时, 非模板加载会闪一下问题
    /// 办法：前端如果过来告诉hideloading,则先加个标志，等loadfinish再移除loadingview
    var needUpdateSucWhenFinish = false
    
    private(set) weak var statisticsDelegate: BrowserViewStatisticsDelegate?
    /// 打开非doc/Sheet 类文档时，如果完整包没有ready，就拦截住，等着
    var needReloadingUrl: URL?
    let notNeedCheckTypes: [DocsType] = [.doc, .sheet, .docX, .bitable]
    /// 当这个字段为true时，当前对象不再放入复用池，因为此时当前webView没有重新加载完整包，这个情况只会在精简包切完整包，以及完整包升级时
    var notReloadMainFrameOfFullPkg: Bool = false

    public override var docsLoader: DocsLoader? {
        return webLoader
    }
    public override var editorView: DocsEditorViewProtocol {
        return webView
    }
    public override var scrollViewProxy: EditorScrollViewProxy {
        return webScrollViewProxy
    }
    public override var viewGestureProxy: EditorGestureProxy {
        return webViewGestureProxy
    }
    // MARK: - 重载 BrowserViewDocsAttribute 的方法
    public override var loadedURL: URL? {
        self.webView.url
    }
    
    public override var isInEditorPool: Bool {
        didSet {
            if isInEditorPool {
                self.startInPoolCheckForResponsivenessTimer()
            } else {
                self.stopInPoolCheckForResponsivenessTimer()
            }
        }
    }
    
    /// 保活定时器，防止 webView 的在离开视图层级后，被挂起。
    var keepWebViewActiveTimer: Timer?
    let createTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    
    /// webview在复用池中定时检测卡死
    var InPoolCheckForResponsivenessTimer: Timer?

    deinit {
        //https://stackoverflow.com/questions/38733634/ios-wkwebview-scrollview-delegate-cause-bad-access
        webView.scrollView.delegate = nil
        unRegisterBridge()
        DocsLogger.info("\(editorIdentity) BrowserView deinit")
        stopInPoolCheckForResponsivenessTimer()

        guard ProcessInfo.isWebviewCrashOnTerminate else { return }
        let tmpWebView = self.webView

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            DocsLogger.info("\(tmpWebView.title ?? "")")
        }
    }

    override init(frame: CGRect, config: BrowserViewConfig, userResolver: UserResolver) {
        webView = WebBrowserView.makeDefaultWebView()
        webLoader = WebLoader(webView: webView, userResolver: userResolver)
        webScrollViewProxy = WebViewNoZoomScrollViewProxyImpl()
        webViewGestureProxy = WebViewGestureProxy()
        statisticsDelegate = config.statisticsDelegate
        super.init(frame: frame, config: config, userResolver: userResolver)

        webLoader?.delegate = self
        webLoader?.jsServiceManager = self.jsServiceManager
        webViewActionHandler = DocsBrowserWebViewActionHandler(browser: self, identifier: editorIdentity, actionHandler: webLoader!)
        scrollViewProxy.setScrollView(webView.scrollView)
        webView.scrollView.delegate = scrollViewProxy as? UIScrollViewDelegate
        webView.uiDelegate = webViewActionHandler
        webView.navigationDelegate = webViewActionHandler
        webView.setSKGestureDelegate(viewGestureProxy as? EditorViewGestureDelegate)
        webView.scrollView.backgroundColor = .clear
        webView.identifyId = editorIdentity

        leakAvoider = LeakAvoider(self)
        registerBridge()
        PreloadHtmlTask.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(fullPackageHasReady), name: Notification.Name.feFullPackageHasReady, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(simulateWebViewUnresponsive), name: Notification.Name.SimulateWebViewUnresponsive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(killWebContentProcess), name: Notification.Name.KillWebContentProcess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onThermalStateChange), name: ProcessInfo.thermalStateDidChangeNotification, object: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func browserDidAppear() {
        super.browserDidAppear()
    }

    public override func browserDidDisappear() {
        super.browserDidDisappear()
    }

    override func clear() {
        super.clear()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(waitDidFinishTimeout), object: nil)
        stopKeepActiveTimer()
        hideSSRWebViewIfNeed(forceClose: true)
    }

    override func checkDownloadFullPackageIfNeed(url: URL, fileType: DocsType?) -> Bool {
        let isUsingSimpleJS = GeckoPackageManager.shared.isUsingSimplePkgForWebInfo()
        
        var needWaitFullPackage = false
        //原来需要等待下载完整包的判断
        if let type = fileType, !notNeedCheckTypes.contains(type), isUsingSimpleJS {
            needWaitFullPackage = true
        }
        
        //如果本地没有可用的资源包，可能是完整包正在解压，需要等待完整包解压完成再刷新页面
        let pkgIsEmpty = GeckoPackageManager.shared.localPkgForWebInfoIsEmpty()
        if pkgIsEmpty && !UserScopeNoChangeFG.HZK.fullPkgUnzipOptimize {
            DocsLogger.warning("locatorMapping is Empty, The full package may be unzipping")
            needWaitFullPackage = true
        }
        
        needReloadingUrl = nil
        /// 如果当前locator使用的是精简包，则就拦截下来，等待
        if needWaitFullPackage {
            // 当前业务，只有使用精简包，并且是bitable、slide、mindnote的时候会走到这里来
            //1、先显示loading，等待下载好完整包的通知
            // 2、收到通知之后，重新reload 模板
            // 3、重新走加载url的逻辑（是否有模板加载完毕的回调？）
            docsLoader?.resetDocsInfo(url) // 准备好docsInfo对象，后续SpaceEditorViewManager初始化内部要用到
            needReloadingUrl = url
            var config = SpaceEditorViewManagerConfig()
            config.hostView = self.hostView
            config.loadingAnimation = DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)
            config.statusViewDelegate = self
            config.bannerItemAgent = self
            config.identity = editorIdentity
            viewManager = SpaceEditorViewManager(config: config, delegate: self, userResolver: userResolver)

            self.requestShowLoadingFor(url)
            waitingDownloadFullPkgStatistics(isStart: true)
            GeckoPackageManager.shared.recordWaitingDownloadFullPkgTime(isStart: true)
            if UserScopeNoChangeFG.HZK.fullPkgUnzipOptimize {
                GeckoPackageManager.shared.downloadFullPackageIfNeeded()
            }
            docsLoader?.rootTracing.info("need downloadFullPackage fileType: \(fileType?.name ?? ""), isUsingSimpleJS: \(isUsingSimpleJS)")
            return true
        }
        return false
    }

    override func updateFileType(fileType: DocsType?) {
        let handler = self.webView.configuration.urlSchemeHandler(forURLScheme: DocSourceURLProtocolService.scheme)
        if let handler = handler as? DocSourceSchemeHandler {
            handler.updateCurrentFileTye(fileType)
        }
    }
    
    ///disable webView的右键手势
    public override func disableSecondaryClick() {
        guard let type = docsInfo?.inherentType else {
            DocsLogger.error("docsType is nil", component: LogComponents.webContextMenu)
            return
        }
        if #available(iOS 16.0, *), type.editMenuInteractionEnable, SKDisplay.pad {
            guard let secondaryClick = NSClassFromString(secondaryClickMethod),
                  let recognizers = webView.gestureRecognizers,
                  let contentRecoginzers = webView.contentView?.gestureRecognizers else {
                return
            }
            for recognizer in recognizers where recognizer.isKind(of: secondaryClick) {
                if type == .sheet, UserScopeNoChangeFG.LJW.sheetSecondaryClickEnabled {
                    recognizer.isEnabled = true
                } else {
                    recognizer.isEnabled = false
                    DocsLogger.info("disable webView recognizer", component: LogComponents.webContextMenu)
                }
            }
            for recognizer in contentRecoginzers where recognizer.isKind(of: secondaryClick) {
                if type == .sheet, UserScopeNoChangeFG.LJW.sheetSecondaryClickEnabled {
                    recognizer.isEnabled = true
                } else {
                    recognizer.isEnabled = false
                    DocsLogger.info("disable webView recognizer", component: LogComponents.webContextMenu)
                }
            }
        }
    }

    @objc
    private func fullPackageHasReady() {
        guard let url = needReloadingUrl else {
            self.notReloadMainFrameOfFullPkg = true
            return
        }
        DispatchQueue.main.async {
            self.waitingDownloadFullPkgStatistics(isStart: false)
            
            if !UserScopeNoChangeFG.HZK.fullPkgUnzipOptimize {
                
                let type = self.getRealFileType(from: url)
                GeckoPackageManager.shared.recordWaitingDownloadFullPkgTime(isStart: false)
                self.docsLoader?.rootTracing.info("fullPackageHasReady fileType: \(type?.name ?? "")")
                self.load(url: self.getMainFrameUrl())
                self.removeSPView()
                self.load(url: url)
                
                // Mark一下，当前BrowserView不再加入复用池，因为没有加载完整包的模板, 目前只有doc、sheet文档会
                // 如果当前的文档打开的是doc/sheet，不能重新加载当前webView的模板，会导致白屏，所以要标记一下，用完不再放入复用池
                self.notReloadMainFrameOfFullPkg = true
                
            } else {
                // MARK: 注意这里，后续如果恢复使用精简包，需要保留这里的逻辑，去掉fullPkgUnzipOptimize也不要删除下面这段代码，进行屏蔽即可
                if let type = self.getRealFileType(from: url), !self.notNeedCheckTypes.contains(type) {
                    GeckoPackageManager.shared.recordWaitingDownloadFullPkgTime(isStart: false)
                    self.docsLoader?.rootTracing.info("fullPackageHasReady fileType: \(type.name)")
                    self.load(url: self.getMainFrameUrl())
                    self.removeSPView()
                    self.load(url: url)
                } else {
                    // Mark一下，当前BrowserView不再加入复用池，因为没有加载完整包的模板, 目前只有doc、sheet文档会
                    // 如果当前的文档打开的是doc/sheet，不能重新加载当前webView的模板，会导致白屏，所以要标记一下，用完不再放入复用池
                    self.notReloadMainFrameOfFullPkg = true
                }
            }
            
        }
    }

    
    private func getMainFrameUrl() -> URL {
        var mainFrameUrl = DocsUrlUtil.mainFrameTemplateURL()
        mainFrameUrl = DocsUrlUtil.changeUrl(mainFrameUrl, schemeTo: DocSourceURLProtocolService.scheme)
        return mainFrameUrl
    }
    
    override public func evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)?) {
        callJsString(script, funcName: "evalJS", completionHandler: completion)
    }

    override public func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        autoreleasepool {
            var paramsStr: String?
            if let params = params {
                let paramsStrBeforeFix = params.ext.toString()
                paramsStr = JSServiceUtil.fixUnicodeCtrlCharacters(paramsStrBeforeFix ?? "", function: function.rawValue)
            }

            let script = function.rawValue + "(\(paramsStr ?? ""))"
            callJsString(script, funcName: function.rawValue, completionHandler: completion)
        }
    }

    private func callJsString(_ javaScriptString: String, funcName: String, completionHandler: ((Any?, Error?) -> Void)?) {
        let runJSBlock = {
            self.webView.evaluateJavaScript(javaScriptString) { [weak self] (obj, error) in
                completionHandler?(obj, error)
                guard let error = error, let self = self else { return }
                #if DEBUG
                DocsLogger.debug("evaluateJavaScript for \(self.editorIdentity) fail, js func:\(funcName)", error: error, component: nil)
                #else
                DocsLogger.error("evaluateJavaScript for \(self.editorIdentity) fail, js func:\(funcName)", error: error, component: nil)
                #endif
            }
        }
        //如果是webview挂掉了，且不在视图层级直接不执行JS
        if webLoader?.webviewHasBeenTerminated.value == true, webLoader?.getIsInViewHierarchy() == false {
            DocsLogger.error("\(self.editorIdentity), webview Has Been Terminated，don't call JS")
            return
        }
        if Thread.isMainThread {
            runJSBlock()
        } else {
            DispatchQueue.main.async {
                runJSBlock()
            }
        }
    }

    override public func hideLoadingIfNeed() {
        if needUpdateSucWhenFinish {
            DocsLogger.info("loadFinish, updateSucStatus, \(editorIdentity)", component: LogComponents.fileOpen)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(waitDidFinishTimeout), object: nil)
            updateSucStatus()
        }
    }

    func updateSucStatus() {
        lifeCycleEvent.browserDidHideLoading()
        loadingDelegate?.updateLoadStatus(.success, oldStatus: nil)
    }
    
    @objc
    private func willEnterForeground() {
        checkForResponsiveness(from: .enterForeground)
        startInPoolCheckForResponsivenessTimer()
    }
    
    @objc
    private func didEnterBackground() {
        stopInPoolCheckForResponsivenessTimer()
    }
    
    @objc
    private func willResignActive() {
        stopInPoolCheckForResponsivenessTimer()
    }
    
    @objc
    private func simulateWebViewUnresponsive() {
#if BETA || ALPHA || DEBUG
        guard !self.isInEditorPool else { return }
        makeWebViewUnresponsive()
#endif
    }
    @objc
    private func killWebContentProcess() {//仅文档debug页面使用，正式功能不要使用
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500) { [weak self] in
            let web = self?.webView as? LarkWebView
            web?.killWebViewProcess()
            //Kill Process后，如果webview此时不可见，url会变成nil
        }
    }
}
extension WebBrowserView: ErrorPageProtocol {
    public func didClickReloadButton() {
        guard let webLoader = webLoader else {
            DocsLogger.error("didClickReloadButton error, webLoader is nil")
            return
        }
        webView.reload() // 这里得调用webview的reload
        webLoader.removeTerminateErrorPage()
    }
}

extension WebBrowserView {
    public func webViewGoBack() {
        webView.goBack()
    }
}

extension WebBrowserView: DocsLoaderDelegate {
    
    var renderSettingConfig: [String: Any]? {
        self.docComponentDelegate?.config.settingConfig
    }
    
    var fileConfigInfo: FileConfig? {
        self.fileConfig
    }
    
    func didTerminated() {
        lifeCycleEvent.browserTerminate()
    }
    
    func showTerminateErrorPage() {
        terminateErrorView.isHidden = false
        bringSubviewToFront(terminateErrorView)
        terminateErrorView.config(error: ErrorInfoStruct.terminateCode)
    }
    func removeTerminateErrorPage() {
        terminateErrorView.isHidden = true
    }
    
    func beforeCallRender(darkMode: Bool) {
        isRenderDarkMode = darkMode
        recordBeforeCallRender()
        if UserScopeNoChangeFG.LYL.enableStatisticTrace {
            lifeCycleEvent.browserBeforeCallRender()
        }
    }

    func didUpdateLoadStatus(_ status: LoadStatus, oldStatus: LoadStatus) {
        if !status.isLoading {
            //切换到非loading状态，都隐藏SSRWebview
            self.hideSSRWebViewIfNeed()
        }
        
        switch status {
        case .unknown: ()
        case .loading:
            handleLoadingStatus(status)
        case .success:
            let waitFinishMaxTime = SettingConfig.openDocsConfig?.hideLoadingWaitFinishMaxTime ?? 2.0
            DocsLogger.info("\(editorIdentity) LoadStatus=success, didNaviLoadEnd=\(navigatorDidLoadEnd), progress:\(self.webView.estimatedProgress), waitTime:\(waitFinishMaxTime)", component: LogComponents.fileOpen)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(waitDidFinishTimeout), object: nil)
            if navigatorDidLoadEnd {
                needUpdateSucWhenFinish = false
                updateSucStatus()
            } else {
                if waitFinishMaxTime < 0 { // -1一直wait
                    needUpdateSucWhenFinish = true
                } else if waitFinishMaxTime == 0 { // 0马上
                    needUpdateSucWhenFinish = false
                    updateSucStatus()
                } else { // >0延时
                    needUpdateSucWhenFinish = true
                    self.perform(#selector(waitDidFinishTimeout), with: nil, afterDelay: TimeInterval(waitFinishMaxTime))
                }
            }
        case .overtime:
            loadingDelegate?.updateLoadStatus(.overtime, oldStatus: oldStatus)
        case .cancel: ()
        case .fail:
            if URLValidator.isMainFrameTemplateURL(docsLoader?.currentUrl) == true {
                DocsLogger.info("\(editorIdentity) preload failed")
                return
            }
            if status.errorIsFromWebview {
                statisticsDidEndLoadFinishType(.nativeFail, resultCode: status.errCode)
            }
            if let msg = status.errorMsg {
                appendInfo(msg)
                loadingDelegate?.updateLoadStatus(.fail(msg: msg, code: status.newCodeFromMsg), oldStatus: oldStatus)
            } else {
                DocsLogger.error("status.errorMsg is nil")
            }
        }
        notifyLoadDocsResult(status)
        self.lifeCycleEvent.browserLoadStatusChange(status)
    }
    
    @objc
    func waitDidFinishTimeout() {
        DocsLogger.warning("\(editorIdentity) waiting too long, hide Loading rightNow,status:\(self.loadStatus),needUpdate:\(needUpdateSucWhenFinish)", component: LogComponents.fileOpen)
        if self.loadStatus.isSuccess {
            self.hideLoadingIfNeed()
        }
    }

    private func handleLoadingStatus(_ status: LoadStatus) {
        guard status.isLoading else {
            spaceAssertionFailure()
            return
        }
        switch status {
        case .loading(let loadStage):
            switch loadStage {
            case let .start(url: url, isPreload: isPreload):
                statisticsDidStartLoad(url.absoluteString, openType: isPreload ? .preload : .noPreload)
                openProgressManager?.showOpenBasicInfoIfNeeded(isPreload: isPreload, url: url, usedCount: usedCounter)
            case .preloadOk:
                guard let tmpDocsLoader = docsLoader else { return }
                statisticsLoaderDidEndLoadTemplate(tmpDocsLoader)
            case .renderCachStart: ()
            case .renderCacheSuccess:()
            case .renderCalled:
                guard let tmpDocsLoader = docsLoader else { return }
                statisticsLoaderDidCallRender(tmpDocsLoader)
                statisticsLoadingStageChangeTo(loadStage)
            case .afterReadLocalClientVar, .beforeReadLocalHtmlCache:
                statisticsLoadingStageChangeTo(loadStage)
            }
        default:
            spaceAssertionFailure()
        }
    }

    func requestShowLoadingFor(_ url: URL) {
        if self.ssrWebContainer?.superview != nil,
            self.ssrWebContainer?.isRenderEnd == true {
            //SSRWebView渲染完成后，不用再显示Loading状态
            DocsLogger.info("[ssr] ssrwebview showing, stop update loading status", component: LogComponents.ssrWebView)
            return
        }
        loadingDelegate?.updateLoadStatus(.larkLoading(url: url), oldStatus: nil)
    }

    private func notifyLoadDocsResult(_ status: LoadStatus) {
        switch status {
        case .success:
            NotificationCenter.default.post(name: Notification.Name.OpenFileRecord.AutoOpenEnd, object: ["open_docs_result": true], userInfo: nil)
            
        case .fail, .cancel, .overtime:
            NotificationCenter.default.post(name: Notification.Name.OpenFileRecord.AutoOpenEnd, object: ["open_docs_result": false], userInfo: nil)
        default: ()
        }
    }
}
