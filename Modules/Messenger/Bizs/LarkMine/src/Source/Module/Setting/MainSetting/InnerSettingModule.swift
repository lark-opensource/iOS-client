//
//  InnerSettingModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/21.
//

import UIKit
import Foundation
import RxSwift
import LarkContainer
import LarkRustClient
import RustPB
import LarkUIKit
import UniverseDesignToast
import UniverseDesignDialog
import EENavigator
import LKCommonsLogging
import LarkOpenSetting
import LarkSettingUI

final class InnerSettingModule: BaseModule {

    private var rustService: RustService?

    override func createSectionProp(_ key: String) -> SectionProp? {
        let item = TapCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_GetLatestConfigurationMobile(),
                                      color: UIColor.ud.colorfulBlue) { [weak self] _ in
            self?.syncConfig()
        }
        let section = SectionProp(items: [item])
        return section
    }

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        self.rustService = try? self.userResolver.resolve(assert: RustService.self)
    }

    private func fetchFeatureGating() -> Observable<Void> {
        var request = Settings_V1_GetSettingsRequest()
        request.fields = ["lark_features"]
        request.syncDataStrategy = .forceServer
        guard let rustService = self.rustService else { return .empty() }
        return rustService.sendAsyncRequest(request).map({ _ in })
    }

    /// Sync Config: FG and AppConfig
    private func syncConfig() {
        guard let vc = self.context?.vc else { return }
        let hud = UDToast.showLoading(on: vc.view, disableUserInteraction: true)
        self.fetchFeatureGating()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak vc, weak self] (_) in
                guard let vc = vc, let `self` = self else { return }

                hud.remove()
                /// 弹窗确认
                let alertController = UDDialog()
                alertController.setTitle(text: BundleI18n.LarkMine.Lark_NewSettings_GetConfigurationToastTitle())
                alertController.setContent(text: BundleI18n.LarkMine.Lark_NewSettings_GetConfigurationToast)
                alertController.addSecondaryButton(text: BundleI18n.LarkMine.Lark_NewSettings_GetConfigurationToastLater)
                alertController.addPrimaryButton(text: BundleI18n.LarkMine.Lark_NewSettings_GetConfigurationToastRestart, dismissCompletion: { [weak vc] in
                    guard vc != nil else { return }
                    exit(0)
                })
                SettingLoggerService.logger(.module("innerSetting")).info("api/SyncConfig/res: ok")
                self.userResolver.navigator.present(alertController, from: vc)
            }, onError: { [weak vc] (error) in
                guard let vc = vc else {
                    assertionFailure()
                    return
                }
                hud.remove()
                UDToast.showFailure(
                    with: BundleI18n.LarkMine.Lark_Legacy_MineSettingTranslateError,
                    on: vc.view,
                    error: error
                )
                SettingLoggerService.logger(.module("innerSetting")).error("api/SyncConfig/res: error: \(error)")
            }).disposed(by: self.disposeBag)
    }
}
