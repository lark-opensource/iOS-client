//
//  DocsViewControllerFactory.swift
//  Lark
//
//  Created by liuwanlin on 2018/7/6.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//
// swiftlint:disable pattern_matching_keywords file_length line_length

import UIKit
import RxSwift
import RxCocoa
import SpaceKit
import LarkModel
import LarkUIKit
import LKCommonsLogging
import LKCommonsTracker
import SSZipArchive
import EENavigator
import LarkRustClient
import LarkAppResources
import UniverseDesignToast
import LarkCustomerService
import LarkContainer
import SpaceInterface
import LarkAccountInterface
import LarkAppConfig
import LarkReleaseConfig

#if MessengerMod
import LarkSDKInterface
#endif

import LarkPerf
import LarkNavigation
import AnimatedTabBar
import Swinject
import SKCommon
import SKFoundation
import SKInfra
import SKSpace
import SKDrive
import SKBrowser
import SKDoc
import SKWikiV2
import LarkCache
import LarkKeyCommandKit
import SKResource
import LarkSplitViewController
import LarkTab
import RustPB
import LarkStorage
import SKBitable

// MARK: -
public protocol DocsFactoryDependency {
    var isLogin: Bool? { get }
    var token: String { get }
    var userID: String { get }
    var tenantID: String { get }
    var deviceID: String { get }
    var rustService: RustService { get }
    var docsDependency: DocsDependency { get }

    var userDomain: String { get }
    var docsApiDomain: String { get }
    var docsHomeDomain: String { get }
    var docsMainDomain: String { get }
    var internalApiDomain: String { get }
    var docsHelpDomain: String { get }
    var docsLongConDomain: [String] { get }
    var suiteMainDomain: String { get }
    var tnsReportDomain: [String] { get }
    var tnsLarkReportDomain: [String] { get }
    var helpCenterDomain: String { get }
    var docsFeResourceUrl: String { get }
    var suiteReportDomain: String { get }
    var docsMgApi: [String: [String: String]] { get }
    var docsMgFrontier: [String: [String: [String]]] { get }
    var docsMgGeoRegex: String { get }
    var docsMgBrandRegex: String { get }
    var docsDriveDomain: String { get }
    var mpAppLinkDomain: String { get }

    #if MessengerMod
    var userAppConfig: UserAppConfig { get }
    var docAPI: DocAPI { get }
    #endif

    var globalWatermarkOn: Observable<Bool> { get }

    func openURL(_ url: URL?, from controller: UIViewController)
    func showUserProfile(_ userId: String, fileName: String?, from controller: UIViewController, params: [String: Any])
    func showEnterpriseTopic(query: String,
                             addrId: String,
                             triggerView: UIView,
                             triggerPoint: CGPoint,
                             clientArgs: String,
                             clickHandle: EnterpriseTopicClickHandle?,
                             tapApplinkHandle: EnterpriseTopicTapApplinkHandle?,
                             targetVC: UIViewController)
    func dismissEnterpriseTopic()
    func didEndEdit(_ docUrl: String,
                    thumbNailUrl: String,
                    chatId: String,
                    changed: Bool,
                    from: UIViewController,
                    syncThumbBlock: ((PublishSubject<Any>) -> Void)?)

    func showPublishAlert(params: AnnouncementPublishAlertParams)

    func shareImage(_ image: UIImage, from controller: UIViewController)

    func sendDebugFile(path: String, fileName: String, vc: UIViewController)
    func scanQR(_ code: String, from: UIViewController)

    func markFeedCardShortcutHandle(for feedId: String,
                                    isAdd: Bool,
                                    type: RustPB.Basic_V1_Channel.TypeEnum,
                                    success: ((_ tips: String) -> Void)?,
                                    failure: ((_ error: Error) -> Void)?)
    func isFeedCardShortcut(feedId: String) -> Bool
    func fetchLarkFeatureGating(with key: String, isStatic: Bool, defaultValue: Bool) -> Bool?
    /// 设置Lark 传入，最终注入给RN appInfo的appkey
    func setupAppKey(trigerBlock: @escaping (String) -> Void)
    /// 更新长链域名
    func updateLongDomain(trigerBlock: @escaping ([String]) -> Void)
    /// 判断视频会议是否正在进行，如果正在进行播放视频不修改AVAudioSession配置
    func checkVCIsRunning() -> Bool
    /// 注册精简模式下，定时清除本地数据的通知
    func registerLeanModeCleanPushNotification(trigerBlock: @escaping (Int64) -> Void)
    func checkIsSearchMainContainerViewController(responder: UIResponder) -> Bool
    
    func createGroupGuideBottomView(docToken: String, docType: String, templateId: String, chatId: String, fromVC: UIViewController?) -> UIView
}

// MARK: - DocsViewControllerFactory
public final class DocsViewControllerFactory {
    var dependency: DocsFactoryDependency!
    let logger = Logger.log(DocsViewControllerFactory.self, category: "Module.Docs")
    let resolver: Resolver
    var customerService: LarkCustomerServiceAPI?
    var isNeedReload: Bool = true
    var docs: DocsSDK!
    var appConfigDisposeBage = DisposeBag()
    var globalWatermarkIsShow: Bool = false
    private(set) var pushCenter: PushNotificationCenter?

    init(dependency: DocsFactoryDependency, resolver: Resolver) {
        self.dependency = dependency
        self.resolver = resolver
    }
    
    private var userResolver: UserResolver {
        let userResolver = resolver.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        return userResolver
    }
    
    public func initDocsSDK() {
        #if DEBUG
        DocsSDK.registerDocsLogger(.debug, handler: self, flag: false)
        #else
        DocsSDK.registerDocsLogger(.info, handler: self, flag: false)
        #endif
        let docsConfig = defaultDocsConfig()
        DocsTracker.shared.handler = { (event, params, category, shouldAddPrefix) in
            let docsEvent = (shouldAddPrefix ? "docs_" : "") + event
            if let params = params as? [String: Any] {
                Tracker.post(TeaEvent(docsEvent, category: category, params: params)) // 避免 SwiftLint 警告
            } else {
                Tracker.post(TeaEvent(docsEvent, category: category, params: [:])) // 避免 SwiftLint 警告
            }
        }
        
        let sdk = DocsSDKImpl(config: docsConfig, delegate: self, userResolver: userResolver)
        DocsTracker.shared.matchSuccHanlder = nil
        DocsTracker.shared.deviceid = self.dependency.deviceID
        self.docs = sdk
        dependency.setupAppKey { [weak self] (appKey) in
            self?.docs.updateAppKey(appKey)
        }
        dependency.updateLongDomain(trigerBlock: { [weak self] (longDomainArray) in
            self?.docs.updateLongDomain(longDomainArray)
        })
        dependency.registerLeanModeCleanPushNotification { [weak self] clearTimeLimited in
            self?.docs.clearDataIfNeedInLeanMode(clearTimeLimited)
        }
        DocsContainer.shared.register(AppealAlertDependency.self) { _ in
            return AppealAlertDependencyImpl()
        }

        #if MessengerMod
        DocsContainer.shared.register(SmartComposeSDK.self, factory: { _ in
            return SmartComposeSDK {
                let userID = User.current.basicInfo?.userID ?? ""
                return KVPublic.Setting.smartComposeDoc.value(forUser: userID)
            }
        }).inObjectScope(.container)
        #endif

        DocsContainer.shared.register(DocsRustNetStatusService.self,
                                      factory: { [weak self] _ in
                                        let netOb = self?.resolver.pushCenter
                                            .observable(for: PushDynamicNetStatus.self).map { $0.dynamicNetStatus }
                                        return DocsRustNetStatus(statusObservable: netOb ?? .just(.excellent))
        }).inObjectScope(.container)

        DocsContainer.shared.register(DriveSDKLocalFilePreviewAbility.self) { [weak self] _ in
            return DriveSKDLocalFilePreviewAbilityImpl(resolver: self?.resolver)
        }.inObjectScope(.container)
        
        DocsContainer.shared.register(DriveSDKIMLocalCacheServiceProtocol.self) { [weak self] _ in
            return DriveSDKIMLocalCacheServiceImpl(resolver: self?.resolver)
        }.inObjectScope(.container)


        DocsContainer.shared.register(MediaCompressDependency.self) { [weak self] _ in
            return MediaCompressDependencyImpl(resolver: self?.resolver)
        }.inObjectScope(.container)
        
        DocsContainer.shared.register(SKMediaMutexDependency.self) { _ in
            return LarkMediaMutexDepenencyImpl()
        }

        //注册清理任务
        let task = LarkCacheDocsImpl()
        CleanTaskRegistry.register(cleanTask: task)

        prepareCookieChecker()
        
        if UserScopeNoChangeFG.HZK.enableNetworkOptimize {
            URLProtocolHook.begin()
        }
        FeedDocPreLoadListener.docHasInit = true
        // App启动到触发SDK初始化耗时
        DocsTracker.log(enumEvent: .preLoadTemplate, parameters: ["cost_time_app_launch_to_doc_init": LarkProcessInfo.sinceStart()])
    }

    func prepareCookieChecker() {
        // hook cookie if need
        let config = SettingConfig.cookieCompensationConfig
        let canHook = config?.canHookSetCookie ?? false
        if canHook {
            DocCookieChecker.slardarEnable = config?.slardarEnable ?? false
            DocCookieChecker.hookCookie()
        }
        let netConfig = self.docs.userResolver.docs.netConfig
        netConfig?.needAuthDomains = config?.needAuthUrls ?? []
        DocsCustomHeader.cookieMissClosure = { url in
            DocsTracker.newLog(enumEvent: .docsCookieMiss, parameters: ["domain": url.host ?? "-"])
        }
    }

    func isSupportURLType(url: URL) -> (Bool, type: String, token: String) {
        return docs.isSupportURLType(url: url)
    }

    func create(dependency: DocsDependency, url: URL? = nil, infos: [String: Any]? = nil) -> UIViewController? {
        let browserVC = self.docs.open(url?.absoluteString, extraInfos: infos)
        return browserVC
    }

    func createNativeDocsTabController(dependency: DocsDependency) -> UIViewController {
        createSpaceTabViewController()
    }

    func createBitableHomeViewController(url: URL) -> UIViewController {
        let usePageV4 = Display.phone && UserScopeNoChangeFG.LYL.enableHomePageV4
        let version: BaseHomeContext.BaseHomeVersion = usePageV4 ? .hp_v2 : .original
        var baseHpFrom = url.docs.queryParams?["base_hp_from"]
        if usePageV4 {
            baseHpFrom = baseHpFrom ?? "workbench"
        }
        let context = BaseHomeContext(userResolver: userResolver, containerEnv: .workbench, baseHpFrom: baseHpFrom, version: version)
        let homeType = SpaceHomeType.baseHomeType(context: context)

        if usePageV4 {
            return BitableHomeTabCreateDependency.createHomePage(context: context)
        }

        guard let homeVC = docs.makeSpaceHomeViewController(userResolver: userResolver,
                                                            homeType: homeType) else {
            DocsLogger.error("can not get homeVC")
            return BaseViewController()
        }
        var containerVC = SpaceListContainerController(contentViewController: homeVC, title: SKResource.BundleI18n.SKResource.Bitable_Common_AppNameBitable)
        containerVC.needLogNavBarEvent = false
        return containerVC
    }

    private func createSpaceTabViewController() -> UIViewController {
        // 快速切tab时，偶先 UserID 注入不及时，这里取最新的 UserID
        let userID = userResolver.userID
        let homeVC: SpaceHomeViewController?
        
        if UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
            homeVC = docs.makeSpaceNextHomeViewController(userResolver: userResolver)
        } else {
            homeVC = docs.makeSpaceHomeViewController(userResolver: userResolver)
        }
        
        guard let homeViewController = homeVC else {
            DocsLogger.error("can not get HomeVC")
            return BaseViewController()
        }
        
        let tabViewController = SpaceTabViewController(userReslover: userResolver, spaceHomeViewController: homeViewController)
        tabViewController.isLkShowTabBar = true
        if Display.pad {

            let navi = LkNavigationController(rootViewController: tabViewController)
            let splitVC = SplitViewController(supportSingleColumnSetting: false)
            splitVC.setViewController(navi, for: .primary)
            splitVC.setViewController(navi, for: .compact)
            splitVC.isShowSidePanGestureView = false
            splitVC.isShowPanGestureView = false
            splitVC.defaultVCProvider = { () -> DefaultVCResult in
                return DefaultVCResult(defaultVC: UIViewController.DefaultDetailController(), wrap: LkNavigationController.self)
            }

            splitVC.isLkShowTabBar = true
            docs.docsRootVC = splitVC
            return splitVC
        } else {
            docs.docsRootVC = tabViewController
            return tabViewController
        }
    }

    fileprivate func defaultDocsConfig() -> DocsConfig {
        let channels = [(GeckoChannleType.webInfo, "docs_channel", "SKResource.framework/SKResource.bundle/eesz-zip",
                         GeckoPackageManager.shared.bundleSlimPkgName)]
        let geckoConfig = GeckoInitConfig(channels: channels, deviceId: dependency.deviceID)
        var docsConfig = DocsConfig(geckoConfig: geckoConfig)
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            docsConfig.infos["Lark"] = appVersion
        }
        docsConfig.domains = self.getDocsDomains()
        docsConfig.envInfo = self.envInfo
        return docsConfig
    }

    private func getDocsDomains() -> DocsConfig.Domains {
        var domains = DocsConfig.Domains.getADomains()
        domains.userDomain = self.userDomain
        domains.docsHomeDomain = self.docsHomeDomain
        domains.docsMainDomain = self.docsMainDomain
        domains.docsApiDomain = self.docsApiDomain
        domains.docsLongConDomain = self.docsLongConDomain
        domains.docsHelpDomain = self.docsHelpDomain
        domains.internalApiDomain = self.internalApiDomain
        domains.suiteMainDomain = self.suiteMainDomain
        domains.docsFeResourceUrl = self.docsFeResourceUrl
        domains.docsMgApi = self.docsMgApi
        domains.docsMgFrontier = self.docsMgFrontier
        domains.docsMgGeoRegex = self.docsMgGeoRegex
        domains.docsMgBrandRegex = self.docsMgBrandRegex
        domains.docsDriveDomain = self.docsDriveDomain
        domains.tnsReportDomain = self.tnsReportDomain
        domains.tnsLarkReportDomain = self.tnsLarkReportDomain
        domains.helpCenterDomain = self.helpCenterDomain
        domains.suiteReportDomain = self.suiteReportDomain
        domains.mpAppLinkDomain = self.mpAppLinkDomain
        return domains
    }
}

extension DocsViewControllerFactory {
    func setPushCenter(_ pushCenter: PushNotificationCenter) {
        self.pushCenter = pushCenter
        #if MessengerMod
        _ = pushCenter
            .observable(for: SpaceNoticeMessage.self)
            .subscribe(onNext: { (pushMessage) in
                SpaceNoticeHandler.shared.handle(body: pushMessage.body)
            })
        #endif
    }
}

// MARK: - DocsManagerDelegate
extension DocsViewControllerFactory: DocsManagerDelegate {
    public func launchCustomerService() {
        customerService = resolver.resolve(LarkCustomerServiceAPI.self)
        customerService?.launchCustomerService()
    }

    public func markFeedCardShortcut(for feedId: String, isAdd: Bool, success: SKMarkFeedSuccess?, failure: SKMarkFeedFailure?) {
        /// Channel.TypeEnum的type设定为.doc
        markFeedCardShortcutForDocs(for: feedId, isAdd: isAdd, type: .doc, success: success, failure: failure)
    }

    private func markFeedCardShortcutForDocs(for feedId: String,
                                             isAdd: Bool,
                                             type: RustPB.Basic_V1_Channel.TypeEnum,
                                             success: SKMarkFeedSuccess?,
                                             failure: SKMarkFeedFailure?) {
        dependency.markFeedCardShortcutHandle(for: feedId,
                                              isAdd: isAdd,
                                              type: type,
                                              success: success,
                                              failure: failure)
    }

    public func isFeedCardShortcut(feedId: String) -> Bool {
        let isFeed = dependency.isFeedCardShortcut(feedId: feedId)
        return isFeed
    }

    public var basicUserInfo: BasicUserInfo? {
        guard dependency.isLogin == true else { return nil }
        return BasicUserInfo(dependency.userID,
                             dependency.tenantID,
                             dependency.token,
                             AccountServiceAdapter.shared.currentAccountInfo.isGuestUser)
    }

    public var userDomain: String {
        return dependency.userDomain
    }
    public var docsDomains: DocsConfig.Domains {
        return self.getDocsDomains()
    }
    public var docsHomeDomain: String {
        return dependency.docsHomeDomain
    }

    public var docsApiDomain: String {
        return dependency.docsApiDomain
    }

    public var docsLongConDomain: [String] {
        return dependency.docsLongConDomain
    }
    public var docsMainDomain: String {
        return dependency.docsMainDomain
    }
    public var internalApiDomain: String {
        return dependency.internalApiDomain
    }
    public var docsHelpDomain: String {
        return dependency.docsHelpDomain
    }
    public var suiteMainDomain: String {
        return dependency.suiteMainDomain
    }
    public var docsDriveDomain: String {
        return dependency.docsDriveDomain
    }
    public var docsFeResourceUrl: String {
        return dependency.docsFeResourceUrl
    }
    public var docsMgApi: [String: [String: String]] {
        return dependency.docsMgApi
    }
    var docsMgFrontier: [String: [String: [String]]] {
        return dependency.docsMgFrontier
    }
    var docsMgGeoRegex: String {
        return dependency.docsMgGeoRegex
    }
    var docsMgBrandRegex: String {
        return dependency.docsMgBrandRegex
    }
    public var globalWatermarkIsOn: Bool {
        return self.globalWatermarkIsShow
    }
    public var tnsReportDomain: [String] {
        return dependency.tnsReportDomain
    }
    public var tnsLarkReportDomain: [String] {
        return dependency.tnsLarkReportDomain
    }
    
    public var helpCenterDomain: String {
        return dependency.helpCenterDomain
    }
    
    public var suiteReportDomain: String {
        return dependency.suiteReportDomain
    }
    
    public var mpAppLinkDomain: String {
        return dependency.mpAppLinkDomain
    }

    public var envInfo: DomainConfig.EnvInfo {
        let account = AccountServiceAdapter.shared
        let envMeta = DomainConfig.EnvInfo(package: ReleaseConfig.releaseChannel, isFeishuPackage: ReleaseConfig.isFeishu, brand: account.foregroundTenantBrand, isFeishuBrand: account.isFeishuBrand, geo: account.foregroundUserGeo, isChinaMainland: account.isChinaMainlandGeo)
        return envMeta
    }

    public var rustService: RustService {
        return dependency.rustService
    }

    public func handleAuthenticationChallenge() {
    }

    public var animationLoading: DocsLoadingViewProtocol? {
        let loading = DocsLoadingView()
        loading.displayContent.isHidden = true
        return loading
    }

    public func requiredNewBearSession(completion: @escaping (String?, Error?) -> Void) {
    }

    public func docRequiredToHandleOpen(_ url: String, in browser: BaseViewController) {
        dependency.openURL(URL(string: url), from: browser)
    }

    public func requestShareAccessory(in browser: BaseViewController) -> UIView? {
        return (browser as? BrowserViewController)?.shareAccessoryView(dependency: dependency.docsDependency)
    }

    public func requestShareAccessory(with feedId: String) -> UIView? {
        return  DocsAccessoryView(dependency.docsDependency, with: feedId)
    }

    public func docRequiredToShowUserProfile(_ userId: String, fileName: String?, from controller: UIViewController, params: [String: Any]) {
        dependency.showUserProfile(userId, fileName: fileName, from: controller, params: params)
    }

    public func docRequiredToShowEnterpriseTopic(query: String,
                                                 addrId: String,
                                                 triggerView: UIView,
                                                 triggerPoint: CGPoint,
                                                 clientArgs: String,
                                                 clickHandle: EnterpriseTopicClickHandle?,
                                                 tapApplinkHandle: EnterpriseTopicTapApplinkHandle?,
                                                 targetVC: UIViewController) {
        dependency.showEnterpriseTopic(query: query,
                                       addrId: addrId,
                                       triggerView: triggerView,
                                       triggerPoint: triggerPoint,
                                       clientArgs: clientArgs,
                                       clickHandle: clickHandle,
                                       tapApplinkHandle: tapApplinkHandle,
                                       targetVC: targetVC)
    }

    public func docPequiredToDismissEnterpriseTopic() {
        dependency.dismissEnterpriseTopic()
    }

    public func didEndEdit(_ docUrl: String,
                           thumbnailUrl: String,
                           chatId: String,
                           changed: Bool,
                           from: UIViewController,
                           syncThumbBlock: ((PublishSubject<Any>) -> Void)?) {
        dependency.didEndEdit(docUrl, thumbNailUrl: thumbnailUrl, chatId: chatId, changed: changed, from: from, syncThumbBlock: syncThumbBlock)
    }

    public func showPublishAlert(params: AnnouncementPublishAlertParams) {
        dependency.showPublishAlert(params: params)
    }

    public func sendLarkOpenEvent(_ event: LarkOpenEvent) {

        switch event {
        case .record:
            break
        case .shareImage(let image, let fromVC):
            dependency.shareImage(image, from: fromVC)
        case .openURL(let url, let vc):
            dependency.openURL(url, from: vc)
        case .scanQR(let code, let vc):
            dependency.scanQR(code, from: vc)
        case .customerService(let fromVC):
            let isPad = Display.pad
            let routerParams = RouterParams(
                sourceModuleType: SourceModuleType.docs,
                needDissmiss: false,
                showBehavior: isPad ? .present : .push,
                wrap: isPad ? LkNavigationController.self : nil,
                from: fromVC,
                prepare: { $0.modalPresentationStyle = isPad ? .formSheet : .overFullScreen })
            customerService?.showCustomerServicePage(routerParams: routerParams, onSuccess: nil) {
                guard let window = fromVC?.view.window else {
                    return
                }
                UDToast.showFailure(with: BundleI18n.CCMMod.Lark_Legacy_NetworkErrorRetry, on: window)
            }
        case .sendDebugFile(path: let path, fileName: let fileName, let vc):
            dependency.sendDebugFile(path: path, fileName: fileName, vc: vc)
        default:
            break
        }
    }

    public func sendReadMessageIDs(_ params: [String: Any], in browser: BaseViewController?, callback: @escaping ((Error?) -> Void)) {
    #if MessengerMod
        if let isFromFeed = params["isFromFeed"] as? Bool, isFromFeed == true {
            var localBag = DisposeBag()
            guard let messageIds = params[DocsSDK.Keys.readFeedMessageIDs] as? [String],
                  let objToken = params["obj_token"] as? String,
                  let type = params["doc_type"] as? DocsType else { return }
            self.dependency.docAPI
                .updateDocMeRead(messageIds: messageIds,
                                 token: objToken,
                                 docType: transform(docType: type))
                .subscribe(onNext: { [weak self] () in
                    localBag = DisposeBag()
                    self?.logger.info("send readMessageIDs success ids:\(messageIds)")
                    callback(nil)
                }, onError: { [weak self] (error) in
                    self?.logger.error("send readMessageIDs failed ids:\(messageIds)")
                    callback(error)
                }).disposed(by: localBag)
        }

        guard let doccBrowser = browser as? BrowserViewController else {
            logger.error("browser is not BrowserViewController!")
            return
        }
        if let docsInfo = doccBrowser.docsInfo,
            let readFeedMessageIDs = params[DocsSDK.Keys.readFeedMessageIDs] as? [String] {
            var localBag = DisposeBag()
            self.dependency.docAPI
                .updateDocMeRead(messageIds: readFeedMessageIDs,
                                 token: docsInfo.objToken,
                                 docType: transform(docType: docsInfo.type))
                .subscribe(onNext: { () in
                    localBag = DisposeBag()
                }, onError: { (_) in
                }).disposed(by: localBag)
        }
    #endif
    }

    public func fetchLarkFeatureGating(with key: String, isStatic: Bool, defaultValue: Bool) -> Bool? {
        return dependency.fetchLarkFeatureGating(with: key, isStatic: isStatic, defaultValue: defaultValue)
    }

    public func getABTestValue(with key: String, shouldExposure: Bool) -> Any? {
        Tracker.experimentValue(key: key, shouldExposure: shouldExposure)
    }

    private func transform(docType: DocsType) -> RustPB.Basic_V1_Doc.TypeEnum {
        switch docType {
        case .doc:
            return .doc
        case .docX:
            return .docx
        case .sheet:
            return .sheet
        case .bitable:
            return .bitable
        case .mindnote:
            return .mindnote
        case .file:
            return .file
        case .slides:
            return .slides
        case .wiki:
            return .wiki
        case .folder:
            return .folder
        case .wikiCatalog:
            return .catalog
        case .trash, .myFolder, .mediaFile, .imMsgFile, .unknown, .minutes, .whiteboard, .sync, .baseAdd:
            return .unknown
        }
    }

    public func checkVCIsRunning() -> Bool {
        return dependency.checkVCIsRunning()
    }

    public func createGroupGuideBottomView(docToken: String, docType: String, templateId: String, chatId: String, fromVC: UIViewController?) -> UIView {
        return dependency.createGroupGuideBottomView(docToken: docToken, docType: docType, templateId: templateId, chatId: chatId, fromVC: fromVC)
    }

    public func openLKWebController(url: URL, from: UIViewController?) {
        // Lark内不需要特殊处理，可以直接push
        guard let from = from else {
            assertionFailure("cannot get from vc")
            logger.error("openLKWebController cannot get from vc")
            return
        }
        Navigator.shared.push(url, from: from)
    }

    public func generatePasswordFreeLink(urlString: String, completion: @escaping (String) -> Void) {
        guard let service = resolver.resolve(AccountService.self) else {
            DocsLogger.error("iPad share AccountService is empty")
            completion(urlString)
            return
        }
        guard let url = URL(string: urlString) else {
            completion(urlString)
            return
        }
        service.generateDisposableLoginToken(identifier: urlString, completion: { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let info):
                    var res: [String: Any] = [:]
                    res[info.userId.key] = info.userId.value
                    res[info.deviceLoginId.key] = info.deviceLoginId.value
                    res[info.timestamp.key] = info.timestamp.value
                    res[info.unitItem.key] = info.unitItem.value
                    res[info.authAutoLogin.key] = info.authAutoLogin.value
                    res[info.versionItem.key] = info.versionItem.value
                    res[info.tenantBrandItem.key] = info.tenantBrandItem.value
                    res[info.pkgBrandItem.key] = info.pkgBrandItem.value

                    do {
                        let resData = try JSONSerialization.data(withJSONObject: res, options: [])
                        let base64Prefix = resData.base64EncodedString()
                        let disposableLoginToken = "\(base64Prefix).\(info.token.value)"
                        let dst = url.docs.addEncodeQuery(parameters: ["disposable_login_token": disposableLoginToken])
                        completion(dst.absoluteString)
                    } catch {
                        DocsLogger.error("iPad share json serialization error: \(error)")
                        completion(urlString)
                    }
                case .failure(let error):
                    DocsLogger.error("iPad share error: \(error)")
                    completion(urlString)
                }
            }
        })
    }

    // 给飞书文档提供的接口， 移除之前Spacekit内部的默认实现，避免协议改动没有报错的问题
    // Lark不需要实现，避免编译错误添加默认实现
    public var serviceTermURL: String {
        spaceAssertionFailure("should not call in lark")
        return ""
    }
    public var privacyURL: String {
        spaceAssertionFailure("should not call in lark")
        return ""
    }

    public func getOPContextInfo(with params: [AnyHashable: Any]) -> DocsOPAPIContextProtocol? {
        if let info = try? DocOPIContextInfo(params) {
            return info
        }
        return nil
    }

    public func checkIsSearchMainContainerViewController(responder: UIResponder) -> Bool {
        return dependency.checkIsSearchMainContainerViewController(responder: responder)
    }
}

// MARK: -
extension DocsViewControllerFactory: DocsLoggerHandler {
    public func handleDocsLogEvent(_ event: DocsLogEvent) {
        let logLevel = event.level
        let message = (event.component ?? "") + event.message
        let extraInfo = event.extraInfo?.mapValues({ (value) -> String in
            "\(value)"
        })
        let error = event.error
        let fileName = event.fileName
        let funcLine = event.funcLine
        let funcName = event.funcName

        let larkLogLevel: LogLevel
        switch logLevel {
        case .debug, .verbose:
            larkLogLevel = .debug
        case .info:
            larkLogLevel = .info
        case .warning:
            larkLogLevel = .warn
        case .error, .severe:
            larkLogLevel = .error
        }
        let timeStamp = event.useCustomTimeStamp ? (event.time ?? 0) : Date().timeIntervalSince1970
        logger.log(
            logId: "",
            message,
            params: extraInfo,
            level: larkLogLevel,
            time: timeStamp,
            error: error,
            file: fileName,
            function: funcName,
            line: funcLine)
    }
}

// MARK: LauncherDelegate
extension DocsViewControllerFactory {
    public func larkUserDidLogin(_ account: Account?, _ error: Error?) {
        logger.info("larkUserDidLogin")
        isNeedReload = true
    }

    public func larkUserDidLogout(_ account: Account?, _ error: Error?) {
        logger.info("larkUserDidLogout error is nil ? \(error == nil)")
        if error == nil {
            docs.handleUserLogout()
        }
    }

    public func accountLoaded(userResolver: UserResolver) {
        docs.updateUserResolver(userResolver)
        logger.info("accountLoaded")
        //这个比较基础，最先做这个
        docs.refreshConfig(["device_id": dependency.deviceID])
        //详细加载流程看Launcher的State
        DocsTracker.startRecordTimeConsuming(eventType: .docsSDKInit, parameters: nil)
        docs.handleUserLogin(userResolver: userResolver, docsConfig: defaultDocsConfig())
        DocsTracker.endRecordTimeConsuming(eventType: .docsSDKInit, parameters: nil)

        appConfigDisposeBage = DisposeBag()
        #if MessengerMod
        dependency.userAppConfig.appConfigSignal.subscribe(onNext: { [weak self] (appConfig) in
            guard let `self` = self else { return }
            self.docs.refreshUserHistoryDomain(appConfig.urlConfig.docDomains.map { $0.domain })
        }).disposed(by: appConfigDisposeBage)
        #endif

        dependency.globalWatermarkOn
            .subscribe(onNext: { [weak self] (isOn) in
                self?.globalWatermarkIsShow = isOn
                self?.docs.refreshConfig(["globalWatermarkIsOn": isOn])
            }).disposed(by: appConfigDisposeBage)

        if let docsTab = TabRegistry.resolve(Tab.doc) as? DocsTab,
           let tabBadgeRelay = docsTab.badge {
            let badgeConfig = docs.spaceBadgeConfig
            badgeConfig.badgeVisableUpdated
                .map { visable -> BadgeType in
                    if visable {
                        return .dot(1)
                    } else {
                        return .none
                    }
                }
                .bind(to: tabBadgeRelay)
                .disposed(by: appConfigDisposeBage)
        }
    }

    public func homeDidFinishLaunch(_ account: Account?, _ error: Error?) {
        logger.info("homeDidFinishLaunch isNeedReload\(isNeedReload)")
    }

    public func didFinishSwitchAccount(_ error: Error?) {
        logger.info("didFinishSwitchAccount isNeedReload\(isNeedReload)")
        if error == nil {
            docs.handleUserLogout()
        }
    }

    public func loadFirstPageIfNeeded() {
        docs.loadFirstPageIfNeeded()
    }

    public func handleBeforeUserLogout() {
        docs.handleBeforeUserLogout()
    }

    public func handleBeforeUserSwitchAccout() {
        docs.handleBeforeUserSwitchAccout()
    }
}

extension DocsViewControllerFactory {
    func createNativeWikiTabControllerV2(params: [AnyHashable: Any]?,
                                         navigationBarDependency: WikiHomePageViewController.NavigationBarDependency) -> UIViewController {
        let vc = WikiTabViewControllerV2(userResolver: userResolver,
                                         params: params,
                                         navigationBarDependency: navigationBarDependency)
        WikiPerformanceTracker.shared.reportStartLoading()
        WikiPerformanceTracker.shared.begin(stage: .createVC)
        defer {
            WikiPerformanceTracker.shared.end(stage: .createVC, succeed: true, dataSize: 0)
        }
        if Display.pad {

            let navi = LkNavigationController(rootViewController: vc)
            let splitVC = SplitViewController(supportSingleColumnSetting: false)
            splitVC.setViewController(navi, for: .primary)
            splitVC.setViewController(navi, for: .compact)
            splitVC.isShowSidePanGestureView = false
            splitVC.isShowPanGestureView = false
            splitVC.defaultVCProvider = { () -> DefaultVCResult in
                return DefaultVCResult(defaultVC: UIViewController.DefaultDetailController(), wrap: LkNavigationController.self)
            }

            splitVC.isLkShowTabBar = true
            docs.docsRootVC = splitVC
            return splitVC
        } else {
            return vc
        }
    }
    
    func createNativeBaseTabControllerV2(params: [AnyHashable: Any]?) -> UIViewController {
        let usePageV4 = Display.phone && UserScopeNoChangeFG.LYL.enableHomePageV4
        let version: BaseHomeContext.BaseHomeVersion = usePageV4 ? .hp_v2 : .original
        let context = BaseHomeContext(userResolver: userResolver, containerEnv: .larkTab, baseHpFrom: "lark_tab", shouldShowRecommend: BaseTabViewController.shouldShowRecommend(), version: version)
        let homeType = SpaceHomeType.baseHomeType(context: context)

        if usePageV4 {
            return BitableHomeTabCreateDependency.createHomePage(context: context)
        }

        guard let homeVC = docs.makeSpaceHomeViewController(userResolver: userResolver,
                                                            homeType: homeType) else {
            DocsLogger.error("can not get HomeVC")
            return BaseViewController()
        }
        let vc = BaseTabViewController(context: context, spaceHomeViewController: homeVC)
        if Display.pad {
            let navi = LkNavigationController(rootViewController: vc)
            let splitVC = SplitViewController(supportSingleColumnSetting: false)
            splitVC.setViewController(navi, for: .primary)
            splitVC.setViewController(navi, for: .compact)
            splitVC.isShowSidePanGestureView = false
            splitVC.isShowPanGestureView = false
            splitVC.defaultVCProvider = { () -> DefaultVCResult in
                return DefaultVCResult(defaultVC: UIViewController.DefaultDetailController(), wrap: LkNavigationController.self)
            }

            splitVC.isLkShowTabBar = true
            docs.docsRootVC = splitVC
            return splitVC
        } else {
            return vc
        }
    }
}

// MARK: - DriveSDK
extension DocsViewControllerFactory {
    var driveSDK: DriveSDK {
        docs.driveSDK
    }
}
