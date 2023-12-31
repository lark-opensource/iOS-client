//
//  SmartModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/7/4.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import UniverseDesignDialog
import LarkSDKInterface
import RustPB
import LarkStorage
import LKCommonsLogging
import LarkContainer
import EENavigator
import LarkOpenSetting
import LarkSettingUI
import LarkSetting

final class AudioToTextModule: BaseModule {
    private var autoAudioToText: Bool = false

    private var configurationAPI: ConfigurationAPI?
    private var pushCenter: PushNotificationCenter?

    override func createSectionProp(_ key: String) -> SectionProp? {
        let item = SwitchNormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_AutoConvertAudioToText,
                                        isOn: autoAudioToText) { [weak self] _, isOn in
            self?.updateAudioToTextSettting(autoAudioToText: isOn)
        }
        return SectionProp(items: [item])
    }

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)

        self.configurationAPI = try? self.userResolver.resolve(assert: ConfigurationAPI.self)
        self.pushCenter = try? self.userResolver.userPushCenter

        self.pushCenter?.observable(for: Settings_V1_PushUserSetting.self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](userSetting) in
                guard let self = self else { return }
                self.autoAudioToText = userSetting.autoAudioToText
                self.context?.reload()
            }).disposed(by: disposeBag)
        fetchRemoteNotificationSettings()
    }

    private var isGetAudioFromServer = false
    private func fetchRemoteNotificationSettings() {
        self.configurationAPI?.getAudioToTextSetting(isFromServer: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (enable) in
                guard let `self` = self else { return }
                guard self.isGetAudioFromServer == false else { return }
                self.autoAudioToText = enable
                self.context?.reload()
            }).disposed(by: self.disposeBag)
        self.configurationAPI?.getAudioToTextSetting(isFromServer: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (enable) in
                guard let `self` = self else { return }
                guard self.isGetAudioFromServer == false else { return }
                self.isGetAudioFromServer = true
                self.autoAudioToText = enable
                self.context?.reload()
            }).disposed(by: self.disposeBag)
    }

    private func updateAudioToTextSettting(autoAudioToText: Bool) {
        let origin = self.autoAudioToText
        self.autoAudioToText = autoAudioToText
        self.context?.reload()
        let logger = SettingLoggerService.logger(.module(self.key))
        self.configurationAPI?
            .setAudioToTextSetting(enable: autoAudioToText)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                logger.info("api/setAudioToTextSetting/req enable: \(autoAudioToText); res: ok")
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                self.autoAudioToText = origin
                self.showAlertInController(title: BundleI18n.LarkMine.Lark_Legacy_Hint, message: BundleI18n.LarkMine.Lark_Legacy_ChangeFailed)
                self.context?.reload()
                logger.error("api/setAudioToTextSetting/req enable: \(autoAudioToText); res: error: \(error)")
            }).disposed(by: self.disposeBag)

        MineTracker.trackAutoAudioToText(enable: autoAudioToText)
    }

    func showAlertInController(title: String, message: String) {
        let alertController = UDDialog()
        alertController.setTitle(text: title)
        alertController.setContent(text: message)
        alertController.addPrimaryButton(text: BundleI18n.LarkMine.Lark_Legacy_Sure)
        guard let from = self.context?.vc else { return }
        self.userResolver.navigator.present(alertController, from: from)
    }
}
