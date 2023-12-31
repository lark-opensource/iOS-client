//
//  TTNetInitializor.swift
//  LarkTTNetInitializor
//
//  Created by qihongye on 2020/12/17.
//

import UIKit
import Foundation
import LarkReleaseConfig
import TTNetworkManager
import LarkFoundation
import LarkAccountInterface
import RustPB
import LarkDebug
import LarkSetting

private let EMPTYSTRING = "<empty-string>"

/// Tracker adaptor
public protocol TTNetInitializorTracker: AnyObject {
    func track(data: [AnyHashable: Any]?, logType: String)
    func info(_ message: String, error: Error?, file: String, method: String, line: Int)
}

/// TTNetInitializorError
public enum TTNetInitializorError: Error {
    case ttnetworkManagerInstanceFailed

    public var code: Int {
        switch self {
        case .ttnetworkManagerInstanceFailed:
            return 1_001
        }
    }
}

/// TTNetInitializor
public final class TTNetInitializor {
    /// TTNetInitializor initialize configuration.
    public enum EnvType: String {
        case release
        case staging
        case preRelease = "pre-release"
    }

    /// TTNetInitializor initialize configuration.
    public struct Configuration {
        /// UserAgent from lark app.
        public let userAgent: String
        /// Device id from lark device id.
        public let deviceID: String
        /// Session info from lark app.
        public let session: String
        /// Current user tenent id.
        public let tenentID: String
        /// A/B test id, this uuid is computed from userID in Lark.
        public let uuid: String
        /// EnvType
        /// exp:
        /// enum TypeEnum: Int {
        ///     case release = 1
        ///     case staging = 2
        ///     case preRelease = 3
        /// }
        public let envType: EnvType
        /// EnvUnit
        /// exp:
        /// struct Unit {
        ///     数据单元: 中国北部
        ///     unit: north of China
        ///     static let NC: String = "eu_nc"
        ///
        ///     数据单元 美国东部(维吉尼亚)
        ///     unit: east of America(Virginia)
        ///     static let EA: String = "eu_ea"
        ///
        ///     数据单元: 新加坡 SaaS unit 1
        ///     unit: Singapore SaaS unit 1
        ///     static let SaaS1Lark: String = "saas1lark"
        ///
        ///     数据单元: 新加坡 SaaS unit 2
        ///     unit: Singapore SaaS unit 2
        ///     static let SaaS2Lark: String = "saas2lark"
        ///
        ///     数据单元: 中国 BOE
        ///     unit: China BOE
        ///     static let BOECN: String = "boecn"
        ///
        ///     数据单元: 海外 BOE
        ///     unit: oversea BOE
        ///     static let BOEVA: String = "boeva"
        /// }
        public let envUnit: String
        /// Certifications
        public let certificateList: [Data]?

        /// tnc base config.
        /// example:
        ///        {
        ///            "data": {
        ///               "tnc_update_interval": 3600,
        ///               "chromium_open": 1,
        ///               "http_dns_enabled": 1,
        ///               "ttnet_http_dns_enabled": 1,
        ///               "ttnet_tt_http_dns":1,
        ///               "ttnet_http_dns_timeout": 5,
        ///               "opaque_data_enabled":1,
        ///               "wpad_enabled": 0,
        ///               "clear_pool_enabled": 1
        ///           },
        ///           "message":"success"
        ///       }
        public let tncConfig: String
        /// tnc domains
        /// example:
        /// ["dm.feishu.cn", "dm-lf.feishu.cn", "dm-hl.feishu.cn"]
        public let tncDomains: [String]
        /// http dns domain
        /// example:
        /// ["dig.bdurl.net"]
        public let httpDNS: [String]
        /// log domain
        /// example:
        /// ["crash.snssdk.com"]
        public let netlogDomain: [String]

        /// constructor
        /// - Parameters:
        ///   - userAgent: String. User-Agent
        ///   - deviceID: String. Device id
        ///   - session: String. Session(cookie)
        public init(
            userAgent: String,
            deviceID: String,
            session: String,
            tenentID: String,
            uuid: String,
            envType: EnvType,
            envUnit: String,
            tncConfig: String,
            tncDomains: [String],
            httpDNS: [String],
            netlogDomain: [String],
            certificateList: [Data]?
        ) {
            self.userAgent = userAgent
            self.deviceID = deviceID
            self.session = session
            self.tenentID = tenentID
            self.uuid = uuid
            self.envType = envType
            self.envUnit = envUnit
            self.tncConfig = tncConfig
            self.tncDomains = tncDomains
            self.httpDNS = httpDNS
            self.netlogDomain = netlogDomain
            self.certificateList = certificateList
        }
    }

    private static var rwlock = pthread_rwlock_t()
    private static var _tracker: TTNetInitializorTracker?
    private static var tracker: TTNetInitializorTracker? {
        get {
            pthread_rwlock_rdlock(&rwlock)
            defer {
                pthread_rwlock_unlock(&rwlock)
            }
            return _tracker
        }
        set {
            pthread_rwlock_wrlock(&rwlock)
            _tracker = newValue
            pthread_rwlock_unlock(&rwlock)
        }
    }

    // 长连开关
    private static var ttnetPushEnabled: Bool = {
        // lint:disable lark_storage_check
        let userDefault = UserDefaults(suiteName: "lk_safe_mode")
        guard let dicConfig = userDefault?.dictionary(forKey: "lark_custom_exception_config") else {
            return false
        }
        // lint:enable lark_storage_check
        guard let dicTab = dicConfig["ttnet_push"] as? [String: Bool] else {
            return false
        }
        guard let isEnabled = dicTab["ttnet_push_enabled"] else {
            return false
        }
        return isEnabled
    }()

    /// Setup tracker adaptor
    /// - Parameter tracker: TTNetInitializorTracker
    public static func setupTracker(_ tracker: TTNetInitializorTracker) {
        self.tracker = tracker
    }

    // swiftlint:disable function_body_length

    enum AlphaOrBeta {
        case alpha(Int?)
        case beta(Int?)
    }

    static let versionCode: String? = {
        // 计算方法参考： https://bytedance.feishu.cn/docx/doxcnefNFhlZzybnHOYBdsaNODg

        let shortVersion: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
        let result = shortVersion.split(maxSplits: 4, omittingEmptySubsequences: true, whereSeparator: { $0 == "." || $0 == "-"})
        guard result.count >= 3 else { return nil }
        guard let major = Int(result[0]), let minor = Int(result[1]), let patch = Int(result[2]) else { return nil }

        var alphaOrBeta: AlphaOrBeta?

        if result.count > 3 {
            if result[3].starts(with: "alpha") {
                let alpahVersion = result[3].replacingOccurrences(of: "alpha", with: "")
                alphaOrBeta = .alpha(Int(alpahVersion))
            } else if result[3].starts(with: "beta") {
                let betaVersion = result[3].replacingOccurrences(of: "beta", with: "")
                alphaOrBeta = .beta(Int(betaVersion))
            }
        }

        let latestTwoNumber: Int
        if let alphaOrBeta = alphaOrBeta {
            switch alphaOrBeta {
            case .alpha:
                latestTwoNumber = 0
            case .beta(let betaVersion):
                latestTwoNumber = betaVersion ?? 1
            }
        } else {
            latestTwoNumber = 50
        }
        let intVersion = major * 1000000 + minor * 10000 + patch * 100 + latestTwoNumber
        return "\(intVersion)"
    }()

    /// initialize
    /// - Parameter configuration: TTNetInitializor.Configuration
    public static func initialize(_ configuration: Configuration) {
        TTNetworkManager.setMonitorBlock { (data, logType) in
            Self.tracker?.info(
                "data null is \(data == nil); logType is \(logType ?? "null")",
                error: nil, file: #fileID, method: "initial", line: #line
            )
            Self.tracker?.track(data: data, logType: logType)
        }
        let ttnetworkManager = TTNetworkManager.shareInstance()
        if !appCanDebug() || UserDefaults.standard.caStoreEnabled {
            ttnetworkManager.serverCertificate = RootCertificates.getRootCertificates()
        }
        ttnetworkManager.commonParamsblock = { [unowned ttnetworkManager] in
            Self.setTNCRequest(
                ttnetworkManager: ttnetworkManager,
                envType: configuration.envType,
                envUnit: configuration.envUnit,
                session: configuration.session,
                uuid: configuration.uuid,
                tenentID: configuration.tenentID
            )
            return [
                "aid": appID,
                "app_name": appName,
                "region": Locale.current.regionCode ?? "CN",
                "device_id": configuration.deviceID,
                "device_platform": plaform,
                "uuid": configuration.uuid,
                "tnc_load_flags": "128",
                "httpdns_load_flags": "128",
                "version_code": versionCode ?? "",
                "is_drop_first_tnc": "1"
            ]
        }
        ttnetworkManager.enableQuic = true
        ttnetworkManager.enableHttp2 = true
        ttnetworkManager.enableBrotli = true
        ttnetworkManager.getDomainDefaultJSON = configuration.tncConfig
//            "{\"data\":"
//            + "{\"tnc_update_interval\":3600,\"chromium_open\":1,\"http_dns_enabled\":1,"
//            + "\"ttnet_http_dns_enabled\":1,\"ttnet_tt_http_dns\":1,\"ttnet_http_dns_timeout\":5,"
//            + "\"ttnet_local_dns_timeout_map\":{\"dig.bdurl.net\":2},\"ttnet_preconnect_urls\":"
//            + "{\"dig.bdurl.net\":1,\"internal-api-lark-api.feishu.cn\":1}},"
//            + "\"message\":\"success\"}"
        ttnetworkManager.userAgent = "\(configuration.userAgent) TTNet"
        if
            let fileSchedulingSetting = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "fine_scheduling")), //Global  取的时机比较早，没有用户态数据，可以允许串用户数据
            fileSchedulingSetting["lark.enable_close_ios_http_cache"] != nil {
            Self.tracker?.info("close http cache",
                               error: nil,
                               file: #fileID,
                               method: "initialize",
                               line: #line)
            ttnetworkManager.enableHttpCache = false
        }
        setTNCRequest(
            ttnetworkManager: ttnetworkManager,
            envType: configuration.envType,
            envUnit: configuration.envUnit,
            session: configuration.session,
            uuid: configuration.uuid,
            tenentID: configuration.tenentID
        )
        setDomains(ttnetworkManager,
                   tncDomains: configuration.tncDomains,
                   httpDNS: configuration.httpDNS,
                   netlogDomain: configuration.netlogDomain)
        ttnetworkManager.domainBoe = ".boe-gateway.byted.org"
        ttnetworkManager.setBoeProxyEnabled(UserDefaults.standard.boeProxyEnabled)
        ttnetworkManager.bypassBoeJSON = ""

        if let certificateList = configuration.certificateList {
            Self.tracker?.info(
                "Client CertificateList: \(certificateList.count)",
                error: nil,
                file: #fileID,
                method: "initialize",
                line: #line
            )
            setCAStore(ttnetworkManager: ttnetworkManager, certificateList: certificateList)
        }

        #if DEBUG
        ttnetworkManager.enableVerboseLog()
        #endif
        tracker?.info(
            "start ttnet",
            error: nil, file: #fileID, method: "initialize", line: #line
        )
        ttnetworkManager.start()
        // 开启长连通道
        DispatchQueue.global().async {
            ttnetPushStart()
        }
    }
    // swiftlint:enable function_body_length

    /// 开启长连通道
    private static func ttnetPushStart() {
        guard Self.ttnetPushEnabled == true else {
            return
        }
        guard ReleaseConfig.isKA == false else {
            return
        }
        TTPushManager.shared()
    }

    // swiftlint:disable function_parameter_count

    /// initialWithLarkUserInfo
    /// - Parameters:
    ///   - session: Lark session token for each user.
    ///   - deviceID: Lark device id for each device.
    ///   - tenantID: Lark tenant id for each user.
    public static func initialWithLarkUserInfo(session: String,
                                               deviceID: String,
                                               tenantID: String,
                                               uuid: String,
                                               envType: EnvType,
                                               envUnit: String,
                                               tncDomains: [String],
                                               httpDNS: [String],
                                               netlogDomain: [String]) {
        let ttnetworkManager = TTNetworkManager.shareInstance()
        ttnetworkManager.commonParamsblock = { [unowned ttnetworkManager] in
            Self.setTNCRequest(ttnetworkManager: ttnetworkManager, envType: envType, envUnit: envUnit, session: session, uuid: uuid, tenentID: tenantID)

            return [
                "aid": appID,
                "app_name": appName,
                "region": Locale.current.regionCode ?? "CN",
                "device_id": deviceID,
                "uuid": uuid,
                "device_platform": plaform,
                "tnc_load_flags": "128",
                "httpdns_load_flags": "128",
                "version_code": versionCode ?? "",
            ]
        }

        var headers = ttnetworkManager.tncRequestHeaders ?? [:]
        headers["x-session"] = session
        headers["uuid"] = uuid
        ttnetworkManager.tncRequestHeaders = headers

        var queries = ttnetworkManager.tncRequestQueries ?? [:]
        queries["tenant_id"] = tenantID
        ttnetworkManager.tncRequestQueries = queries

        setDomains(ttnetworkManager,
                   tncDomains: tncDomains,
                   httpDNS: httpDNS,
                   netlogDomain: netlogDomain)
    }
    // swiftlint:enable function_parameter_count
}

fileprivate extension TTNetInitializor {
    static func setTNCRequest(ttnetworkManager: TTNetworkManager, envType: EnvType, envUnit: String, session: String, uuid: String, tenentID: String) {
        // tnc header
        // envtype用string
        let headers = [
            "x-env-v2": "type=\(envType.rawValue);unit=\(envUnit);brand=\(AccountServiceAdapter.shared.foregroundTenantBrand)",
            "x-session": session,
            "uuid": uuid
        ]
        ttnetworkManager.tncRequestHeaders = headers

        var tncRequestQueries = ttnetworkManager.tncRequestQueries ?? [:]
        tncRequestQueries["tenant_id"] = tenentID
        if let versionCode = Self.versionCode {
            tncRequestQueries["version_code"] = versionCode
        }
        ttnetworkManager.tncRequestQueries = tncRequestQueries
    }

    @inline(__always)
    private static func setCAStore(ttnetworkManager: TTNetworkManager, certificateList: [Data]) {
        ttnetworkManager.clientCertificates = certificateList
            .compactMap({ genTTClientCertificate(certData: $0) })
    }

    @inline(__always)
    static func genTTClientCertificate(certData: Data) -> TTClientCertificate? {
        guard let cert = try? Basic_V1_NetworkClientCertificate(serializedData: certData) else {
            return nil
        }
        let ttcert = TTClientCertificate()
        ttcert.hostsList = cert.hosts
        ttcert.certificate = cert.cert
        ttcert.privateKey = cert.privkey
        return ttcert
    }

    @inline(__always)
    static func setDomains(_ ttnetworkManager: TTNetworkManager,
                           tncDomains: [String],
                           httpDNS: [String],
                           netlogDomain: [String]) {
        // TNC service domains
        if let domain = tncDomains.first {
            ttnetworkManager.serverConfigHostFirst = domain
            ttnetworkManager.serverConfigHostSecond = domain
            ttnetworkManager.serverConfigHostThird = domain
        }
        if tncDomains.count > 1 {
            ttnetworkManager.serverConfigHostSecond = tncDomains[1]
        }
        if tncDomains.count > 2 {
            ttnetworkManager.serverConfigHostThird = tncDomains[2]
        }
        // http dns
        ttnetworkManager.domainHttpDns = httpDNS.first ?? "dig.bdurl.net"
        ttnetworkManager.domainNetlog = netlogDomain.first ?? "crash.snssdk.com"

        Self.tracker?.info(
            "Setup domains: TNC(\(tncDomains.joined(separator: ","))) " +
                "HTTPDNS(\(ttnetworkManager.domainHttpDns ?? EMPTYSTRING)) " +
                "NETLOG(\(ttnetworkManager.domainNetlog ?? EMPTYSTRING))",
            error: nil, file: #fileID, method: "setDomains", line: #line
        )
    }

    static var plaform: String = {
        if Utils.isiOSAppOnMacSystem {
            return "mac"
        }
        if UIDevice.current.model.contains("iPhone") {
            return "iphone"
        }
        if UIDevice.current.model.contains("iPad") {
            return "ipad"
        }
        return "ios"
    }()

    static var appName: String = {
        return Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Lark"
    }()

    static var appID: String = {
        return ReleaseConfig.appId
    }()
}
