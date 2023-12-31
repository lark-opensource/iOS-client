//
//  UIViewController+LarkUIKit.swift
//  LarkUIKit
//
//  Created by liuwanlin on 2017/12/13.
//  Copyright © 2017年 liuwanlin. All rights reserved.
//

import UIKit
import LarkCompatible

extension UIViewController: LarkUIKitExtensionCompatible {}

extension LarkUIKitExtension where BaseType: UIViewController {
    public var presentContainerVC: PresentViewController? {
        if let presentContainerVC = self.base.parent as? PresentViewController {
            return presentContainerVC
        }

        return nil
    }
}
