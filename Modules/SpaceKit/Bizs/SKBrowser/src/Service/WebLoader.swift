//
//  WebLoader.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/11/30.
// swiftlint:disable file_length line_length

import SKFoundation
import SwiftyJSON
import WebKit
import ThreadSafeDataStructure
import SKUIKit
import SKCommon
import EENavigator
import UniverseDesignToast
import SpaceInterface
import SKInfra
import LarkContainer
import LKCommonsTracker
import RunloopTools

// swiftlint:disable class_delegate_protocol
protocol DocsLoaderDelegate: SKExecJSFuncService {
//swiftlint:enable class_delegate_protocol
    func appendInfo(_ info: @autoclosure () -> String )
    func didUpdateLoadStatus(_ status: LoadStatus, oldStatus: LoadStatus)
    func requestShowLoadingFor(_ url: URL)
    func simulateJSMessage(_ msg: String, params: [String: Any])
    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?)
    func beforeCallRender(darkMode: Bool)
    func receiveRenderCallBack(success: Bool, error: Error?)
    func didLoadEnd(error: Error?)
    func killAndReloadWebView()
    func checkWebViewResponsiveInOpenOvertime()
//    func requestShowPartialLoading()
    var editorIdentity: String { get }
    
    var renderSettingConfig: [String: Any]? { get }
    
    var fileConfigInfo: FileConfig? { get }
    
    //白屏错误页
    func didTerminated()
    func showTerminateErrorPage()
    func removeTerminateErrorPage()
    func tryRenderSSRWebView(data: [String: Any]?) -> Bool
}

final public class WebLoader: NSObject, DocsLoader {
    
    public private(set) var loadStatus: LoadStatus = .unknown {
        didSet {
            delegate?.didUpdateLoadStatus(loadStatus, oldStatus: oldValue)
            rootTracing.info("loadStatus become \(loadStatus.descriptionInLog)")
        }
    }
    private(set) public var docsInfo: DocsInfo?
    private var isRenderOpen = false // 是否以render方式打开
    private(set) var isInViewHierarchy = false
    private var loadingDelayPast: Bool = false
    private var hadShowLoading: Bool = false
    private var hadRequestShowLoading: Bool = false
    private var isFirstLoadUrl: Bool = true //代理模式下第一次打开页面
    private(set) var preloadStatus = ObserableWrapper<PreloadStatus>(PreloadStatus())
    private(set) var webviewHasBeenTerminated = ObserableWrapper<Bool>(false)
    private(set) var preloadHtmlIsReady = false
    var webviewHasBeenNonResponsive = false
    private var ssrHitPreloadCache = false // 预加载框架接入，打开文档时feedback给框架
    
    private var clientInfos = SafeDictionary<String, String>()
    private(set) weak var webView: DocsWebViewProtocol?
    //崩溃恢复状态记录
    var shouldReloadAfterTerminateWhenBecomeForeground = false
    var currentReloadCount = 0
    weak var delegate: DocsLoaderDelegate?
    public var currentUrl: URL?
    public var naviHeight: CGFloat = 0
    lazy var webviewTerminateHandler: WebviewTerminateHandler = {
        let identify = String(describing: delegate?.editorIdentity)
        let handler = WebviewTerminateHandler(webView: self.webView, webviewIdentify: identify)
        return handler
    }()
    public var openSessionID: String?
    private lazy var newCache: NewCacheAPI? = {
        try? userResolver.resolve(assert: NewCacheAPI.self)
    }()
    
    // 提供给 log 进行追踪
    var editorIdForLog: String {
        return "\(delegate?.editorIdentity ?? "noid")"
    }
    public var tracingContext: TracingContext?
    public var tracingComponent: String {
        return LogComponents.fileOpen
    }
    public var tracingCommonParams: [String: Any] {
        return ["editorId": "\(editorIdForLog)"]
    }
    
    public var docContext: DocContext?
    
    var jsServiceManager: DocsJSServicesManager?
    var hasCheckResponsiveInOpen: Bool = false //是否在打开文档检测过卡死
    private var hasCalledRenderCache: Bool = false //是否调用了renderSSR (变量有歧义，后续删除掉)
    private (set) var renderSSRWebviewType: RenderSSRWebviewType = .none
    private var renderSSRInCSRWebView: Bool = false
    
    let userResolver: UserResolver
    
    public init(webView: DocsWebViewProtocol?,
                userResolver: UserResolver) {
        self.webView = webView
        self.userResolver = userResolver
        super.init()
        addObserverForTerminateRecovery()
    }

    deinit {}
    
    @discardableResult
    private func updateLoadStatus(_ newStatus: LoadStatus) -> Bool {
        var canUpdate = true
        let ignoreRepeatLoadStatus = SettingConfig.openDocsConfig?.ignoreRepeatLoadStatus ?? true
        if ignoreRepeatLoadStatus, self.loadStatus.isSuccess, case let .loading(val) = newStatus {
            //如果已经是success状态，除了.loading(.start),不能流转到.loading状态，避免重复出现loading
            if case .start(_, _) = val {
                canUpdate = true
            } else {
                canUpdate = false
                DocsLogger.info("loadStatus become \(newStatus) but was ignored, now Status:\(self.loadStatus)", component: LogComponents.fileOpen)
            }
        }
        if canUpdate {
            loadStatus = newStatus
        }
        return canUpdate
    }

}

// MARK: - Load url
extension WebLoader {
    
    public func load(url: URL) {
        resetDocsInfo(url)
        if !UserScopeNoChangeFG.LJY.enableRenderSSRWhenPreloadHtmlReady {
            preloadIfNeed(url)
        }
        loadV2(url: url)
    }

    private func loadV2(url: URL) { // 3.11 加载流程，支持使用wikiurl直接加载
        realLoadUrl(url)
        if docsInfo != nil {
            enableHandoff(for: url)
            delegate?.simulateJSMessage(DocsJSService.utilUpdateDocInfo.rawValue, params: ["docsInfo": docsInfo!])
        }
    }

    private func preloadIfNeed(_ url: URL) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(preloadOvertime), object: nil)
        if let docsType = docsInfo?.type, !preloadStatus.value.hasPreload(docsType) {
            DocsLogger.info("[ssr] preloadIfNeed(\(docsType.rawValue), \(self.editorIdForLog)", component: LogComponents.fileOpen)
            startCheckPreloadJsModuleOvertimeIfNeed()
            let startTime = CFAbsoluteTimeGetCurrent()
            delegate?.callFunction(DocsJSCallBack.preloadJsModule, params: ["type": [docsType.name]]) { [weak self] (_, _) in
                guard let self = self else { return }
                let costTime = CFAbsoluteTimeGetCurrent() - startTime
                DocsLogger.info("call preloadJsModule complete,cost:\(costTime)", component: LogComponents.fileOpen)
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(type(of: self).preloadOvertime), object: nil)
            }
            rootTracing.startChildAndEndAutomatically(spanName: SKBrowserTrace.callPreloadTemplete,
                                                       params: ["fileType": docsInfo?.type.name ?? ""])
        }
    }

    private func realLoadUrl(_ url: URL) {
        rootTracing.startChild(spanName: SKBrowserTrace.loadUrl)
        guard let webView = webView else {
            spaceAssertionFailure("no webview")
            rootTracing.endSpan(spanName: SKBrowserTrace.loadUrl, spanResult: .error(errMsg: "no webview"))
            return
        }
        cancleDeferringOvertimeTip()
        currentUrl = url
        if WebViewSchemeManager.enableCustomSchemeIfNeed(url: url, webView: webView) == false {
            DocsLogger.info("restore to http link", component: LogComponents.fileOpen)
            currentUrl = WebViewSchemeManager.removeCustomDocsSourceScheme(for: url)
        }
        guard currentUrl != nil else {
            spaceAssertionFailure()
            rootTracing.endSpan(spanName: SKBrowserTrace.loadUrl,
                                 spanResult: .error(errMsg: "urlIsNil"))
            return
        }
        let openUrl = URLValidator.standardizeDocURL(currentUrl!)
        currentUrl = openUrl
        disableScrollViewBounceIfNeed()
        if !URLValidator.isMainFrameTemplateURL(openUrl) {
            delayShowOvertimeTip()
        }

        if OpenAPI.enableOptimizateLoadUrl == true {
            DispatchQueue.main.async {
                self.startToLoad(url: openUrl)
            }
        } else {
            self.startToLoad(url: openUrl)
        }
    }

    private func startToLoad(url: URL) {
        isInViewHierarchy = true
        let url = addExtraInfo(url: url)
        if URLValidator.isMainFrameTemplateURL(url) {
            updateLoadStatus(.loading(.start(url: url, isPreload: false)))
            loadRequest(with: url)
            rootTracing.endSpan(spanName: SKBrowserTrace.loadUrl,
                                 params: ["loadType": "templete"])
            
        } else if !OpenAPI.offlineConfig.protocolEnable {
            //代理模式下，支持模版复用，第一次打开直接打开，第二次走Render
            if UserScopeNoChangeFG.LJY.enableRenderSSRWhenPreloadHtmlReady {
                preloadIfNeed(url)
            }
            
            if !isFirstLoadUrl && OpenAPI.docs.isAgentRepeatModuleEnable {
                isRenderOpen = true
                updateLoadStatus(.loading(.start(url: url, isPreload: true)))
                startRender(url: url, isRenderCache: false)
            } else {
                isFirstLoadUrl = false
                updateLoadStatus(.loading(.start(url: url, isPreload: false)))
                loadRequest(with: url)
                preloadStatusChangeBind(url: url)
            }
        
            rootTracing.endSpan(spanName: SKBrowserTrace.loadUrl,
                                 params: ["loadType": "openWithoutOffline"])
        } else {
            let canRender = canRender()
            updateLoadStatus(.loading(.start(url: url, isPreload: canRender)))
            var isRenderCache = false
            
            //render之前尝试使用独立SSRWebView渲染SSR
            isRenderCache = renderCachedHtmlIfNeeded(isFromSSRWebView: true)
            if !isRenderCache, UserScopeNoChangeFG.LJY.enableRenderSSRWhenPreloadHtmlReady {
                //如果没用独立SSRWebView，尝试render()之前使用普通CSRWebView渲染SSR
                isRenderCache = tryRenderCacheHtmlBeforeRender(canRender)
            }
            
            if canRender {
                isRenderOpen = true
                startRender(url: url, isRenderCache: isRenderCache)
                rootTracing.endSpan(spanName: SKBrowserTrace.loadUrl,
                                     params: ["loadType": "normal",
                                              "isRenderOpen": isRenderOpen,
                                              "isNeedPreloadTemplete": false])
                rootTracing.startChild(spanName: SKBrowserTrace.pullJS)
                
            } else {
                isRenderOpen = false
                if UserScopeNoChangeFG.LJY.enableRenderSSRWhenPreloadHtmlReady {
                    if !self.needWatingPreloadHtml() {
                        //先判断是否需要等待htmlReady，需要则先不触发预加载。
                        //为了优先ssr，将preloadStatusChangeBind放在htmlReady之后,updatePreloadHtmlReadyStatus里触发
                        preloadStatusChangeBind(url: url)
                    }
                } else {
                    preloadStatusChangeBind(url: url) //会间接触发preloadIfNeed
                }
                rootTracing.endSpan(spanName: SKBrowserTrace.loadUrl,
                                     params: ["loadType": "normal",
                                              "isRenderOpen": isRenderOpen,
                                              "isNeedPreloadTemplete": true])
                rootTracing.startChild(spanName: SKBrowserTrace.waitPreloadTemplete)
            }
        }
    }

    private func preloadStatusChangeBind(url: URL, needPreload: Bool = true) {
        preloadStatus.bind(target: self) { [unowned self] (status) in
            guard let type = self.docsInfo?.type, status.hasPreload(type) else {
                if needPreload {
                    self.preloadIfNeed(url)
                }
                return
            }
            self.preloadStatus.bind(target: self, block: nil)
            updateLoadStatus(.loading(.preloadOk))
            rootTracing.endSpan(spanName: SKBrowserTrace.waitPreloadTemplete)
            rootTracing.startChild(spanName: SKBrowserTrace.pullJS)
            self.startRender(url: url, isRenderCache: false)
        }
    }
    
    func updatePreloadHtmlReadyStatus(preloadTypes: [String]) {
        self.preloadHtmlIsReady = true
        guard canRenderSSRInpreloadHtmlReady(), let docsInfo = self.docsInfo else {
            return
        }
        // 只在loading的时候做ssr渲染，比如opps之后刷新也会触发这里，但这时不需要提前渲染ssr
        guard loadStatus.isLoading else {
            DocsLogger.info("[ssr] updatePreloadHtmlReadyStatus not loading status, do nothing", component: LogComponents.fileOpen)
            return
        }
        
        let isRenderCache = renderCachedHtmlIfNeeded()
        let canRender = canRender()
        let needPreload = !preloadTypes.contains(docsInfo.type.name) //避免重复调用preloadJSModule
        DocsLogger.info("[ssr] renderCacheHtml in preloadHtmlReadyChangeBind, result:\(isRenderCache), canRender:\(canRender), needPreload:\(needPreload)", component: LogComponents.fileOpen)
        if !canRender, let url = self.currentUrl {
            // 如果模板没有准备好，在htmlReady后再触发一下预加载
            preloadStatusChangeBind(url: url, needPreload: needPreload)
        }
    }

    private func startRender(url: URL, isRenderCache: Bool) {
        //代理模式下模版复用，不做这个判断
        if !OpenAPI.docs.isAgentRepeatModuleEnable {
            guard let type = docsInfo?.type, preloadStatus.value.hasPreload(type) else {
                spaceAssertionFailure("必须ready以后才能调用这个")
                return
            }
        }
        
        var isRenderCache = isRenderCache //是否真正render了SSR
        if !UserScopeNoChangeFG.LJY.enableRenderSSRWhenPreloadHtmlReady || self.hasCalledRenderCache == false {
            DocsLogger.info("[ssr] renderSSR If Need with render", component: LogComponents.fileOpen)
            isRenderCache = renderCachedHtmlIfNeeded()
        }
        let renderBlock = {
            if self.render(url) != nil {
            } else {
                self.loadRequest(with: url)
                spaceAssertionFailure("取不到render的参数")
                self.delegate?.appendInfo("not render, load url \(url)")
            }
        }
        if isRenderCache == true {
            //如果是使用了render Cache，真正的数据等下次runloop再执行
            DispatchQueue.main.async {
                renderBlock()
            }
        } else {
            renderBlock()
        }
    }

    public func setNavibarHeight(naviHeight: CGFloat) {
        self.naviHeight = naviHeight
    }
    
    
    @discardableResult
    private func tryRenderCacheHtmlBeforeRender(_ canRender: Bool) -> Bool {
        guard canRenderSSRInpreloadHtmlReady() else {
            return false
        }
        
        hasCalledRenderCache = true
        if self.preloadHtmlIsReady || canRender {
            let isRenderCache = renderCachedHtmlIfNeeded()
            DocsLogger.info("[ssr] tryRenderCacheHtml before render \(self.editorIdForLog), jsReady:\(self.preloadHtmlIsReady) , isRenderOpen:\(canRender), result:\(isRenderCache)", component: LogComponents.fileOpen)
            return isRenderCache
        } else {
            //html还没就绪，waiting
            DocsLogger.info("[ssr] waiting preloadHtmlReady to renderSSR", component: LogComponents.fileOpen)
            return false
        }
    }
    
    /// 是否需要等待preloadHtml
    private func needWatingPreloadHtml() -> Bool {
        //在preloadHtml ready前调用了render ssr，就认为需要等待
        return self.hasCalledRenderCache && !self.preloadHtmlIsReady
    }
    

    /// 告知H5首批数据
    /// params: isFromSSRWebView: SSRWebView发起渲染
    // swiftlint:disable cyclomatic_complexity
    private func renderCachedHtmlIfNeeded(isFromSSRWebView: Bool = false) -> Bool {
        if isFromSSRWebView, !self.canRenderCacheInSSRWebView() {
            return false
        }
        if self.renderSSRInCSRWebView || self.renderSSRWebviewType != .none {
            DocsLogger.warning("[ssr] repeat render ssr!!", component: LogComponents.fileOpen)
            return false
        }
        
        updateLoadStatus(.loading(.beforeReadLocalHtmlCache))
        rootTracing.startChild(spanName: SKBrowserTrace.readLocalHtmlCache)
        guard let docsInfo = docsInfo else {
            return false
        }
        if docsInfo.isFromWiki {
            delegate?.appendInfo("render wiki SSR")
        }
        // 使用 wiki 的真实类型加载 SSR
        let type = docsInfo.originType
        // 用 wiki 内容的 token
        let token = docsInfo.originToken
        switch type {
        case .doc:
            if docsInfo.isFromWiki {
                // wiki doc 1.0 不使用 SSR
                return false
            }
        case .docX:
            if !LKFeatureGating.docxSSREnable && !UserScopeNoChangeFG.HZK.enableIpadSSR {
                return false
            }
        case .sheet:
            guard LKFeatureGating.sheetSSRFg else {
                return false
            }
        default:
            return false
        }
        guard let isHistory = self.currentUrl?.absoluteString.contains("#history"), isHistory == false else { return false }
        // 判断当前页面是否为订阅详情页
        guard isSubscription() == false else {
            return false
        }
        guard let renderKey = type.htmlCachedKey,
              let prefix = User.current.info?.cacheKeyPrefix
        else {
            return false
        }
        
        guard let record = newCache?.getH5RecordBy(H5DataRecordKey(objToken: token, key: prefix + renderKey)),
              let cachedHtml = record.payload
        else {
            if DocHtmlCacheFetchManager.fetchSSRBeforeRenderEnable() {
                //没有ssr，可能正在加载中，先尝试使用ssr webview，data传nil
                if delegate?.tryRenderSSRWebView(data: nil) == true {
                    //使用SSRWebView渲染SSR
                    self.hasCalledRenderCache = true
                    self.renderSSRWebviewType = .fetchSSR
                    return true
                }
            }
            return false
        }
        
        guard let tmpDic = self.handleCachedHtml(cachedHtml, record: record) else {
            return false
        }
        
        defer {
            if OpenAPI.docs.enableSSRCahceToastForTest, let showView = webView {
                // disable-lint: magic number
                let delay = TimeInterval(2.5)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    UDToast.showTips(with: "SSR load Success, ssrwebview:\(self.renderSSRWebviewType) , from: \(record.cacheFrom)", on: showView)
                }
                // enable-lint: magic number
            }
        }
        
        if delegate?.tryRenderSSRWebView(data: tmpDic) == false {
            guard isFromSSRWebView == false else {
                //从SSRWebView发起的渲染，不能调用到CSRWebview的renderCachedHtml
                return false
            }
            //使用CSRWebView渲染SSR
            self.hasCalledRenderCache = true
            self.renderSSRInCSRWebView = true
            DocsLogger.info("[ssr] redner ssr in csrwebview", component: LogComponents.fileOpen)
            delegate?.callFunction(DocsJSCallBack.renderCachedHtml, params: tmpDic, completion: {  [weak self] (_, error) in
                guard let self = self else { return }
                let spanResult: SpanResult = error == nil ? .normal : .error(errMsg: "callbackFail")
                self.rootTracing.endSpan(spanName: SKBrowserTrace.renderLocalCacheHtml, spanResult: spanResult)
                self.delegate?.appendInfo("render cached html" + (error == nil ? "success" : "fail"))
                if let error = error {
                    DocsLogger.error("[ssr] render ssr err:\(error)", component: LogComponents.fileOpen)
                }
                self.updateLoadStatus(.loading(.renderCacheSuccess))
            })
        } else {
            //使用SSRWebView渲染SSR
            self.hasCalledRenderCache = true
            self.renderSSRWebviewType = .localSSR
        }
        return true
    }
    
    //抽取 处理ssr data，构建数据进行render ssr 的方法
    func handleCachedHtml(_ cachedHtml: NSCoding, record: H5DataRecord) -> [String: Any]? {
        guard let cachedHtmlDic = (cachedHtml as? [String: Any]) else { return nil }
        let mutDic = NSMutableDictionary(dictionary: cachedHtmlDic)
        let dic = ["statusBarHeight": self.webView?.window?.safeAreaInsets.top ?? 0,
                   "titleBarHeight": (self.naviHeight + SKDisplay.topBannerHeight)]
        mutDic.setValue(dic, forKey: "deviceInfo")
        
        if docsInfo?.inherentType == .docX,
            let url = currentUrl,
            let doccomponentSetting = DocComponentManager.getSceneConfig(for: url) {
            mutDic["docComponentConfig"] = doccomponentSetting.setting
            if let renderSettingConfig = self.delegate?.renderSettingConfig {
                mutDic["injectDocComponentConfig"] = renderSettingConfig
            }
        }
        
        if UserScopeNoChangeFG.HZK.enableIpadSSR && SKDisplay.pad {
            if let mode = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.widescreenModeLastSelected), !mode.isEmpty {
                mutDic["widescreenMode"] = mode
            } else {
                mutDic["widescreenMode"] = WidescreenMode.fullwidth.rawValue //默认值为true
            }
        }
        
        guard let tmpDic = (mutDic as? [String: Any]) else { return nil }
        // 命中预加载的缓存
        ssrHitPreloadCache = record.cacheFrom.isFromPreload
        recordHitPreloadIfNeed(for: record)
        OpenFileRecord.setSSRCacheFrom(record.cacheFrom.name, for: openSessionID)

        rootTracing.startChild(spanName: SKBrowserTrace.renderLocalCacheHtml)
        updateLoadStatus(.loading(.renderCachStart))
        if let data = tmpDic["data"] as? [String: Any], let version = data["clientVarsVersion"] as? Int64 {
            DocsLogger.info("SSR's clientVarsVersion:\(version)", component: LogComponents.fileOpen)
        }
        return tmpDic
    }
    
    private func canRenderSSRInpreloadHtmlReady() -> Bool {
        return UserScopeNoChangeFG.LJY.enableRenderSSRWhenPreloadHtmlReady &&
        self.docsInfo?.inherentType == .docX
    }

    // swiftlint:disable cyclomatic_complexity init_color_with_token
    // nolint: long_function
    @discardableResult
    private func render(_ originUrl: URL) -> String? {
        guard let userID = User.current.info?.userID, let tenantID = User.current.info?.tenantID else { return nil }
        let url: URL
        if UserScopeNoChangeFG.CS.renderUrlDeleteQueryFix {
            url = originUrl.docs.safeDeleteQuery(key: URLValidator.versionParam)
        } else {
            url = originUrl
        }
        guard let renderPath = DocsUrlUtil.getRenderPath(url)?.docs.escapeSingleQuote() else { return nil }
        updateLoadStatus(.loading(.renderCalled))
        rootTracing.endSpan(spanName: SKBrowserTrace.readLocalHtmlCache)
        rootTracing.startChild(spanName: SKBrowserTrace.readLocalClientVar)
        webView?.tryRecoveryOpaque()
        docsStartTrace(.readClientVar)
        defer {
            docsEndTrace(.readClientVar)
        }
        var parameters = [String: Any]()
        parameters["userId"] = userID
        parameters["tenantId"] = tenantID
        parameters["canCreateSheet"] = "1"
        parameters["timestamp"] = OpenFileRecord.timeStampDictForH5(for: openSessionID)
        parameters["isPreloadFinished"] = isRenderOpen ? 1 : 0
        /// 是否是通过模板创建新文档来的，会自动弹起键盘
        parameters["isTemplate"] = TemplateCreateFileRecord.isJustCreateFileByTemplate() ? true : false
        if let token = DocsUrlUtil.getFileToken(from: url), let scrollPos = MultiTaskService.docsScrollRecords[token] {
            parameters["x"] = scrollPos.x
            parameters["y"] = scrollPos.y
        }

        //从一事一档打开的文档
        if let associateAppUrl = delegate?.fileConfigInfo?.associateAppUrl {
            parameters[RouterDefine.associateAppUrl] = associateAppUrl
        }
        
        if let curDocInfo = docsInfo {
            var onlyCache = false
            if UserScopeNoChangeFG.HZK.docsRenderGetClintVarOnlyCache {
                //如果在CSRWebview渲染了ssr，读clientVar只读缓存+数据库，不读本地文件io
                onlyCache  = self.renderSSRInCSRWebView
            }
            let h5record = clientVarH5RecordKey(with: curDocInfo, onlyCache: onlyCache)
            var clientVarHitCache = false
            if let h5record, let clientVars = h5record.payload as? [String: Any] {
                parameters["clientvars"] = clientVars
                let cacheFrom = h5record.cacheFrom
                clientVarHitCache = cacheFrom.isFromPreload
                let key = H5DataRecordKey(objToken: h5record.objToken, key: h5record.key)
                recordHitPreloadIfNeed(for: h5record)
                if OpenAPI.docs.enableSSRCahceToastForTest, let showView = webView {
                    let delay = TimeInterval(1.5)
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        UDToast.showTips(with: "ClientVars load Success \(cacheFrom.name)", on: showView)
                    }
                }
            } else {
                rootTracing.info("cannot get client var when render")
                parameters["clientvars"] = ""
            }
            OpenFileRecord.setClientVarCacheFrom(h5record?.cacheFrom.name ?? H5DataRecordFrom.cacheFromUnKnown.name, for: openSessionID)
            userResolver.docs.editorManager?.preloadFeedback(curDocInfo.isVersion ? curDocInfo.token : curDocInfo.objToken, hitPreload: (clientVarHitCache || ssrHitPreloadCache))
        }
        if let objToken = docsInfo?.objToken {
            let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
            parameters["title"] = dataCenterAPI?.spaceEntry(objToken: objToken)?.name
        }
        if docsInfo?.type == .sheet {
            var preFetchDic: [String: Any] = [:]
            let plugInConfig = SKBaseDataPluginConfig(cacheService: DocsContainer.shared.resolve(NewCacheAPI.self)!, model: nil)
            if let dic = CCMKeyValue.globalUserDefault.dictionary(forKey: UserDefaultKeys.sheetPreFetchData),
                let arr = dic["prefetchKeys"] as? [String] {
                for key in arr {
                    let data = plugInConfig.cacheService.object(forKey: docsInfo?.objToken ?? "", subKey: key)
                    preFetchDic[key] = data
                }
                parameters["prefetchData"] = preFetchDic
            }
        }
        if docsInfo?.originType == .sync {
            if UserScopeNoChangeFG.LJW.syncBlockPermissionEnabled {
                //独立授权fg命中时不需要对token判空，前端会处理
                parameters["syncBlockSourceToken"] = docsInfo?.objToken
            } else if let parentToken = docsInfo?.objToken, !parentToken.isEmpty {
                parameters["syncBlockSourceToken"] = docsInfo?.objToken
            } else {
                let error = NSError(domain: LoaderErrorDomain.getSyncedBlockParent, code: LoaderErrorCode.syncedBlockParentTokenError.rawValue)
                self.failWithError(error)
                spaceAssertionFailure("load syncedBlock but has no parentToken")
                return nil
            }
        }
        if SKDisplay.pad {
            if let mode = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.widescreenModeLastSelected), mode.count > 0 {
                parameters["widescreenMode"] = mode
            } else {
                parameters["widescreenMode"] = WidescreenMode.fullwidth.rawValue //默认值为true
            }
        }
        parameters["theme"] = UIColor.docs.isCurrentDarkMode ? "dark" : "light"
        parameters["hasSSRWebView"] = self.renderSSRWebviewType != .none
        parameters["renderSSRWebviewType"] = self.renderSSRWebviewType.getIntValue()
        if let wikiInfo = docsInfo?.wikiInfo {
            parameters["wikiInfo"] = wikiInfo.dictValue
        }
        if let versionInfo = docsInfo?.versionInfo {
            var subparam = [String: Any]()
            subparam["version"] = versionInfo.version
            subparam["versionToken"] = versionInfo.versionToken
            parameters["versionInfo"] = subparam
            DocsLogger.info("render info \(versionInfo.version)", component: LogComponents.version)
        } else {
            DocsLogger.info("render info fail", component: LogComponents.version)
        }

        if docsInfo?.inherentType == .docX, let doccomponentSetting = DocComponentManager.getSceneConfig(for: url) {
            parameters["docComponentConfig"] = doccomponentSetting.setting
            OpenFileRecord.updateFileinfo([RouterDefine.docAppId: doccomponentSetting.appId], for: openSessionID)
            if let renderSettingConfig = self.delegate?.renderSettingConfig {
                parameters["injectDocComponentConfig"] = renderSettingConfig
            }
        }
        let renderStr = DocsJSCallBack.windowRender.rawValue + "('\(renderPath)',\(parameters.jsonString ?? "{}"))"
        rootTracing.endSpan(spanName: SKBrowserTrace.readLocalClientVar)
        rootTracing.startChild(spanName: SKBrowserTrace.callRenderFuc)
        
        if UserScopeNoChangeFG.CS.msDowngradeNewStrategyEnable,
           let downgradeInfo = UtilDowngradeService.getCurrentMSPowerDowngradeInfoParams(userResolver: userResolver) {
            let performanceInfo: [String: Any] = ["downgradeInfo": downgradeInfo]
            parameters["performanceInfo"] = performanceInfo
        } else {
            let performanceInfo: [String: Any] = ["thermalState": ProcessInfo.processInfo.thermalState.rawValue]
            parameters["performanceInfo"] = performanceInfo
        }
        
        var params = ["url": renderPath, "infos": parameters] as [String: Any]
        //mg域名优化，传对应文档mg api和长链
        if UserScopeNoChangeFG.HZK.mgDomainOptimize {
            let urlInfo = DocsUrlUtil.getDocsCurrentUrlInfo(url)
            if !urlInfo.docsApiPrefix.isEmpty, !urlInfo.frontierDomain.isEmpty { //两个都不为空才会传
                params["docsApiPrefix"] = urlInfo.docsApiPrefix
                params["frontierDomain"] = urlInfo.frontierDomain
            }
            if let unit = urlInfo.unit {
                params["unit"] = unit
            }
            if let brand = urlInfo.brand {
                params["brand"] = brand
            }
            if let srcUrl = urlInfo.srcUrl {
                params["srcUrl"] = srcUrl
            }
            if let srcHost = urlInfo.srcHost {
                params["srcHost"] = srcHost
            }
            DocsLogger.info("render docsApiPrefix: \(urlInfo.docsApiPrefix ?? ""), frontierDomain: \(urlInfo.frontierDomain), unit:\(urlInfo.unit ?? ""), brand:\(urlInfo.brand ?? "")", component: LogComponents.version)
        }
        
        delegate?.beforeCallRender(darkMode: UIColor.docs.isCurrentDarkMode)
        delegate?.callFunction(DocsJSCallBack.windowRender, params: params, completion: { [weak self] (_, error) in
            guard let self = self else { return }
            self.delegate?.receiveRenderCallBack(success: error == nil, error: error)
            if let err = error {
                self.rootTracing.endSpan(spanName: SKBrowserTrace.callRenderFuc,
                                          spanResult: .error(errMsg: "render faile"))
                let urlErr = err as NSError
                if UserScopeNoChangeFG.GXY.renderReportEnable {
                    self.cancleDeferringOvertimeTip()
                    let error = NSError(domain: LoaderErrorDomain.failEventRender, code: urlErr.code, userInfo: nil)
                    self.failWithError(error)
                    DocsLogger.info("render error:\(urlErr)")
                }
                #if DEBUG
                #else
                    var params: [String: Any] = [:]
                    params["file_type"] = self.docsInfo?.type.name ?? "unknown"
                    params["error_code"] = urlErr.code
                    params["doc_from"] = self.docsInfo?.openDocsFrom.rawValue ?? ""
                    params["err_msg"] = urlErr.userInfo.description
                    DocsTracker.newLog(enumEvent: .docsRenderJSFailPerformance, parameters: params)
                #endif
            } else {
                self.rootTracing.endSpan(spanName: SKBrowserTrace.callRenderFuc)
            }
        })
        updateLoadStatus(.loading(.afterReadLocalClientVar))
        delegate?.appendInfo("call render:" + renderStr)
        return renderPath
    }

    func getIsInViewHierarchy() -> Bool {
        return isInViewHierarchy
    }
    
    public func reload(with docUrl: URL?) {
        if let url = docUrl ?? currentUrl {
            rootTracing.info("reload url")
            //每次reloadURL，是一次新的打开过程
            openSessionID = OpenFileRecord.generateNewOpenSession()
            load(url: url)
        } else {
            rootTracing.error("can not reload url", errMsg: "url is nil")
        }
    }

    func updateMainFrameStatus(_ status: PreloadStatus) {
        preloadStatus.value = status
    }

    public func canRender() -> Bool {
        guard let fileType = docsInfo?.type else { return false }
        return preloadStatus.value.hasPreload(fileType)
    }

    public func updateClientInfo(_ newInfos: [String: String]) {
        newInfos.forEach { (key, value) in
            clientInfos[key] = value
        }
    }

    func addExtraInfo(url: URL) -> URL {
        let params: [String: String] = {
            var dict = [String: String]()
            if let feedID = clientInfos["feedID"], !feedID.isEmpty {
                dict["sourceType"] = "feed"
            }
            return dict
        }()
        return url.docs.addQuery(parameters: params)
    }

    private func loadRequest(with url: URL) {
        let req = URLRequest(url: url)
        webView?.load(req)
    }

    private func enableHandoff(for url: URL) {
        guard URLValidator.isMainFrameTemplateURL(url) == false else { return }
        let httpUrl = DocsUrlUtil.changeUrl(url, schemeTo: "https")
        webView?.userActivity = NSUserActivity.openWebPage(httpUrl.absoluteString)
        webView?.userActivity?.becomeCurrent()
    }

    private func disableScrollViewBounceIfNeed() {
        if !UserScopeNoChangeFG.LYL.disableFixBitableWKScrollViewBounces,
            self.docsInfo?.inherentType == .bitable {
            // iOS16.0 ～ 16.1 版本，在 Base 甘特视图退后台或者进入 itemView 再返回，下拉会触发  UIScrollView 的弹性
            // 而 Base 场景不需要原生的弹性所以这里直接禁用
            self.webView?.scrollView.bounces = false
            self.webView?.scrollView.alwaysBounceVertical = false
        } else {
            self.webView?.scrollView.bounces = (self.docsInfo?.type != .sheet)
        }
    }
    
    private func clientVarH5RecordKey(with docsInfo: DocsInfo, onlyCache: Bool) -> H5DataRecord? {
        if docsInfo.type == .wiki { // 对wiki类型进行特殊处理
            guard let wikiInfo = docsInfo.wikiInfo else {
                spaceAssertionFailure("no wiki info in docsinfo @peipei")
                return nil
            }
            // 如果是wiki类型，需要先取到wiki到对应单品的信息，然后再去除对应单品的clientVar
            let wikiKey = H5DataRecordKey(objToken: docsInfo.token, key: wikiInfo.docsType.clientVarKey())
            return newCache?.getH5RecordBy(wikiKey, onlyCache: onlyCache)
        } else {
            let recordKey = H5DataRecordKey(objToken: docsInfo.originToken, key: docsInfo.originType.clientVarKey())
            return newCache?.getH5RecordBy(recordKey, onlyCache: onlyCache)
        }
    }

    private func recordHitPreloadIfNeed(for record: H5DataRecord) {
        guard UserScopeNoChangeFG.LJW.recordHitPreloadEnabled else { return }
        //记录预加载缓存被命中
        if record.cacheFrom == .cacheFromPreload {
            let key = H5DataRecordKey(objToken: record.objToken, key: record.key)
            RunloopDispatcher.shared.addTask(priority: .low) { [weak self] in
                guard self != nil else { return }
                self?.newCache?.updateCacheFrom(key, cacheFrom: .cacheHasBeenHitFromPreload)
            }.waitCPUFree()
        }
    }
}

extension WebLoader {
    public func resetDocsInfo(_ url: URL) {
        rootTracing.startChild(spanName: SKBrowserTrace.resetDocsInfo)
        if let type = DocsType(url: url),
            let token = DocsUrlUtil.getFileToken(from: url, with: type), token.isEmpty == false {
            let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
            let spaceEntry = dataCenterAPI?.spaceEntry(objToken: token)
            let version: String? = url.queryParameters["wiki_version"]
            self.docsInfo = spaceEntry?.transform() ?? DocsInfo(type: type, objToken: token)
            if type == .wiki {
                if let wikiInfo = self.userResolver.docs.browserDependency?.getWikiInfo(by: token, version: version) {
                    self.docsInfo?.wikiInfo = wikiInfo
                } else {
                    spaceAssertionFailure("wiki no realtype @peipei")
                }
            }
            if type == .sheet, let fileIdKey = DocsContainer.shared.resolve(DriveShadowFileManagerProtocol.self)?.fileIdParamKey {
                let shadowFileId = url.queryParameters[fileIdKey]
                docsInfo?.shadowFileId = shadowFileId
            }
            if type == .sync {
                if case .syncedBlock(let parentToken) = docContext,
                    UserScopeNoChangeFG.LJW.syncBlockPermissionEnabled || parentToken != nil {
                    docsInfo?.objToken = parentToken ?? ""
                    docsInfo?.type = .docX
                } else {
                    let error = NSError(domain: LoaderErrorDomain.getSyncedBlockParent, code: LoaderErrorCode.syncedBlockParentTokenError.rawValue)
                    self.failWithError(error)
                    spaceAssertionFailure("load syncedBlock but has no parentToken")
                }
            }
            //同步块sync类型不需要请求版本数据
            if let fileType = self.docsInfo?.originType,
               let token = self.docsInfo?.originToken,
                fileType.supportVersionInfo {
                DocsVersionManager.shared.getVersionDataFor(token: token, type: fileType)
                DocsVersionManager.shared.requestAllVersionNames(token: token, type: fileType)
            }
            
            if type.supportVersionInfo {
                DocsVersionManager.shared.checkDocsToken(type: type, token: token)
            }
            
            if  !URLValidator.isMainFrameTemplateURL(url),
                let fileType = self.docsInfo?.inherentType,
                fileType.supportVersionInfo,
                url.isVersion,
                !URLValidator.isVCFollowUrl(url),
                let stoken = self.docsInfo?.sourceToken,
               let vernum = URLValidator.getVersionNum(url) {
                DocsLogger.info("current is verison", component: LogComponents.version)
                let (versionToken, vName, createtime, updatetime, creator, creator_en, aliasInfo) = DocsVersionManager.shared.getVersionTokenForToken(token: stoken, type: fileType, version: vernum)
                if versionToken != nil, vName != nil {
                    let vinfo = VersionInfo(objToken: token,
                                            versionToken: versionToken!,
                                            version: vernum,
                                            name: vName!,
                                            create_time: createtime,
                                            update_time: updatetime,
                                            creator_name: creator,
                                            creator_name_en: creator_en,
                                            aliasInfo: aliasInfo)
                    self.docsInfo?.versionInfo = vinfo
                } else {
                    spaceAssertionFailure("version data not ready")
                }
            }
            
            if let from = url.docs.queryParams?["from"] {
                if from == DocsVCFollowFactory.fromKey {
                    self.docsInfo?.isInVideoConference = true
                } else if from == OpenDocsFrom.docsfeed.rawValue {
                    self.docsInfo?.openDocsFrom = .docsfeed
                } else if from == OpenDocsFrom.baseInstructionDocx.rawValue {
                    self.docsInfo?.openDocsFrom = .baseInstructionDocx
                }
            }
            
            rootTracing.endSpan(spanName: SKBrowserTrace.resetDocsInfo,
                                 params: ["type": type.rawValue,
                                          "isInVC": self.docsInfo?.isInVideoConference ?? false])
        } else {
            rootTracing.endSpan(spanName: SKBrowserTrace.resetDocsInfo)
            self.docsInfo = nil
            DocsLogger.info("Url error， docs Info is nil")
        }
    }
    
    public func updateVersionInfo() {
        if  self.docsInfo?.isVersion ?? false,
            let fileType = self.docsInfo?.inherentType,
            let versionInfo = self.docsInfo?.versionInfo {
            DocsLogger.info("update verison info", component: LogComponents.version)
            let (versionToken, vName, createtime, updatetime, creator, creator_en, aliasInfo) = DocsVersionManager.shared.getVersionTokenForToken(token: versionInfo.objToken, type: fileType, version: versionInfo.version)
            if versionToken != nil, vName != nil {
                let vinfo = VersionInfo(objToken: versionInfo.objToken,
                                        versionToken: versionToken!,
                                        version: versionInfo.version,
                                        name: vName!,
                                        create_time: createtime,
                                        update_time: updatetime,
                                        creator_name: creator,
                                        creator_name_en: creator_en,
                                        aliasInfo: aliasInfo)
                self.docsInfo?.versionInfo = vinfo
            } else {
                spaceAssertionFailure("version data not ready")
            }
        }
    }
}

extension WebLoader {
    // 判断当前页面是否为订阅详情页
    private func isSubscription() -> Bool {
        if let url = self.currentUrl, let subscription = url.docs.queryParams?["subscription"] {
            return subscription == "1"
        }
        return false
    }
}
 
extension WebLoader: EditorConfigDelegate {
    public var editorRequestHeaders: [String: String] {
        var userAgent = UserAgent.defaultWebViewUA
        let language = (Locale.preferredLanguages.first ?? Locale.current.identifier).hasPrefix("zh") ? "zh" : "en"
        userAgent +=  " [\(language)] Bytedance"
        userAgent += " \("DocsSDK")/\(SpaceKit.version)"
        clientInfos.forEach({ (key, value) in
            userAgent += " \(key)/\(value)"
        })
        var dict = requestHeader
        dict["User-Agent"] = userAgent
        return dict
    }

    public var netRequestHeaders: [String: String] {
        var dict = requestHeader
        dict["User-Agent"] = UserAgent.defaultNativeApiUA
        return dict
    }

    private var requestHeader: [String: String] {
        return SpaceHttpHeaders()
            .addLanguage()
            .addCookieString()
            .merge(clientInfos.getImmutableCopy())
            .merge(SpaceHttpHeaders.common)
            .dictValue
    }
}

extension WebLoader: BrowserViewLifeCycleEvent {
    public func browserDidGetWikiInfo(error: Error?) {
        if let error = error {
            updateLoadStatus(.fail(error: error))
            rootTracing.startChildAndEndAutomatically(spanName: SKBrowserTrace.openDocFinish, spanResult: .error(errMsg: error.localizedDescription))
        } else if docsInfo?.isFromWiki ?? false {
            loadAfterGotRealToken()
        } else {
            spaceAssertionFailure("docsInfo is not wiki")
        }
    }

    private func loadAfterGotRealToken() {
        rootTracing.info("loadAfterGotRealToken")
        guard let url = currentUrl, let docInfo = docsInfo else {
            spaceAssertionFailure("loadAfterGotRealTokenm current url is \(currentUrl?.description ?? ""), docInfo is \(String(describing: docsInfo))")
            return
        }
        let openUrl: URL = {
            var component = URLComponents(url: url, resolvingAgainstBaseURL: false)
            component?.path = DocsUrlUtil.url(type: docInfo.type, token: docInfo.objToken, originUrl: url).path
            var queryItems = component?.queryItems
            queryItems?.append(.init(name: "wiki_token", value: docsInfo?.wikiInfo?.wikiToken))
            component?.queryItems = queryItems
            return component?.url ?? url
        }()
        realLoadUrl(openUrl)
    }

    public func removeContentIfNeed() {
        if preloadStatus.value.hasLoadSomeThing {
            rootTracing.info("called window.clear(), \(delegate != nil)")
            delegate?.callFunction(DocsJSCallBack.windowClear, params: nil, completion: nil)
        }
    }

    public func browserWillClear() {
        preloadStatus.bind(target: self, block: nil)
        removeContentIfNeed()
        clientInfos["feedID"] = nil
        webView?.userActivity?.resignCurrent()
        if isLoading {
            updateLoadStatus(.cancel)
        }
        if !loadingDelayPast {
            reportHasShowLoading()
        }
        hadRequestShowLoading = false
        self.webView?.scrollView.bounces = true
        hasCalledRenderCache = false
        loadingDelayPast = false
        hadShowLoading = false
        isInViewHierarchy = false
        webviewHasBeenNonResponsive = false
        ssrHitPreloadCache = false
        cancleDeferringOvertimeTip()
        self.renderSSRWebviewType = .none
        self.renderSSRInCSRWebView = false
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showLoading), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(preloadOvertime), object: nil)
    }
}

extension WebLoader: BrowserLoadingReporter {
    
    public func didHideLoading() {
        rootTracing.info("didHideLoading isLoading: \(isLoading)")
        if isLoading {
            updateLoadStatus(.success)
            rootTracing.startChildAndEndAutomatically(spanName: SKBrowserTrace.openDocFinish)
            SKMemoryMonitor.logMemory(when: "finish load browser \(editorIdForLog)", component: LogComponents.fileOpen)
            SKMemoryMonitor.logMemory(when: "finish load browser delay10 \(editorIdForLog)", delay: 10, component: LogComponents.fileOpen)
        }
        cancleDeferringOvertimeTip()
        delegate?.callFunction(DocsJSCallBack.notifyWebViewSizeChange,
                                             params: [:],
                                             completion: nil)
    }

    public func didLoadFinish() {
        self.delegate?.didLoadEnd(error: nil)
        if webviewHasBeenNonResponsive {
            DocsLogger.info("didLoadFinish after NonResponsive", component: LogComponents.fileOpen)
            reportLoadFinishAfterNonResponsive()
        }
    }

    public func failWithError(_ error: Error?) {
        DocsLogger.info("failWithError: \(error)", component: LogComponents.fileOpen)
        self.delegate?.didLoadEnd(error: error)
        updateLoadStatus(.fail(error: error))
        rootTracing.startChildAndEndAutomatically(spanName: SKBrowserTrace.openDocFinish,
                                                   spanResult: .error(errMsg: error?.localizedDescription ?? ""))
        if loadStatus.errorIsFromWebview {
            updateMainFrameStatus(PreloadStatus())
        }
        if loadStatus.shouldReload {
            openSessionID = OpenFileRecord.generateNewOpenSession()
            if let url = WebViewSchemeManager.disableDocsSourceSchemeIfNeed(for: currentUrl) {
                load(url: url)
            }
            rootTracing.info("reload with https")
        }
    }
}

extension WebLoader {
    func delayShowOvertimeTip() {
        var openDocTimeout = (DocsNetStateMonitor.shared.accessType == .wifi) ? OpenAPI.docs.wifiOpenDocTimeout : OpenAPI.docs.noWifiOpenDocTimeout
        openDocTimeout += self.canRender() ? 0 : OpenAPI.docs.templateWaitTime
        self.perform(#selector(type(of: self).becomeOverTime), with: nil, afterDelay: openDocTimeout)
        DocsLogger.info("delayShowOvertimeTip, openDocTime:\(openDocTimeout)")
    }

    public func resetShowOverTimeTip() {
        //进入后台时修改超时逻辑
        switch loadStatus {
        case .loading:
            guard  OpenAPI.docs.backGroundOpenDocTimeout > 0 else { return }
            rootTracing.info("resetShowOverTimeTip loading")
            cancleDeferringOvertimeTip()
            var backGroundOpenDocTimeout = OpenAPI.docs.backGroundOpenDocTimeout
            backGroundOpenDocTimeout += self.canRender() ? 0 : OpenAPI.docs.templateWaitTime
            self.perform(#selector(type(of: self).becomeOverTime), with: nil, afterDelay: backGroundOpenDocTimeout)
        default:
            rootTracing.info("resetShowOverTimeTip defaultValue")
        }
    }

    func cancleDeferringOvertimeTip() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(becomeOverTime), object: nil)
    }

    @objc
    func becomeOverTime() {
        rootTracing.info("becomeOverTime")
        updateLoadStatus(.overtime)
        startCheckWebViewResoponsiveInOpenIfNeed()
    }

    public func delayShowLoading() {
        if URLValidator.isMainFrameTemplateURL(currentUrl) {
            return
        }
        if hadRequestShowLoading {
            return
        }
        rootTracing.info("delayShowLoadingg")
        hadRequestShowLoading = true
        let delay = loadingDelayInSecond
        self.perform(#selector(type(of: self).showLoading), with: nil, afterDelay: delay)
    }

    @objc
    func showLoading() {
        spaceAssert(Thread.isMainThread)
        spaceAssert(!loadingDelayPast)
        defer {
            reportHasShowLoading()
            loadingDelayPast = true
        }
        guard isLoading else {
            rootTracing.info("no need show loading isLoading: \(isLoading), loadingDelayPast: \(loadingDelayPast)")
            return
        }
        hadShowLoading = true
        currentUrl.map {
            rootTracing.info("show Loading")
            delegate?.requestShowLoadingFor($0)
        }
    }

    private var isLoading: Bool {
        return loadStatus.isLoading
    }

    var loadingDelayInSecond: Double {
        // 这里不需要判断机型, 因为和复用个数无关, 只是用来控制UI
        if webviewReuseEnableInMS {
            return 0
        }
        return OpenAPI.browserLoadingDelayInSeconds
    }
    
    private var webviewReuseEnableInMS: Bool {
        let fgEnable = UserScopeNoChangeFG.CS.msWebviewReuseEnable
        return fgEnable
//        let abKey = "docs_ms_webview_reuse_enable_ios"
//        let abEnable: Bool
//        if let value = Tracker.experimentValue(key: abKey, shouldExposure: true) as? Int, value == 1 {
//            abEnable = true
//        } else {
//            abEnable = false
//        }
    }
    
    private func reportHasShowLoading() {
        rootTracing.info("has show loading", extraInfo: ["hadShowLoading": hadShowLoading])
        var params: [String: Any] = [DocsTracker.Params.hasShownLoading: hadShowLoading ? 1 : 0]
        params[DocsTracker.Params.fileType] = docsInfo?.type.name
        DocsTracker.log(enumEvent: .loadingHasShown, parameters: params)
    }
}


extension UIView {
    func isVisible() -> Bool {
        guard let window = window else {
            return false
        }
        guard !window.isHidden, !isHidden else {
            return false
        }
        return alpha > 0
    }
}
