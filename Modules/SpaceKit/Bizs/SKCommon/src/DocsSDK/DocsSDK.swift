//
//  Docs.swift
//  Docs
//
//  Created by weidong fu on 31/1/2018.
//

import Foundation
import LarkUIKit
import os
import EENavigator
import SpaceInterface
import SKUIKit
import RustPB
import RxSwift
import RxRelay
import LarkRustClient
import SKFoundation
import LarkDynamicResource
import SKInfra
import LarkContainer

public typealias SetDomainAliasRequest = Tool_V1_SetDomainAliasRequest
public typealias SetDomainAliasResponse = Tool_V1_SetDomainAliasResponse
public typealias DomainSettings = Basic_V1_DomainSettings

open class DocsSDK: NSObject {
    public static let mediatorNotification = "mediatorNotification"

    public struct Keys {
        public static let readFeedMessageIDs = "readFeedMessageIDs"
    }
    public let resolver: DocsResolver
    public private(set) var userResolver: UserResolver
    public var disposeForMina = DisposeBag()
    public var offlineSyncManager: DocsOfflineSyncManager {
        return resolver.resolve(DocsOfflineSyncManager.self)!
    }
    
    public var launcherV2MonitorInterval: Double {
        guard let config = SettingConfig.launcherV2Config else {
            DocsLogger.error("failed to get launcherV2Config")
            return 1.0
        }
        let monitorInterval = config.monitorInterval
        return monitorInterval != 0.0 ? monitorInterval : 1.0
    }
    public var launcherV2LeisureCondition: Double {
        guard let config = SettingConfig.launcherV2Config else {
            DocsLogger.error("failed to get launcherV2Config")
            return 0.1
        }
        let leisureCondition = config.leisureCondition
        return leisureCondition != 0.0 ? leisureCondition / 100 : 0.1
    }
    public var launcherV2LeisureTimes: Int {
        guard let config = SettingConfig.launcherV2Config else {
            DocsLogger.error("failed to get launcherV2Config")
            return 3
        }
        let leisureTimes = config.leisureTimes
        return leisureTimes != 0 ? leisureTimes : 3
    }
    public weak var docsRootVC: UIViewController?
    public let appLifeCycle: AppLifeCycle = AppLifeCycle()
    public weak var delegate: DocsManagerDelegate?

    public var driveSDK: DriveSDK {
        return resolver.resolve(DriveSDK.self)!
    }

    public var spaceBadgeConfig: SpaceBadgeConfig {
        return resolver.resolve(SpaceBadgeConfig.self)!
    }

    public init(resolver: DocsResolver = DocsContainer.shared, userResolver: UserResolver) {
        self.resolver = resolver
        self.userResolver = userResolver
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(setupRNEvent), name: Notification.Name.SetupDocsRNEnvironment, object: nil)
    }

    /// DocsSDK还未完全完成用户态改造, 所以在登录态变化时用这个方法更新userResolver
    public func updateUserResolver(_ userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    /// 用于刷新配置
    ///
    /// - Parameter newConfig: 新的配置信息
    public func refreshConfig(_ newConfig: [String: Any]) {
        SDKConfigUpdater(updatedConfig: newConfig).updateWith(self)
    }

    public class func registerDocsLogger(_ level: DocsLogLevel, handler: DocsLoggerHandler?, flag: Bool) {
        if let forceLevel = OpenAPI.forceLogLevel, let logLevel = DocsLogLevel(rawValue: forceLevel) {
            DocsLogger.setLogger(logLevel, handler: handler, flag: flag)
        } else {
            DocsLogger.setLogger(level, handler: handler, flag: flag)
        }
    }

    /// 更新当前用户的历史域名列表
    ///
    /// - Parameter domainList: 历史域名列表，字符串数组
    public func refreshUserHistoryDomain(_ domainList: [String]) {
    }

    open func loadFirstPageIfNeeded() {}
    open func preloadFile(_ url: String, from source: String) {}
    open func handleUserLogin(userResolver: UserResolver, docsConfig: DocsConfig) {}
    open func handleUserLogout() {}
    open func handleBeforeUserSwitchAccout() {}
    open func handleBeforeUserLogout() {}
}

// MARK: - Open URL

extension DocsSDK {

    public func canOpen(_ url: String) -> Bool {
        let canOpen = URLValidator.canOpen(url)
        if canOpen == false, let aUrl = URL(string: url), URLValidator.isDocsTypeUrlInKA(url: aUrl) {
            return true
        }
        guard canOpen else { return false }
        self.setupRN(needBlockUI: true)
        return true
    }

    public func isSupportURLType(url: URL) -> (Bool, type: String, token: String) {
        return URLValidator.isSupportURLType(url: url)
    }

    public func open(_ urlStr: String?, extraInfos: [String: Any]? = nil) -> UIViewController? {
        guard urlStr != nil, let url = URL(string: urlStr!) else {
            spaceAssertionFailure("url \(urlStr ?? "") 不正确")
            return UIViewController()
        }
        guard canOpen(urlStr!) else {
            spaceAssertionFailure("打不开url: \(urlStr!)")
            return UIViewController()
        }

        // 如果是从lark搜索打开时，则将其记录下来
        if url.queryParameters["from"] == "lark_search" {
            DocsTracker.log(enumEvent: .clickSearch, parameters: ["action": "click_search_item",
                                                                  "source": "lark",
                                                                  "os_source": "search_lark_index",
                                                                  "group": "all"])
        }
        var extra: [String: Any] = extraInfos ?? [:]

        if let feedID = extraInfos?["feed_id"] {
            extra["Type"] = "Feed"
            extra["feedID"] = feedID
        }

        extra["from_sdk"] = true
        extra["docs_entrance"] = url.queryParameters["from"]
        extra["is_from_pushnotification"] = url.queryParameters["sourceType"] == "push"
        extra["timestamp"] = Date().timeIntervalSince1970 * 1000
        let (vc, _) = SKRouter.shared.open(with: url, params: extra)
        (vc as? LikeListViewController)?.listDelegate = self

        // 防止连续push导致埋点不对
        if !(vc is ContinuePushedVC) {
            DocsFeedTracker.startTrack(url, params: extra)
        } else {
            DocsLogger.info("卡顿了，这个时候不应该打点")
        }

        return vc
    }
}


// MARK: - Config

extension DocsSDK {
    public static var isBeingTest: Bool = {
#if DEBUG // 线上有卡死，只在debug环境读取
        return ProcessInfo.processInfo.environment["IS_TESTING_DOCS_SDK"] == "1"
#else
        return false
#endif
    }()

    public static var isInDocsApp: Bool = {
        if let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String {
            return appName.hasPrefix("Docs") || appName.hasPrefix("Space")
        }
        return false
    }()

    public static var isInLarkDocsApp: Bool = {
        let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
        return appName?.hasPrefix("LarkDocs") ?? false
    }()

    public static var isEnableRustHttp: Bool {
        return OpenAPI.enableRustHttp
    }

    public static var isNeedDelayRN: Bool {
        let timeForDelayLoadRN = OpenAPI.delayLoadRNInSeconds
        if timeForDelayLoadRN > 0 {
            return true
        }
        return false
    }

    /// VC 单品会通过 SKNavigationBarControlService 设置这个全局变量，进而控制我们每个 browser 的导航栏按钮
    /// 控制 BrowserViewController 的导航栏按钮显示
    public static var navigationMode: SKNavigationBar.NavigationMode = .open

    public static let openFileLog = OSLog(subsystem: "com.doc.bytedance", category: "openFile")
    public static let runLoopLog = OSLog(subsystem: "com.doc.bytedance", category: "runloop")
}

extension DocsSDK: LikeListDelegate {
    public func requestDisplayUserProfile(userId: String, fileName: String?, listController: LikeListViewController) {
        self.delegate?.docRequiredToShowUserProfile(userId, fileName: fileName, from: listController, params: [:])
    }

    public func requestCreateBrowserView(url: String, config: FileConfig) -> UIViewController? {
        return open(url, extraInfos: config.extraInfos)
    }
}


extension DocsSDK {
    static var appConfigForFrontEndStr: String {
        var appConfigStr: String?
        var appConfigDic = SettingConfig.appConfigForFrontEnd ?? [:]
        if CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.debugUploadImgByDocRequest) {
            appConfigDic["driveImageUploadEnabled"] = false
        }
        if let dataToSave = try? JSONSerialization.data(withJSONObject: appConfigDic, options: []) {
            appConfigStr = String(data: dataToSave, encoding: .utf8)
        }
        return appConfigStr ?? "{}"
    }
}
// MARK: - 品牌点位动态化相关逻辑
extension DocsSDK {
    static func getDynamicFeatureConfig(for reletivePath: String) -> String? {
        return DynamicResourceManager.shared.getFeatureConfig(reletivePath: reletivePath)
    }

}


// MARK: - HostAppBridge

extension DocsSDK {
    public func registerHostBridge() {
        HostAppBridge.shared.register(service: ShowUserProfileService.self) { [weak self] (service) -> Any? in
            self?.delegate?.docRequiredToShowUserProfile(service.userId, fileName: service.fileName, from: service.fromVC, params: service.params)
            return nil
        }

        HostAppBridge.shared.register(service: GetDocsManagerDelegateService.self) { [weak self] (_) -> Any? in
            return self?.delegate
        }

        HostAppBridge.shared.register(service: GetLarkFeatureGatingService.self) { [weak self] service -> Bool? in
            return self?.delegate?.fetchLarkFeatureGating(with: service.key, isStatic: service.isStatic, defaultValue: service.defaultValue)
        }

        HostAppBridge.shared.register(service: GetABTestService.self) { [weak self] service -> Any? in
            self?.delegate?.getABTestValue(with: service.key, shouldExposure: service.shouldExposure)
        }

        HostAppBridge.shared.register(service: FeedShortcutService.self) { [weak self] (service) -> Any? in
            if service.method == FeedShortcutService.Method.get {
                return self?.delegate?.isFeedCardShortcut(feedId: service.feed)
            } else if service.method == .set {
                guard let isAdd = service.isAdd else {
                    skAssertionFailure("isAdd cannot be nil when using Method.set")
                    return nil
                }
                self?.delegate?.markFeedCardShortcut(for: service.feed, isAdd: isAdd, success: service.success, failure: service.failure)
            }
            return nil
        }
        HostAppBridge.shared.register(service: RequestShareAccessory.self) { [weak self] (service) -> Any? in
            return self?.delegate?.requestShareAccessory(with: service.feedId)
        }

        HostAppBridge.shared.register(service: GetVCRuningStatusService.self) { [weak self] (_) -> Bool in
            return self?.delegate?.checkVCIsRunning() ?? false
        }

        HostAppBridge.shared.register(service: LarkURLService.self) { [weak self] (service) -> Any? in
            self?.delegate?.openLKWebController(url: service.url, from: service.fromVC)
            return nil
        }

        HostAppBridge.shared.register(service: LaunchCustomerService.self) { [weak self] (_) -> Any? in
            self?.delegate?.launchCustomerService()
            return nil
        }

        HostAppBridge.shared.register(service: DocsAccountService.self) { [weak self] (_) -> Any? in
            return self?.delegate
        }

        HostAppBridge.shared.register(service: OpenContextService.self) { [weak self] (service) -> Any? in
            return self?.delegate?.getOPContextInfo(with: service.params)
        }

        HostAppBridge.shared.register(service: EnterpriseTopicActionService.self) { [weak self] (service) -> Any? in
            if service.action == .dismiss {
                self?.delegate?.docPequiredToDismissEnterpriseTopic()
            } else if service.action == .show,
                      let query = service.query,
                      let addrId = service.addrId,
                      let triggerView = service.triggerView,
                      let triggerPoint = service.triggerPoint,
                      let clientArgs = service.clientArgs,
                      let targetVC = service.targetVC {
                self?.delegate?.docRequiredToShowEnterpriseTopic(query: query,
                                                                 addrId: addrId,
                                                                 triggerView: triggerView,
                                                                 triggerPoint: triggerPoint,
                                                                 clientArgs: clientArgs,
                                                                 clickHandle: service.clickHandle,
                                                                 tapApplinkHandle: service.tapApplinkHandle,
                                                                 targetVC: targetVC)
            }
            return nil
        }

        HostAppBridge.shared.register(service: ResponderService.self) { [weak self] service -> Bool in
            return self?.delegate?.checkIsSearchMainContainerViewController(responder: service.responder) ?? false
        }
    }
}

// MARK: - LifeCycle


// MARK: - RN
extension DocsSDK {
    public func setupRN(needBlockUI: Bool = false) {
            guard DocsSDK.isNeedDelayRN == true else { return }
            DocsLogger.info("DocsSDK start setupRN")
    //        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(setupRN), object: nil)
            if needBlockUI == false {
                DispatchQueue.main.async {
                    self.setupRNEvent()
                }
            } else {
                self.setupRNEvent()
            }
        }

    @objc public func setupRNEvent() {
        guard RNManager.manager.hadStarSetUp == false else { return }
        DocsLogger.info("DocsSDK setupRNEvent")
        RNManager.manager.loadBundle()
        RNManager.manager.registerRnEvent(eventNames: [.rnGetData,
                                                       .rnSetData,
                                                       .offlineCreateDocs,
                                                       .modifyOfflineDocInfo,
                                                       .syncDocInfo,
                                                       .notifySyncStatus,
                                                       .logger,
                                                       .batchLogger,
                                                       .uploadImage,
                                                       .uploadFile,
                                                       .getAppSetting,
                                                       .showQuotaDialog],
                                          handler: offlineSyncManager)
    }

    
    public func updateAppKey(_ appKey: String) {
        DomainConfig.appKey = appKey
        RNManager.manager.updateAPPInfoIfNeed()
    }

    public func updateLongDomain(_ domains: [String]) {
        DocsLogger.info("【LongConDomain】, orgin=\(DomainConfig.ka.longConDomain), update long domains=\(domains)")
        guard domains != DomainConfig.ka.longConDomain else {
            return
        }
        DomainConfig.ka.longConDomain = domains
        RNManager.manager.updateAPPInfoIfNeed()
    }
}


// MARK: - 精简模式收到清除数据的通知
extension DocsSDK {
    public func clearDataIfNeedInLeanMode(_ timeLimited: Int64) {
        guard SimpleModeManager.isOn else {
            DocsLogger.info("clearDataIfNeedInLeanMode called, but not in lean mode", component: LogComponents.simpleMode)
            return
        }
        SimpleModeManager.timeLimit = TimeInterval(timeLimited)
        SimpleModeManager.trigerClearActions()
    }
}
