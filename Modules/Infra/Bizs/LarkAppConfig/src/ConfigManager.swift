//
//  ConfigManager.swift
//
//
//  Created by 李晨 on 2019/11/14.
//

import Foundation
import RxSwift
import RxRelay
import LarkReleaseConfig
import LKCommonsLogging
import AppContainer
import LarkPerf
import LarkEnv
import LarkSetting
import EEAtomic
import LarkCombine

public final class ConfigurationManager: AppConfiguration {
    private static let logger = Logger.log(ConfigurationManager.self, category: "configuration.manager")
    private var anyCancellable = Set<AnyCancellable>()
    private var extraCookieDomainAliases = Set<DomainKey>()
    private let cookieDomainLock = DispatchSemaphore(value: 1)

    // swiftlint:disable identifier_name
    internal lazy var _envSubjectV2 = BehaviorRelay<Env>(value: EnvManager.env)
    public var envSignalV2: Observable<Env> { return _envSubjectV2.asObservable() }
    // swiftlint:enable identifier_name
    /// shared instance
    public static let shared: ConfigurationManager = ConfigurationManager()

    /// prifix
    public var larkPrefix: String = ""
    public var h5JSSDKPrefix: String = ""

    /// domain
    public var mainDomains: [String] { DomainSettingManager.shared.currentSetting[.suiteMainDomain] ?? [] }
    public var mainDomain: String {
        if let mainDomain = self.mainDomains.first {
            return mainDomain
        }
        assertionFailure()
        return ""
    }

    public var cookieDomains: [String] {
        cookieDomainLock.wait()
        let extraCookieDomainAliases = self.extraCookieDomainAliases
        cookieDomainLock.signal()
        let mainDomains = self.mainDomains
        var cookieDomains = mainDomains
        let domainSettings = DomainSettingManager.shared.currentSetting
        let extraCookieDomains = extraCookieDomainAliases.compactMap { domainSettings[$0]?.first }
        cookieDomains.append(contentsOf: extraCookieDomains)
        ConfigurationManager.logger.info("""
            get cookieDomains mainDomains: \(mainDomains) \
            extraCookieDomains: \(extraCookieDomains) \
            extraCookieDomainAliases: \(extraCookieDomainAliases)
            """)
        return Array(Set(cookieDomains))
    }

    public func register(cookieDomainAlias: DomainKey) {
        cookieDomainLock.wait()
        defer {
            cookieDomainLock.signal()
        }
        ConfigurationManager.logger.info("register cookieDomainAlias: \(cookieDomainAlias)")
        extraCookieDomainAliases.insert(cookieDomainAlias)
    }

    public func unregister(cookieDomainAlias: DomainKey) {
        cookieDomainLock.wait()
        defer {
            cookieDomainLock.signal()
        }
        ConfigurationManager.logger.info("remove cookieDomainAlias: \(cookieDomainAlias)")
        extraCookieDomainAliases.remove(cookieDomainAlias)
    }

    public init() {
        AppStartupMonitor.shared.start(key: .initDomain)
        self.updateDomain(settings: DomainSettingManager.shared.currentSetting)
        self.observeDomain()
        AppStartupMonitor.shared.end(key: .initDomain)
    }

    public func switchEnv(_ env: Env) {
        self.updateDomain(settings: DomainSettingManager.shared.currentSetting)
    }

    private func updateDomain(settings: DomainSettingsMap) {
        if let api = settings[.api]?.first {
            self.larkPrefix = "https://\(api)"
        }
        /// 武汉特化逻辑
        if !EnvManager.env.isChinaMainlandGeo {
            if let api = settings[.internalApi]?.first { self.h5JSSDKPrefix = "https://\(api)/lark" }
        } else {
            if let mina = settings[.mina]?.first {
                self.h5JSSDKPrefix = "https://\(mina)"
            }
        }
    }

    private func observeDomain() {
        DomainSettingManager.shared.domainCombineSubjectPublisher.sink(
            receiveValue: { [weak self] in
                guard let self = self else { return }
                self.updateDomain(settings: DomainSettingManager.shared.currentSetting)
            }).store(in: &anyCancellable)
    }

    @available(*, deprecated, message: "Please use DomainSettingManager.shared.currentSetting, will remove")
    public var domainSettings: DomainSettingsMap { DomainSettingManager.shared.currentSetting }

    @available(*, deprecated, message: "Please use DomainSettingManager.shared.currentSetting, will remove")
    public var settings: [InitSettingKey: [String]] { return domainSettings }
}
