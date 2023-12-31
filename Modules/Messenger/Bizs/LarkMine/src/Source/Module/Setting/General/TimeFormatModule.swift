//
//  TimeFormatModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/29.
//

import Foundation
import UIKit
import LarkContainer
import LarkSDKInterface
import LarkOpenSetting
import LarkSettingUI

final class TimeFormatModule: BaseModule {

    private var userGeneralSettings: UserGeneralSettings?
    private var configAPI: ConfigurationAPI?

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        self.userGeneralSettings = try? self.userResolver.resolve(assert: UserGeneralSettings.self)
        self.configAPI = try? self.userResolver.resolve(assert: ConfigurationAPI.self)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        let item = SwitchNormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_24HourTime,
                                               isOn: userGeneralSettings?.is24HourTime.value ?? false,
                                               onSwitch: { [weak self] _, isOn in
            self?.updateTimeFormat(isOn)
        })
        return SectionProp(items: [item])
    }

    private func updateTimeFormat(_ isOn: Bool) {
        let logger = SettingLoggerService.logger(.module(key))
        MineTracker.trackIs24HourTime(isOn)
        logger.info("api/SetUserSettingRequest: format: \(isOn ? "twentyFourHour" : "twelveHour")")
        configAPI?.setTimeFormat(isOn ? .twentyFourHour : .twelveHour)
            .subscribe(onError: { [weak self] (error) in
                self?.context?.reload()
                logger.error("api/SetUserSettingRequest: error", error: error)
            }).disposed(by: disposeBag)
    }
}
