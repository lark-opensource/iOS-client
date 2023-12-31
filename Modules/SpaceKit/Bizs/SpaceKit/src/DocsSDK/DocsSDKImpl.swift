//
//  SpaceKitImpl.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/4/26.
//  swiftlint:disable file_length

import Foundation
import LarkUIKit
import os
import EENavigator
import SpaceInterface
import RustPB
import RxSwift
import RxRelay
import LarkRustClient
import LarkExtensions
import SKFoundation
import SKCommon
import SKSpace
import SKDrive
import SKBrowser
import SKDoc
import SKWikiV2
import SKSheet
import SKBitable
import SKMindnote
import SKComment
import SKPermission
import LarkFeatureGating
import SKInfra
import SKSlides
import BootManager
import LarkContainer
import LarkAccountInterface
import LKCommonsTracker

#if SK_EDITOR_JS
import LarkEditorJS
#endif

public final class DocsSDKImpl: DocsSDK {
    
    public init(config: DocsConfig, delegate: DocsManagerDelegate, userResolver: UserResolver, resolver: DocsResolver = DocsContainer.shared) {
        super.init(resolver: resolver, userResolver: userResolver)
        self.delegate = delegate

        DocsLogger.info("---SDK Init---", component: LogComponents.sdkConfig)
        registerModules()
        registerDependencies()

        registerLauncherV2(with: config)

        self.registerRouter()
        UserDefaultKeys.registureDefault()

        #if DEBUG && targetEnvironment(simulator)
        self.tryInjectionForDebug()
        #endif

        #if canImport(SKEditor)
        DocsNativeEditorManager.registerDependency()
        #endif
    }
    
    private func prepareUserInfo() {//TODO:refactor 移到Common
        if let basicUserInfo = userResolver.docs.user?.basicInfo {
            let userInfo = UserInfo(basicUserInfo.userID)
            userInfo.updateUserPropertiesFromUserDefaults(about: basicUserInfo.userID)
            userResolver.docs.user?.reloadUserInfo(userInfo)
        }
    }

    /// login:
    /// 后面新加的任务请尽量用通知：userDidLogin
    public override func handleUserLogin(userResolver: UserResolver, docsConfig: DocsConfig) {
        DocsLogger.info("loginStatus-login")
        guard let userInfo = delegate?.basicUserInfo, !userInfo.userID.isEmpty else {
            DocsLogger.error("user info is nil or user id is empty")
            spaceAssertionFailure("deleget userinfo is nil")
            return
        }
        DocsContainer.shared.userDidLogin()
        // 关键信息，不要随便更改位置顺序
        initRustClient()
        refreshDomain()
        userResolver.docs.user?.reloadUser(basicInfo: userInfo) // 会将 User.current.info 整个重新赋值
        userResolver.docs.netConfig?.updateBaseUrl(OpenAPI.docs.baseUrl)

        let deviceid = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.deviceID) ?? ""

        GeckoPackageManager.shared.setDomain(DomainConfig.geckoDomain)
        userResolver.docs.netConfig?.currentLang = DocsSDK.convertedLanguage
        userResolver.docs.netConfig?.currentLangLocale = DocsSDK.currentLanguage.languageIdentifier
        setupCookies()
        userResolver.docs.user?.refreshUserProfileIfNeed()

        userResolver.docs.moduleManager.userDidLogin()

        // 模板里有用户信息，需要reset一次
        DocsLogger.info("drain and delay preload", component: LogComponents.editorPool)

        DispatchQueue.main.async {
//            if ListConfig.needDelayLoadDB {
//                let listConfigAPI = DocsContainer.shared.resolve(ListConfigAPI.self)
//                listConfigAPI?.excuteWhenSpaceAppearIfNeeded(needAdd: true) {
//                    CacheService.deleteOldFileIfExist()
//                }
//            } else {
                SKDataManager.shared.loadData(userInfo.userID) { ret in
                    DocsLogger.info("load db result = \(ret)")
                    CacheService.deleteOldFileIfExist()
                }

//            }
            userResolver.docs.editorManager?.updateDocsConfig(docsConfig)
            userResolver.docs.editorManager?.delegate = self
            self.fetchConfigAfterUserLogin()
        }

        refreshWatermark()
        resolver.resolve(NewCacheAPI.self)?.userDidLogin()
        resolver.resolve(ManuOfflineRNWatcherAPI.self)?.userDidLogin()
        if OpenAPI.offlineConfig.protocolEnable {
            GeckoPackageManager.shared.syncResourcesIfNeeded()
        }
        _ = offlineSyncManager
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5 + OpenAPI.delayLoadRNInSeconds) {
            var preloadDisabled = false
            preloadDisabled = SettingConfig.disablePreloadConfig?.preloadDisabled ?? preloadDisabled
            if let abConfig = Tracker.experimentValue(key: "ccm_preload_source_disabled", shouldExposure: true) as? [String: Any] {
                preloadDisabled = abConfig["preload_disabled_when_app_start"] as? Bool ?? preloadDisabled
            }
            if !NewBootManager.shared.liteConfigEnable(), !preloadDisabled {
               RecentListDataModel.preloadFirstPage()
            }
            if UserScopeNoChangeFG.HZK.fullPkgUnzipOptimize {
                GeckoPackageManager.shared.downloadFullPackageIfNeeded()
            }
            
        }
        // 后面新增任务尽可能用通知
        NotificationCenter.default.post(name: Notification.Name.Docs.userDidLogin, object: nil,
                                        userInfo: ["userID": userResolver.userID])
        resolver.resolve(DomainConfigRNWatcher.self)?.registerRNEvent()
        // handle user login task if current in LarkDocs
        handleLarkDocsUserLogin()
        lockFGForUser()
    }

    public override func loadFirstPageIfNeeded() {
        let manager = SKDataManager.shared
        if manager.hadLoadDBForCurrentUser == true {
            DocsLogger.info("db is loaded")
            return
        }
        guard let userID = userResolver.docs.user?.info?.userID, !userID.isEmpty else {
            DocsLogger.warning("user id is empty")
            return
        }
        manager.forceAsyncLoadDBIfNeeded(userID) { ret in
            DocsLogger.info("load db result \(ret)")
        }

    }

    // MARK: 预加载文档内容
    public override func preloadFile(_ url: String, from source: String) {
        spaceAssert(url.count > 0, "url should not be empty!")
        EditorManager.shared.preloadContent(url, from: source)
    }

    /// logout:
    /// 后面新加的任务请尽量用通知：userWillLogout/userDidLogout
    /// 有依赖用户id、网络、文件数据等这些的，需要在userWillLogout里操作
    public override func handleUserLogout() {
        DocsLogger.info("loginStatus-logout")

        // 不要随意换位置, 新增任务尽可能用通知
        NotificationCenter.default.post(name: Notification.Name.Docs.userWillLogout, object: nil)

        Launcher.shared.shutdown()
        SKDataManager.shared.clear { ret in
            DocsLogger.info("dataManager clear \(ret)")
        }
        EditorManager.shared.pool.drain()
        userResolver.docs.user?.logout()
        userResolver.docs.netConfig?.cancelRequestsAndReset()
        userResolver.docs.netConfig?.resetDomain()
        DocsUrlUtil.resetConfig()
        PreloadKey.cacheKeyPrefix = ""
        resolver.resolve(ManuOfflineRNWatcherAPI.self)?.userDidLogout()
        resolver.resolve(NewCacheAPI.self)?.userDidLogout()
        resolver.resolve(BTUploadAttachCacheCleanable.self)?.userDidLogout()
        resolver.resolve(DriveCacheServiceBase.self)?.userDidLogout()
        resolver.resolve(ListConfigAPI.self)?.clearDelayedBlocks()

        userResolver.docs.moduleManager.userDidLogout()

        NotificationCenter.default.post(name: Notification.Name.Docs.userDidLogout, object: nil)
    }

    /// 账号登出前的操作
    public override func handleBeforeUserLogout() {
        cancelDriveAllAsyncInBackground()
    }

    /// 切换租户前的操作
    public override func handleBeforeUserSwitchAccout() {
        cancelDriveAllAsyncInBackground()
    }

    /// 封装了取消所有上传/下载请求的后台异步接口，避免401错误码
    private func cancelDriveAllAsyncInBackground() {
        DispatchQueue.global(qos: .userInteractive).async {
            let resultCode = SpaceRustRouter.shared.cancelAllRequest()
            DocsLogger.error("DriveCancelAllRequest with resut: \(String(describing: resultCode))")
        }
    }

}

// MARK: - Setup

extension DocsSDKImpl {
    private func registerModules() {
        var modules: [ModuleService] = [
            CommonModule(),
            SpaceModule(),
            BrowserModule(),
            DriveModule(),
            DriveSDKModule(),
            DocModule(),
            SheetModule(),
            SlidesModule(),
            BitableModule(),
            MindNoteModule(),
            SpaceKitModule(),
            WikiModuleV2(),
            CommentModule(),
            PermissionModule()
        ]
        self.userResolver.docs.moduleManager.registerModules(modules)
    }

    private func registerDependencies() {
        let userContainer = Container.shared.inObjectScope(CCMUserScope.userScope)
        
        if CCMUserScope.docEnabled {
            userContainer.register(SKBrowserDependency.self) {
                SKBrowserDependencyImpl(userResolver: $0)
            }
        } else {
            Container.shared.register(SKBrowserDependency.self, factory: { _ in
                SKBrowserDependencyImpl(userResolver: nil)
            }).inObjectScope(.container)
        }
        
        DocsContainer.shared.register(SKDriveDependency.self, factory: { (_) -> SKDriveDependency in
            return SKDriveDependencyImpl()
        }).inObjectScope(.container)
        DocsContainer.shared.register(SKCommonDependency.self, factory: { (_) -> SKCommonDependency in
            return SKCommonDependencyImpl()
        }).inObjectScope(.container)
        DocsContainer.shared.register(DocsLoadingViewProtocol.self) { _ in (self.delegate?.animationLoading)! }
        SKFoundationConfigImpl.shared.config()
        SKUIKitConfigImpl.shared.config()
    }

    // 初始化rust
    func initRustClient() {
        if !DocsContainer.shared.useLarkContainer {
            //统一使用LarkContainer，已经在LarkContainer注册过了，所以不用再次在DocsContainer注册了
            DocsContainer.shared.register(RustService.self) { (_) -> RustService in
                return self.delegate!.rustService
            }
        }
    }

    // 给rust设置Docs的Domain-Alias映射
    //https://bytedance.feishu.cn/space/doc/doccntyxM9nVlJxMHAcIYb6aONf#
    func setupRustDomainToAlias() {
        DocsLogger.info("Docs:setupRustDomainToAlias")

        let rustService = self.delegate!.rustService
        var request = SetDomainAliasRequest()

        /// 这么写是因为KA用户的 mainLandDomainRelease和mainLandDomainStaging，在同一个环境release、staging是一个，
        /// 同时为了兼容非KA用户
        var domain2AliasDict = [DomainConfig.NewDomainHost.mainLandDomainRelease: DomainSettings.Alias.docsApi]
        domain2AliasDict[DomainConfig.NewDomainHost.mainLandDomainStaging] = DomainSettings.Alias.docsApi
        domain2AliasDict[DomainConfig.NewDomainHost.overSeaDomainRelease] = DomainSettings.Alias.docsApi
        domain2AliasDict[DomainConfig.NewDomainHost.overSeaDomainStaging] = DomainSettings.Alias.docsApi

        request.domain2Alias = domain2AliasDict

        _ = rustService.sendAsyncRequest(request).subscribe()
    }
}


// MARK: - Launcher

fileprivate extension DocsSDKImpl {

    func registerLauncherV2(with config: DocsConfig) {
        DocsPerformance.initTime = Date().timeIntervalSince1970
        DocsTracker.startRecordTimeConsuming(eventType: .sdkInit, parameters: nil)
        // SerialStage代表加入到这个阶段里的任务，是以串行方式，一个接着一个进行执行
        let initSyncStage = SerialStage(identifier: "initSyncStage")
        // ConcurrentStage代表加入到这个阶段里的任务，是并发的进行，最大并发数等于CPU核心数+1，isLeisureStage为true代表会在满足闲时时才进行
        let initAsyncStage = ConcurrentStage(identifier: "initAsyncStage", isLeisureStage: false)
        //        let leisureAsyncStage = ConcurrentStage(identifier: "leisureAsyncStage", isLeisureStage: true)// 暂时无相关任务
        initSyncStage.appendTask(name: "environmentSetup", taskClosure: {
            self.registerHostBridge()
            /// lark 登录模块触发handleUserLogin的时机偶现不及时，导致启动App后快速点击到Space时，User.current.info == nil，此时去链接数据库等会中断言
            /// 所以要提前准备好userInfo
            self.prepareUserInfo()
            self.netConfigTask(with: config)
        })
        initSyncStage.appendTask(name: "DocsManager", taskClosure: {
            self.docsManagerTask(with: config)
        })
        initAsyncStage.appendTask(name: "leisureAsync", taskClosure: {
            self.launchAsyncTask(with: config)
        })
        // sync代表阶段里的注册的所有任务执行时，会阻塞当前线程，直到所有任务完成后，才会继续
        Launcher.shared.addSync(initSyncStage)
        // async代表阶段里的注册的所有任务执行时，会放到其他线程执行，如果阶段标记为isLeisureStage，会在满足闲时时执行
        Launcher.shared.addAsync(initAsyncStage)
        //        Launcher.shared.addAsync(leisureAsyncStage)
        // 每1.0s监控一次当前状态(默认值)
        Launcher.shared.config.monitorInterval = launcherV2MonitorInterval
        // CPU瞬时低于10%记为闲时(默认值)
        Launcher.shared.config.leisureCondition[.cpu] = launcherV2LeisureCondition
        // CPU连续闲时次数超过3次触发闲时任务(默认值)
        Launcher.shared.config.leisureTimes = launcherV2LeisureTimes
        // 开始执行
        Launcher.shared.kickOff()

        DocsTracker.endRecordTimeConsuming(eventType: .sdkInit, parameters: nil)
    }


    private func docsManagerTask(with config: DocsConfig) {
        self.makeURLRouter()
        // 不要阻塞主线程
        DispatchQueue.global().async {
            #if SK_EDITOR_JS
            CommonJSUtil.unzipIfNeeded()
            #endif
            self.setupGecko(config: config.geckoConfig)
            if !DocsSDK.isNeedDelayRN {
                self.setupRNEvent()
            }
        }
        UIApplication.registDocsSwizz()
        _ = NotificationCenter.default.rx.notification(Notification.Name.Docs.docsTabDidAppear)
            .subscribe(onNext: { [weak self] _ in self?.setupRN(needBlockUI: false) }) // Demo 测试这种写法needBlockUI恒为false

        _ = NotificationCenter.default.rx.notification(Notification.Name(DocsSDK.mediatorNotification))
            .subscribe(onNext: { [weak self] notification in self?.didReceiveMediatorNotification(notification: notification) })

        EditorManager.shared.updateDocsConfig(config)
        EditorManager.shared.delegate = self
    }


    private func launchAsyncTask(with config: DocsConfig) {
        // DocsSDK的init流程影响整个docs的启动速度, 如果非关键业务相关, 请优先考虑放在asyncSetup中
        self.printConfig()
        self.configLogger()
        self.saveConfig(config)
        self.appLifeCycle.add(lifeCycle: self)
        AutoTestSetting.configAutoTestSetting()
        DocsSDKImpl.enableRunLoopObserver()
    }
}


// MARK: - Config

fileprivate extension DocsSDKImpl {

    func netConfigTask(with config: DocsConfig) {
        DomainConfig.ka.updateDomains(config.domains)
        DomainConfig.appKey = config.appKey
        if let envInfo = config.envInfo {
            DomainConfig.updateEnvInfo(envInfo)
            DocsLogger.info("update envInfo: \(envInfo)")
        }

        DomainConfig.updateUserDomain(config.domains.userDomain)
        
        /* 这个FG 3.3 已经全量，在用户第一次安装的时候，必须是true，不然会影响OpenAPI.docs.baseUrl的返回值，导致
         DomainConfig.requestExDomainConfig()中的请求偶现被取消，因为NetConfig.baseUrl域名更换，会把当前的请求cancel
         */
        CCMKeyValue.globalUserDefault.set(true, forKey: UserDefaultKeys.isNewDomainSystemKey)

        userResolver.docs.netConfig?.currentLang = DocsSDK.convertedLanguage
        userResolver.docs.netConfig?.currentLangLocale = DocsSDK.currentLanguage.languageIdentifier
        userResolver.docs.netConfig?.configWith(baseURL: OpenAPI.docs.baseUrl, additionHeader: config.infos)
        // 这里改成更可靠的方法来获取userID给网络层，因为走这里的时候User.current.info == nil，User.current.info在login中初始化
        userResolver.docs.netConfig?.userID = userResolver.docs.user?.basicInfo?.userID

        userResolver.docs.netConfig?.authDelegate = self.delegate
        //Rust的DomainToAlia映射设置
        self.setupRustDomainToAlias()
        // 模版加载以及RN初始化都是延迟进行，所以无需两个请求同时请求，只需保留handleUserLogin中的请求。
//        DomainConfig.requestExDomainConfig()
    }

    func configLogger() {
        let isUsingProxy = NetUtil.shared.isUsingProxyFor(OpenAPI.docs.baseUrl)
        if isUsingProxy {
            DocsTracker.shared.forbiddenTrackerReason.insert(.useSystemProxy)
        } else {
            DocsTracker.shared.forbiddenTrackerReason.remove(.useSystemProxy)
        }
        DocsLogger.info("isUsing proxy: \(isUsingProxy)", component: LogComponents.net)
        if OpenAPI.docs.isSetAgentToFrontend {
            DocsTracker.shared.forbiddenTrackerReason.insert(.useProxyToAgent)
        } else {
            DocsTracker.shared.forbiddenTrackerReason.remove(.useProxyToAgent)
        }
    }

    func saveConfig(_ config: DocsConfig) {
        if let deviceId = config.geckoConfig?.deviceId, !deviceId.isEmpty {
            CCMKeyValue.globalUserDefault.set(deviceId, forKey: UserDefaultKeys.deviceID)
        }
    }

    func printConfig() {
        let model = UIDevice.current.lu.modelName()
        let versionCode = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String// app版本号，如 1.16.1
        let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String // app的名字 Docs/Lark
        // swiftlint:disable line_length
        DocsLogger.info("envInfo, env=\(OpenAPI.DocsDebugEnv.env), spaceKit version is \(SpaceKit.version); user os is \(UIDevice.current.systemVersion), model is \(model)", component: LogComponents.sdkConfig)
        DocsLogger.info("versionCode is \(versionCode ?? "null")", component: LogComponents.sdkConfig)
        DocsLogger.info("app is \(appName ?? "empty"), version is \(appVersion ?? "empty")", component: LogComponents.sdkConfig)
        DocsLogger.info(OpenAPI.getConfigStr(), component: LogComponents.sdkConfig)

        /// 记录历史版本
        var historyVersions = CCMKeyValue.globalUserDefault.stringArray(forKey: UserDefaultKeys.historyInstallVersion) ?? []
        DocsLogger.info("historyVersions=\(historyVersions)", component: LogComponents.sdkConfig)
        if let appVersion = appVersion, !historyVersions.contains(appVersion) {
            historyVersions.append(appVersion)
            if historyVersions.count > 20 {
                historyVersions.removeFirst()
            }
            CCMKeyValue.globalUserDefault.setStringArray(historyVersions, forKey: UserDefaultKeys.historyInstallVersion)
        }

    }


    func refreshDomain() {
        guard let delegate = delegate else {
            DocsLogger.error("can't get docsDomains from delegate", component: LogComponents.domain)
            return
        }
        DomainConfig.updateEnvInfo(delegate.envInfo)
        DomainConfig.ka.updateDomains(delegate.docsDomains)
        DomainConfig.updateUserDomain(delegate.userDomain)
        DocsLogger.info("set userDomain: \(delegate.userDomain), envInfo: \(delegate.envInfo)", component: LogComponents.domain)
    }


    func setupCookies() {
        userResolver.docs.netConfig?.removeAuthCookie()
        userResolver.docs.netConfig?.setCookie(authToken: userResolver.docs.user?.token, docsMainDomain: DomainConfig.ka.docsMainDomain)
        userResolver.docs.netConfig?.setLanguageCookie(for: URL(string: OpenAPI.docs.baseUrl))
        
        #if USING_WEBP_PROCESSOR
        guard let cookie = netSession.cookie else { return }
        ImageDownloader.default.sessionConfiguration.httpCookieStorage?.setCookie(cookie)
        #endif
    }

    func fetchConfigAfterUserLogin() {
        if CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.exDomainConfigKey) != nil { //当本地存在数据数据时直接进行RN加载不需要等待请求完成，请求完成再进行数据注入
            let leisureAsyncStage = ConcurrentStage(identifier: "leisureAsyncStage-loadRN", isLeisureStage: true)
            leisureAsyncStage.appendTask(name: "loadRN", taskClosure: {
                self.setupRN()
            })
            Launcher.shared.addAsync(leisureAsyncStage)
            Launcher.shared.kickOff()
        }

        disposeForMina = DisposeBag()
        let exDomainConfigFetch = DomainConfig.requestExDomainConfig()
        exDomainConfigFetch.subscribe(onNext: { [weak self] (suc) in
            guard let self = self else { return }
            if suc == false {
                // 即便失败了也需要走后续逻辑
                DocsLogger.error("error get MinaConfig and exDomainConfig")
            }
            self.handleRemoteConfigData()
            let leisureAsyncStage = ConcurrentStage(identifier: "leisureAsyncStage-preloadBlank", isLeisureStage: true)
            if !RNManager.manager.hadSetupEnviroment.value {
                leisureAsyncStage.appendTask(name: "loadRN", taskClosure: {
                    self.setupRN()
                })
            } else {
                RNManager.manager.injectDataIntoRN()
            }
            leisureAsyncStage.appendTask(name: "PreloadBlank", taskClosure: {
                EditorManager.shared.drainPoolAndPreload()
            })
            Launcher.shared.addAsync(leisureAsyncStage)
            Launcher.shared.kickOff()
            
        }).disposed(by: disposeForMina)
    }
}

// MARK: - RunLoop Observer

extension DocsSDKImpl {
    static var runLoopCount: UInt64 = 1000
    static var lastRunloopStartTime: TimeInterval?

    public static func enableRunLoopObserver() {
        guard #available(iOS 12.0, *) else {
            return
        }
        #if DEBUG
        let activityToObserve: CFRunLoopActivity = [.beforeTimers]
        let observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, activityToObserve.rawValue, true, 0) { (_, activity) in
            if activity == .beforeTimers {
                let current = CFAbsoluteTimeGetCurrent()
                if let lastTime = lastRunloopStartTime {
                    let elapsed = current - lastTime
                    if elapsed > 0.5 {
                        DocsLogger.info("last Runloop cost \(elapsed) second")
                    }
                }
                lastRunloopStartTime = current
                os_signpost(.end, log: DocsSDK.runLoopLog, name: "runLoop", signpostID: .init(runLoopCount))
                runLoopCount += 1
                os_signpost(.begin, log: DocsSDK.runLoopLog, name: "runLoop", signpostID: .init(runLoopCount))
            }
        }
        CFRunLoopAddObserver(RunLoop.main.getCFRunLoop(), observer, CFRunLoopMode.commonModes)
        #endif
    }
}

// MARK: - EditorManagerDelegate
extension DocsSDK: EditorManagerDelegate {
    public func editorManagerMakeVC(_ editorManager: EditorManager, url: URL) -> UIViewController? {
        var params: [String: Any] = [:]
        if let root = editorManager.currentEditor?.window?.rootViewController,
           let from = UIViewController.docs.topMost(of: root) {
            params[ContextKeys.from] = NavigatorFromWrapper(from)
        }
        let (vc, _) = SKRouter.shared.open(with: url, params: params)
        guard let viewController = vc else {
            return nil
        }
        return viewController
    }

    public func editorManager(_ editorManager: EditorManager, markFeedMessagesRead params: [String: Any], in browser: BrowserViewControllerAbility?) {
        let browser = browser as? BrowserViewController
        delegate?.sendReadMessageIDs(params, in: browser, callback: { _ in })
    }

    public func didEndEdit(_ docUrl: String, thumbnailUrl: String, chatId: String, changed: Bool, from: UIViewController, syncThumbBlock: ((PublishSubject<Any>) -> Void)?) {
        self.delegate?.didEndEdit(docUrl, thumbnailUrl: thumbnailUrl, chatId: chatId, changed: changed, from: from, syncThumbBlock: syncThumbBlock)
    }
    
    public func showPublishAlert(params: AnnouncementPublishAlertParams) {
        self.delegate?.showPublishAlert(params: params)
    }

    public func editorManager(_ editorManager: EditorManager, requiresToHandleOpen url: String, in browser: BrowserViewControllerAbility) {
        guard let browser = browser as? BaseViewController else {
            spaceAssertionFailure("fromVC cannot be nil")
            return
        }
        if let topMost = UIViewController.docs.topMost(of: browser), topMost.isBeingDismissed {
            //文档上的控制器dismiss过程中打开新页面会有动画冲突，新页面打开失败，延时再执行open，保证时序
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchQueueConst.MilliSeconds_300) { [weak self] in
                self?.delegate?.docRequiredToHandleOpen(url, in: browser)
            } 
            return
        }
        self.delegate?.docRequiredToHandleOpen(url, in: browser)
    }

    func editorManager(_ editorManager: EditorManager, didDismissWith browser: BrowserViewController?) {}
    public func editorManager(_ editorManager: EditorManager, syncFinished browser: BrowserViewControllerAbility?) {}

    public func editorManagerRequestShareAccessory(_ editorManager: EditorManager, browser: BrowserViewControllerAbility) -> UIView? {
        guard let browser = browser as? BrowserViewController else { return nil }
        return self.delegate?.requestShareAccessory(in: browser)
    }

    public func sendLarkOpenEvent(_ event: LarkOpenEvent) {
        delegate?.sendLarkOpenEvent(event)
    }

    public func editorManager(_ editorManager: EditorManager,
                              markFeedCardShortcut feedId: String,
                              isAdd: Bool,
                              success: SKMarkFeedSuccess?,
                              failure: SKMarkFeedFailure?) {
        delegate?.markFeedCardShortcut(for: feedId,
                                       isAdd: isAdd,
                                       success: success,
                                       failure: failure)
    }

    public func editorManager(_ editorManager: EditorManager, getShortcutFor feedId: String) -> Bool {
        guard let delegate = delegate else {
            DocsLogger.info("[Feed] delegate cannot be nil")
            return false
        }
        return delegate.isFeedCardShortcut(feedId: feedId)
    }
}

extension DocsSDKImpl {

    private func refreshWatermark() {
        let globalWatermarkIsOn = delegate?.globalWatermarkIsOn
        CCMKeyValue.globalUserDefault.set(delegate?.globalWatermarkIsOn, forKey: UserDefaultKeys.globalWatermarkEnabled)
        DocsLogger.info("set watermark: \(globalWatermarkIsOn?.description ?? "default")", component: LogComponents.watermark)
    }


    fileprivate func handleLarkDocsUserLogin() {
        guard DocsSDK.isInLarkDocsApp else { return }
        // all pre-shared records corresponding to the phone number will be converted into real authorization records,
        // So we need to tell the back end at user login
        Collaborator.shareConvert()
    }

    fileprivate func tryInjectionForDebug() {
        //Runtime Code Injection for Objective-C & Swift https://github.com/johnno1962/injectionforxcode
        if ProcessInfo.processInfo.environment["INJECTION"] == "1" {
            Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
        }
    }

    private func lockFGForUser() {
        DocsType.updateMindnoteEnabled()
    }
}


// MARK: - Notification
extension DocsSDKImpl {
    func didReceivedAuthenticationChallenge(_ completion: ((Error?) -> Void)?) {
        reloadEditorWhenAuthCompleted()
    }

    fileprivate func reloadEditorWhenAuthCompleted() {
        delegate?.requiredNewBearSession(completion: { (_, error) in
            guard error == nil else { return }
            DispatchQueue.main.async {
                EditorManager.shared.reload()
            }
        })
    }

    func didReceiveMediatorNotification(notification: Notification) {
        guard let event = notification.object as? LarkOpenEvent else { spaceAssertionFailure("must pass a LarkOpenEvent in this notification"); return }
        switch event {
        case .routeChat(chatID: let chatID):
            delegate?.sendLarkOpenEvent(.routeChat(chatID: chatID))
        case .customerService(let vc):
            delegate?.sendLarkOpenEvent(.customerService(controller: vc))
        case let .sendDebugFile(path: path, fileName: fileName, vc: vc):
            delegate?.sendLarkOpenEvent(.sendDebugFile(path: path, fileName: fileName, vc: vc))
        case .shareImage:
            delegate?.sendLarkOpenEvent(event)
        default:
            delegate?.sendLarkOpenEvent(event)
        }
    }
}
