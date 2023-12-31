//
//  IpadSingleColumnModeModule.swift
//  LarkMine
//
//  Created by Yaoguoguo on 2023/4/25.
//

import Foundation
import LarkUIKit
import LarkContainer
import LarkOpenSetting
import LarkSettingUI
import LarkSplitViewController
import LarkFeatureGating

final class IpadSingleColumnModeModule: BaseModule {

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        guard Display.pad else { return nil }
        let item = SwitchNormalCellProp(title: BundleI18n.LarkMine.Lark_Core_IpadSingleColumnMode_Button,
                                        isOn: SplitViewController.supportSingleColumn,
                                        onSwitch: { _, isOn in
            SplitViewController.supportSingleColumn = isOn
        })
        return SectionProp(items: [item])
    }
}
