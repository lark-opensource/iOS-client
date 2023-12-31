//
//  ReplayKitFixer.swift
//  ByteView
//
//  Created by kiri on 2021/2/3.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import ReplayKit
import ByteViewUI

struct ReplayKitFixer {
    static let fixOnce: Bool = {
        if #available(iOS 14.0, *) {
        } else if #available(iOS 13.0, *), let clz = NSClassFromString("RPModalPresentationWindow") {
            Util.swizzleInstanceMethod(clz, from: #selector(setter: UIWindow.screen),
                                       to: #selector(UIWindow.setScreen_RPModalPresentationWindow(_:)))
        }
        return true
    }()
}

extension UIWindow {
    @objc func setScreen_RPModalPresentationWindow(_ screen: UIScreen) {
        if #available(iOS 13.0, *) {
            windowScene = VCScene.windowScene
        } else {
            setScreen_RPModalPresentationWindow(screen)
        }
    }
}
