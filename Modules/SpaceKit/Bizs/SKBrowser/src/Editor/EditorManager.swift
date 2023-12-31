//
//  EditorManager.swift
//  Docs
//
//  Created by weidong fu on 4/2/2018.
//
//  swiftlint:disable file_length type_body_length

import Foundation
import SKFoundation
import WebKit
import SwiftyJSON
import LarkLocalizations
import RxSwift
import RxRelay
import EENavigator
import LarkUIKit
import SKUIKit
import SKCommon
import SKResource
import UniverseDesignToast
import ThreadSafeDataStructure
import UniverseDesignColor
import UniverseDesignIcon
import RunloopTools
import LarkPerf
import SpaceInterface
import SKInfra
import LarkTab
import LarkContainer

let createFileURLPlaceholder = URL(string: "create://createFile.create.create")

public extension CCMExtension where Base == UserResolver {

    var editorManager: EditorManager? {
        if CCMUserScope.docEnabled {
            let obj = try? base.resolve(type: EditorManager.self)
            return obj
        } else {
            return .singleInstance
        }
    }
}

public final class EditorManager: NSObject {
    private var needReloadEditorPool = false
    private var hasPreloadWebView = false  // 是否触发过webview预加载
    private var hasPreloadModule = false   // 模版是否加载成功
    private weak var resolver: DocsResolver?
    lazy private var preloader: DocPreloaderManagerAPI? = {
        nonEmptyUserResolver.docs.docPreloaderManagerAPI
    }()
    public private(set) var config: DocsConfig?

    public private(set) lazy var newBrowsersStack: SafeArray<WeakBrowserVCAbility> = [] + .readWriteLock
    
    // TODO: @chenjiahao.gill 这里*可能*需要一个FG
    let orientationManagerFG = true
    lazy var orientationManager: BrowserOrientationManager = {
        return BrowserOrientationManager()
    }()
    lazy var fileManuOfflineManager: FileManualOfflineManagerAPI? = resolver?.resolve(FileManualOfflineManagerAPI.self)
    var currentBrowser: BrowserViewControllerAbility? {
        return newBrowsersStack.last?.value
    }
    #if canImport(SKEditor)
    private var nativeDocxEnableFg: Bool = LKFeatureGating.nativeDocxEnable
    public var nativeDocxEnable: Bool {
        let nativeEditorUseDebugSetting = CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.nativeEditorUseDebugSetting)
        let docxUseNativeEditorInDebug = CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.docxUseNativeEditorInDebug)
        DocsLogger.info("nativeEditorUseDebugSetting=\(nativeEditorUseDebugSetting), docxUseNativeEditorInDebug=\(docxUseNativeEditorInDebug)")
        if nativeEditorUseDebugSetting == true {
            // 使用debug面板设置
            return docxUseNativeEditorInDebug
        } else {
            // 使用fg下发
            return nativeDocxEnableFg
        }
    }
    #else
    public var nativeDocxEnable: Bool { false }
    #endif

    public var browsersStackisEmpty = BehaviorRelay<Bool>(value: true)
    public lazy var pool: EditorsPool<BrowserView> = {
        let maxCount = OpenAPI.docs.editorPoolMaxCount
        let pool = EditorsPool<BrowserView>(poolMaxCount: maxCount,
                                            maxUsedPerItem: OpenAPI.docs.editorPoolItemMaxUseCount,
                                            userResolver: self.nonEmptyUserResolver) { [unowned self] (editorType) -> BrowserView in
            var config = BrowserViewConfig()
            // 配置代理
            config.statisticsDelegate = self
            config.offlineDelegate = self
            config.shareDelegate = self
            config.navigator = self
            config.clientInfos = self.config?.infos ?? [String: String]()
            var editor: BrowserView!
            DocsLogger.info("init BrowserView, editorType=\(editorType), enable=\(self.nativeDocxEnable)", component: LogComponents.fileOpen)
            
            let ur = self.nonEmptyUserResolver
            #if canImport(SKEditor)
            if self.nativeDocxEnable, editorType == .nativeEditor {
                editor = NativeBrowserView(frame: .zero, config: config)
            } else {
                editor = WebBrowserView(frame: .zero, config: config, userResolver: ur)
            }
            #else
            editor = WebBrowserView(frame: .zero, config: config, userResolver: ur)
            #endif
            
            return editor
        }
        return pool
    }()

    public weak var delegate: EditorManagerDelegate!

    public var currentEditor: BrowserView? {
        guard let editor = currentBrowser?.browerEditor else { return nil }
        return editor
    }
    
    let userResolver: UserResolver? // 为nil表示是单例
    
    var nonEmptyUserResolver: UserResolver {
        userResolver ?? Container.shared.getCurrentUserResolver(compatibleMode: true)
    }
    
    public init(userResolver: UserResolver?) {
        self.userResolver = userResolver
        self.resolver = DocsContainer.shared
        super.init()
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500) { [weak self] in
            _ = self?.preloader
        }
        addListPageObserver()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(gecoPackageUpdateNotify),
                                               name: Notification.Name.Docs.geckoPackageDidUpdate,
                                               object: nil)
    }

    @available(*, deprecated, message: "new code should use `userResolver.docs.editorManager`")
    public static var shared: EditorManager {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: true)
        if let obj = userResolver.docs.editorManager {
            return obj
        }
        spaceAssertionFailure("basically impossible, contact chensi.123")
        return singleInstance
    }
    
    fileprivate static let singleInstance = EditorManager(userResolver: nil) //TODO.chensi 用户态迁移完成后删除旧的单例代码

    public func makeEditor(for url: URL, fileConfig: FileConfig, tracingContext: TracingContext) -> BrowserView {
        let fileType: DocsType = {
            guard let type = DocsType(url: url) else {
                return .doc
            }
            return type
        }()
        let editor = self.pool.dequeueReuseableItem(for: fileType)
        fileConfig.feedID.map { editor.docsLoader?.updateClientInfo(["feedID": $0]) }
        editor.docsLoader?.openSessionID = fileConfig.openSessionID
        editor.docsLoader?.removeContentIfNeed()
        editor.docsLoader?.tracingContext = tracingContext
        editor.docsLoader?.docContext = fileConfig.docContext
        editor.fileConfig = fileConfig
        SKTracing.shared.endSpan(spanName: SKBrowserTrace.createEditorUI, rootSpanId: tracingContext.traceRootId, component: LogComponents.fileOpen)
        //< Make me perfect, no if else,no create file editor
        if url == createFileURLPlaceholder {
            spaceAssertionFailure()
        } else {
            // load
            editor.docsLoader?.currentUrl = url
            //大于0代表配置了延时加载URL，在BrowserVC viewdidLoad做延时加载
            if OpenAPI.delayLoadUrl <= 0 {
                editor.load(url: url)
                if editor.docsInfo != nil {
                    editor.docsInfo?.isExternal = fileConfig.isExternal
                } else {
                    spaceAssertionFailure("wrong url when load")
                    DocsLogger.info("load 文档失败， 设置docs Info额外信息失败")
                }
            } else {
                // 延迟触发 loadUrl 但应该先触发 resetDocsInfo，保证 DocsInfo 不为空
                editor.docsLoader?.resetDocsInfo(url)
            }
        }
        fileConfig.extraInfos.map { editor.docsLoader?.updateClientInfo($0) }
        return editor
    }

    private func topVcIsCurrentBrowser() -> Bool {
        guard let editorView = currentEditor else { return false }
        let windowRootVC = editorView.window?.rootViewController
        guard let windowRootVC = windowRootVC else {
            DocsLogger.info("windowRootVC is nil")
            return false
        }
        let topMostVC = UIViewController.docs.topMost(of: windowRootVC)
        let topIsCurrentVC = currentBrowser == topMostVC
        DocsLogger.info("topIsCurrentVC=\(topIsCurrentVC)")
        return topIsCurrentVC
    }
    
    private func getVersionInfo(_ inUrl: URL) -> [String: Any]? {
        if let type = DocsType(url: inUrl),
            let token = DocsUrlUtil.getFileToken(from: inUrl, with: type),
            token.isEmpty == false {
            let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
            let spaceEntry = dataCenterAPI?.spaceEntry(objToken: token)
            let version: String? = inUrl.queryParameters["wiki_version"]
            var param: [String: Any] = [:]
            var inherentType = type
            var sourceToken = token
            if type == .wiki {
                if let wikiInfo = nonEmptyUserResolver.docs.browserDependency?.getWikiInfo(by: token, version: version) {
                    inherentType = wikiInfo.docsType
                    sourceToken = wikiInfo.objToken
                } else {
                    spaceAssertionFailure("wiki no realtype @peipei")
                }
            }
            
            if  !URLValidator.isMainFrameTemplateURL(inUrl),
                inherentType.supportVersionInfo,
                inUrl.isVersion,
                !URLValidator.isVCFollowUrl(inUrl),
                let vernum = URLValidator.getVersionNum(inUrl) {
                let (versionToken, vName, _, _, _, _, _) = DocsVersionManager.shared.getVersionTokenForToken(token: sourceToken, type: inherentType, version: vernum)
                if versionToken != nil, vName != nil {
                    param["is_version"] = OpenFileRecord.VersionType.version.rawValue
                    param["edition_id"] = URLValidator.getVersionNum(inUrl) ?? ""
                }
            } else {
                param["is_version"] = OpenFileRecord.VersionType.source.rawValue
            }
            return param
                
        } else {
            return nil
        }
    }

    public func open(_ inUrl: URL, fileConfig: FileConfig) -> (targetVC: BrowserViewController?, currentTopVC: UIViewController?) {
        CCMKeyValue.globalUserDefault.set(true, forKey: UserDefaultKeys.didOpenOneDocsFile)
        SKMemoryMonitor.logMemory(when: "start open browser url \(inUrl.absoluteString.encryptToShort)")
        let topMostVC = UIViewController.docs.topMost(of: currentEditor?.window?.rootViewController)

        //iphone模式下或者是iPad 系统版本低于13，需要控制重复点击
        if (SKDisplay.phone || UIDevice.current.systemVersion < "13"),
            let objToken = self.currentEditor?.browserInfo.docsInfo?.objToken,
            self.topVcIsCurrentBrowser(),
            inUrl.path.contains(objToken) ,
            isDocVersionSame(inUrl),
            let currentUrl = self.currentEditor?.browserInfo.currentURL,
            currentUrl.docs.isDocHistoryUrl == inUrl.docs.isDocHistoryUrl,
            currentUrl.docs.isAppealUrl == inUrl.docs.isAppealUrl,
            currentUrl.docs.isWikiDocURL == inUrl.docs.isWikiDocURL,
            currentUrl.docs.isGroupTabUrl == inUrl.docs.isGroupTabUrl,
            currentUrl.queryParameters["from"] != DocsVCFollowFactory.fromKey,
            inUrl.queryParameters["from"] != DocsVCFollowFactory.fromKey {
            let encryptedObjToken = DocsTracker.encrypt(id: objToken)
            DocsLogger.info("open \(encryptedObjToken) in a row, jump over", component: LogComponents.fileOpen)
            var params = [String: String]()
            params[DocsTracker.Params.fileId] = encryptedObjToken
            params[DocsTracker.Params.userid] = User.current.info?.enctypedId
            params[DocsTracker.Params.fileType] = self.currentEditor?.browserInfo.docsInfo?.type.name
            DocsTracker.log(enumEvent: .continuousOpen, parameters: params)
            return (nil, topMostVC)
        }
        
        let rootId = SKTracing.shared.startRootSpan(spanName: SKBrowserTrace.openBrowser)
        let controller = openBrowserView(inUrl, fileConfigz: fileConfig, tracingContext: TracingContext(rootId: rootId))
        addBrowserController(controller)
        SKTracing.shared.endSpan(spanName: SKBrowserTrace.openBrowser,
                                 rootSpanId: rootId,
                                 params: ["type": controller.editor.docsInfo?.type.name ?? "",
                                          "editorId": controller.editor.editorIdentity ?? "noid"],
                                 component: LogComponents.fileOpen)

        return (controller, topMostVC)
    }

    public func openBrowserView(_ url: URL, fileConfigz: FileConfig, tracingContext: TracingContext) -> BrowserViewController {
        let openURL: URL = {
            var url = DocsUrlUtil.appendVersionParamForURL(url)
            // private protocol
            if OpenAPI.offlineConfig.protocolEnable, let type = DocsType(url: url),
                (URLValidator.isMainFrameTemplateURL(url) || DocsType.typesCanUseLocalResources.contains(type)) {
                url = DocsUrlUtil.changeUrl(url, schemeTo: DocSourceURLProtocolService.scheme)
            } else {
                url = url.docs.changeSchemeTo(OpenAPI.docs.currentNetScheme)
            }
            return url
        }()
        let sessionId = fileConfigz.openSessionID ?? OpenFileRecord.generateNewOpenSession()
        WebBrowserView.statisticsDidStartCreatUIFor(sessionId: sessionId, versionInfo: getVersionInfo(url), url: url)
        SKTracing.shared.startChild(spanName: SKBrowserTrace.createEditorUI, rootSpanId: tracingContext.traceRootId, component: LogComponents.fileOpen)
        var fileConfig = fileConfigz
        fileConfig.addExtra(key: "create_ui_start_time", value: "\(Int(Date().timeIntervalSince1970 * 1000))", overwrite: true)
        fileConfig.openSessionID = sessionId
        let docBrowserType = fileConfig.docBrowserType
        docBrowserType.preloadEmbedVC(url: url)
        let editor = self.makeEditor(for: openURL, fileConfig: fileConfig, tracingContext: tracingContext)
        fileConfig.addExtra(key: "create_ui_end_time", value: "\(Int(Date().timeIntervalSince1970 * 1000))", overwrite: true)
        fileConfig.feedFromInfo?.record(.makeEditorEnd)
        let newBrowser = docBrowserType.init(userResolver: self.nonEmptyUserResolver)
        newBrowser.tracingContext = tracingContext
        newBrowser.setInitEditor(editor)
        // 工具栏初始化过早，要先把这个chatid设置一下
        editor.setChatID(fileConfig.chatId)
        editor.jsServiceManager.registerDocsCustomService(toolConfig: newBrowser.toolbarManager)
        editor.jsServiceManager.registerShareCustomService(toolConfig: newBrowser.toolbarManager)

        newBrowser.updateTitleAccordingUrl(openURL.absoluteString)
        newBrowser.openSessionID = sessionId
        newBrowser.updateUrl(openURL)
        newBrowser.updateConfig(fileConfig)
        newBrowser.editor.delegate = newBrowser
        newBrowser.lifeCycleDelegate = self
        let bulletinManager = DocsContainer.shared.resolve(DocsBulletinManager.self)
        bulletinManager?.registerRN()
        bulletinManager?.addObserver(newBrowser)

        return newBrowser
    }

    public func addBrowserController(_ contrller: BrowserViewController?) {
        if let vc = contrller {
            vc.setDismissDelegate(self)
            if newBrowsersStack.count == 0 {
                //当前没有显示WebView，准备push第一个，发一个通知告诉大家
                NotificationCenter.default.post(name: Notification.Name.Docs.showingDocsViewController, object: nil, userInfo: nil)
            }
            browsersStackisEmpty.accept(false)
            newBrowsersStack.append(WeakBrowserVCAbility(vc))
            
            guard let editor = vc.browerEditor else {
                DocsLogger.error("addBrowserController: editor is nil")
                return
            }

            if let objToken = editor.docsInfo?.objToken,
               let type = editor.docsInfo?.type,
               let realToken = editor.docsInfo?.token,
                editor.currentURL?.docs.isDocHistoryUrl != true {
                if LKFeatureGating.refreshWikiTokenOnFetch {
                    DocsOfflineSyncManager.shared.addWebviewHandledObjToken(realToken)
                } else {
                    DocsOfflineSyncManager.shared.addWebviewHandledObjToken(objToken)
                }
                if editor.docsInfo?.inherentType.changeOrientationsEnable == true {
                    self.orientationManager.addEditor(vc)
                }
                let offlineFile = ManualOfflineFile(objToken: realToken, type: type)
                fileManuOfflineManager?.startOpen(offlineFile)
            }
        }
    }

    public class func getDocsBrowserType(_ docType: DocsType) -> BrowserViewController.Type {
        let ur = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        if let vcType = ur.docs.browserDependency?.getBrowserViewControllerType(docType) {
            return vcType
        }
        return BrowserViewController.self
    }

    // public for DocsSDK
    public func create(_ type: DocsType, from viewController: UIViewController, isFromLark: Bool = false, source: FromSource = .larkCreate, parent: String? = nil, context: [String: Any]? = nil) {
        let supported: [DocsType] = [.doc, .docX]
        guard supported.contains(type) else {
            spaceAssertionFailure("不支持的类型")
            return
        }
        DocsLogger.info("create document(\(type.rawValue) fromLark:\(isFromLark), source:\(source.rawValue)")
        let trackParams = DocsCreateDirectorV2.TrackParameters(source: source, module: .home(.recent), ccmOpenSource: .lark)
        let director = WorkspaceCreateDirector(location: .default, trackParameters: trackParams)
        UDToast.showLoading(with: BundleI18n.SKResource.Doc_List_TemplateCreateLoading, on: viewController.view)
        director.create(docsType: type) { [weak self] (_, controller, _, _, error) in
            UDToast.removeToast(on: viewController.view)
            if let error {
                if let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self) {
                    let context = PermissionCommonErrorContext(objToken: "", objType: type, operation: .createSubNode)
                    if let handler = permissionSDK.canHandle(error: error, context: context) {
                        handler(viewController, BundleI18n.SKResource.Doc_Facade_CreateFailed)
                        return
                    }
                }
                if let docsError = error as? DocsNetworkError {
                    if docsError.code == .createLimited {
                        DocsNetworkError.showTips(for: .createLimited, from: viewController)
                        return
                    }
                }
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_CreateFailed, on: viewController.view)
                return
            }

            // 成功创建
            guard let browser = controller else { return }
            if let vc = browser as? BaseViewController {
                vc.showTemporary = context?["showTemporary"] as? Bool ?? false
                if SKDisplay.pad {
                    self?.nonEmptyUserResolver.navigator.showTemporary(vc,
                                                   other: .showDetail,
                                                   context: ["showTemporary": true],
                                                   wrap: LkNavigationController.self,
                                                   from: viewController)

                } else {
                    viewController.navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                if SKDisplay.pad {
                    self?.nonEmptyUserResolver.navigator.showTemporary(browser,
                                                   other: .showDetail,
                                                   context: ["showTemporary": true],
                                                   wrap: LkNavigationController.self,
                                                   from: viewController)

                } else {
                    viewController.navigationController?.pushViewController(browser, animated: true)
                }
            }
        }
    }

    // 创建请求后，生成 VC
    // 由 EditorManager 管理的文档，需要走到这里
    // 目前有 Docs、Sheet、Mindnote
    public func createCompleteV2(token: String,
                                 type: DocsType,
                                 source: FromSource?,
                                 ccmOpenType: CCMOpenType?,
                                 templateCenterSource: SKCreateTracker.TemplateCenterSource?,
                                 templateSource: TemplateCenterTracker.TemplateSource? = nil,
                                 moduleDetails: [String: Any]?,
                                 templateInfos: [String: Any]?,
                                 extra: [String: Any]?) -> UIViewController? {
        // 埋点
        SKCreateTracker.reportCreateNewObj(type: type,
                                           token: token,
                                           source: source,
                                           templateCenterSource: templateCenterSource,
                                           moduleInfo: moduleDetails,
                                           templateInfos: templateInfos,
                                           extra: extra)
        let vcType = EditorManager.getDocsBrowserType(type)
        var fileConfig = FileConfig(vcType: vcType)
        fileConfig.isExternal = false
        var fileUrl: URL?
        guard DocsCreateDirectorV2.isEditorManagerHandleType(type) else {
            spaceAssertionFailure("EditorManager 暂不支持创建的类型")
            return nil
        }
        // 拼接新建文档的 URL,source用来作为上报，首页的上报跟新建文档的from冲突了，需要在这里强制改下
        var trueSource: FromSource?
        if source != .larkCreate {
            trueSource = .docCreate
        } else {
            trueSource = source
        }
        debugPrint("create ccmOpenType: \(ccmOpenType?.trackValue ?? "undefined")")
        if type.isEditorManagerHandleType(),
           let url = fetchCreatedURL(type: type, token: token, source: trueSource, ccmOpenType: ccmOpenType) {
            fileUrl = url
            if let currentS = templateSource, currentS.shouldUseNewForm() {
                fileUrl = fileUrl?.docs.addOrChangeEncodeQuery(parameters: ["larkForm": "1"])
            }
            if type == .bitable && UserScopeNoChangeFG.XM.ccmBitableRecordsGantt {
                fileUrl = fileUrl?.docs.addOrChangeEncodeQuery(parameters: ["from": "create_suite_template"])
                self.currentBrowser?.updateUrl(fileUrl ?? url)
            } else {
                self.currentBrowser?.updateUrl(url)
            }
            DocsTracker.startRecordTimeConsuming(eventType: .createFile, parameters: ["fileType": type.name])
        }
        // 开始打开
        if let url = fileUrl {
            // 根据配置获取一个 BrowserVC
            let browser = self.open(url, fileConfig: fileConfig)
            return browser.targetVC
        } else {
            return nil
        }
    }
    
    private func isDocVersionSame(_ url: URL) -> Bool {
        guard let currentUrl = self.currentEditor?.browserInfo.currentURL,
                let type = DocsType(url: url),
                let version = URLValidator.getVersionNum(url),
                let currentVersion = self.currentEditor?.browserInfo.docsInfo?.versionInfo?.version,
                let currentType = DocsType(url: currentUrl) else {
            return false
        }
        if type.supportVersionInfo {
            return (type == currentType) && (version == currentVersion)
        }
        return true
    }

    private func fetchCreatedURL(type: DocsType, token: String, source: FromSource?, ccmOpenType: CCMOpenType?) -> URL? {
        if !type.isEditorManagerHandleType() {
            spaceAssertionFailure("暂不支持的类型")
            return nil
        }

        var url = DocsUrlUtil.url(type: type, token: token)
        // private protocol
        if OpenAPI.offlineConfig.protocolEnable, let type = DocsType(url: url),
            (URLValidator.isMainFrameTemplateURL(url) || type == .doc || type == .folder || type == .sheet || type == .mindnote) {
            url = DocsUrlUtil.changeUrl(url, schemeTo: DocSourceURLProtocolService.scheme)
        }
        if let from = source {
            url = url.docs.addQuery(parameters: ["from": from.rawValue])
        }
        if let ccmOpenType = ccmOpenType {
            url = url.docs.addQuery(parameters: [CCMOpenTypeKey: ccmOpenType.trackValue])
        }
        
        return url
    }

    public func reload(_ urlStr: String? = nil) {
        guard let urlStr = urlStr, let url = URL(string: urlStr) else { return }
        currentEditor?.load(url: url)
    }

    public func preloadContent(_ url: String, from source: String) {
        preloader?.loadContent(url, from: source)
    }
    
    public func registerIdelTask(preloadName: String, action: @escaping () -> Void) -> Bool {
        return preloader?.registerIdelTask(preloadName: preloadName, action: action) ?? false
    }

    public func appDidBecomeActive(_ notify: NSNotification) {
        pool.isInForeground = true
    }

    public func appDidEnterBackground(_ notify: NSNotification) {
        pool.isInForeground = false
        guard let topBrowser = currentBrowser else { return }
        topBrowser.browerEditor?.docsLoader?.resetShowOverTimeTip()
        if let webEditor = topBrowser.browerEditor as? WebBrowserView {
            webEditor.resetStaticsOverTime()
        }
    }

    public func appdidReceiveMemoryWarning(_ notify: NSNotification) {
        DispatchQueue.main.async {
            DocsLogger.info("appdidReceiveMemoryWarning drain", component: LogComponents.editorPool)
            self.pool.drain()
//            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10, execute: {
//                DocsLogger.info("preload afeter receive memory warning", component: LogComponents.editorPool)
//                self.pool.preload()
//            })
        }
    }

    @objc
    @discardableResult
    public func tryToPreload() -> Bool {
        if User.current.info != nil {
            pool.preload()
            return true
        }
        return false
    }

    private func preload(delay: Double) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(tryToPreload), object: nil)
        perform(#selector(tryToPreload), with: nil, afterDelay: delay)
    }

    private func drainPoolAndPreload(delaytime: Double = 0) {
        DocsLogger.info("EditorManager drainPoolAndPreload:\(delaytime)")
        #if DEBUG
        if #available(iOS 12.0, *) {
            os_signpost(.begin, log: DocsSDK.openFileLog, name: "loadBlank")
        }
        #endif
        DispatchQueue.main.async {
            self.pool.drain()
            if delaytime > 0 {
                self.preload(delay: delaytime)
            } else {
                self.pool.preload()
            }
        }
    }

    public func drainPoolAndPreload() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            //ipad 保持旧逻辑
            drainPoolAndPreload(delaytime: 0.0)
        } else {
            //iphone上只有当前没有打开Docs才可以直接重新加载复用池，如果已经打开文档则等关闭文档后才开始加载复用池
            let count = newBrowsersStack.count
            if count > 0 {
                //避免影响当前打开的webview，添加一个标识，在文档关闭后重新加载
                needReloadEditorPool = true
                DocsLogger.info("drainPoolAndPreload later", component: LogComponents.editorPool)
            } else {
                drainPoolAndPreload(delaytime: 0.0)
            }
        }
        if hasPreloadWebView == false {
            hasPreloadWebView = true
            // App启动到触发webview预加载初始化耗时
            DocsTracker.log(enumEvent: .preLoadTemplate, parameters: ["cost_time_to_fill_pool": LarkProcessInfo.sinceStart()])
        }
    }
    
    public func reportPreloadStatics() {
        if hasPreloadModule == false {
            hasPreloadModule = true
            // 模版加载完到SDK初始化的时间
            DocsTracker.log(enumEvent: .preLoadTemplate, parameters: ["cost_time_preload_finish_to_doc_init": (Date().timeIntervalSince1970 - DocsPerformance.initTime) * 1000])
        }
    }
    
    public func getSSRPreloadTime(_ token: String) -> TimeInterval? {
        return preloader?.getSSRPreloadTime(token)
    }
    
    public func getClientVarsPreloadTime(_ token: String) -> TimeInterval? {
        return preloader?.getClientVarsPreloadTime(token)
    }
    
    public func preloadFeedback(_ token: String, hitPreload: Bool) {
        preloader?.preloadFeedback(token, hitPreload: hitPreload)
    }
    
    private func preloadFileIfNeeded(_ browser: BrowserViewControllerAbility) {
        if UserScopeNoChangeFG.GXY.ssrPreloadOptimizationEnable {
            guard  let webBrowser = browser.browerEditor as? WebBrowserView,
                   let filetype = browser.browerEditor?.docsInfo?.type,
                   filetype == .docX,
                   let renderKey = filetype.htmlCachedKey,
                   let prefix = User.current.info?.cacheKeyPrefix,
                   let token = browser.browerEditor?.docsInfo?.token,
                   let newCache = DocsContainer.shared.resolve(NewCacheAPI.self),
                   newCache.getH5RecordBy(H5DataRecordKey(objToken: token, key: prefix + renderKey))?.payload == nil,
                   let urlString = webBrowser.currentUrl?.absoluteString else {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500) { [weak self] in
                guard let `self` = self else { return }
                self.preloader?.IdlePreloadDocs(urlString)
            }
        }
    }
    
    @objc private func gecoPackageUpdateNotify() {
        DocsLogger.info("gecoPackageUpdate try to drainPoolAndPreload", component: LogComponents.editorPool)
        drainPoolAndPreload()
    }
    
    public func updateDocsConfig(_ config: DocsConfig) {
        self.config = config
    }
}

// MARK: - BrowserViewControllerDelegate

public protocol BrowserViewControllerDelegate: AnyObject {
    func browserViewControllerRedisplay(_ browser: BrowserViewControllerAbility)
    func browserViewControllerDismiss(_ browser: BrowserViewControllerAbility)
    func browserViewControllerDeinit(_ browser: BrowserViewControllerAbility)
    func markFeedCardShortcut(for feedId: String, isAdd: Bool, success: SKMarkFeedSuccess?, failure: SKMarkFeedFailure?)
    func isFeedCardShortcut(feedId: String) -> Bool
}

extension EditorManager: BrowserViewControllerDelegate {
    public func browserViewControllerRedisplay(_ browser: BrowserViewControllerAbility) {
        // 重新显示场景，这里做一个逻辑加入
        if newBrowsersStack.first(where: { (tempContainer) -> Bool in
            if let tempBrowser = tempContainer.value {
                return tempBrowser == browser
            }
            return false
        }) == nil {
            newBrowsersStack.append(WeakBrowserVCAbility(browser))
            if newBrowsersStack.count == 0 {
                //当前没有显示WebView，准备push第一个，发一个通知告诉大家
                NotificationCenter.default.post(name: Notification.Name.Docs.showingDocsViewController, object: nil, userInfo: nil)
            }
            browsersStackisEmpty.accept(false)
        }
    }

    public func browserViewControllerDismiss(_ browser: BrowserViewControllerAbility) {
        // 新重用逻辑下，需要在dimiss手动移除TopBrowser的引用，解决快速点击还未被释放的情况
        if let index = newBrowsersStack.firstIndex(where: { (tempContainer) -> Bool in
            if let tempBrowser = tempContainer.value {
                return tempBrowser == browser
            }
            return false
        }) {
            newBrowsersStack.remove(at: index)
            if newBrowsersStack.isEmpty {
                if needReloadEditorPool == true {
                    needReloadEditorPool = false
                    drainPoolAndPreload()
                } else {
                    //当前没有显示WebView，已经移除最后一个WebView，发一个通知告诉大家
                    NotificationCenter.default.post(name: Notification.Name.Docs.didHideDocsViewController, object: nil, userInfo: nil)
                }
            }
        }
    }

    public func browserViewControllerDeinit(_ browser: BrowserViewControllerAbility) {
        if let orientationDelegate = browser as? BrowserOrientationDelegate {
            orientationManager.removeEditor(orientationDelegate)
        }
        // 检查是否需要预加载SSR
        preloadFileIfNeeded(browser)
        let identity = browser.browerEditor?.jsEngine.editorIdentity ?? "no id"
        DocsLogger.info("\(identity) browserViewControllerDeinit", component: LogComponents.fileOpen)
        // 获取edit加载状态
        if let type = browser.browerEditor?.docsInfo?.type,
           let realToken = browser.browerEditor?.docsInfo?.token,
            browser.browerEditor?.currentURL?.docs.isDocHistoryUrl != true {
            DocsOfflineSyncManager.shared.removeWebviewHandledObjToken(realToken)
            let offlineFile = ManualOfflineFile(objToken: realToken, type: type)
            fileManuOfflineManager?.endOpen(offlineFile)
        }
        (browser.browerEditor as? WebBrowserView)?.statisticsDidEndLoadFinishType(.cancel)
        browser.browerEditor?.clear()
        (browser.browerEditor as? WebBrowserView)?.webViewGoBack()
        if let webBrowserView = browser.browerEditor as? WebBrowserView {
            pool.reclaim(editor: webBrowserView)
            if webBrowserView.isInEditorPool {
                //只有复用了才有必要检测卡死情况
                webBrowserView.checkForResponsiveness(from: .reclaimToPool)
            }
        }
        // 走到这里其实VC已经有没有引用者了，直接把value为nil的移除就好
        if let index = newBrowsersStack.firstIndex(where: { $0.value == nil }) {
            newBrowsersStack.remove(at: index)
            if newBrowsersStack.isEmpty {
                if needReloadEditorPool == true {
                    needReloadEditorPool = false
                    drainPoolAndPreload()
                } else {
                    //当前没有显示WebView，已经移除最后一个WebView，发一个通知告诉大家
                    NotificationCenter.default.post(name: Notification.Name.Docs.didHideDocsViewController, object: nil, userInfo: nil)
                }
            }
        }
        if newBrowsersStack.isEmpty {
            // 栈空通知
            browsersStackisEmpty.accept(true)
        }
        let param = SettingConfig.appConfigForFrontEnd
        browser.browerEditor?.callFunction(DocsJSCallBack(MinaConfigChange.callbacks), params: param, completion: nil)
    }

    public func markFeedCardShortcut(for feedId: String, isAdd: Bool, success: SKMarkFeedSuccess?, failure: SKMarkFeedFailure?) {
        delegate.editorManager(self,
                               markFeedCardShortcut: feedId,
                               isAdd: isAdd,
                               success: success,
                               failure: failure)
    }

    public func isFeedCardShortcut(feedId: String) -> Bool {
        return delegate.editorManager(self, getShortcutFor: feedId)
    }
}
extension EditorManager: BrowserViewControllerLifeCycle {
    func browserViewController(_ browser: BrowserViewController,
                               viewDidAppearAnimated: Bool) {
        _appear(browser)
    }

    func browserViewController(_ browser: BrowserViewController,
                               viewWillDisappearAnimated: Bool) {
        _disappear(browser)
    }

    private func _appear(_ browser: BrowserViewController) {
        lazyLoadDB()
        if !orientationManagerFG {
            return
        }
        if SKDisplay.phone {
            if browser.orientationDirector?.needSetLandscapeWhenAppear ?? false {
                browser.setLandscapeStrategyWhenAppear(false)
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
                    browser.orientationDirector?.setLandscapeIfNeed()
                }
            }
        }
    }

    private func lazyLoadDB() {
        // 数据库懒加载，首次进入web页面的时候，执行判断，懒加载数据库
        guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else {
            spaceAssertionFailure("dataCenterAPI nil")
            return
        }
        if dataCenterAPI.hadLoadDBForCurrentUser {
            DocsLogger.info("db is loaded")
            return
        }
        guard let userID = User.current.info?.userID, !userID.isEmpty else {
            DocsLogger.warning("user id is empty")
            return
        }
        dataCenterAPI.forceAsyncLoadDBIfNeeded(userID) { ret in
            DocsLogger.info("load db result \(ret)")
        }
    }

    private func _disappear(_ browser: BrowserViewController) {
        if !orientationManagerFG || browser.isInVideoConference {
            return
        }
        if UIApplication.shared.statusBarOrientation.isLandscape {
            browser.orientationDirector?.needSetLandscapeWhenAppear = true
        }
//        if SKDisplay.phone, UIApplication.shared.statusBarOrientation.isLandscape,
//            browser.orientationDirector?.needSetPortraitWhenDismiss ?? false {
//            browser.orientationDirector?.forceSetOrientation(.portrait)
//        }
        if SKDisplay.phone {
            orientationManager.resetLastBrowserNeedSetPortraitWhenDismiss()
        }
    }
}

// MARK: - EditorDelegate 离线操作同步本地数据库
extension EditorManager: BrowserViewOfflineDelegate {
    func browserView(_ browserView: BrowserView, setTitle title: String, for objToken: String) {
        DispatchQueue.global().async {
            let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
            dataCenterAPI?.rename(objToken: objToken, with: title)
        }
    }

    func browserView(_ browserView: BrowserView, setNeedSync needSync: Bool, for objToken: FileListDefine.ObjToken, type: DocsType) {
        DocsLogger.info("set need sync in objToken \(DocsTracker.encrypt(id: objToken))")
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        dataCenterAPI?.updateNeedSyncState(objToken: objToken, type: type, needSync: needSync, completion: nil)
    }

    func browserView(_ browserView: BrowserView, didSyncWithObjToken objToken: String, type: DocsType) {
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        dataCenterAPI?.updateNeedSyncState(objToken: objToken, type: type, needSync: false, completion: nil)
        delegate?.editorManager(self, syncFinished: _currentBrowserVC(browserView))
    }
}

extension EditorManager: DocsBrowserShareDelegate {

    func browserViewRequestShareAccessory(_ browserView: BrowserView) -> UIView? {
        guard let topBrowser = _currentBrowserVC(browserView) else {
            return nil
        }
        return delegate?.editorManagerRequestShareAccessory(self, browser: topBrowser)
    }

}

extension EditorManager {

    func sendLarkOpenEvent(_ browserView: BrowserView, event: LarkOpenEvent) {
        delegate?.sendLarkOpenEvent(event)
    }

    func browserView(_ browserView: BrowserView, markFeedMessagesRead params: [String: Any]) {
        guard let topBrowser = _currentBrowserVC(browserView) else {
            return
        }

        delegate?.editorManager(self, markFeedMessagesRead: params, in: topBrowser)
    }

    func browserView(_ browserView: BrowserView, setTitleInfo titleInfo: NavigationTitleInfo?) {
        if let customNaviBrowserVC = _currentBrowserVC(browserView) as? BrowserViewController,
           customNaviBrowserVC.editor.chatId == nil /* 群公告不更新标题 */ {
            if customNaviBrowserVC.navigationBar.titleInfo?.displayType == .fullCustomized {
                return  // 已有的 titleInfo 是 fullCustomized，则不允许这里的覆盖设置
            }
            customNaviBrowserVC.navigationBar.titleInfo = titleInfo
        }
    }

    func browserView(_ browserView: BrowserView, setNeedDisPlay needDisPlay: Bool, tagValue: String) {
        if let customNaviBrowserVC = _currentBrowserVC(browserView) as? BrowserViewController {
            customNaviBrowserVC.setShowExternalTag(needDisPlay: needDisPlay, tagValue: tagValue)
            if customNaviBrowserVC.editor.chatId == nil, /* 群公告不显示外部标签 */
               let defaultTitleView = customNaviBrowserVC.navigationBar.titleView as? SKNavigationBarTitle {
                defaultTitleView.needDisPlayTag = needDisPlay
                defaultTitleView.tagContent = tagValue
                customNaviBrowserVC.navigationBar.setNeedsLayout()
            }
        }
    }
    
    func browserView(_ browserView: BrowserView, setCanRename titleCanRename: Bool?) {
        if let customNaviBrowserVC = _currentBrowserVC(browserView) as? BrowserViewController,
           customNaviBrowserVC.editor.chatId == nil /* 群公告不更新标题 */ {
            customNaviBrowserVC.navigationBar.titleCanRename = titleCanRename
        }
    }

    func browserView(_ browserView: BrowserView, setAvatar avatarInfo: IconSelectionInfo?) {
        if let customNaviBrowserVC = _currentBrowserVC(browserView) as? BrowserViewController,
           customNaviBrowserVC.editor.chatId == nil, /* 群公告不显示自定义 icon */
           let defaultTitleView = customNaviBrowserVC.navigationBar.titleView as? SKNavigationBarTitle {
            defaultTitleView.iconInfo = avatarInfo
            customNaviBrowserVC.navigationBar.setNeedsLayout()
        }
    }

    func browserView(_ browserView: BrowserView, setTitleBarStatus status: Bool) {
        UIView.performWithoutAnimation {
            let curBrowser = _currentBrowserVC(browserView)
            curBrowser?.setNavigationBarHidden(status, animated: false)
        }
    }

    ///密级title标签
    func browserView(_ browserView: BrowserView, secretTitle title: String) {
        if let customNaviBrowserVC = _currentBrowserVC(browserView) as? BrowserViewController,
           let defaultTitleView = customNaviBrowserVC.navigationBar.titleView as? SKNavigationBarTitle {
            let icon = UDIcon.safePassOutlined.ud.withTintColor(UDColor.iconN3)
            let titleBottomAttachInfo = SKBarTitleBottomAttachInfo(icon: icon, title: title)
            defaultTitleView.titleBottomAttachInfo = titleBottomAttachInfo
        }
    }

    func browserView(_ browserView: BrowserView, setToggleSwipeGestureEnable enable: Bool) {
        _currentBrowserVC(browserView)?.setToggleSwipeGestureEnable(enable)
    }
    
    func browserView(_ browserView: BrowserView, setTemplate isTemplate: Bool) {
        if let customNaviBrowserVC = _currentBrowserVC(browserView) as? BrowserViewController {
            customNaviBrowserVC.setShowTemplateTag(isTemplate)
            if let defaultTitleView = customNaviBrowserVC.navigationBar.titleView as? SKNavigationBarTitle {
                defaultTitleView.showTemplateTag = isTemplate
                customNaviBrowserVC.navigationBar.setNeedsLayout()
            }
        }
    }

    //是否已经处理好了本页面的跳转
    private func handleSamePageFor(_ browserView: BrowserView, url: URL, showToast: Bool = true) -> Bool {
        guard let topBrowser = _currentBrowserVC(browserView), let navigation = topBrowser.navigationController else {
            spaceAssertionFailure("navigation vc missed to open browser")
            DocsLogger.info("get topBrowser fail", component: LogComponents.requireOpen)
            return false
        }
        
        guard let type = DocsUrlUtil.getFileType(from: url), type.isOpenByWebview else {
            DocsLogger.info("isOpenByWebview fail", component: LogComponents.requireOpen)
            return false
        }
        
        guard let vc = checkIfFileInStack(browserView, url: url) else {
            DocsLogger.info("\(type) checkIfFileInStack fail", component: LogComponents.requireOpen)
            return false
        }
        
        func jumpToBlock() {
            guard url.fragment != nil else { return }
            DocsLogger.info("jumpToBlock", component: LogComponents.requireOpen)
            vc.browerEditor?.callFunction(DocsJSCallBack.navigationJump, params: ["hash": url.fragment.unsafelyUnwrapped.docs.escapeSingleQuote()], completion: nil)
        }
        let shouldLocateToBlock = url.docs.isFragmentADocBlock
        
        DocsLogger.info("handleSamePageFor",
                        extraInfo: ["fragment": url.fragment,
                                    "isTopViewController": (!isTopViewController(vc, topBrowser: topBrowser))],
                        component: LogComponents.requireOpen)
        let tuple = url.docs.isCommentAnchorLink
        let commentAnchorLinkEnable = UserScopeNoChangeFG.HYF.commentAnchorLinkEnable
        if !isTopViewController(vc, topBrowser: topBrowser) {
            navigation.popToViewController(vc, animated: true)
            if tuple.isCommentAnchor, commentAnchorLinkEnable {
                vc.browerEditor?.activeComment(by: tuple.commentId)
            } else if shouldLocateToBlock {
                jumpToBlock()
            }
        } else if shouldLocateToBlock {
            jumpToBlock()
        } else if showToast {
            if tuple.isCommentAnchor, commentAnchorLinkEnable {
                if let presentedViewController = topBrowser.presentedViewController,
                   !presentedViewController.isBeingDismissed {
                    topBrowser.dismiss(animated: false)
                }
                topBrowser.browerEditor?.activeComment(by: tuple.commentId)
            } else {
                let hud = UDToast.showFailure(with: BundleI18n.SKResource.Doc_Normal_SamePageTip, on: topBrowser.view)
                hud.observeKeyboard = false
                if let toolContainer = (vc as? BrowserViewController)?.toolbarManager.m_container,
                   let toolBarHeight = browserView.toolbarManagerProxy.toobar?.frame.height,
                   toolBarHeight > 0 {
                    let offset = abs(toolContainer.frame.minY) + toolBarHeight + 20
                    hud.setCustomBottomMargin(offset)
                }
            }
        }
        return true
    }

    private func isTopViewController(_ curVC: UIViewController, topBrowser: UIViewController) -> Bool {
        let isWikiTopVC = nonEmptyUserResolver.docs.browserDependency?.isWikiTopViewController(curVC, topBrowser: topBrowser) ?? false
        if isWikiTopVC {
            return true
        } else {
            return curVC as? BaseViewController == topBrowser
        }
    }

    private func checkIfFileInStack(_ browserView: BrowserView, url: URL) -> BrowserViewControllerAbility? {
        guard let currentVC = _currentBrowserVC(browserView), let navigation = currentVC.navigationController else {
            spaceAssertionFailure("navigation vc missed to open browser")
            return nil
        }
        guard let token = DocsUrlUtil.getFileToken(from: url),
            let type = DocsUrlUtil.getFileType(from: url) else { return nil }
        
        var stackVCs = navigation.viewControllers
        if !stackVCs.contains(currentVC) {
            stackVCs.insert(currentVC, at: 0)
        }
        
        return stackVCs.first(where: { (vc) -> Bool in
            guard let vc = vc as? BrowserViewControllerAbility, let docsInfo = vc.browerEditor?.docsInfo else { return false }
            if !UserScopeNoChangeFG.YY.bitableDocxInBaseFixJumpDisable, 
                let currentVC = currentVC as? BrowserViewController,
                currentVC.isEmbedMode,
                browserView.isDescendant(of: vc.view) {
                // 当前 VC 是嵌入模式(例如：docx@base)，则当前 VC 的宿主 VC 不被认为是 stack 内的目标对象
                return false
            }
            let vcIsHistory = vc.browerEditor?.currentUrl?.docs.isDocHistoryUrl ?? false
            let vcIsAppeal = vc.browerEditor?.currentUrl?.docs.isAppealUrl ?? false
            let targetIsHistory = url.docs.isDocHistoryUrl
            let targetIsAppeal = url.docs.isAppealUrl
            let vcVersionNum = URLValidator.getVersionNum(vc.browerEditor?.currentUrl)
            let targetVersionNum = URLValidator.getVersionNum(url)
            
            if type == .wiki {
                return docsInfo.wikiInfo?.wikiToken == token && vcIsHistory == targetIsHistory &&
                (browserView.vcFollowDelegate == nil ? vcVersionNum == targetVersionNum : true)
            } else {
                return docsInfo.urlToken == token
                    && docsInfo.urlType == type
                    && vcIsHistory == targetIsHistory
                    && vcIsAppeal == targetIsAppeal
                    && (browserView.vcFollowDelegate == nil ? vcVersionNum == targetVersionNum : true)
            }
        }) as? BrowserViewControllerAbility
    }
}

extension EditorManager {
    public var netRequestHeader: [String: String]? {
        return SpaceHttpHeaders()
            .addLanguage()
            .addCookieString()
            .merge(config?.infos)
            .dictValue
    }
}

extension EditorManager: BrowserViewStatisticsDelegate {
    func browserView(_ browserView: BrowserView, isPreLoad url: String) -> Bool {
        return URLValidator.isMainFrameTemplateURL(URL(string: url))
    }

    func browserView(_ browserView: BrowserView, encryptedTokenFor token: String) -> String {
        return DocsTracker.encrypt(id: token)
    }
}

extension EditorManager: BrowserViewNavigator {
    public func currentBrowserVC(_ browserView: BrowserView) -> UIViewController? {
        return _currentBrowserVC(browserView)
    }

    @discardableResult
    public func browserView(_ browserView: BrowserView, requiresOpen url: URL) -> Bool {
        return requiresOpen(browserView, url: url)
    }

    private func _currentBrowserVC(_ browserView: BrowserView) -> BrowserViewControllerAbility? {
        let browser = newBrowsersStack.first { (weakVC) -> Bool in
            guard let vc = weakVC.value else {
                return false
            }
            return vc.browerEditor == browserView
        }
        return browser?.value
    }
    
    public func pageIsExistInStack(_ browserView: BrowserView, url: URL) -> Bool {
        return handleSamePageFor(browserView, url: url, showToast: false)
    }
}

extension EditorManager {
    // swiftlint:disable cyclomatic_complexity
    public func requiresOpen(_ browserView: BrowserView, url: URL) -> Bool {
        var url = url
        //处理同页面的情况
        DocsLogger.info("start \(url.unlForLog)", component: LogComponents.requireOpen)
        if OpenAPI.docs.isSetAgentToFrontend == false {
            //如果代理到前端在调试则不做这个判断
            if handleSamePageFor(browserView, url: url) {
                DocsLogger.info("handleSamePage true", component: LogComponents.requireOpen)
                return false
            }
        }
        guard let topBrowser = _currentBrowserVC(browserView) else {
            return false
        }
        if let previewBrowser = self.curBrowserVC as? TemplatePreviewBrowser,
           previewBrowser.isFromTemplatePreview {
            if URLValidator.isDocsURL(url) {
                return false
            }
        }
        // 允许Load 本地资源, 并且清除render
        if url.isFileURL {
            topBrowser.browerEditor?.clearPreloadStatus()
            return true
        }
        // 通过loadRequest或render设置的加载、302重定向的加载、主文档模板直接允许
        if URLValidator.isMainFrameTemplateURL(url) {
            DocsLogger.debug("main frame \(url) requires open")
            return true
        }
        
        if OperationInterceptor.interceptUrlIfNeed(url.absoluteString,
                                                   from: topBrowser,
                                                   followDelegate: topBrowser.browerEditor?.vcFollowDelegate) {
            return false
        }

        url = DocsUrlUtil.transformUpgradeUrl(url)
        if URLValidator.canOpen(url.absoluteString) {
            // Docs链接, 是在新的VC打开
            guard let navigation = topBrowser.navigationController else {
                spaceAssertionFailure("navigation vc missed to open browser")
                return false
            }
            let modifiedUrl = url.docs.addQuery(parameters: ["from": FromSource.other.rawValue])
            if let from = currentBrowser, !SKRouter.shared.jumpDocsTabIfProssible(modifiedUrl, from: from) {
                guard let vc = delegate.editorManagerMakeVC(self, url: modifiedUrl) else {
                    return false
                }
                // 避免连续push的问题，如果是特殊VC，则不跳转
                guard !(vc is ContinuePushedVC) else { return false }
                _handleOrientationChange(navigation, newVC: vc, url: modifiedUrl)
                excuteAfterHideKeyboard(topBrowser) {
                    if !UserScopeNoChangeFG.ZYS.baseRecordTempOpenFixDisable {
                        var shouldOpenInTemp = false
                        var canOpenInTemp = false
                        if let fromVC = topBrowser as? TabContainable, fromVC.isTemporaryChild {
                            shouldOpenInTemp = true
                        }
                        if let toVC = vc as? TabContainable, toVC.docsCanOpenInTemporary {
                            canOpenInTemp = true
                        }
                        if shouldOpenInTemp, canOpenInTemp {
                            Navigator.shared.showTemporary(vc, from: topBrowser)
                        } else {
                            Navigator.shared.push(vc, from: topBrowser)
                        }
                        return
                    }
                    if let browserVC = topBrowser as? TabContainable, browserVC.isTemporaryChild {
                        Navigator.shared.showTemporary(vc,from: topBrowser)
                    } else {
                        navigation.pushViewController(vc, animated: true)
                    }
                }
            }
            return false
        } else {
            if JiraPatternUtil.checkIsCommonJiraDomain(url: url.absoluteString) == true {
                if UIApplication.shared.canOpenURL(url) == true {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    return false
                } else { DocsLogger.info("atlassian.net,没有安装jira APP") }
            }
            if UIApplication.shared.statusBarOrientation.isLandscape {
                //打开外部链接转先转到竖屏
                LKDeviceOrientation.setOritation(.portrait)
                topBrowser.setLandscapeStrategyWhenAppear(true)
            }
            excuteAfterHideKeyboard(topBrowser) {
                self.delegate?.editorManager(self, requiresToHandleOpen: url.absoluteString, in: topBrowser)
            }
            return false
        }
    }

    private func excuteAfterHideKeyboard(_ topBrowser: BrowserViewControllerAbility?, action: @escaping () -> Void) {
        if #available(iOS 14, *), let browserVC = topBrowser as? BrowserViewController, browserVC.keyboard.isShow {
            //https://jira.bytedance.com/browse/DM-9984 iOS14中键盘显示时，pushvc会出现动画异常，先收起键盘
            DocsLogger.info("[test] hidekeyboard in endEdit")
            browserVC.browerEditor?.toolbarManagerProxy.toobar?.hideKeyboard()
            DispatchQueue.main.async {
                action()
            }
        } else {
            action()
        }
    }

    private func _handleOrientationChange(_ navigation: UINavigationController,
                                          newVC: UIViewController,
                                          url: URL) {
        // 跳转的界面可能是支持横竖屏切换的 Browser。如果不支持，应该让界面旋转回去
        if orientationManagerFG {
            let last = navigation.viewControllers.last as? BrowserViewController
            let new = newVC as? BrowserViewController
            let needChangeOrientationsWhenTransition = DocsUrlUtil.getFileType(from: url)?.alwaysOrientationsEnable ?? false
            let orientationEnable = needChangeOrientationsWhenTransition
            let statusBarIsLandscape = UIApplication.shared.statusBarOrientation.isLandscape
            // 上一个。他的 dismiss 要不要转，是由新一个决定的
            if orientationEnable {
                last?.orientationDirector?.needSetPortraitWhenDismiss = false
            }
            // 新一个。他的 dismiss 要不要转，是由上一个决定的
            if statusBarIsLandscape {
                new?.orientationDirector?.needSetPortraitWhenDismiss = false
            }
        } else {
            if !(DocsUrlUtil.getFileType(from: url)?.alwaysOrientationsEnable ?? false) {
                LKDeviceOrientation.setOritation(UIDeviceOrientation.portrait)
            }
        }
    }

    //different with func requiresOpen(url: URL) -> Bool?
    func openURL(_ url: URL?) {
        guard let topBrowser = currentBrowser, let url = url else { return }
        delegate?.sendLarkOpenEvent(.openURL(url, topBrowser))
    }
}

// MARK: -
extension EditorManager {
    private func addListPageObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didDeleteFile(_:)),
                                               name: Notification.Name.Docs.deletedBySpaceOperation,
                                               object: nil)
    }

    @objc
    func didDeleteFile(_ notification: Notification) {
        guard SKDisplay.pad,
            let objs = notification.object as? (String, String?),
            currentBrowser?.browerEditor?.docsInfo?.objToken == objs.1 else {
                return
        }
        let browserVC = currentBrowser as? BaseViewController
        browserVC?.back(canEmpty: true)
    }
}

extension EditorManager: DocsOfflineSynManagerDependency {
    public var curBrowserVC: UIViewController? {
        return currentBrowser
    }
}
