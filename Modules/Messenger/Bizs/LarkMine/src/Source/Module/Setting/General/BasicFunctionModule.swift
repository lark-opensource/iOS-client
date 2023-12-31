//
//  BasicFunctionModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/29.
//

import Foundation
import UIKit
import LarkMinimumMode
import EENavigator
import UniverseDesignDialog
import UniverseDesignToast
import LarkContainer
import LarkOpenSetting
import LarkSettingUI
import LarkStorage

final class BasicFunctionModule: BaseModule {
    private var minimumModeInterface: MinimumModeInterface?

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        self.minimumModeInterface = try? self.userResolver.resolve(assert: MinimumModeInterface.self)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        let item = SwitchNormalCellProp(title: BundleI18n.LarkMine.Lark_Settings_BasicModeTitle,
                                               isOn: KVPublic.Core.minimumMode.value(),
                                               onSwitch: { [weak self] _, isOn in
            self?.updateBasicFunction(isOn)
        })
        return SectionProp(items: [item], footer: .title(BundleI18n.LarkMine.Lark_Settings_BasicModeDesc()))
    }

    private func updateBasicFunction(_ isOn: Bool) {
        guard let vc = self.context?.vc else { return }
        let logger = SettingLoggerService.logger(.module(self.key))
        let basicFunctionHandler: (Bool) -> Void = { [weak self] isOn in
            let hud = UDToast.showLoading(on: vc.view)
            self?.minimumModeInterface?.putDeviceMinimumMode(isOn, fail: { _ in
                hud.remove()
                UDToast.showFailure(with: BundleI18n.LarkMine.Lark_Settings_BasicModeSwitchFailed, on: vc.view)
                logger.error("api/set/req: \(isOn); res: fail")
            })
        }

        let alertController = UDDialog()
        //关闭是在基本模式下，此处不用处理
        if isOn {
            alertController.setTitle(text: BundleI18n.LarkMine.Lark_Settings_BasicModeOnConfirmTitle)
            alertController.setContent(text: BundleI18n.LarkMine.Lark_Settings_BasicModeOnConfirmDesc())
            alertController.addCancelButton()
            alertController.addPrimaryButton(text: BundleI18n.LarkMine.Lark_Settings_BasicModeOnConfirmButton, dismissCompletion: { basicFunctionHandler(isOn) })
        }
        self.userResolver.navigator.present(alertController, from: vc)
    }
}
