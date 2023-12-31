//
//  WhenPhoneCheckedModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/7/6.
//

import Foundation
import RxSwift
import LarkContainer
import LarkOpenSetting
import LarkSDKInterface
import LarkSetting
import UniverseDesignToast
import LarkSettingUI

let whenPhoneCheckedModuleProvider: ModuleProvider = { userResolver in
    let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self)
    let fg = featureGatingService?.staticFeatureGatingValue(with: .whenPhoneChecked) ?? false
    guard fg else { return nil }
    return WhenPhoneCheckedModule(userResolver: userResolver)
}

final class WhenPhoneCheckedModule: BaseModule {
    private var notifyConfig: UserUniversalSettingService?
    private var notifyKey: String { "CHECK_PHONE_NOTIFY" }
    private var notifyMeIsOn: Bool = true
    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        if let notifyConfig = try? self.userResolver.resolve(assert: UserUniversalSettingService.self) {
            self.notifyConfig = notifyConfig
        }
        self.notifyConfig?.getBoolUniversalUserObservableSetting(key: notifyKey)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let self = self else { return }
                if let isOn = response, isOn != self.notifyMeIsOn {
                    self.notifyMeIsOn = isOn
                    self.context?.reload()
                }
                SettingLoggerService.logger(.module("whenPhoneCheckedSetting")).info("api/get/res: \(response)")
            }).disposed(by: disposeBag)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        if let isOn = self.notifyConfig?.getBoolUniversalUserSetting(key: notifyKey) {
            self.notifyMeIsOn = isOn
        }
        let item = SwitchNormalCellProp(title: BundleI18n.LarkMine.Lark_Legacy_NotifyMeWhenMemberViewMyPhone,
                                        isOn: self.notifyMeIsOn,
                                        onSwitch: { [weak self] _, status in
                                            guard let self = self else { return }
                                            self.setStatusOfCheckNotifyPhone(enable: status)
                                            MineTracker.trackSettingPrivacyNotifyClick(isOn: status)
        })
        return SectionProp(items: [item])
    }

    private func setStatusOfCheckNotifyPhone(enable: Bool) {
        let logger = SettingLoggerService.logger(.module(self.key))
        self.notifyConfig?.setUniversalUserConfig(values: [notifyKey: .boolValue(enable)])
            .subscribe(onNext: {
                logger.info("api/set/req: \(enable); res: ok")
            }, onError: { [weak self] error in
                guard let self = self else { return }
                if let window = self.context?.vc?.view.window {
                    DispatchQueue.main.async {
                        UDToast.showFailure(with: BundleI18n.LarkMine.Lark_Legacy_NetworkError, on: window, error: error)
                    }
                }
                self.context?.reload()
                logger.error("api/set/req: \(enable); res: error \(error)")
            }).disposed(by: disposeBag)
    }
}
