//
//  UIViewController+RT.swift
//  RichTextEditor
//
//  Created by chenhuaguan on 2020/6/30.
//

import UIKit
import Foundation
import EENavigator
import LarkTraitCollection
import LarkSplitViewController

extension UIViewController: RTExtensionCompatible {}

extension RTExtension where BaseType == UIViewController {

    static var businessWindow: UIWindow? {
        return UIApplication.shared.windows.first {
            $0.rootViewController != nil && $0.windowLevel == .normal
        }
    }

}
