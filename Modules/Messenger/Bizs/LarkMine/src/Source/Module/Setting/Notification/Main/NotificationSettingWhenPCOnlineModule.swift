//
//  NotificationSettingWhenPCOnlineModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/27.
//

import Foundation
import EENavigator
import LarkContainer
import LarkMessengerInterface
import Swinject
import LarkSDKInterface
import RustPB
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkUIKit
import LarkOpenSetting
import LarkSettingUI

// 该设置项只针对某一个设备
final class NotificationSettingWhenPCOnlineModule: BaseModule {

    private var userGeneralSettings: UserGeneralSettings?

    private var notifyConfig: NotifyConfig? {
        return self.userGeneralSettings?.notifyConfig
    }

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)

        self.userGeneralSettings = try? userResolver.resolve(assert: UserGeneralSettings.self)

        self.notifyConfig?.atNotifyOpenDriver.distinctUntilChanged().drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.context?.reload()
        }).disposed(by: self.disposeBag)
        self.notifyConfig?.notifyDisableDriver.distinctUntilChanged().drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.context?.reload()
        }).disposed(by: self.disposeBag)
        self.notifyConfig?.notifySpecialFocusDriver.distinctUntilChanged().drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.context?.reload()
        }).disposed(by: self.disposeBag)
        self.userGeneralSettings?.fetchDeviceNotifySettingFromServer()
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        var titleStr = BundleI18n.LarkMine.Lark_NewSettings_TurnOffMobileNotification
        var detailStr = BundleI18n.LarkMine.Lark_NewSettings_TurnOffMobileNotificationDescription()
        if Display.pad {
            titleStr = BundleI18n.LarkMine.Lark_Legacy_iPadCloseNotifyLabel
            detailStr = BundleI18n.LarkMine.Lark_Legacy_iPadCloseNotifyWhilePcOnlineTips
        }
        let pc = SwitchNormalCellProp(title: titleStr,
                                             detail: detailStr,
                                             isOn: self.notifyConfig?.notifyDisable ?? false,
                                             id: MineNotificationSettingBody.ItemKey.OffWhenPCOnline.rawValue) { [weak self] _, isOn in
            MineTracker.trackSettingPcLoginMuteMobileNotification(status: isOn)
            self?.updateNotificationStatus(status: isOn)
        }
        let buzz = !(self.notifyConfig?.notifyDisable ?? false) ? nil : SwitchNormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_TurnOffMobileNotificationBuzzStill,
                                               isOn: true,
                                               isEnabled: false)
        let atNotifyOpen = self.notifyConfig?.atNotifyOpen ?? false
        let atMe = !(self.notifyConfig?.notifyDisable ?? false) ? nil : SwitchNormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_TurnOffMobileNotificationMentionStill,
                                                                                        isOn: atNotifyOpen) { [weak self] _, isOn in
            MineTracker.trackSettingPcLoginMuteMobileNotificationMention(status: isOn)
            self?.updateAtNotificationStatus(status: isOn)
        }
        let showSpecialFocus = self.notifyConfig?.notifyDisable ?? false
        let special = !showSpecialFocus ? nil : SwitchNormalCellProp(title: BundleI18n.LarkMine.Lark_IM_StarredContactsNotifyMeAnyways_Title,
                                                  isOn: self.notifyConfig?.notifySpecialFocus ?? false) { [weak self] _, isOn in
            self?.updateSpecialFocusNotificationStatus(status: isOn)
        }
        let items = [pc, buzz, atMe, special].compactMap { $0 }
        return SectionProp(items: items)
    }

    private func updateSpecialFocusNotificationStatus(status: Bool) {
        let logger = SettingLoggerService.logger(.module(self.key))
        self.userGeneralSettings?.updateNotificationStatus(notifySpecialFocus: status)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {_ in
                logger.info("api/set/req: specialFocus: \(status); res: ok")
            }, onError: { [weak self] error in
                guard let self = self, let vc = self.context?.vc else { return }
                UDToast.showFailure(with: BundleI18n.LarkMine.Lark_Settings_BadgeStyleChangeFail, on: vc.view, error: error)
                self.context?.reload()
                logger.error("api/set/req: specialFocus: \(status); res: error \(error)")
        }).disposed(by: self.disposeBag)
    }

    private func updateAtNotificationStatus(status: Bool) {
        let logger = SettingLoggerService.logger(.module(self.key))
        self.userGeneralSettings?.updateNotificationStatus(notifyAtEnabled: status)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                logger.info("api/set/req: notifyAtEnabled: \(status); res: ok")
            }, onError: { [weak self] error in
                guard let self = self, let vc = self.context?.vc else { return }
                UDToast.showFailure(with: BundleI18n.LarkMine.Lark_Settings_BadgeStyleChangeFail, on: vc.view, error: error)
                self.context?.reload()
                logger.error("api/set/req: notifyAtEnabled: \(status); res: error \(error)")
        }).disposed(by: self.disposeBag)
    }

    private func updateNotificationStatus(status: Bool) {
        let logger = SettingLoggerService.logger(.module(self.key))
        self.userGeneralSettings?.updateNotificationStatus(notifyDisable: status)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                logger.info("api/set/req: notifyDisable: \(status); res: ok")
            }, onError: { [weak self] error in
                guard let self = self, let vc = self.context?.vc else { return }
                UDToast.showFailure(with: BundleI18n.LarkMine.Lark_Settings_BadgeStyleChangeFail, on: vc.view, error: error)
                self.context?.reload()
                logger.error("api/set/req: notifyDisable: \(status); res: error \(error)")
        }).disposed(by: self.disposeBag)
    }
}
