//
//  TimeZoneModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/7/6.
//

import Foundation
import RxSwift
import LarkContainer
import LarkOpenSetting
import EENavigator
import RustPB
import LarkSetting
import LarkSDKInterface
import LarkSettingUI
import LarkMessengerInterface

typealias TimeZoneSetting = RustPB.Settings_V1_ExternalDisplayTimezoneSetting

let timeZoneEntryModuleProvider: ModuleProvider = { userResolver in
    guard let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self) else { return nil }
    guard featureGatingService.staticFeatureGatingValue(with: "messenger.chat.usertimezone") &&
            featureGatingService.staticFeatureGatingValue(with: "im.setting.external_display_timezone") else { return nil }
    return TimeZoneEntryModule(userResolver: userResolver)
}

final class TimeZoneEntryModule: BaseModule {
    private var configAPI: ConfigurationAPI?
    private var pushCenter: PushNotificationCenter?

    private var timeZoneSetting = TimeZoneSetting()

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        self.configAPI = try? self.userResolver.resolve(assert: ConfigurationAPI.self)
        self.pushCenter = try? userResolver.userPushCenter
        self.configAPI?.getExternalDisplayTimezone()
            .subscribe(onNext: { [weak self] res in
                self?.timeZoneSetting = res
                self?.context?.reload()
            }).disposed(by: self.disposeBag)
        pushCenter?.observable(for: RustPB.Settings_V1_PushUserSetting.self)
            .map { $0.externalDisplayTimezone }
            .subscribe(onNext: { [weak self] res in
                self?.timeZoneSetting = res
                self?.context?.reload()
            }).disposed(by: self.disposeBag)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        let timeZoneDescription: String
        if timeZoneSetting.hasTimezone, timeZoneSetting.type != .hidden {
            if let timeZone = TimeZone(identifier: timeZoneSetting.timezone),
                let localizedName = timeZone.localizedName(for: .standard, locale: NSLocale.current),
                !localizedName.isEmpty {
                timeZoneDescription = localizedName
            } else {
                timeZoneDescription = "GMT\(timeZoneSetting.timezoneOffset > 0 ? "+" : "")\(timeZoneSetting.timezoneOffset / 3600):\(abs(timeZoneSetting.timezoneOffset) % 3600 / 60)"
            }
        } else {
            timeZoneDescription = ""
        }
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_IM_PrivacySettings_TimeZoneDisplay_Title,
                                  accessories: [.text(timeZoneDescription, spacing: 4), .arrow()]) { [weak self] _ in
            guard let from = self?.context?.vc else { return }
            self?.userResolver.navigator.push(body: ShowTimeZoneWithOtherBody(), from: from)
        }
        return SectionProp(items: [item], footer: .title(BundleI18n.LarkMine.Lark_IM_PrivacySettings_TimeZoneDisplay_Desc))
    }
}

final class TimeZoneSettingModule: BaseModule {
    private var configAPI: ConfigurationAPI?
    private var pushCenter: PushNotificationCenter?
    private var dependency: MineDependency?

    private var timeZoneSetting: TimeZoneSetting

    init(userResolver: UserResolver,
        timeZoneSetting: TimeZoneSetting) {
        self.timeZoneSetting = timeZoneSetting
        super.init(userResolver: userResolver)
        self.configAPI = try? self.userResolver.resolve(assert: ConfigurationAPI.self)
        self.pushCenter = try? self.userResolver.userPushCenter
        self.dependency = try? self.userResolver.resolve(assert: MineDependency.self)
        pushCenter?.observable(for: RustPB.Settings_V1_PushUserSetting.self)
            .map { $0.externalDisplayTimezone }
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                self.timeZoneSetting = res
                self.context?.reload()
                SettingLoggerService.logger(.module(self.key)).info("api/push/setting: \(timeZoneSetting)")
            }).disposed(by: self.disposeBag)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        let timeZoneDescription: String
        if timeZoneSetting.hasTimezone {
            if let timeZone = TimeZone(identifier: timeZoneSetting.timezone),
                let localizedName = timeZone.localizedName(for: .standard, locale: NSLocale.current),
                !localizedName.isEmpty {
                SettingLoggerService.logger(.module(self.key)).info("use timeZone")
                timeZoneDescription = localizedName
            } else {
                SettingLoggerService.logger(.module(self.key)).info("use timezoneOffset")
                timeZoneDescription = "GMT\(timeZoneSetting.timezoneOffset > 0 ? "+" : "")\(timeZoneSetting.timezoneOffset / 3600):\(abs(timeZoneSetting.timezoneOffset) % 3600 / 60)"
            }
        } else {
            timeZoneDescription = ""
        }
        // 自定义时区
        let custom = CheckboxNormalCellProp(title: BundleI18n.LarkMine.Lark_IM_PrivacySettings_TimeZoneDisplay_CustomizeTimeZone_Option,
                                            boxType: .single,
                                            isOn: self.timeZoneSetting.type == .custom,
                                            accessories: self.timeZoneSetting.type == .custom ? [.text(timeZoneDescription), .arrow()] : []) { [weak self] _ in
            guard let self = self else { return }
            if self.timeZoneSetting.type != .custom {
                var setting = self.timeZoneSetting
                setting.type = .custom
                setting.timezone = TimeZone.current.identifier
                self.setupExternalDisplayTimezoneSetting(setting)
            }
            self.showTimeZoneSelectController(timeZone: TimeZone(identifier: self.timeZoneSetting.timezone))
        }
        // 跟随系统时区
        let followSystem = CheckboxNormalCellProp(title: BundleI18n.LarkMine.Lark_IM_PrivacySettings_TimeZoneDisplay_UseDeviceTime_Option,
                                                  boxType: .single,
                                                  isOn: self.timeZoneSetting.type == .followSystem,
                                                  accessories: self.timeZoneSetting.type == .followSystem ? [.text(timeZoneDescription)] : []) { [weak self] _ in
            guard let self = self else { return }
            var setting = self.timeZoneSetting
            setting.type = .followSystem
            setting.timezone = TimeZone.current.identifier
            self.setupExternalDisplayTimezoneSetting(setting)
        }
        // 隐藏时区
        let hidden = CheckboxNormalCellProp(title: BundleI18n.LarkMine.Lark_IM_PrivacySettings_HideMyTimeZone_Option,
                                            boxType: .single,
                                            isOn: self.timeZoneSetting.type == .hidden,
                                            accessories: []) { [weak self] _ in
            guard let self = self else { return }
            var setting = self.timeZoneSetting
            setting.type = .hidden
            self.setupExternalDisplayTimezoneSetting(setting)
        }
        return SectionProp(items: [followSystem, custom, hidden])
    }

    func setupExternalDisplayTimezoneSetting(_ timeZoneSetting: TimeZoneSetting) {
        // 设置之前的类型
        let originTimeZoneSetting = self.timeZoneSetting
        guard originTimeZoneSetting != timeZoneSetting else { return }
        self.timeZoneSetting = timeZoneSetting
        let key = self.key
        self.context?.reload()
        configAPI?
            .setupExternalDisplayTimezoneSetting(setting: timeZoneSetting)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                SettingLoggerService.logger(.module(key)).info("api/set/req: \(timeZoneSetting); res: ok")
            }, onError: { [weak self] (error) in
                // 设置失败后重置类型
                self?.timeZoneSetting = originTimeZoneSetting
                self?.context?.reload()
                SettingLoggerService.logger(.module(key)).error("api/set/req: \(timeZoneSetting); res: error: \(error)")
            }).disposed(by: self.disposeBag)
    }

    private func showTimeZoneSelectController(timeZone: TimeZone?) {
        guard let from = self.context?.vc else { return }
        dependency?.showTimeZoneSelectController(with: timeZone, from: from) { [weak self] value in
            guard let self = self else { return }
            SettingLoggerService.logger(.module(self.key)).info("showTimeZoneSelectController: onTimeZoneSelect timezone: \(value)")
            var setting = self.timeZoneSetting
            setting.timezone = value.identifier
            setting.followSystem = false
            self.setupExternalDisplayTimezoneSetting(setting)
        }
    }
}
