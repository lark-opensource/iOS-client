//
//  OpenAPI.swift
//  DocsNetwork
//
//  Created by weidong fu on 1/1/2018.
//

import Foundation
import SKFoundation
import LarkEnv
import LarkSetting
import SKUIKit
import SKInfra
import LKCommonsTracker

public extension OpenAPI {
    enum ServerErrorCode: Int {
        case serverTimeOut = -1001
        case invalidDomain = 1
        case noPermission = 4
    }
    ///后台发起请求时的域名，一般请求用这个。
    static var hostKey: String {
        return DomainConfig.userDomainForRequest
    }

    struct Docs {
        
        private enum Const {
            static let msMemoryRatio: Float = 0.65
            static let memoryWarningLevel = 16
            static let docsPreloadTimeOut: Double = 24 * 60 * 60
            static let ssrPreloadRetryMaxCount = 1
            static let preloadWebViewMemorySize = 300
            static let docsRecoverLastPreloadTaskTimeOut: Double = 240 * 60 * 60
            static let docsRecoverPreloadTaskMaxCount = 20
            static let isSetAgentToFrontend: Double = 120
            static let timeout = 25
            static let backGrooundTimeout = 120
        }
        
        public var testServerVersion: Int {
            get {
                guard GlobalSetting.isDevMenuEnable else { return 0 }
                return CCMKeyValue.globalUserDefault.integer(forKey: "testServerVersion")
            }
            set { CCMKeyValue.globalUserDefault.set(newValue, forKey: "testServerVersion") }
        }

        /// 前端代理
        public var isSetAgentToFrontend: Bool {
            get { return CCMKeyValue.globalUserDefault.bool(forKey: "agentToFrontend") }
            set { CCMKeyValue.globalUserDefault.set(newValue, forKey: "agentToFrontend") }
        }

        public var frontendHost: String {
            get { return CCMKeyValue.globalUserDefault.string(forKey: "frontendHost") ?? "" }
            set { CCMKeyValue.globalUserDefault.set(newValue, forKey: "frontendHost") }
        }

        public var isAgentToFrontEndActive: Bool {
            return isSetAgentToFrontend && !frontendHost.isEmpty
        }
        
        /// 代理模式下复用模版开关
        public var isAgentRepeatModule: Bool {
            get { return CCMKeyValue.globalUserDefault.bool(forKey: "agentRepeatModule") }
            set { CCMKeyValue.globalUserDefault.set(newValue, forKey: "agentRepeatModule") }
        }
        
        /// 代理模式下复用模版：打开模版复用，关闭本地离线使用资源包
        public var isAgentRepeatModuleEnable: Bool {
            return isAgentRepeatModule && !OpenAPI.offlineConfig.protocolEnable
        }
        
        /// http 还是 https。如果设置了前端代理，要用http
        public var currentNetScheme: String {
            if !isAgentToFrontEndActive { return "https" }
            return "http"
        }

        public var shouldShowFileOpenBasicInfo: Bool {
            get { return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.shouldShowOpenFileBasicInfo) }
            set { CCMKeyValue.globalUserDefault.set(newValue, forKey: UserDefaultKeys.shouldShowOpenFileBasicInfo) }
        }

        public var isStagingEnv: Bool {
            return DocsDebugEnv.current == .staging
        }

        public var remoteRN: Bool {
            get { return CCMKeyValue.globalUserDefault.bool(forKey: "remoteRN") }
            set { CCMKeyValue.globalUserDefault.set(newValue, forKey: "remoteRN") }
        }

        public func rnDebugShakeFollowSetting() {
            #if DEBUG
            ///Debug设置，"摇一摇功能"跟随调试面板里的"使用远端RN"开关
            var rctDevMenuSetting = CCMKeyValue.globalUserDefault.dictionary(forKey: "RCTDevMenu") ?? [:]
            rctDevMenuSetting["shakeToShow"] = remoteRN
            CCMKeyValue.globalUserDefault.setDictionary(rctDevMenuSetting, forKey: "RCTDevMenu")
            #endif
        }

        public var driveVideoLogEnable: Bool {
            get { return CCMKeyValue.globalUserDefault.bool(forKey: "driveVideoLogEnable") }
            set { CCMKeyValue.globalUserDefault.set(newValue, forKey: "driveVideoLogEnable") }
        }

        public var driveVideoPlayOriginEnable: Bool {
            get { return CCMKeyValue.globalUserDefault.bool(forKey: "driveVideoPlayOriginEnable") }
            set { CCMKeyValue.globalUserDefault.set(newValue, forKey: "driveVideoPlayOriginEnable") }
        }

        public var remoteRNAddress: Bool {
            get { return CCMKeyValue.globalUserDefault.bool(forKey: "remoteRNAddress") }
            set { CCMKeyValue.globalUserDefault.set(newValue, forKey: "remoteRNAddress") }
        }

        public var RNHost: String {
            get { return CCMKeyValue.globalUserDefault.string(forKey: "RNHost") ?? "" }
            set { CCMKeyValue.globalUserDefault.set(newValue, forKey: "RNHost") }
        }

        public var verifiesAllOnboardings: Bool {
            get { return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.verifiesAllOnboardings) }
            set {
                CCMKeyValue.globalUserDefault.set(newValue, forKey: UserDefaultKeys.verifiesAllOnboardings)
                if newValue {
                    OnboardingManager.shared.clearLocalCache()
                }
            }
        }

        /// 向后台发出请求时的url前缀
        public var baseUrl: String {
            return currentNetScheme + "://" + host + DomainConfig.pathPrefix
        }

        public var docsLongConDomain: [String] {
            return DocsDebugEnv.docsLongConDomain
        }

        /// 向后台发出请求时的host
        public var host: String {
            return isAgentToFrontEndActive ? frontendHost : hostKey
        }

        /// 文档们的url的scheme和host，不是向后台请求时的url
        public var baseUrlForDocs: String {
            let host: String = {
                if isAgentToFrontEndActive { return frontendHost }
                return DomainConfig.userDomainForDocs
            }()
            return currentNetScheme + "://" + host
        }

        /// 属于bytedance公司文档们的scheme和host，不是向后台请求时的url
        public var baseUrlForBDDocs: String {
            let host: String = {
                if isAgentToFrontEndActive { return frontendHost }
                return DomainConfig.userDomainForDBDoc
            }()
            return currentNetScheme + "://" + host
        }

        internal var apiVersion: Int? {
            return nil
        }

        public var editorPoolMaxCount: Int {
            if OpenAPI.useSingleWebview {
                DocsLogger.warning("debug: useSingleWebview")
                return 1
            }
            //代理模式下且模版复用，只用一个webview
            if OpenAPI.docs.isAgentRepeatModuleEnable {
                DocsLogger.warning("debug: AgentRepeatModuleEnable")
                return 1
            }
            if SKDisplay.pad {
                if let maxCount = SettingConfig.editorPoolMaxCount?.maxCountForPad {
                    return maxCount
                }
                DocsLogger.warning("use default iPad editorPoolMaxCount:2")
                return 2
            } else {
                if let maxCount = SettingConfig.editorPoolMaxCount?.maxCountForPhone {
                    return maxCount
                }
                DocsLogger.warning("use default iPhone editorPoolMaxCount:1")
                return 1
            }
        }
        
        public var msMemoryRatio: Float {
            if let ratio = SettingConfig.editorPoolMaxCount?.memoryRatio {
                return ratio
            }
            return Const.msMemoryRatio
        }
        
        public var memoryWarningLevel: Int {
            if let memLevel = SettingConfig.docsPreloadTimeOut?.memoryWarningLevel {
                return memLevel
            }
            return Const.memoryWarningLevel
        }
        
        public var docsPreloadTimeOut: Double {
            if let maxCount = SettingConfig.docsPreloadTimeOut?.timeOut {
                return maxCount
            }
            return Const.docsPreloadTimeOut
        }
        
        public var ssrPreloadRetryMaxCount: Int {
            if let maxCount = SettingConfig.docsPreloadTimeOut?.ssrRetry, maxCount > 0 {
                return maxCount
            }
            return Const.ssrPreloadRetryMaxCount
        }
        
        public var preloadWebViewMemorySize: Int {
            if let memorySize = SettingConfig.docsPreloadTimeOut?.webviewMemorySize, memorySize > 0 {
                return memorySize
            }
            return Const.preloadWebViewMemorySize
        }
           
        
        public var docsRecoverLastPreloadTaskTimeOut: Double {
            if let validityTime = SettingConfig.docsPreloadTaskArchvied?.validityTime {
                return validityTime * 60 * 60
            }
            return Const.docsRecoverLastPreloadTaskTimeOut
        }
        
        public var docsRecoverPreloadTaskMaxCount: Int {
            if let maxCount = SettingConfig.docsPreloadTaskArchvied?.maxCount {
                return maxCount
            }
            return Const.docsRecoverPreloadTaskMaxCount
        }
        
        public var docsRecoverPreloadTaskSupportTypes: [String] {
            if let supportTypes = SettingConfig.docsPreloadTaskArchvied?.supportTypes {
                return supportTypes
            }
            return []
        }
        
        public var docsRecoverPreloadTaskSupportFroms: [String] {
            if let supportFroms = SettingConfig.docsPreloadTaskArchvied?.supportFroms {
                return supportFroms
            }
            return []
        }

        public var editorPoolItemMaxUseCount: Int {
            if OpenAPI.docs.isAgentRepeatModuleEnable {
                DocsLogger.info("offlineConfig disable，using single webview", component: LogComponents.fileOpen)
                return 1000
            }
            if OpenAPI.useSingleWebview {
                DocsLogger.info("using single webview", component: LogComponents.fileOpen)
                return 1000
            }
            if let maxCount = SettingConfig.editorPoolMaxUsedCountPerItem {
                return maxCount
            }
            return 5
        }
        
        public var webviewResponsivenessTimeout: Double {
            guard let timeout = SettingConfig.docsWebViewConfig?.responsiveness_timeout, timeout > 0 else {
                return 3.0
            }
            return timeout
        }

        public var wifiOpenDocTimeout: TimeInterval {
            if isSetAgentToFrontend { return Const.isSetAgentToFrontend }
            var timeout = 60
            switch MobileClassify.mobileClassType {
            case .highMobile:    timeout = SettingConfig.timeoutForOpenDocNew?.highDevice.wifi ?? Const.timeout
            case .middleMobile:  timeout = SettingConfig.timeoutForOpenDocNew?.midDevice.wifi ?? Const.timeout
            case .lowMobile:     timeout = SettingConfig.timeoutForOpenDocNew?.lowDevice.wifi ?? Const.timeout
            case .unClassify:
                if let oldtimeout = SettingConfig.timeoutForOpenDoc?.wifi, oldtimeout > 0 {
                    // iPad评分拉不到，用旧的配置
                    timeout = oldtimeout
                }
            }
            return TimeInterval(timeout)
        }

        public var noWifiOpenDocTimeout: TimeInterval {
            if isSetAgentToFrontend { return Const.isSetAgentToFrontend }
            var timeout = 60
            switch MobileClassify.mobileClassType {
            case .highMobile:    timeout = SettingConfig.timeoutForOpenDocNew?.highDevice.wwan4G ?? Const.timeout
            case .middleMobile:  timeout = SettingConfig.timeoutForOpenDocNew?.midDevice.wwan4G ?? Const.timeout
            case .lowMobile:     timeout = SettingConfig.timeoutForOpenDocNew?.lowDevice.wwan4G ?? Const.timeout
            case .unClassify:
                if let oldtimeout = SettingConfig.timeoutForOpenDoc?.wwan4G, oldtimeout > 0 {
                    // iPad评分拉不到，用旧的配置
                    timeout = oldtimeout
                }
            }
            return TimeInterval(timeout)
        }

        public var backGroundOpenDocTimeout: TimeInterval {
            if isSetAgentToFrontend { return Const.isSetAgentToFrontend }
            var timeout = 120
            switch MobileClassify.mobileClassType {
            case .highMobile:    timeout = SettingConfig.timeoutForOpenDocNew?.highDevice.backGround ?? Const.backGrooundTimeout
            case .middleMobile:  timeout = SettingConfig.timeoutForOpenDocNew?.midDevice.backGround ?? Const.backGrooundTimeout
            case .lowMobile:     timeout = SettingConfig.timeoutForOpenDocNew?.lowDevice.backGround ?? Const.backGrooundTimeout
            case .unClassify:
                if let oldtimeout = SettingConfig.timeoutForOpenDoc?.backGround, oldtimeout > 0 {
                    // iPad评分拉不到，用旧的配置
                    timeout = oldtimeout
                }
            }
            return TimeInterval(timeout)
        }
        
        public var templateWaitTime: TimeInterval {
            if isSetAgentToFrontend { return 0 }
            var timeout = 0
            switch MobileClassify.mobileClassType {
            case .highMobile:    timeout = SettingConfig.timeoutForOpenDocNew?.highDevice.templateWaitTime ?? 10
            case .middleMobile:  timeout = SettingConfig.timeoutForOpenDocNew?.midDevice.templateWaitTime ?? 10
            case .lowMobile:     timeout = SettingConfig.timeoutForOpenDocNew?.lowDevice.templateWaitTime ?? 10
            case .unClassify:
                if let oldtimeout = SettingConfig.timeoutForOpenDoc?.templateWaitTime, oldtimeout > 0 {
                    // iPad评分拉不到，用旧的配置
                    timeout = oldtimeout
                }
            }
            return TimeInterval(timeout)
        }
        
        public var lowDeviceCanPreload: Bool {
            return SettingConfig.offlineCacheConfig?.lowDeviceCanPrelaod ?? true
        }
        
        public var checkResponsiveInOpenDoc: Bool {
            if isSetAgentToFrontend { return false }
            return true
        }

        public var featureID: String? {
            get { return CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.featureIDKey) }
            set { CCMKeyValue.globalUserDefault.set(newValue, forKey: UserDefaultKeys.featureIDKey) }
        }
        public var disableEditorResue: Bool {
            get { return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.disableEditorReuseKey) }
            set { CCMKeyValue.globalUserDefault.set(newValue, forKey: UserDefaultKeys.disableEditorReuseKey) }
        }

        public var disableFilterBOMChar: Bool {
            get { return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.disableFilterBOMChar) }
            set { CCMKeyValue.globalUserDefault.set(newValue, forKey: UserDefaultKeys.disableFilterBOMChar) }
        }
        
        public var enableSSRCahceToastForTest: Bool {
            get { return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.enableSSRCahceToastForTest) }
            set { CCMKeyValue.globalUserDefault.set(newValue, forKey: UserDefaultKeys.enableSSRCahceToastForTest) }
        }
        
        public var enableKeepSSRWebViewTest: Bool {
            get { return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.keepSSRWebViewAliveForTest) }
            set { CCMKeyValue.globalUserDefault.set(newValue, forKey: UserDefaultKeys.keepSSRWebViewAliveForTest) }
        }
    }

    static var docs = Docs()

    static var memberId: String {
        return abs(Date().timeIntervalSince1970.hashValue).description
    }
}

extension OpenAPI {

    public struct OfflineConfig {

        let geckoFetchKey = String(describing: OpenAPI.OfflineConfig.self) + "geckoFetchEnable"

        public var geckoFetchEnable: Bool {
            get {
                let enable: Bool? = CCMKeyValue.globalUserDefault.value(forKey: geckoFetchKey)
                return enable ?? true
            }
            set {
                CCMKeyValue.globalUserDefault.set(newValue, forKey: geckoFetchKey)
                GeckoPackageManager.shared.disableUpdate(disable: !newValue)
            }
        }

        // 是否使用私有协议，即是否使用离线包打开文档
        public var protocolEnable: Bool {
            get {
                if GlobalSetting.isDevMenuEnable {
                    let enable: Bool? = CCMKeyValue.globalUserDefault.value(forKey: "OpenAPI_OfflineConfig_protocolEnable")
                    return enable ?? true
                } else {
                    let isManualSet: Bool? = CCMKeyValue.globalUserDefault.value(forKey: "OpenAPI_OfflineConfig_protocolEnable")
                    if let isManualSet = isManualSet {
                        return isManualSet
                    }
                    return true
                }
            }
            set { CCMKeyValue.globalUserDefault.set(newValue, forKey: "OpenAPI_OfflineConfig_protocolEnable") }
        }
    }
    public static var offlineConfig = OfflineConfig()
}

// MARK: - debug configs
extension OpenAPI {
    static let enableStatisticsEncryptionStr = "enableStatisticsEncryption"

    public static var enableStatisticsEncryption: Bool {
        get { return CCMKeyValue.globalUserDefault.value(forKey: OpenAPI.enableStatisticsEncryptionStr) ?? true }
        set { CCMKeyValue.globalUserDefault.set(newValue, forKey: OpenAPI.enableStatisticsEncryptionStr) }
    }

    public static var useSingleWebview: Bool {
        get { return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.useSingleWebviewKey) }
        set {
            CCMKeyValue.globalUserDefault.set(newValue, forKey: UserDefaultKeys.useSingleWebviewKey)
            DocsLogger.info("set use single webview \(useSingleWebview)")
        }
    }

    public static var enableRustHttp: Bool {
        if DocsSDK.isBeingTest {
            return CCMKeyValue.globalUserDefault.bool(forKey: "enableRustHttpKeyForTest")
        }
        if CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.disableRustRequest) {
            // 调试开关
            return false
        }
        // 已经GA了
        return true
    }

    public static var renderCachedHtmlDelayInSeconds: Double {
        return Double(renderCachedHtmlDelayInMilliscond) / 1000.0
    }

    public static var renderCachedHtmlDelayInMilliscond: Int {
        get { return 30 }
        set {
            CCMKeyValue.globalUserDefault.set(newValue, forKey: UserDefaultKeys.renderCacheDelayMilliscond)
            DocsLogger.info("render cache delay \(renderCachedHtmlDelayInMilliscond)")
        }
    }

    public static var browserLoadingDelayInSeconds: Double {
        guard let delayInMillisecond = SettingConfig.loadingDelayMilliscond else { return 0.3 }
        return  Double(delayInMillisecond) / 1000.0
    }

    public static var delayLoadRNInSeconds: Double {
        guard let timeForDelayLoadRN = SettingConfig.timeForDelayLoadRN else { return 90 }
        return Double(timeForDelayLoadRN)
    }

    public static var delayLoadUrl: Double {
        let delayLoadUrl = SettingConfig.timeForDelayURL ?? 0
        return Double(delayLoadUrl)
    }

    public static var globalWatermarkEnabled: Bool {
        get {
            #if BETA || ALPHA || DEBUG
            let policy = WatermarkPolicy.current
            if policy == .forceOff {
                return false
            } else if policy == .forceOn {
                return true
            }
            #endif
            return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.globalWatermarkEnabled)
        }
        set {
            CCMKeyValue.globalUserDefault.set(newValue, forKey: UserDefaultKeys.globalWatermarkEnabled)
        }
    }

    public static var forceLogLevel: Int? {
        get {
            return CCMKeyValue.globalUserDefault.value(forKey: UserDefaultKeys.forceLogLevel)
        }
        set {
            CCMKeyValue.globalUserDefault.set(newValue, forKey: UserDefaultKeys.forceLogLevel)
        }
    }
    public static var currentLogLevel: String {
        if let level = forceLogLevel, let logLevel = DocsLogLevel(rawValue: level) {
            return "\(logLevel)"
        } else {
            return "默认"
        }
    }

    /// 是不是给QA打的包
    public static var isForQATest: Bool {
        get { return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.isForQA) }
        set { CCMKeyValue.globalUserDefault.set(newValue, forKey: UserDefaultKeys.isForQA) }
    }

    public static var useComplexConnectionForPost: Bool {
        return false
    }

    public static var needDelayDeallocWebview: Bool {
        get { return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.needDelayDeallocWebview) }
        set { CCMKeyValue.globalUserDefault.set(newValue, forKey: UserDefaultKeys.needDelayDeallocWebview) }
    }
    
    public static var webviewCheckResponsiveEnable: Bool {
#if DEBUG
        return true
#else
        var enable = LKFeatureGating.webviewCheckResponsiveEnable
        if enable {
            do {
                let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "webview_check_responsive_enable_osversion"))
                let minsystemVersion = settings["check_responsive_enable_min_osversion"] as? Int
                if minsystemVersion != nil {
                    let systemVersion = (UIDevice.current.systemVersion as NSString).intValue
                    if systemVersion > minsystemVersion! {
                        return true
                    }
                    return false
                }
                if #available(iOS 15.0, *) {
                    return true
                }
                return false
            } catch {
                DocsLogger.error("webview_check_responsive_enable_osversion get settings error", error: error)
                if #available(iOS 15.0, *) {
                    return true
                }
                return false
            }
        }
        return enable
#endif
    }
    
    public static var webviewCheckResponsivTime: TimeInterval {
        let defultTime = TimeInterval(5 * 60)
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "webview_check_responsive_enable_osversion"))
            if let minTime = settings["check_responsive_enable_time"] as? Int, minTime > 0 {
                return TimeInterval(minTime)
            }
            return defultTime
        } catch {
            DocsLogger.error("webviewCheckResponsivTime get settings error", error: error)
            return defultTime
        }
    }
    
    public static func enableTemplateTag(docsInfo: DocsInfo) -> Bool {
        if docsInfo.isVersion {
            return false
        }
        if docsInfo.inherentType == .slides {
            //slides还不支持模版新建，先屏蔽
            return false
        }
        if let isInVideoConference = docsInfo.isInVideoConference, isInVideoConference {
            return false
        }
        if docsInfo.templateType == .egcTemplate {
            // 企业模板
            return false
        }
        return true
    }
    
    public static func showTemplateTag(docsInfo: DocsInfo) -> Bool {
        return enableTemplateTag(docsInfo: docsInfo) && (docsInfo.templateType == .ugcTemplate || docsInfo.templateType == .pgcTemplate)
    }
}
