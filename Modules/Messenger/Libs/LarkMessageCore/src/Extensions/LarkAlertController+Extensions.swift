//
//  LarkAlertController+Extensions.swift
//  LarkMessageCore
//
//  Created by 姜凯文 on 2020/3/12.
//

import UIKit
import Foundation
import LarkAlertController
import EENavigator

public extension LarkAlertController {
    // 资源上限统一报错
    func showCloudDiskFullAlert(from viewController: UIViewController, nav: Navigatable) {
        self.setTitle(text: BundleI18n.LarkMessageCore.Lark_Chat_CloudDiskFullTitle)
        self.setContent(text: BundleI18n.LarkMessageCore.Lark_Chat_CloudDiskFull)
        self.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_Legacy_ApplicationPhoneCallTimeButtonKnow)
        nav.present(self, from: viewController)
    }
}
