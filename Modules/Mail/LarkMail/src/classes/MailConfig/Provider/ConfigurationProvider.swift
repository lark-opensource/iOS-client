//
//  ConfigurationProvider.swift
//  LarkMail
//
//  Created by tefeng liu on 2019/10/9.
//

import Foundation
import MailSDK
import Swinject
import RxSwift
import RustPB
import LarkSDKInterface
import LarkAppConfig
import LarkEnv
import LarkAccountInterface
import LarkContainer

class ConfigurationProvider: MailSDK.ConfigurationProxy {
    private var configurationAPI: ConfigurationAPI? {
        return try? resolver.resolve(assert: ConfigurationAPI.self)
    }
    private var configrationManager: AppConfiguration? {
        return try? resolver.resolve(assert: AppConfiguration.self)
    }
    private var timeSettingService: TimeFormatSettingService? {
        return try? resolver.resolve(assert: TimeFormatSettingService.self)
    }

    private let resolver: UserResolver

    private var userServiece: PassportUserService? {
        try? resolver.resolve(assert: PassportUserService.self)
    }

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func getAndReviseBadgeStyle() -> (Observable<RustPB.Settings_V1_BadgeStyle>, Observable<RustPB.Settings_V1_BadgeStyle>) {
        guard let api = configurationAPI else {
            assert(false, "this shouldnt happen!")
            return (Observable.empty(), Observable.empty())
        }
        return api.getAndReviseBadgeStyle()
    }

    func getDomainSetting(key: InitSettingKey) -> [String] {
        guard let manager = configrationManager else {
            return []
        }
        return manager.settings[key] ?? []
    }

    /// 获取是否24小时制
    var is24HourTime: Bool {
        return timeSettingService?.is24HourTime ?? false
    }

    var isFeishuBrand: Bool {
        return userServiece?.isFeishuBrand == true
    }
}
