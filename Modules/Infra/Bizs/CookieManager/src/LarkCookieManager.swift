//
//  LarkCookieManager.swift
//  Lark
//
//  Created by 齐鸿烨 on 2017/5/20.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import WebKit
import LKCommonsLogging
import LarkAppConfig
import RxSwift
import Swinject
import LarkAccountInterface
import LarkExtensions
import LarkFeatureGating
import LarkSetting
import LarkContainer

extension String {
    public static let defaultMaskPadding: Int = 2
    public static let defaultMaskPad: Character = "*"
    public static let defaultMaskExcept: [Character] = ["*", "_", "-"]

    /// 字符串掩码脱敏
    /// 将任意字符串转换为掩码脱敏，尽可能不泄漏信息的前提下，暴露信息用于问题排查。
    /// 例如：
    /// "123456789" => "12*****89"
    /// "MONITOR_WEB_ID" => "MO*****_***_ID"
    /// "_ga" => "_**"
    /// "_hjid" => "_h**d"
    /// "rutland-session" => "ru*****-*****on"
    ///
    /// - Parameters:
    ///   - padding: 前后保留字符长度, 如果长度较短时优先使用掩码策略
    ///   - pad: 掩码
    ///   - except: 忽略字符
    /// - Returns: 替换掩码后的字符串
    public func cookie_mask(
        padding: Int = String.defaultMaskPadding,
        pad: Character = String.defaultMaskPad,
        except: [Character] = String.defaultMaskExcept
    ) -> String {
        if self.isEmpty {
            return ""
        } else if self.count == 1 {
            return "*"
        } else if self.count == 2 {
            return "**"
        } else if self.count == 3 {
            let prefixIndex = String.Index(encodedOffset: 1)
            let suffixIndex = String.Index(encodedOffset: 2)
            let maskRange = prefixIndex ..< suffixIndex
            return self.replacingCharacters(in: maskRange, with: "*")
        } else {
            var padding = Int(floor(Double(self.count / 4)))
            var length = self.count - padding * 2
            let toIndex = String.Index(encodedOffset: padding)
            let fromIndex = String.Index(encodedOffset: padding + length)
            return self.substring(to: toIndex) + "***" + self.substring(from: fromIndex)
        }
    }
}


public final class LarkCookieManager {
    public static let shared = LarkCookieManager()

    public static let logger = Logger.log(LarkCookieManager.self, category: "CookieManager")

    private let cookieStorage: HTTPCookieStorage = .shared

    public static let sessionName = "session"
    public static let openSessionName = "osession"
    public static let bearSessionName = "bear-session"

    public let cnTopLevelDomain = ".cn"

    @FeatureGating("cookiewithdot")
    private var cookieWithDotEnable: Bool

    lazy var cookieExpiresDate: Date = {
        if let oneYearAfter = Calendar.current.date(byAdding: .year, value: 1, to: Date()) {
            return oneYearAfter
        }
        let year = Calendar.autoupdatingCurrent.component(.year, from: Date())
        return self.date(year: year + 2, month: 1, day: 1)
    }()

    private var cookies: [HTTPCookie] {
        return cookieStorage.cookies ?? []
    }

    private let appConfig: AppConfiguration

    private init() {
        self.appConfig = ConfigurationManager.shared
        LarkCookieDoctor.shared.setup()
        _ = LarkCookieInstrument.shared

        DomainSettingManager.shared.registerDomainPreUpdateHandler(whitPriority: 100) {
            [weak self] (new, old) in
            guard let self = self else { return }
            guard let passportService = try? Container.shared.resolve(assert: PassportService.self) else {
                Self.logger.warn("[CookieManager] disable pre plant - no service")
                return
            }
            guard passportService.foregroundUser?.tenant.isByteDancer ?? false else {
                Self.logger.warn("[CookieManager] disable pre plant - not byte")
                return
            }
            let enable = (try? SettingManager.shared.setting(with: CookieManagerFeatureConfig.self).enablePlantingCookieWhenDomainPreUpdate) ?? false
            guard enable else {
                Self.logger.warn("[CookieManager] disable pre plant - switch off")
                return
            }
            if Thread.isMainThread {
                self.plantCookieWhenSettingsWillUpdate(new: new, old: old)
            } else {
                // 同步到主线程执行
                DispatchQueue.main.sync {
                    self.plantCookieWhenSettingsWillUpdate(new: new, old: old)
                }
            }
        }
    }

    /// 修复私有化4.10版本覆盖升级安装，cookie中CN顶级域名session值过期导致需要退出重新登录问题
    /// https://bytedance.feishu.cn/wiki/wikcntfKoTQiy7K5aF2jfLgSjoh
    public func clearDirtyCookie() {
        if FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.cookie.clearcntoplevel.disable")) {
            LarkCookieManager.logger.info("cookie ===>>> skip clear cntoplevel cookie when disable fg is open")
            return
        }
        LarkCookieManager.logger.info("cookie ===>>> start clear dirty cookie")
        for cookie in (cookieStorage.cookies ?? []) {
            let padding = max(1, (Int(cookie.value.count / 4)))
            let clipValue = cookie.value.cookie_mask(padding: padding)
            if cookie.domain == cnTopLevelDomain {
                LarkCookieManager.logger.info("cookie ===>>> delete cn top level domain cookie, doamin:\(cookie.domain), path:\(cookie.path), name:\(cookie.name),value:\(clipValue)")

                LarkCookieDoctor.shared.performCookieStorageOperation {
                    cookieStorage.deleteCookie(cookie)
                }

            } else {
                LarkCookieManager.logger.info("cookie ===>>> print cookie, doamin:\(cookie.domain), path:\(cookie.path), name:\(cookie.name),value:\(clipValue)")
            }
        }

        let wkStorage = WKWebsiteDataStore.default()
        wkStorage.fetchDataRecords(ofTypes: [
            WKWebsiteDataTypeCookies
        ]) { (records) in
            LarkCookieManager.logger.info("cookie ===>>> fetched cookie records \(records.count)")
            if !records.isEmpty {
                var completionCount = 0
                for record in records where record.displayName == self.cnTopLevelDomain {
                    LarkCookieManager.logger.info("cookie ===>>> WKWebsiteDataStore clear cn top level dirty cookie:\(record.displayName) done, datatypes:\(record.dataTypes)")
                    wkStorage.removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {
                        LarkCookieManager.logger.info("cookie ===>>> WKWebsiteDataStore clear cn top level dirty cookie: \(record.displayName) done")
                    })
                }
            }
        }
    }

    public func clearCookie(_ completion: (() -> Void)?) {
        LarkCookieManager.logger.info("cookie ===>>> start clear cookie")
        for cookie in (cookieStorage.cookies ?? []) {
            LarkCookieDoctor.shared.performCookieStorageOperation {
                cookieStorage.deleteCookie(cookie)
            }
        }

        let wkStorage = WKWebsiteDataStore.default()
        wkStorage.fetchDataRecords(ofTypes: [
            WKWebsiteDataTypeCookies
        ]) { (records) in
            LarkCookieManager.logger.info("cookie ===>>> fetched cookie records \(records.count)")
            if records.isEmpty {
                completion?()
            } else {
                var completionCount = 0
                for record in records {
                    wkStorage.removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {
                        LarkCookieManager.logger.info("cookie ===>>> WKWebsiteDataStore clear \(record.displayName) done.")
                        completionCount += 1
                        if completionCount == records.count {
                            completion?()
                        }
                    })
                }
            }
        }
    }

    func setCookie(cookie: HTTPCookie) {
        LarkCookieDoctor.shared.performCookieStorageOperation {
            cookieStorage.setCookie(cookie)
        }
        DispatchQueue.main.async {
            WKWebsiteDataStore.default().httpCookieStore.setCookie(cookie, completionHandler: nil)
        }
    }

    /// 对外暴露构建larkcookie的方法，domains缺省为Lark cookieDomains
    public func buildLarkCookies(session: String, domains: [String]?) -> [String: [HTTPCookie]] {
        var domains = domains ?? appConfig.cookieDomains
        if cookieWithDotEnable {
            let domainsWithDot = domains.compactMap { domain -> String? in
                if domain.first != "." {
                    return "." + domain
                }
                return nil
            }
            domains += domainsWithDot
        }
        LarkCookieManager.logger.info(
            "cookie ===>>> build cookies with dot enable: \(cookieWithDotEnable), with domains: [\(domains.joined(separator: ","))]"
        )

        return domains.reduce([:]) { res, domain in
            let allCookieProperties: [[HTTPCookiePropertyKey: Any]] = [
                genCookieProperties(
                    domain: domain, name: Self.sessionName, value: session
                ),
                genCookieProperties(
                    domain: domain, name: Self.openSessionName, value: session
                ),
                genCookieProperties(
                    domain: domain, name: Self.bearSessionName, value: session
                )
            ]
            var res = res
            res[domain] = allCookieProperties.compactMap({ HTTPCookie(properties: $0) })
            return res
        }
    }

    public func getCookies(url: URL?) -> [HTTPCookie] {
        if url == nil {
            return cookies
        }
        return cookieStorage.cookies(for: url!) ?? []
    }

    public func processRequest(_ request: URLRequest) -> URLRequest {
        guard let url = request.url else { return request }

        // fix bug：Lark会向feishu.cn种cookie，然后会被恶意伪造的比如"http://my.feishu.cn"获取到种的cookie；
        //          目前cookie是向二级域名种的，所以可以被恶意伪造的三级域名获取cookie。
        // 解决思路：首先我们排除https情况（因为https安全），所以我们对于我们飞书的domin，如果是非https方式的url，则不设置cookie
        let isLarkDomain = self.appConfig.mainDomains.contains(where: { (url.host ?? "").contains($0) })
        if isLarkDomain, (url.scheme ?? "") != "https" {
            return request
        }

        var request = request
        var headers: [String: String] = request.allHTTPHeaderFields ?? [:]
        var cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
        cookies = (cookieStorage.cookies(for: url) ?? []).lf_unique()
        let cookieString = cookies
            .map { "\($0.name)=\($0.value)" }
            .joined(separator: ";")
        headers["Cookie"] = cookieString
        request.allHTTPHeaderFields = headers
        return request
    }

    /// SetCookie to HTTPCookieStorage
    @discardableResult
    public func plantCookie(token: String) -> Bool {
        var result: Bool = true
        appConfig.cookieDomains.forEach { (domain) in
            result = self.plantCookie(token: token, domain: ".\(domain)") && result
        }

        return result
    }

    @discardableResult
    public func plantCookie(token: String, name: String) -> Bool {
        var result: Bool = true
        appConfig.cookieDomains.forEach { [weak self] (domain) in
            guard let self = self else { return }
            result = self.plantCookie(token: token, domain: ".\(domain)", name: name) && result
        }
        return result
    }

    public func plantCookies(_ tokens: [String: [String: String]]) {
        tokens.forEach { (arg0) in
            let (domain, value) = arg0
            if let name = value["name"],
                let session = value["value"] {
                plantCookie(token: session, domain: ".\(domain)", name: name)
            }
        }
    }

    @discardableResult
    private func plantCookie(token: String, domain: String, name: String) -> Bool {
        let properties: [HTTPCookiePropertyKey: Any] = genCookieProperties(domain: domain, name: name, value: token)
        if let cookie = HTTPCookie(properties: properties) {
            self.setCookie(cookie: cookie)
            let padding = max(1, (Int(token.count / 4)))
            let clipToken = token.cookie_mask(padding: padding)
            LarkCookieManager.logger.info("cookie ===>>> SetCookie To HTTPCookieStorage For \(domain), expired date=\(self.cookieExpiresDate),name= \(name) session=\(clipToken)")
            return true
        }
        LarkCookieManager.logger.info("cookie ===>>> unable to plant cookie")

        return false
    }

    @inline(__always)
    private func isCookieMatchDomain(_ cookie: HTTPCookie, _ domain: String) -> Bool {
        return cookie.domain.hasSuffix(domain)
    }

    private func plantCookie(token: String, domain: String) -> Bool {
        // 与lark server的请求都走rust-sdk，CookieStorage中的cookie不会续期，
        // 所以设置expire date到2100-1-1，相当于忽略本地expire date的检测
        if token.isEmpty { LarkCookieManager.logger.error("cookie ===>>> \(Self.sessionName) is empty") }

        let properties: [HTTPCookiePropertyKey: Any] = genCookieProperties(
            domain: domain, name: Self.sessionName, value: token
        )

        let osessionProperties: [HTTPCookiePropertyKey: Any] = genCookieProperties(
            domain: domain, name: Self.openSessionName, value: token
        )

        let bsessionProperties: [HTTPCookiePropertyKey: Any] = genCookieProperties(
            domain: domain, name: Self.bearSessionName, value: token
        )

        if let cookie = HTTPCookie(properties: properties),
            let osessionCookie = HTTPCookie(properties: osessionProperties),
            let bsessionCookie = HTTPCookie(properties: bsessionProperties) {
            let cookieNameSet = Set<String>([Self.sessionName, Self.openSessionName, Self.bearSessionName])
            for cookie in (cookieStorage.cookies ?? []) where cookieNameSet.contains(cookie.name) && isCookieMatchDomain(cookie, domain) {
                let padding = max(1, (Int(cookie.value.count / 4)))
                let clipValue = cookie.value.cookie_mask(padding: padding)
                LarkCookieManager.logger.info("cookie ===>>> delete cookie before set domain= \(cookie.domain), name= \(cookie.name) value = \(clipValue)")
                LarkCookieDoctor.shared.performCookieStorageOperation {
                    cookieStorage.deleteCookie(cookie)
                }
            }
            self.setCookie(cookie: cookie)
            self.setCookie(cookie: osessionCookie)
            self.setCookie(cookie: bsessionCookie)
            let padding = max(1, (Int(token.count / 4)))
            let clipToken = token.cookie_mask(padding: padding)
            LarkCookieManager.logger.info("cookie ===>>> SetCookie To HTTPCookieStorage For \(domain), expired date=\(self.cookieExpiresDate), session value=\(clipToken)")

            return true
        }
        LarkCookieManager.logger.info("cookie ===>>> unable to plant cookie")

        return false
    }

    // 为了拆出对LarkCore的依赖，Copy自 DateToolsSwift
    private func date(year: Int, month: Int, day: Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0

        return Calendar.current.date(from: dateComponents) ?? Date()
    }

    private func genCookieProperties(domain: String, name: String, value: String) -> [HTTPCookiePropertyKey: Any] {
        [
            .name: name,
            .value: value,
            .path: "/",
            .domain: domain,
            .expires: self.cookieExpiresDate,
            HTTPCookiePropertyKey(rawValue: "HttpOnly"): "YES",
            .secure: "TRUE"
        ]
    }

    // MARK: - Cookie Doctor Usage

    internal func generateAppConfigCookies(session: String) -> [HTTPCookie] {
        let domains = appConfig.cookieDomains.map {
            $0.hasPrefix(".") ? $0 : ".\($0)"
        }
        let names = [Self.sessionName, Self.openSessionName, Self.bearSessionName]

        var result = [HTTPCookie]()
        domains.forEach { domain in
            names.forEach { name in
                if let cookie = generateCookie(domain: domain, name: name, session: session) {
                    result.append(cookie)
                }
            }
        }
        return result
    }

    /**
     根据 Passport 服务端返回的数据格式组装 cookie
     e.g.
     {
     "larksuite.com": {
     "name": "session",
     "value": "XN0YXJO-blabla"
     }
     }
     */
    internal func generatePassportKeyValueCookies(sessionKeyWithDomains: [String: [String: String]]) -> [HTTPCookie] {
        var result = [HTTPCookie]()
        sessionKeyWithDomains.forEach { item in
            let (domain, payload) = item
            if let name = payload["name"],
               let value = payload["value"],
               let cookie = generateCookie(domain: domain, name: name, session: value) {
                result.append(cookie)
            }
        }
        return result
    }

    private func generateCookie(domain: String, name: String, session: String) -> HTTPCookie? {
        let props = genCookieProperties(domain: domain, name: name, value: session)
        return HTTPCookie(properties: props)
    }

    /// 周期性补种 cookie timer
    private var timer: DispatchSourceTimer?
    /// 周期性补种 cookie 的间隔，单位秒
    private var scheduleCookiePlantingInterval: Int {
        if let seconds = try? SettingManager.shared.setting(with: Int.self,
                                                            key: UserSettingKey.make(userKeyLiteral: "passport_cookie_scheduled_backup_interval")) {
            return seconds
        }
        Self.logger.warn("[CookieManager] backup: cannot fetch setting")
        return 60
    }
    private let timerQueue = DispatchQueue(label: "com.larksuite.Infra.LarkCookieManager.background", qos: .background)
    private var timerIsSuspended: Bool = true
}

extension LarkCookieManager {

    private func scheduleCookiePlantingBackup() {
        timer = DispatchSource.makeTimerSource(queue: timerQueue)
        guard let timer = timer else { return }
        Self.logger.info("[CookieManager] backup: schedule cookie backup timer")
        timer.schedule(deadline: .now(), repeating: .seconds(self.scheduleCookiePlantingInterval), leeway: .seconds(5))
        timer.setEventHandler(handler: { [weak self] in
            guard let self else { return }
            self.plantCookieWithoutRemovingPrevious()
        })
        resumeTimer()
    }

    /// 在不执行 delete 前提下 setCookie，目前只用于定时补种
    private func plantCookieWithoutRemovingPrevious() {
        guard let passportService = try? Container.shared.resolve(assert: PassportService.self),
              let token = passportService.foregroundUser?.sessionKey,
              !token.isEmpty else { return }
        Self.logger.info("[CookieManager] backup: try make cookie backup")
        var domains = appConfig.cookieDomains
        if let pCookieDomains = DomainSettingManager.shared.currentSetting[.passportCookie], !pCookieDomains.isEmpty {
            domains.append(contentsOf: pCookieDomains)
        }
        domains = Array(Set(domains))
        domains.forEach { domain in
            self.plantCookieWithoutRemovingPrevious(token: token, domain: domain.hasPrefix(".") ? domain : ".\(domain)")
        }
    }

    private func plantCookieWithoutRemovingPrevious(token: String, domain: String) {
        if token.isEmpty || domain.isEmpty {
            Self.logger.error("[CookieManager] backup: token or domain is empty")
            return
        }

        let properties: [HTTPCookiePropertyKey: Any] = genCookieProperties(
            domain: domain, name: Self.sessionName, value: token
        )
        let osessionProperties: [HTTPCookiePropertyKey: Any] = genCookieProperties(
            domain: domain, name: Self.openSessionName, value: token
        )
        let bsessionProperties: [HTTPCookiePropertyKey: Any] = genCookieProperties(
            domain: domain, name: Self.bearSessionName, value: token
        )

        guard let cookie = HTTPCookie(properties: properties),
              let osessionCookie = HTTPCookie(properties: osessionProperties),
              let bsessionCookie = HTTPCookie(properties: bsessionProperties) else {
            Self.logger.error("[CookieManager] backup: session cookies init error")
            return
        }

        let current = cookieStorage.cookies ?? []
        if !current.includes(cookie) {
            Self.logger.warn("[CookieManager] backup: did work. set session cookie \(domain)")
            LarkCookieDoctor.shared.performCookieStorageOperation {
                cookieStorage.setCookie(cookie)
            }
        }
        if !current.includes(osessionCookie) {
            Self.logger.warn("[CookieManager] backup: did work. set O-session cookie \(domain)")
            LarkCookieDoctor.shared.performCookieStorageOperation {
                cookieStorage.setCookie(cookie)
            }
        }
        if !current.includes(bsessionCookie) {
            Self.logger.warn("[CookieManager] backup: did work. set BEAR-session cookie \(domain)")
            LarkCookieDoctor.shared.performCookieStorageOperation {
                cookieStorage.setCookie(cookie)
            }
        }
    }

    func suspendTimer() {
        timerQueue.async {
            guard let timer = self.timer, !self.timerIsSuspended else { return }
            Self.logger.info("[CookieManager] backup: timer suspended")
            timer.suspend()
            self.timerIsSuspended = true
        }
    }

    func resumeTimer() {
        timerQueue.async {
            if let timer = self.timer {
                guard self.timerIsSuspended else { return }
                Self.logger.info("[CookieManager] backup: timer resumed")
                timer.resume()
                self.timerIsSuspended = false
            } else {
                // 冷启动时初始化 timer
                if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "lark.cookie_manager.cookie_scheduled_backup")) {
                    Self.logger.info("[CookieManager] backup: FG on")
                    self.scheduleCookiePlantingBackup()
                } else {
                    Self.logger.warn("[CookieManager] backup: FG off")
                }
            }
        }
    }
}

extension LarkCookieManager {
    /// 用于 Settings 更新前补种新域名 cookie
    /// larkoffice.com 域名替换项目引入
    private func plantCookieWhenSettingsWillUpdate(new: DomainSetting, old: DomainSetting) {
        do {
            // 只补种新增域名
            let domains = difference(from: (new[.suiteMainDomain] ?? []), to: (old[.suiteMainDomain] ?? []))
            guard !domains.isEmpty else {
                Self.logger.warn("[CookieManager] no added main domains")
                return
            }
            let passportService = try Container.shared.resolve(assert: PassportService.self)
            guard let sessionKey = passportService.foregroundUser?.sessionKey else {
                Self.logger.warn("[CookieManager] no foreground user")
                return
            }
            Self.logger.info("[CookieManager] plant cookie when settings updated")
            domains.forEach { domain in
                let dotDomain = domain.hasPrefix(".") ? domain : ".\(domain)"
                _ = plantCookie(token: sessionKey, domain: dotDomain)
            }
        } catch {
            Self.logger.error("[CookieManager] cannot resolve passport service")
        }
    }

    /// 找到只有`from`中才有的元素
    /// let from = ["student", "class", "teacher"]
    /// let to = ["class", "teacher", "classroom"]
    /// Output: ["student"]
    private func difference(from: [String], to: [String]) -> [String] {
        if from.isEmpty || to.isEmpty { return from }
        let fromSet = Set(from)
        let toSet = Set(to)
        let unique = Array(fromSet.symmetricDifference(toSet))
        return from.filter { unique.contains($0) }
    }
}

public final class CookieServiceDelegate: LauncherDelegate, PassportDelegate {
    public let name: String = "Cookie"

    private static let logger = Logger.log(CookieServiceDelegate.self, category: "LarkAccount.CookieServiceDelegate")

    private lazy var cookieService = LarkCookieManager.shared

    private var disposeBag = DisposeBag()

    private let resolver: Resolver

    public init(resolver: Resolver) {
        self.resolver = resolver
    }

    public func afterLogout(_ context: LauncherContext) {
        cookieService.clearCookie(nil)
    }

    public func userDidOffline(state: PassportState) {
        cookieService.suspendTimer()
        cookieService.clearCookie(nil)
    }

    public func userDidOnline(state: PassportState) {
        cookieService.resumeTimer()
    }
}

struct CookieManagerFeatureConfig: SettingDecodable {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "cookie_manager_feat_config")
    let enablePlantingCookieWhenDomainPreUpdate: Bool
}

internal extension Array where Element == HTTPCookie {
    func includes(_ cookie: HTTPCookie) -> Bool {
        let result = self.filter { $0.name == cookie.name && $0.domain == cookie.domain }
        return !result.isEmpty
    }
}
