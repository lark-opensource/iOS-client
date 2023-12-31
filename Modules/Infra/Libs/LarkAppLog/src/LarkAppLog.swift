//
//  LarkAppLog.swift
//  LarkAppLog
//
//  Created by Yiming Qu on 2020/11/6.
//

import Foundation
import RangersAppLog
import LarkReleaseConfig
import LarkFeatureSwitch
import LKCommonsLogging
import LarkLocalizations
import LarkKAFeatureSwitch
import LarkStorage

// swiftlint:disable missing_docs
public enum StoreKey {
    public static let tracerManagerCustomHeaderKey = "tracer.manager.custom.header"
}

public final class LarkAppLog {

    static let logger = Logger.log(LarkAppLog.self, category: "SuiteLogin.RangersAppLog")

    /// KV存储
    public static let globalStore = KVStores.udkv(
        space: .global, domain: Domain.biz.infra.child("AppLog")
    )

    /// instance
    public static let shared: LarkAppLog = LarkAppLog()

    /// 头条埋点库
    public private(set) var tracker: BDAutoTrack

    public let serialQueue = DispatchQueue(label: "tracer.manager.queue", qos: .background)

    /// 发起设备注册请求，获取did
    public func sendRegisterRequest() {
        self.serialQueue.async {
            self.tracker.sendRegisterRequest()
        }
    }

    // MARK: config

    /// 设置 注册、激活设备使用的 URLConfig
    public func setupURLConfig(_ config: URLConfig) {
        self.urlConfig = config
        setupTracker()
    }

    /// 更新 注册、激活设备使用的 URLConfig
    public func updateURLConfig(_ config: URLConfig) {
        self.urlConfig = config
    }

    /// 设置 Tea埋点使用的 URL
    public func setupTeaEndpointsURL(_ teaEndpointsURL: [String]) {
        self.teaEndpointsURL = teaEndpointsURL
        setupTracker()
    }

    /// 设置 Tea埋点使用的 URL
    public func updateTeaEndpointsURL(_ teaEndpointsURL: [String]) {
        self.teaEndpointsURL = teaEndpointsURL
    }

    /// 设置 激活设备使用的 URL
    /// KA 使用
    public func updateTTActiveUri(_ ttActiveUri: [String]) {
        self.urlConfig.ttActiveURL = ttActiveUri
    }

    /// 设置 注册设备使用的 URL
    /// KA 使用
    public func updateTTDeviceUri(_ ttDeviceUri: [String]) {
        self.urlConfig.ttDeviceURL = ttDeviceUri
    }

    /// 设置 CommonHost
    /// SaaS 用于 注册、激活设备
    public func updateCommonHost(_ commonHost: [String]) {
        self.urlConfig.commonHost = commonHost
    }

    // MARK: clear

    /// 清除RangersAppLog UserDefault、Keychain缓存
    public func clearCache() {
        let remover = BDAutoTrackCacheRemover()
        remover.removeDefaults(forAppID: Self.appID)
        remover.removeKeychain(forAppID: Self.appID, serviceVendor: self.vendorType)
    }

    /// 更新埋点上报的CustomHeader
    public func updateCustomHeader(customHeader: [String: Any]) {
        Self.globalStore.setDictionary(customHeader, forKey: StoreKey.tracerManagerCustomHeaderKey)
        setCumstomHeader(customHeader: customHeader)
        Self.globalStore.synchronize()
    }
    
    
    /// 设置did需要自动更新
    public func setDeviceIDNeedAutoUprade(_ need: Bool ) {
        isEnableDIDAutoUpgrade = need
    }
    
    /// 标记已经切换到统一did
    public func setDeviceIDUnitUpgraded(_ flag: Bool) {
        isUniDID = flag
    }

    /// 上报所有的缓存埋点
    public func flush() { tracker.flush() }

    private init() {
        self.tracker = Self.createBDTracker(vendorType: self.vendorType)
        self.setupTracker()
    }

    private static func createBDTracker(vendorType: BDAutoTrackServiceVendor) -> BDAutoTrack {
        let config = BDAutoTrackConfig(appID: self.appID, launchOptions: nil)
        config.serviceVendor = vendorType
        config.appID = self.appID
        config.appName = self.appName
        config.channel = self.channel
        config.monitorEnabled = false
        config.autoFetchSettings = true
        let tracker = BDAutoTrack(config: config) ?? {
            #if DEBUG
            fatalError("unexpected")
            #else
            return BDAutoTrack.shared()
            #endif
        }()
        tracker.setFilterEnable(true)
        tracker.setAppLauguage(LanguageManager.currentLanguage.localeIdentifier)
        return tracker
    }

    private func setCumstomHeader(customHeader: [String: Any]) {
        tracker.setCustomHeaderBlock { customHeader }
    }

    private func setupTracker() {
        self.serialQueue.async {
            self.tracker.setServiceVendor(self.vendorType)
            if let customHeaderCache = Self.globalStore.dictionary(
                forKey: StoreKey.tracerManagerCustomHeaderKey
            ) {
                self.setCumstomHeader(customHeader: customHeaderCache)
            }

            /* 自定义URL, commented on purpose */
            self.tracker.setRequestURLBlock { [weak self] _, requestURLType -> String? in
                return self?.urlConfig.url(for: requestURLType, teaEndpointsURL: self?.teaEndpointsURL ?? [])
            }

            self.tracker.setRequestHostBlock { [weak self] _, requestURLType -> String? in
                return self?.urlConfig.host(for: requestURLType)
            }

            //设置自定义Header
            self.tracker.setCommonParamtersBlock { [weak self] _, _, headers in

                guard let self = self else { return headers }

                var requestHeaders = headers
                //标记已经升级到了统一did
                requestHeaders["unit_upgraded"] = self.isUniDID
                //标记是否需要升级自增did
                requestHeaders["auto_upgrade"] = self.isEnableDIDAutoUpgrade

                return requestHeaders
            }

            self.tracker.start()
        }
    }

    var vendorType: BDAutoTrackServiceVendor = .private

    var urlConfig: URLConfig = URLConfig()
    // 仅有URL配置；如 https://toblog.tobsnssdk.com/service/2/app_log/
    var teaEndpointsURL: [String]?

    static var appID: String = ReleaseConfig.appIdForAligned

    static var appName: String = (Bundle.main.infoDictionary?["CFBundleName"] as? String) ?? ""

    static var channel: String { ReleaseConfig.isKA ? ReleaseConfig.kaChannelForAligned : ReleaseConfig.channelName }

    //标记did是否需要重新生成，现状只有自增did场景才会重新生成
    private var isEnableDIDAutoUpgrade: Bool = false

    //标记did是否需要重新生成，现状只有自增did场景才会重新生成
    private var isUniDID: Bool = false

    public func clearAllEvent() {
        self.tracker.clearAllEvent()
    }
}

extension LarkAppLog {

    /// AppLog URL配置
    ///
    /// SaaS
    ///   使用commonHost 注册、激活设备
    /// KA
    ///   使用 ttDeviceURL 注册设备
    ///   使用 ttActiveURL 激活设备
    public struct URLConfig {
        // 仅有URL配置，且仅对KA有效
        var ttActiveURL: [String]

        // 仅有URL配置，且仅对KA有效
        var ttDeviceURL: [String]

        // 仅有Host配置，且仅针对SaaS有效；如 toblog.tobsnssdk.com
        var commonHost: [String]

        init() {
            self.ttActiveURL = []
            self.ttDeviceURL = []
            self.commonHost = []
        }

        public init(ttActiveURL: [String], ttDeviceURL: [String], commonHost: [String]) {
            self.ttActiveURL = ttActiveURL
            self.ttDeviceURL = ttDeviceURL
            self.commonHost = commonHost
        }

        func url(for trackType: BDAutoTrackRequestURLType, teaEndpointsURL: [String]) -> String? {
            switch trackType {
            case .urlLog:
                return teaEndpointsURL.first
            case .urlLogBackup:
                return teaEndpointsURL.count > 1 ? teaEndpointsURL[1] : nil
            case .urlRegister:
                return ttDeviceURL.first
            case .urlActivate:
                return ttActiveURL.first
            case .urlSettings, .urlabTest:
                // 使用CommonHost
                return nil
            default:
                return nil
            }
        }

        @inline(__always)
        func host(for trackType: BDAutoTrackRequestURLType) -> String? {
            if let first = commonHost.first {
                return first.lowercased().hasPrefix("http") ? first : "https://" + first
            }
            return nil
        }
    }
}

// swiftlint:enable missing_docs
