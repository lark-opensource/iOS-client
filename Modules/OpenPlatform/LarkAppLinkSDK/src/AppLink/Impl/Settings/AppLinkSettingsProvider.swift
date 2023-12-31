//
//  AppLinkSettingsProvider.swift
//  LarkAppLinkSDK
//
//  Created by yinyuan on 2021/3/29.
//

import Foundation
import RustPB
import Swinject
import LarkRustClient
import LKCommonsLogging
import ECOProbe
import RxSwift
import LarkContainer
import ECOInfra
import LarkSetting

private let logger = Logger.oplog(AppLinkSettingsProvider.self)

/// AppLinkSettings 信息提供
class AppLinkSettingsProvider {
    
    private let resolver: Resolver
    private let disposeBag = DisposeBag()
    @LazyRawSetting(key: UserSettingKey.make(userKeyLiteral: "key_open_app_link_config")) private var appLinkSettingDic: [String: Any]?
    
    private var parseTimeout: Double?
    @LazyRawSetting(key: UserSettingKey.make(userKeyLiteral: "short_applink_to_long_applink")) private var appLinkParseTimeoutDic: [String: Any]?
    
    private var appLinkSettings: AppLinkSettings?
    
    init(resolver: Resolver) {
        self.resolver = resolver
    }
    
    func getApplinkParseTimeout() -> Double {
        if let parseTimeout = parseTimeout {
            logger.info("ApplinkConfig: use cache setting")
            return Double(parseTimeout / 1_000.0)
        }
        logger.info("ApplinkConfig: setting key:\(String(describing: appLinkParseTimeoutDic?.keys))")
        var timeout = appLinkParseTimeoutDic?["net_timeout"] as? Double ?? 500
        self.parseTimeout = timeout
        return Double(timeout / 1_000.0)
    }
    
    func fetchAppLinkSettings() -> AppLinkSettings {
        if let appLinkSettings = appLinkSettings {
            logger.info("AppLinkSettingsProvider: use cache setting")
            return appLinkSettings
        }
        logger.info("AppLinkSettingsProvider: setting key:\(String(describing: appLinkSettingDic?.keys))")
        var supportedPathsRemote: [String] = appLinkSettingDic?["paths"] as? [String] ?? []
        var supportedRegDomainsRemote: [String] = []
        if let hosts = appLinkSettingDic?["hosts"] as? [String: Any], let reg_exp = hosts["reg_exp"] as? [String] {
            logger.info("AppLinkSettingsProvider: setup reg_exp")
            supportedRegDomainsRemote = reg_exp
        }

        let appLinkSettings = AppLinkSettings(
            supportedPathsRemote: supportedPathsRemote,
            supportedRegDomainsRemote: supportedRegDomainsRemote
        )
        self.appLinkSettings = appLinkSettings
        return appLinkSettings
    }
}
