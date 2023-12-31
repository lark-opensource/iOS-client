//
//  UIViewControllerExtensions.swift
//  ByteView
//
//  Created by kiri on 2021/6/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewCommon

extension VCExtension where BaseType: UIViewController {
    func removeFromParent() {
        base.willMove(toParent: nil)
        base.view.removeFromSuperview()
        base.removeFromParent()
    }
}

extension UITraitCollection {
    var isRegular: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    var isCompact: Bool {
        return horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
}
