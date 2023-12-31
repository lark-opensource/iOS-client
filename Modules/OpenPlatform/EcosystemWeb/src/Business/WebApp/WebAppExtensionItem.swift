//
//  WebAppExtensionItem.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2021/8/14.
//

import ECOInfra
import ECOProbe
import ECOProbeMeta
import EENavigator
import LarkContainer
import LarkFeatureGating
import LarkOPInterface
import LarkSetting
import LKCommonsLogging
import OPWebApp
import SnapKit
import TTMicroApp
import WebBrowser
import WebKit
import LarkOpenAPIModel
import OPSDK
import RustPB
import AppContainer
import OPPluginManagerAdapter
import LarkOpenWorkplace

let webBrowserInterruptionNotification = "kWebBrowserInterruptionNotification"  // code from yiying 逻辑无改动

private struct OfflineSessionExpireSetting: SettingDecodable {
    static var settingKey  = UserSettingKey.make(userKeyLiteral: "op_web_offline_session_request_timer")
    let timer: Int
}

// 应用识别迁移到 Extension framework 框架下，和容器解耦合，先做好解耦合，然后交接到 API 组
final public class WebAppExtensionItem: NSObject, WebBrowserExtensionItemProtocol, OPNoticeViewDelegate, OPHeartBeatMonitorBizProvider {
    public var itemName: String? = "WebApp"
    public var webAppJsSDKWithAuth: WebAppApiAuthJsSDKProtocol? {
        guard let browser = browser else { return nil }
        guard let webPageAppID = ecosyetemWebDependency.appInfoForCurrentWebpage(browser: browser)?.id else {
            let msg = "current page has not config, please contact website develop, call config first"
            Self.logger.error(msg)
            return nil
        }
        // code from xiangyuanyuan
        guard let apiAuthenStatus = ecosyetemWebDependency.appInfoForCurrentWebpage(browser: browser)?.apiAuthenStatus, apiAuthenStatus == .authened else {
            let msg = "current page has not config, please contact website develop, call config first"
            Self.logger.error(msg)
            return nil
        }
        if let auth = webAppJsSDKWithAuthDic[webPageAppID] {
            return auth
        } else {
            let newAuthJsSDK = ecosyetemWebDependency.getWebAppJsSDKWithAuthorization(appId: webPageAppID, apiHost: browser)
            webAppJsSDKWithAuthDic[webPageAppID] = newAuthJsSDK
            return newAuthJsSDK
        }
    }
    public private(set) lazy var apiInvokeInterceptorChain: OpenApiInvokeInterceptorChain = {
        let interceptorContext = WebAppInterceptorContextImp(webAppExtensionItem: self)
        return OpenApiInvokeInterceptorChainImp(webAppContext: interceptorContext)
    }()
    
    public lazy var webAppJsSDKWithoutAuth: WebAppApiNoAuthProtocol? = {
        guard let browser = browser else { return nil }
        return ecosyetemWebDependency.getWebAppJsSDKWithoutAuthorization(apiHost: browser)
    }()
    
    var webAppJsSDKWithAuthDic = [String: WebAppApiAuthJsSDKProtocol]()
    static let logger = Logger.ecosystemWebLog(WebAppExtensionItem.self, category: "WebAppExtensionItem")
    
    var ifEverAppear: Bool = false
    
    var hasDisappear: Bool = false
    
    var hadCheckBlank: Bool = false
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = WebAppWebBrowserLifeCycle(item: self)
    
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = WebAppWebBrowserNavigation(item: self)
    
    public var trace: OPTrace?
    
    weak var browser: WebBrowser?
    
    var webAppAuthStrategy: WebAppAuthStrategyProtocol
    
    var webAppInfo: WebAppInfo? {
        didSet {
            browser?.webview.lkwb_monitor.setMonitorData(key: "app_id", value: webAppInfo?.id)
        }
    }
    
    lazy var appStateServie : AppStateService? =  {
        let rs = self.browser?.resolver
        var appStateService = try? rs?.resolve(assert: AppStateService.self)
        if appStateService == nil {
            let container = BootLoader.container
            appStateService = try? container.resolve(assert: AppStateService.self)
        }
        return appStateService
    }()
    
    var hasAddLaunchWebAppInfoForFirstWebpage: Bool = false
    
    var noticeView: OPNoticeView?
    
    var lkTrackPageID: String?
    
    @InjectedOptional var monitorService: WebAppMonitorProtocol?// user:global
    
    var heartBeatAppIDs = Set<String>()
    
    private lazy var isOfflineWebAppConfigOptimize = {
        return FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webapp.offline.configoptimize"))// user:global
    }()
    
    // 延迟释放优化开关
    public lazy var delayReleaseOptimizeEnable = {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webbrowser.delayrelease.optimize.enable"))// user:global
    }()
    
    private var offlineSessionRequestTimeInterval: Int {
        do {
            let offlineSessionExpireSetting = try SettingManager.shared.setting(with: OfflineSessionExpireSetting.self, key: UserSettingKey.make(userKeyLiteral: "op_web_offline_session_request_timer"))// user:global
            return offlineSessionExpireSetting.timer > 0 ? offlineSessionExpireSetting.timer : 172800
        } catch {
            // 2d * 24h * 60min * 60s = 172800s
            return 172800
        }
    }
    
    // 离线session最近一次请求时间，session的有效期目前是三天，在超过offlineSessionRequestTimeInterval秒的时候进行一下刷新，大部分时候走不到这个逻辑
    private var offlineSessionFetchTimeInterval : Int? // [session: session settimeinterval]
    
    private var firstLoadOfflineURL : URL?
    
    public var offlineJSSDKSession : String?
    
    public init(browser: WebBrowser, webAppInfo: WebAppInfo?) {
        self.browser = browser
        self.webAppInfo = webAppInfo
        self.webAppAuthStrategy = WebAppAuthStrategyManager.getWebAppAuthStrategy()
        super.init()
        // 离线应用在免鉴权白名单，直接设置免鉴权
        var authOfflineAppWhiteList:[String] = []
        do {
            authOfflineAppWhiteList = try SettingManager.shared.setting(with: Array<String>.self, key: UserSettingKey.make(userKeyLiteral: "WebAppApiAuthPassList"))// user:global
        } catch {
            authOfflineAppWhiteList = []
        }
        if let webAppInfo = webAppInfo, !authOfflineAppWhiteList.isEmpty, authOfflineAppWhiteList.contains(webAppInfo.id) {
            webAppInfo.apiAuthenStatus = .authened
        }
        // Do any additional setup after loading the view. 当app从后台切换到前台，或者锁屏后开启
        NotificationCenter.default.addObserver(self, selector: #selector(onAppBecomeActivate), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    public func updateSession(webAppInfo: WebAppInfo, url: URL?, session: String, webpage: WKBackForwardListItem?) {
        
        Self.logger.info("seesion updated for appId=\(webAppInfo.id), emptySession=\(session.isEmpty)")
        addWebAppInfo(info: webAppInfo, webBrowser: browser, webpage: webpage, needToUpdateMenu: true)
        guard let url = url else {
            Self.logger.warn("can not update seesion for auth service, current webAppID=\(appInfoForCurrentWebpage?.id), authAppID=\(webAppInfo.id)")
            return
        }
        webAppJsSDKWithAuth?.currentURL = url
        webAppJsSDKWithAuth?.updateSession(session: session, url: url)
    }
    
    public func addWebAppInfo(info: WebAppInfo, webBrowser: WebBrowser?, webpage: WKBackForwardListItem?, needToUpdateMenu: Bool){
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.larkwebview.performance.report")),// user:global
           let webView = webBrowser?.webview {
            monitorService?.bind(appId: info.id, webView: webView)
        }
        verifyAuthentication(webAppInfo: info)
        if webAppAuthStrategy.setWebAppInfo(info: info, webpage: webpage, webBrowser: webBrowser) {
            OPMonitor("openplatform_web_app_complete_identify_view")
            /*
             .addCategoryValue("url", webBrowser?.url.safeURLString)
             */
            // 备注：此处没有修改任何产品逻辑，只是因为URL目前是optional的，如果咨询，请联系 xiangyuanyuan
                .addCategoryValue("url", webBrowser?.browserURL?.safeURLString)
                .addCategoryValue("application_id", info.id)
                .addCategoryValue("identify_type", info.status)
                .addCategoryValue("page_id", lkTrackPageID ?? "")
                .addCategoryValue("lifecycle_id", webBrowser?.getTrace().traceId ?? "")
                .tracing(webBrowser?.webview.trace)
                .setPlatform([.tea, .slardar])
                .flush()
            doWebAppBusiness(with: info,needToUpdateMenu: needToUpdateMenu)
            doOpenWebAppStatistics(with: info)
        }
        startHeartBeatIfNeeded(appID: info.id)
    }
    
    public func addWebAppInfo(info: WebAppInfo, webBrowser: WebBrowser?, url: URL, needToUpdateMenu: Bool){
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.larkwebview.performance.report")),
           let webView = webBrowser?.webview {
            monitorService?.bind(appId: info.id, webView: webView)
        }
        verifyAuthentication(webAppInfo: info)
        if webAppAuthStrategy.setWebAppInfo(info: info, url: url, webBrowser: webBrowser) {
            OPMonitor("openplatform_web_app_complete_identify_view")
            /*
             .addCategoryValue("url", webBrowser?.url.safeURLString)
             */
            // 备注：此处没有修改任何产品逻辑，只是因为URL目前是optional的，如果咨询，请联系 xiangyuanyuan
                .addCategoryValue("url", webBrowser?.browserURL?.safeURLString)
                .addCategoryValue("application_id", info.id)
                .addCategoryValue("identify_type", info.status)
                .addCategoryValue("page_id", lkTrackPageID ?? "")
                .addCategoryValue("lifecycle_id", webBrowser?.getTrace().traceId ?? "")
                .tracing(webBrowser?.webview.trace)
                .setPlatform([.tea, .slardar])
                .flush()
            doWebAppBusiness(with: info,needToUpdateMenu: needToUpdateMenu)
            doOpenWebAppStatistics(with: info)
        }
        startHeartBeatIfNeeded(appID: info.id)
    }

    func verifyAuthentication(webAppInfo: WebAppInfo) {
        let canVerify = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "lark.webapp.strategy"))
        if canVerify {
            Self.logger.info("Verify authentication of WebApp\(webAppInfo.id)")
            var appId = webAppInfo.id
            self.appStateServie?.getWebControlInfo(appID: appId, callback: { h5InfoResponse in
                Self.logger.info("Get result of verify authentication")
                let fromScene = self.browser?.configuration.fromScene
                if fromScene == .mainTab || fromScene == .workplace {
                    Self.logger.info("Skip verify authentication result in mainTab and workplace")
                    return
                }
                guard let response = h5InfoResponse, let h5info = h5InfoResponse?.h5Info else {
                    return
                }
                if h5info.status != .usable {
                    Self.logger.info("No verify authentication")
                    let appName = h5info.hasLocalName ? h5info.localName : (webAppInfo.name ?? "")
                    self.showUnusableDialog(appId: appId, appName: appName, tips: response.tips)
                }
            })
        }
    }
    
    func showUnusableDialog(appId:String, appName:String,tips:Openplatform_V1_GuideTips) {
        if let viewContorller = self.browser {
            Self.logger.info("show dialog if no verify authentication")
            self.appStateServie?.presentAlert(appID: appId, appName: appName, tips: tips, VC: viewContorller, appType: .webApp) {
                if let browser = self.browser {
                   let closeState = browser.closeBrowser()
                    Self.logger.info("close browser if no verify authentication,state:\(closeState)")
                }
            }
        }
    }
    
    func addLaunchWebAppInfoOnceIfNeeded() {
        assert(Thread.isMainThread, "please call this method in main thread")
        guard let info = webAppInfo else {
            Self.logger.info("launch webbroswer and webAppInfo is nil")
            return
        }
        
        guard let url = browser?.webview.url else {
            Self.logger.info("webbroswer url is nil")
            return
        }
        if hasAddLaunchWebAppInfoForFirstWebpage {
            return
        }
        hasAddLaunchWebAppInfoForFirstWebpage = true
        let canOptimizeCommit = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.optimizecommit.enable"))

        switch WebAppAuthStrategyManager.getWebAppAuthStrategyType() {
        case.url:
            guard let firstWebpage = firstWebpage else {
                let msg = "should not has no WKBackForwardListItem"
                assertionFailure(msg)
                Self.logger.error(msg)
                return
            }
            if canOptimizeCommit {
                addWebAppInfo(info: info, webBrowser: browser, webpage: firstWebpage, needToUpdateMenu: false)
            }else {
                addWebAppInfo(info: info, webBrowser: browser, webpage: firstWebpage, needToUpdateMenu: true)
            }
        case .container, .prefix:
            if canOptimizeCommit {
                addWebAppInfo(info: info, webBrowser: browser, url: url, needToUpdateMenu: false)
            }else {
                addWebAppInfo(info: info, webBrowser: browser, url: url, needToUpdateMenu: true)
            }
        }
        if isOfflineWebAppConfigOptimize, isWebBrowserInOfflineMode(browser: browser!) {
            webAppInfo?.apiAuthenStatus = .authened
            firstLoadOfflineURL = url
            Self.logger.info("fetch Offline Webapp JSSDKSession after did commit")
            fetchOfflineWebappJSSDKSession(completion: nil)
        }
    }
    
    func isWebBrowserInOfflineMode(browser : WebBrowser) -> Bool {
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.offline.v2")) {// user:global
            if browser.resolve(OfflineResourceExtensionItem.self) != nil {
                return true
            }
        }
        if browser.resolve(WebOfflineExtensionItem.self) != nil {
            return true
        }
        if browser.resolve(FallbackExtensionItem.self) != nil {
            return true
        }
        if browser.configuration.resourceInterceptConfiguration != nil {
            return true
        }
        if browser.configuration.offline {
            return true
        }
        return false
    }
    
    func fetchOfflineWebappJSSDKSession(completion: ((Result<String, Error>) -> Void)?) {
        guard let webAppInfo = webAppInfo, let browser = self.browser  else {
            let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
            completion?(.failure(error))
            return
        }
        // requestAuthCode 调用开始时间戳
        let startTimeStamp = Date().timeIntervalSince1970
        let trace = browser.getTrace()
        let networkContext = OpenECONetworkWebContext(trace: trace, source: .web)
        RequestAuthCodeNetwork.requestAuthCode(with: webAppInfo.id, url: firstLoadOfflineURL, context: networkContext, resolver: browser.resolver) {
            [weak browser, weak self] result in
            guard let browser, let self else {
                return
            }
            let monitorHost = browser.webview.url?.host?.safeURLString ?? ""
            let monitorUrl = browser.webview.url?.safeURLString ?? ""
            switch result {
            case .success(let res):
                if let code = res["code"] as? Int, code == 0, let data = res["data"] as? [String: Any], let session = data["session"] as? String{
                    // requestAuthCode 调用结束埋点
                    let errorCode = ""
                    let errorMessage = ""
                    OPMonitor("wb_offlinewebapp_session_request")
                        .addMap(["appid": self.webAppInfo?.id,
                                 "host": monitorHost,
                                 "end_timestamp": Date().timeIntervalSince1970,
                                 "duration": Date().timeIntervalSince1970 - startTimeStamp,
                                 "url": monitorUrl,
                                 "result_code": 0,
                                 "raw_err_code": errorCode,
                                 "err_message": errorMessage,
                                 "raw_err_message": errorMessage])
                        .tracing(trace)
                        .flush()
                    // 刷新session
                    Self.logger.info("fetch Offline Webapp JSSDKSession appid:\(webAppInfo) success:\(session)")
                    if Thread.isMainThread {
                        self.offlineJSSDKSession = session
                        self.updateSession(webAppInfo: webAppInfo, url: browser.webview.url, session: session, webpage: browser.currentWebPage)
                        self.offlineSessionFetchTimeInterval = Int(Date().timeIntervalSince1970)
                        completion?(.success(session))
                    } else {
                        DispatchQueue.main.async {
                            self.offlineJSSDKSession = session
                            self.updateSession(webAppInfo: webAppInfo, url: browser.webview.url, session: session, webpage: browser.currentWebPage)
                            self.offlineSessionFetchTimeInterval = Int(Date().timeIntervalSince1970)
                            completion?(.success(session))
                        }
                    }
                } else {
                    let errorCode = res["code"] as? Int ?? -1
                    let errorMessage = res["msg"] as? String ?? ""
                    Self.logger.info("fetch Offline Webapp JSSDKSession appid:\(webAppInfo) failed errorcode:\(errorCode), error_msg：\(errorMessage)")
                    let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    completion?(.failure(error))
                    OPMonitor("wb_offlinewebapp_session_request")
                        .addMap(["appid": webAppInfo.id,
                                 "host": monitorHost,
                                 "end_timestamp": Date().timeIntervalSince1970,
                                 "duration": Date().timeIntervalSince1970 - startTimeStamp,
                                 "url": monitorUrl,
                                 "result_code": errorCode,
                                 "raw_err_code": res["code"] as? Int ?? "",
                                 "err_message": errorMessage,
                                 "raw_err_message": res["msg"] as? String ?? ""])
                        .tracing(trace)
                        .flush()
                }
            case .failure(let err):
                completion?(.failure(err))
                let errorCode = ""
                let errorMessage = "network error"
                Self.logger.info("fetch Offline Webapp JSSDKSession appid:\(webAppInfo) failed errorcode:\(errorCode), error_msg：\(errorMessage)")
                OPMonitor("wb_offlinewebapp_session_request")
                    .addMap(["appid": webAppInfo.id,
                             "host": monitorHost,
                             "end_timestamp": Date().timeIntervalSince1970,
                             "duration": Date().timeIntervalSince1970 - startTimeStamp,
                             "url": monitorUrl,
                             "result_code": errorCode,
                             "raw_err_code": errorCode,
                             "err_message": errorMessage,
                             "raw_err_message": errorMessage])
                    .tracing(trace)
                    .flush()
            }
        }
    }
    
    /// 刷新离线应用session
    func updateOfflineSessionIfNeeded() {
        if isOfflineWebAppConfigOptimize, let offlineSessionFetchTimeInterval = offlineSessionFetchTimeInterval {
            let currentTimeInterval = Int(Date().timeIntervalSince1970)
            if (currentTimeInterval - offlineSessionFetchTimeInterval) > self.offlineSessionRequestTimeInterval {
                Self.logger.info("fetch Offline Webapp JSSDKSession before session expire")
                self.fetchOfflineWebappJSSDKSession(completion: nil)
            }
        }
    }
    
    private func startHeartBeatIfNeeded(appID: String) {
        guard !heartBeatAppIDs.contains(appID) else { return }
        heartBeatAppIDs.insert(appID)
        let event = OPMonitor(EPMClientOpenPlatformWebLifecycleCode.web_heartbeat)
        // code from setUniqueID
        // 之前埋点需求方有的要求app_id 有的要求application_id，需求不确定，此处为了安全保险，全部埋入，要啥都有，非特殊需求不要“优化”这里的key，避免漏掉数据
            .addCategoryValue("app_id", appID)
            .addCategoryValue("identifier", appID)
            .addCategoryValue("application_id", appID)
            .addCategoryValue("app_type", "webApp")
            .addCategoryValue("version_type", "current")
            .setPlatform([.slardar, .tea])
        let source = OPHeartBeatMonitorBizSource(heartBeatID: appID, monitorData: event.monitorEvent)
        OPHeartBeatMonitorService.default.registerHeartBeat(with: source, provider: self)
    }
    public func getCurrentStatus(of heartBeatID: String) -> OPHeartBeatMonitorSourceStatus {
        .active
    }
    deinit {
        heartBeatAppIDs.forEach { appID in
            OPHeartBeatMonitorService.default.endHeartBeat(for: appID)
        }
    }
    
    private func doWebAppBusiness(with info: WebAppInfo, needToUpdateMenu: Bool) {
        //  code from changrong
        auditH5AppLaunch(appID: info.id)
        //  更新右侧导航栏菜单
        if needToUpdateMenu {
            browser?.resolve(WebMenuExtensionItem.self)?.updateMenuHanlderIfNeeded()
        }
        /// 识别为 H5 应用，创建应用沙箱
        if EMAFeatureGating.boolValue(forKey: "open_platform.gadget.webapp.sandbox_create") {// user:global
            let uniqueId = OPAppUniqueID(appID: info.id, identifier: nil, versionType: .current, appType: .webApp)
            let module = BDPModuleManager(of: uniqueId.appType).resolveModule(with: BDPStorageModuleProtocol.self)
            let storageModule = module as? BDPStorageModuleProtocol
            Self.logger.info("resolve storage module result", additionalData: [
                "result": "\(storageModule != nil)",
                "appId": "\(uniqueId.appID)"
            ])
            // 创建沙箱
            _ = storageModule?.minimalSandbox(with: uniqueId)
            /// 清理 H5 应用 tmp 时机需要单独考虑，目前暂不支持
        }

        //  code from zhangmeng
        // 沙箱结构探测埋点
        SandboxDetection.asyncDetectAndReportH5SandboxInfo(appId: info.id)
        setupNotice(appID: info.id)
    }
    
    /// 用户打开网页应用行为统计
    private func doOpenWebAppStatistics(with info: WebAppInfo) {
        guard let browser = browser else { return }
        
        let appId = info.id
        if (!browser.reportAppIdSet.contains(appId)) {
            DispatchQueue.main.async {
                if let wrokPlaceDataService = try? browser.resolver?.resolve(assert: WorkplaceOpenAPI.self) {
                    browser.reportAppIdSet.insert(appId)
                    wrokPlaceDataService.reportRecentlyWebApp(appId: appId)
                    Self.logger.info("exec report recently webapp")
                }
            }
        }
    }
    
    private func setupNotice(appID: String) {
        guard let browser = browser else { return }
        let networkContext = OpenECONetworkWebContext(trace: browser.getTrace(), source: .web)
        OPNoticeManager.shared().requsetNoticeModel(forAppID: appID, context: networkContext) { [weak self] model in
            guard let self = self, let model = model else { return }
            guard OPNoticeManager.shared().shouldShowNoticeView(for: model) else { return }
            OPNoticeManager.shared().recordShowNoticeView(for: model, appID: appID)
            self.setupNoticeView(model: model, appID: appID)
        }
    }
    private func setupNoticeView(model: OPNoticeModel, appID: String) {
        guard let webview = browser?.webview else { return }
        if noticeView != nil { return }
        let notice = OPNoticeView(frame: .zero, model: model, isAutoLayout: true)
        notice.appID = appID
        noticeView = notice
        noticeView?.delegate = self
        webview.addSubview(notice)
        noticeView?.snp.makeConstraints({ make in
            make.top.equalTo(webview.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
        })
    }
    public func didCloseNoticeView() {
        OPNoticeManager.shared().recordCloseNoticeView(for: noticeView?.model, appID: noticeView?.appID)
        noticeView = nil
    }
    
    /// code from changrong
    private func auditH5AppLaunch(appID: String) {
        // 只对 H5 应用做审计，其他的 Web，不需要继续
        if let service = try? browser?.resolver?.resolve(assert: OPAppAuditService.self) {
            service.auditEnterApp(appID)
        }
    }
    
    private var firstWebpage: WKBackForwardListItem? {
        if let backListFirst = browser?.webview.backForwardList.backList.first {
            return backListFirst
        }
        return browser?.webview.backForwardList.currentItem
    }
    
    var appInfoForFirstWebpage: WebAppInfo? {
        webAppAuthStrategy.getAppInfoForFirstWebpage(webBrowser: browser)
    }
    
    var appInfoForCurrentWebpage: WebAppInfo? {
        webAppAuthStrategy.getAppInfoForCurrentWebpage(webBrowser: browser)
    }
    
    var isWebAppForCurrentWebpage: Bool {
        guard let appInfo = appInfoForCurrentWebpage else {
            return false
        }
        guard !appInfo.id.isEmpty else {
            return false
        }
        return true
    }
    
    var firstAppInfoOfAuthRecords: WebAppInfo? {
        webAppAuthStrategy.getFirstAppInfoOfAuthRecords(webBrowser: browser)
    }
    
    func update(iconKey: String) {
        webAppAuthStrategy.update(iconKey: iconKey, webBrowser: browser)
    }
    
    func update(iconURL: String, appID: String) {
        webAppAuthStrategy.update(iconURL: iconURL, appID: appID, webBrowser: browser)
    }
    
    // code from yiying 逻辑无改动
    func viewActive(_ isActive: Bool) {
        if let webPageAppID = appInfoForCurrentWebpage?.id {
            let userInfo: [AnyHashable : Any] = ["kAppID" : webPageAppID, "kViewActive": isActive]
            NotificationCenter.default.post(name: Notification.Name(webBrowserInterruptionNotification), object: nil, userInfo: userInfo)
        }
    }

    @objc func onAppBecomeActivate() {
        self.browser?.webview.evaluateJavaScript("document.visibilityState", completionHandler: { [weak self] visibilityStateString, error  in
            guard let visibilityStateString = visibilityStateString as? String else {
                Self.logger.error("get visibilityState failed! stop report pv. error: \(error)")
                return
            }
            if (visibilityStateString.lowercased() == "visible") {
                self?.reportPageView(url: self?.browser?.webview.url)
            } else {
                Self.logger.info("visibilityState=\(visibilityStateString), stop report pv.")
            }
        })
    }

    // pv 上报
    @objc func reportPageView(url: URL?) {
        //  网页应用内的页面曝光(页面加载完成)
        //  1. 每次启动（包含冷启动、从后台切换到前台）时上报
        //  2. 每次在应用内出现页面跳转（即页面的path发生变化，包括页面后退操作导致的变化）时上报
        if let page_path = url,
           let lifecycle_id = browser?.getTrace().traceId,
           let mode = browser?.configuration.scene.rawValue,
           let fromScene = browser?.configuration.fromSceneReport.sceneCode() {
            OPMonitor("openplatform_web_app_page_view")
                .addCategoryValue("page_path", page_path.safeURLString.md5())
                .addCategoryValue("lifecycle_id", lifecycle_id)
                .addCategoryValue("application_id", webAppInfo?.id ?? "none")
                .addCategoryValue("page_id", lkTrackPageID ?? "")
                .addCategoryValue("container_open_mode", mode)
                .addCategoryValue("scene_type", fromScene)
                .setPlatform(.tea)
                .flush()
            // 产品新增埋点，包括普通网页
            let isExternalDomain = isExternalDomain(page_path)
            var u_main = page_path.host ?? "none"
            if isExternalDomain == "false" {
                u_main = getBizType(page_path) ?? "none"
            }
            OPMonitor("openplatform_web_container_page_view")
                .addCategoryValue("page_path", page_path.safeURLString.md5())
                .addCategoryValue("lifecycle_id", lifecycle_id)
                .addCategoryValue("application_id", webAppInfo?.id ?? "none")
                .addCategoryValue("container_open_mode", mode)
                .addCategoryValue("scene_type", fromScene)
                .addCategoryValue("u_main", u_main)
                .addCategoryValue("is_external_domain", isExternalDomain)
                .setPlatform(.tea)
                .flush()
        } else {
            Self.logger.error("reportPageView failed, param invalid!")
        }
    }
    
    private func isExternalDomain(_ url: URL) -> String {
        // DA @秦丽丽 定的规则，不要求判断 100% 准确
        if let urlHostParts = url.host?.split(separator: "."), urlHostParts.count > 1 {
            // 获取二级域名
            let secondHost = urlHostParts[urlHostParts.index(urlHostParts.endIndex, offsetBy: -2)]
            let targetHostList = ["lark", "feishu", "larkoffice"]
            return targetHostList.contains(secondHost.lowercased()) ? "false" : "true" }
        return "true"
    }
    
    private func getBizType(_ url: URL) -> String? {
        // 获取 URL 域名 + 第一位 path
        // 例如 URL www.cc.com/home/detail
        // bizType 为 www.cc.com/home
        if let host = url.host, let hostURL = URL(string: host) {
            var bizTypeURL = hostURL
            let pathComponents = url.pathComponents.prefix(2)
            pathComponents.forEach { bizTypeURL = bizTypeURL.appendingPathComponent($0) }
            let bizTypeStr = bizTypeURL.absoluteString
            return bizTypeStr
        }
        return nil
    }
    
    func urlChangeMonitor(trace: OPTrace?) {
        // url变更后，鉴权策略状态记录 埋点
        let webAppInfo = browser?.appInfoForCurrentWebpage
        let webAppAuthMonitor = OPMonitor(name: WebBrowser.webEventName, code: EPMClientOpenPlatformWebWebappAuthCode.op_webapp_auth_strategy_status_after_url_change)
            .addCategoryValue("appId", webAppInfo?.id ?? "")
            .addCategoryValue("authStrategy", browser?.webAppAuthStrategy?.rawValue ?? "")
            .addCategoryValue("url", browser?.webview.url?.safeURLString)
            .addCategoryValue("count", browser?.countOfAuthRecords ?? 0)
        if webAppInfo == nil {
            webAppAuthMonitor.addCategoryValue("authed", false)
                .addCategoryValue("extraMsg", "webappInfo is not found")
        } else {
            webAppAuthMonitor.addCategoryValue("authed", true)
            // 若是染色策略 返回让当前页面染色的url
            if browser?.webAppAuthStrategy == .prefix {
                let prefixSafeUrl = (webAppAuthStrategy as? WebAppPrefixAuthStrategy)?.getPrefixUrlForCurrentWebpage(webBrowser: browser)?.safeURLString
                webAppAuthMonitor.addCategoryValue("extraMsg", "prefix url is \(prefixSafeUrl)")
            }
        }
        webAppAuthMonitor.tracing(trace)
            .flush()
    }
    
    
    /// 页面路径发生变化时刷新pageid，即使url是a->b->a,也需要重新刷新，通过添加时间戳来区分同一页面不同时机
    /// https://bytedance.feishu.cn/docx/doxcnTt4eYpW52SuZDYvTVDKKFg
    /// - Parameter url: 当前页面url
    func buildlkTrackPageID(url: URL?){
        if let page_path = url {
            let date = Date()
            let mills = Int(date.timeIntervalSince1970 * 1000)
            lkTrackPageID = page_path.safeURLString + "_" + String(mills)
        } else {
            lkTrackPageID = ""
        }
    }
}

// code from yiying 逻辑无改动
final public class WebAppWebBrowserLifeCycle : NSObject, WebBrowserLifeCycleProtocol {
    
    weak var item: WebAppExtensionItem?

    static let logger = Logger.ecosystemWebLog(WebAppWebBrowserLifeCycle.self, category: "WebAppWebBrowserLifeCycle")

    var urlKVOToken: NSKeyValueObservation?
    
    init(item: WebAppExtensionItem) {
        self.item = item
    }

    public func viewWillAppear(browser: WebBrowser, animated: Bool) {
        item?.viewActive(true)
    }

    public func viewDidAppear(browser: WebBrowser, animated: Bool) {
        if let item = item {
            if item.ifEverAppear {
                // 拦截第一次重复pv上报
                item.reportPageView(url: item.browser?.webview.url)
            } else {
                item.ifEverAppear = true
            }
        }
    }
    
    public func viewWillDisappear(browser: WebBrowser, animated: Bool) {
        if let item = item {
            if !item.hasDisappear {
                item.hasDisappear = true
                if (item.delayReleaseOptimizeEnable && browser.webview.isFirstPage && browser.webview.isLoading && !item.hadCheckBlank) {
                    item.hadCheckBlank = true
                    self.monitorCheckBlank(browser: browser)
                }
            }
        }
    }
        
    public func viewDidDisappear(browser: WebBrowser, animated: Bool) {
        item?.viewActive(false)
    }
    
    public func viewDidLoad(browser: WebBrowser) {
        // 监听 wkwebview 的URL变化
        item?.trace = browser.getTrace()
        if let webview = item?.browser?.webview {
            urlKVOToken = webview.observe(\.url, options: [.old, .new], changeHandler: { [weak self] (webview, change) in
                guard let newUrl = change.newValue as? URL else { return }
                self?.item?.urlChangeMonitor(trace: self?.item?.trace)
                self?.item?.buildlkTrackPageID(url: newUrl)
                self?.item?.reportPageView(url: newUrl)
                self?.item?.addLaunchWebAppInfoOnceIfNeeded()
                if LarkWebSettings.lkwEncryptLogEnabel {
                    // 不再重复打印，Url变化日志见 WebBrowser+LifeCycle 函数observeURLChange(webview: LarkWebView)
                    Self.logger.info("webview url change update url app info")
                } else {
                    Self.logger.info("webview url change from: [\(BDPSafeString(String(describing: change.oldValue)))] to: [\(BDPSafeString(String(describing: newUrl)))]")
                }
            })
        }
        // 鉴权策略初始化埋点
        OPMonitor(name: WebBrowser.webEventName, code: EPMClientOpenPlatformWebWebappAuthCode.op_webapp_auth_strategy_init)
            .addMap(["appId": browser.appInfoForCurrentWebpage?.id ?? "",
                     "authStrategy": browser.webAppAuthStrategy?.rawValue ?? ""])
            .tracing(item?.trace)
            .flush()
    }
    
    public func webBrowserDeinit(browser: WebBrowser) {
        // 鉴权策略销毁埋点
        OPMonitor(name: WebBrowser.webEventName, code: EPMClientOpenPlatformWebWebappAuthCode.op_webapp_auth_strategy_destroy)
            .addMap(["authStrategy": browser.webAppAuthStrategy?.rawValue ?? ""])
            .tracing(item?.trace)
            .flush()
        
       
        if let item = item, item.delayReleaseOptimizeEnable {
            Self.logger.info("delayReleaseOptimizeEnable is true")
        } else {
            //原线上逻辑(Deinit时白屏检测)
            self.monitorCheckBlank(browser: browser)
        }
        
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.offline.v2")) {// user:global
        if let webAppInfoId = item?.webAppInfo?.id ?? item?.webAppAuthStrategy.getAppInfoForCurrentWebpage(webBrowser: browser)?.id {
            //WebBrowser 包管理内存清理操作
            let uniqueID = OPAppUniqueID(appID: webAppInfoId ?? "",
                                         identifier: nil,
                                         versionType: .current,
                                         appType: .webApp,
                                         instanceID: browser.configuration.webBrowserID)
            OPWebAppManager.sharedInstance.cleanWebAppInMemory(uniqueID: uniqueID)
        }
        }
    }
    
    private func monitorCheckBlank(browser: WebBrowser) {
                
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.larkwebview.performance.report")) {// user:global
            Self.logger.info("check blank monitor")
            let webAppInfoId = item?.webAppInfo?.id ?? item?.webAppAuthStrategy.getAppInfoForCurrentWebpage(webBrowser: browser)?.id
            item?.monitorService?.checkBlank(appId: webAppInfoId, webView: browser.webview)
            item?.monitorService?.flushEvent(webView: browser.webview, clear: true)
        }
    }
}

final public class WebAppWebBrowserNavigation: WebBrowserNavigationProtocol {
    
    weak var item: WebAppExtensionItem?
    
    private var isFirstPage: Bool = true
    
    static let logger = Logger.ecosystemWebLog(WebAppWebBrowserNavigation.self, category: "WebAppWebBrowserNavigation")
    
    init(item: WebAppExtensionItem) {
        self.item = item
    }

    public func browser(_ browser: WebBrowser, didCommit navigation: WKNavigation!) {
        item?.addLaunchWebAppInfoOnceIfNeeded()
    }

    public func browser(_ browser: WebBrowser, didStartProvisionalNavigation navigation: WKNavigation!) {
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.larkwebview.performance.report")) {// user:global
            let webAppInfoId = item?.webAppInfo?.id ?? item?.webAppAuthStrategy.getAppInfoForCurrentWebpage(webBrowser: browser)?.id
            item?.monitorService?.bind(appId: webAppInfoId, webView: browser.webview)
        }
    }
    
    public func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        if isFirstPage {
            isFirstPage = false
            
            // 仅首个页面加载上报
            let leftBarButtonItems = browser.navigationItem.leftBarButtonItems
            let rightBarButtonItems = browser.navigationItem.rightBarButtonItems

            // 导航栏按钮列表
            var buttonList: String = ""
            leftBarButtonItems?.forEach({ item in
                if let webButtonID = item.webButtonID, !webButtonID.isEmpty {
                    if buttonList.count > 0 {
                        buttonList.append(",")
                    }
                    buttonList.append(webButtonID)
                }
            })
            rightBarButtonItems?.forEach({ item in
                if let webButtonID = item.webButtonID, !webButtonID.isEmpty {
                    if buttonList.count > 0 {
                        buttonList.append(",")
                    }
                    buttonList.append(webButtonID)
                }
            })
            var bottomButtonIDList : String = ""
            if let launchBarItem = browser.resolve(WebLaunchBarExtensionItem.self) {
                bottomButtonIDList = launchBarItem.bottomButtonIDList.joined(separator: ",")
            }
            
            let lifecycle_id = browser.getTrace().traceId
            let webAppInfo = browser.appInfoForCurrentWebpage
            OPMonitor("openplatform_web_container_view")
                .addCategoryValue("lifecycle_id", lifecycle_id)
                .addCategoryValue("application_id", webAppInfo?.id ?? "none")
                .addCategoryValue("button_list", buttonList)
                .addCategoryValue("bottom_button_list", bottomButtonIDList)
                .addCategoryValue("container_open_type", "single_tab")
                .addCategoryValue("windows_type", "embedded_window")
                .setPlatform(.tea)
                .flush()
        }
        
        self.checkBlank(browser: browser)
    }
    
    //实现WebBrowserNavigationProtocol中didFail方法
    public func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {
        self.checkBlank(browser: browser)
    }
    
    private func checkBlank(browser: WebBrowser) {
        
        guard let item = item else {
            Self.logger.error("item is nil")
            return
        }
        
        if !item.delayReleaseOptimizeEnable {
            Self.logger.info("delayReleaseOptimizeEnable is false")
            return
        }
        
        if !browser.webview.isFirstPage {
            Self.logger.info("not first page loadend, needn't check blank")
            return
        }
                
        Self.logger.info("first page loadend, exec check blank")
        let webAppInfoId = item.webAppInfo?.id ?? item.webAppAuthStrategy.getAppInfoForCurrentWebpage(webBrowser: browser)?.id
        if(!item.hadCheckBlank) {
            item.hadCheckBlank = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                item.monitorService?.checkBlank(appId: webAppInfoId, webView: browser.webview)
            }
        }
    }
}

extension WebBrowser {
    public var appInfoForFirstWebpage: WebAppInfo? {
        resolve(WebAppExtensionItem.self)?.appInfoForFirstWebpage
    }
    public var appInfoForCurrentWebpage: WebAppInfo? {
        resolve(WebAppExtensionItem.self)?.appInfoForCurrentWebpage
    }
    public var isWebAppForCurrentWebpage: Bool {
        resolve(WebAppExtensionItem.self)?.isWebAppForCurrentWebpage ?? false
    }
    public var firstAppInfoOfAuthRecords: WebAppInfo? {
        resolve(WebAppExtensionItem.self)?.firstAppInfoOfAuthRecords
    }
    public var webAppAuthStrategy: WebAppAuthStrategyType? {
        resolve(WebAppExtensionItem.self)?.webAppAuthStrategy.webAppAuthStrategyType
    }
    public var countOfAuthRecords: Int? {
        resolve(WebAppExtensionItem.self)?.webAppAuthStrategy.countOfAuthRecords
    }
    public func update(iconKey: String) {
        resolve(WebAppExtensionItem.self)?.update(iconKey: iconKey)
    }
    public func update(iconURL: String, appID: String) {
        resolve(WebAppExtensionItem.self)?.update(iconURL: iconURL, appID: appID)
    }
    public static let webEventName = "op_webapp_auth_strategy"
}
private class WebAppInterceptorContextImp: WebAppInterceptorContext {
    var appID: String? {
        return webAppExtensionItem?.browser?.appInfoForCurrentWebpage?.id
    }
    
    private(set) weak var webAppExtensionItem: WebAppExtensionItem?
    init(webAppExtensionItem: WebAppExtensionItem) {
        self.webAppExtensionItem = webAppExtensionItem
    }
}
