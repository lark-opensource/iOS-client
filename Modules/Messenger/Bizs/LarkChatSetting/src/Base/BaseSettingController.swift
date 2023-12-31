//
//  BaseSettingController.swift
//  LarkChatSetting
//
//  Created by 李晨 on 2021/1/6.
//

import UIKit
import Foundation
import LarkUIKit
import LarkFeatureGating
import UniverseDesignColor

class BaseSettingController: BaseUIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.supportSecondaryOnly = true
        self.addCancelItem()
        view.backgroundColor = UIColor.ud.bgFloatBase
    }
}
