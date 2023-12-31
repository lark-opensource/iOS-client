//
//  Configuration.swift
//  SpaceKit
//
//  Created by weidong fu on 28/3/2018.
// swiftlint:disable line_length

import Foundation
import LarkExtensions
import ThreadSafeDataStructure
import HTTProtocol
import LarkContainer

public extension CCMExtension where Base == UserResolver {

    var netConfig: NetConfig? {
        if CCMUserScope.commonEnabled {
            let obj = try? base.resolve(type: NetConfig.self)
            return obj
        } else {
            return .singleInstance
        }
    }
}

public enum NetConfigQos: Int {
    case `default` = 0
    case high = 1
    case background = 2
}

public enum NetConfigTrafficType: Int {
    case `default` = 0
    case upload = 1
    case docsFetch = 2
    case download = 3
    case preloadPicture = 4
}

public final class NetConfig {
    
    fileprivate static let singleInstance = NetConfig(userResolver: nil)//TODO.chensi 用户态迁移完成后删除旧的单例代码
    
    @available(*, deprecated, message: "new code should use `userResolver.docs.netConfig`")
    public static var shared: NetConfig {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: true)
        if let obj = userResolver.docs.netConfig {
            return obj
        }
        spaceAssertionFailure("basically impossible, contact chensi.123")
        return singleInstance
    }
    
    let userResolver: UserResolver? // 为nil表示是单例
    
    public init(userResolver: UserResolver?) {
        self.userResolver = userResolver
    }
    
    deinit {
        DocsLogger.info("NetConfig deinit: \(ObjectIdentifier(self))")
    }
    
    public var busness: String {
        return SKFoundationConfig.shared.domainFirstValidPath
    }

    private let sessionLock = NSLock()
    var baseUrl: String = ""
    public var userID: String? {
        didSet {
            if let uid = self.userID, uid.count > 2 {
                // 去掉最后两位，相当于做了下加密处理，一般用于日志打印脱敏
                self.encryptUserID = String(uid.prefix(uid.count - 2))
            }
        }
    }
    public var encryptUserID: String?
    public weak var authDelegate: NetworkAuthDelegate?
    private var additionHeader: [String: String] = [:]
    public var currentLang: String = "" // 不带横杆zh
    public var currentLangLocale: String = "" // 带横杆的zh-CN
    public var authToken: String?
    public var docsMainDomain: String?
    private let langCookieHosts: SafeArray<String> = [] + .readWriteLock
    public var needAuthDomains: [String] = []

    static var isPreleaseCCM: Bool = {
        return SKFoundationConfig.shared.preleaseCcmGrayFG
    }()
    static var isPreleaseLark: Bool = {
        return SKFoundationConfig.shared.preleaseLarkGrayFG
    }()
    var preleaseCookieStr: String = {
        let isPreEnv = SKFoundationConfig.shared.isPreReleaseEnv
        var resultStr = "env=pre=0,is_ccm=0,is_lark=0"
        if isPreEnv {
            resultStr = "env=pre=1,is_ccm=1,is_lark=1"
        } else if NetConfig.isPreleaseCCM && NetConfig.isPreleaseLark {
            resultStr = "env=pre=1,is_ccm=1,is_lark=1"
        } else if NetConfig.isPreleaseCCM {
            resultStr = "env=pre=1,is_ccm=1,is_lark=0"
        } else if NetConfig.isPreleaseLark {
            resultStr = "env=pre=0,is_ccm=0,is_lark=1"
        }
        DocsLogger.info("preleaseCookieStr:\(resultStr), isPreEnv=\(isPreEnv)")
        return resultStr
    }()

    private func generateNeteworkSession(isWiFi: Bool) -> NetworkSession {
        spaceAssert(!baseUrl.isEmpty)
        let timeout = isWiFi ? self.timeoutConfig.wifiTimeout : self.timeoutConfig.carrierTimeout
        let ur = self.userResolver ?? Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        let session = NetworkSession(host: self.baseUrl, requestHeader: self.additionHeader, timeoutInterval: timeout, userResolver: ur)
        spaceAssert(authDelegate != nil)
        session.authDelegate = authDelegate
        return session
    }
    private var _carrierDefaultSession: NetworkSession?
    private var carrierDefaultSession: NetworkSession {
        sessionLock.lock()
        defer {
            sessionLock.unlock()
        }
        if _carrierDefaultSession == nil {
            _carrierDefaultSession = generateNeteworkSession(isWiFi: false)
        }
        return _carrierDefaultSession!
    }

    private var _wifiDefaultSession: NetworkSession?
    private var wifiDefaultSession: NetworkSession {
        sessionLock.lock()
        defer {
            sessionLock.unlock()
        }
        if _wifiDefaultSession == nil {
            _wifiDefaultSession = generateNeteworkSession(isWiFi: true)
        }
        return _wifiDefaultSession!
    }
    private var _carrierUploadSession: NetworkSession?
    private var carrierUploadSession: NetworkSession {
        sessionLock.lock()
        defer {
            sessionLock.unlock()
        }
        if _carrierUploadSession == nil {
            _carrierUploadSession = generateNeteworkSession(isWiFi: false)
        }
        return _carrierUploadSession!
    }
    private var _wifiUploadSession: NetworkSession?
    private var wifiUploadSession: NetworkSession {
        sessionLock.lock()
        defer {
            sessionLock.unlock()
        }
        if _wifiUploadSession == nil {
            _wifiUploadSession = generateNeteworkSession(isWiFi: true)
        }
        return _wifiUploadSession!
    }
    private var _carrierFetchSession: NetworkSession?
    private var carrierFetchSession: NetworkSession {
        sessionLock.lock()
        defer {
            sessionLock.unlock()
        }
        if _carrierFetchSession == nil {
            _carrierFetchSession = generateNeteworkSession(isWiFi: false)
        }
        return _carrierFetchSession!
    }
    private var _wifiFetchSession: NetworkSession?
    private var wifiFetchSession: NetworkSession {
        sessionLock.lock()
        defer {
            sessionLock.unlock()
        }
        if _wifiFetchSession == nil {
            _wifiFetchSession = generateNeteworkSession(isWiFi: true)
        }
        return _wifiFetchSession!
    }

    private var _carrierDownloadSession: NetworkSession?
    private var carrierDownloadSession: NetworkSession {
        sessionLock.lock()
        defer {
            sessionLock.unlock()
        }
        if _carrierDownloadSession == nil {
            _carrierDownloadSession = generateNeteworkSession(isWiFi: false)
        }
        return _carrierDownloadSession!
    }
    private var _wifiDownloadSession: NetworkSession?
    private var wifiDownloadSession: NetworkSession {
        sessionLock.lock()
        defer {
            sessionLock.unlock()
        }
        if _wifiDownloadSession == nil {
            _wifiDownloadSession = generateNeteworkSession(isWiFi: true)
        }
        return _wifiDownloadSession!
    }

    private var _carrierPreloadPictureSession: NetworkSession?
    private var carrierPreloadPictureSession: NetworkSession {
        sessionLock.lock()
        defer {
            sessionLock.unlock()
        }
        if _carrierPreloadPictureSession == nil {
            _carrierPreloadPictureSession = generateNeteworkSession(isWiFi: false)
        }
        return _carrierPreloadPictureSession!
    }
    private var _wifiPreloadPictureSession: NetworkSession?
    private var wifiPreloadPictureSession: NetworkSession {
        sessionLock.lock()
        defer {
            sessionLock.unlock()
        }
        if _wifiPreloadPictureSession == nil {
            _wifiPreloadPictureSession = generateNeteworkSession(isWiFi: true)
        }
        return _wifiPreloadPictureSession!
    }

    public var retryCount: UInt = 2
    
    public var timeoutConfig = TimeoutConfig()

    public func configWith(baseURL: String, additionHeader: [String: String]) {
        DocsLogger.info("configWith baseURL=\(baseURL)", component: LogComponents.net)
        self.baseUrl = baseURL
        var headers = additionHeader
        headers.merge(SpaceHttpHeaders.common) { (current, _) -> String in current }
        if SKFoundationConfig.shared.isPreReleaseEnv { 
            headers.merge(other: ["env": "Pre_release"])
        }
        self.additionHeader = headers
    }

    public func updateBaseUrl(_ urlStr: String) {
        DocsLogger.info("urlStr=\(urlStr), baseUrl=\(baseUrl)", component: LogComponents.net)
        guard baseUrl != urlStr else { return }
        baseUrl = urlStr
        cancelRequestsAndReset()
    }

    public func updateDeviceId(_ newDeviceId: String) {
        if additionHeader[DocsCustomHeader.deviceId.rawValue] == newDeviceId {
            DocsLogger.info("new deviceId is same as old", component: LogComponents.net)
            return
        }
        DocsLogger.info("new deviceId is not same as old, reset all", component: LogComponents.net)
        additionHeader[DocsCustomHeader.deviceId.rawValue] = newDeviceId
    }

    public func sessionFor(_ qos: NetConfigQos, trafficType: NetConfigTrafficType = .default) -> NetworkSession {
        var session: NetworkSession
        if DocsNetStateMonitor.shared.accessType == .wifi {
            switch trafficType {
            case .default: session = wifiDefaultSession
            case .upload: session = wifiUploadSession
            case .docsFetch: session = wifiFetchSession
            case .download: session = wifiDownloadSession
            case .preloadPicture: session = wifiPreloadPictureSession
            }
        } else {
            switch trafficType {
            case .default: session = carrierDefaultSession
            case .upload: session = carrierUploadSession
            case .docsFetch: session = carrierFetchSession
            case .download: session = carrierDownloadSession
            case .preloadPicture: session = carrierPreloadPictureSession
            }
        }
        if session.host.isEmpty {
            DocsLogger.info("sessionFor\(trafficType), host is isEmpty", component: LogComponents.net)
            session.host = self.baseUrl
        }
        return session
    }

    public func removeAuthCookie() {
        guard needHandleCookie else {
            DocsLogger.info("在lark里，不需要clear cookie", component: LogComponents.net)
            return
        }
        let agentFrontEndUrl = URL(string: SKFoundationConfig.shared.docsFrontendHost)
        func deleteCookie(for url: URL, name: String) {
            if let deleteCookie = HTTPCookieStorage.shared.cookies(for: url)?.first(where: { (cookie) -> Bool in
                guard let ame = cookie.properties?[HTTPCookiePropertyKey.name] as? String else { return false }
                return ame == name
            }) {
                HTTPCookieStorage.shared.deleteCookie(deleteCookie)
            }
        }

        var urls = Self.legacyUrls
        if agentFrontEndUrl != nil { urls.append(agentFrontEndUrl!) }
        urls.forEach { (url) in
            deleteCookie(for: url, name: "bear-session")
        }

        urls = Self.newUrls
        if agentFrontEndUrl != nil { urls.append(agentFrontEndUrl!) }
        urls.forEach { (url) in
            deleteCookie(for: url, name: "session")
        }
        DocsLogger.info("remove auth cookie", component: LogComponents.net)
    }

    public func setCookie(authToken: String?, docsMainDomain: String?) {
        self.authToken = authToken
        self.docsMainDomain = docsMainDomain
        guard let token = authToken else { return }
        guard needHandleCookie else {
            DocsLogger.info("在lark里，不需要set cookie", component: LogComponents.net)
            return
        }
        let agentFrontEndUrl = URL(string: SKFoundationConfig.shared.docsFrontendHost)
        //种cookie
        var urls = Self.legacyUrls + Self.newUrls
        if agentFrontEndUrl != nil { urls.append(agentFrontEndUrl!) }
        urls.forEach { (url) in
            ["session", "bear-session"].forEach {
                if let cookie = url.cookie(value: token, forName: $0) {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
            }
        }
        var cookieInLog = "default"
        if token.count > 10 {
            cookieInLog = token[0..<10]
        }
        DocsLogger.info("set auth cookie \(cookieInLog)", component: LogComponents.net)
    }

    public func setLanguageCookie(for url: URL?) {
        guard let url = url, let host = url.host else {
            DocsLogger.error("setLanguageCookie, url is isEmpty", component: LogComponents.net)
            return
        }
        guard !langCookieHosts.contains(host) else {
            return
        }
        guard self.currentLang.isEmpty == false else {
            DocsLogger.error("setLanguageCookie, currentLang is isEmpty, host=\(host)", component: LogComponents.net)
            return
        }
        guard let cookieLang = url.cookie(value: self.currentLang, forName: "lang"), let cookieLangLocale = url.cookie(value: self.currentLangLocale, forName: "locale") else {
            spaceAssertionFailure("setLanguageCookie, generate language cookie fail, host=\(host)")
            return
        }
        langCookieHosts.append(host)
        HTTPCookieStorage.shared.setCookie(cookieLang)
        HTTPCookieStorage.shared.setCookie(cookieLangLocale)
        DocsLogger.info("setLanguageCookie, setLangForHost=\(host)", component: LogComponents.net)
    }

    public func cookies() -> [HTTPCookie]? {
        if self.baseUrl.isEmpty {
            DocsLogger.info("cookies, baseUrl is isEmpty", component: LogComponents.net)
            return nil
        } else {
            return wifiDefaultSession.cookies()
        }
    }

    private func sessions() -> [NetworkSession] {
        var array = [NetworkSession]()
        array.addOptional(_wifiDefaultSession)
        array.addOptional(_carrierDefaultSession)
        array.addOptional(_wifiUploadSession)
        array.addOptional(_carrierUploadSession)
        array.addOptional(_wifiFetchSession)
        array.addOptional(_carrierFetchSession)
        return array
    }

    public func cancelRequestsAndReset() {
        sessions().forEach { $0.manager.cancelAllTasks() }
        
        _wifiFetchSession = nil
        _wifiUploadSession = nil
        _wifiDefaultSession = nil
        _carrierFetchSession = nil
        _carrierUploadSession = nil
        _carrierDefaultSession = nil
    }
}

extension Array where Element == NetworkSession {
    mutating func addOptional(_ session: NetworkSession?) {
        if session != nil {
            append(session!)
        }
    }
}

// 网络的配置都放到这里
extension NetConfig {
    // 远程配置
    enum ConfigKey: String {
        case carrierNetworkTimeOut    = "remoteConfigKeyForCarrierNetworkTimeOut"
        case wifiNetworkTimeOut       = "remoteConfigKeyForWifiNetworkTimeOut"
    }
    
    public struct TimeoutConfig {
        public var wifiTimeout: Double {
            get {
                let configTimeOut = CCMKeyValue.globalUserDefault.double(forKey: NetConfig.ConfigKey.wifiNetworkTimeOut.rawValue)
                if configTimeOut > 0, configTimeOut < 200 {
                    return configTimeOut
                }
                return 15
            }
            set {
                CCMKeyValue.globalUserDefault.set(newValue, forKey: NetConfig.ConfigKey.wifiNetworkTimeOut.rawValue)
            }
        }
        public var carrierTimeout: Double {
            get {
                let configTimeOut = CCMKeyValue.globalUserDefault.double(forKey: NetConfig.ConfigKey.carrierNetworkTimeOut.rawValue)
                if configTimeOut > 0, configTimeOut < 200 {
                    return configTimeOut
                }
                return 30
            }
            set {
                CCMKeyValue.globalUserDefault.set(newValue, forKey: NetConfig.ConfigKey.carrierNetworkTimeOut.rawValue)
            }
        }
    }

    public func resetDomain() {
        langCookieHosts.removeAll()
        SKFoundationConfig.shared.resetNetConfigDomain()
    }
    
    public func resetWKProcessPool() {
        resetSharedWKProcessPool()
    }

}

extension NetConfig {
    // 此处暂时不用适配KA，等具体的域名
    // Docs App 内处理cookie用的，暂时不用改，待测试
    static let legacyUrls = ["https://bear-test.bytedance.net", "https://docs-staging.bytedance.net", "https://docs.bytedance.net"].map { URL(string: $0)! }
    static let newUrls = ["https://.feishu.cn", "https://.larksuite.com", "https://.feishu-staging.cn", "https://.larksuite-staging.com", "https://.feishu-boe.cn", "https://.larksuite-boe.com"].map { URL(string: $0)! }
    var needHandleCookie: Bool {
        return SKFoundationConfig.shared.isInDocsApp || SKFoundationConfig.shared.isInLarkDocsApp
    }
}
