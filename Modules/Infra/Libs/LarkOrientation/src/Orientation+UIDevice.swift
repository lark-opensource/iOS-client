//
//  Orientation+UIDevice.swift
//  LarkOrientation
//
//  Created by 李晨 on 2020/11/29.
//

import UIKit
import Foundation
import LarkFoundation
extension UIDevice {

    static var orientationSwizzingFunc: [(AnyClass, Selector, Selector)] {
        return [
            (UIDevice.self, #selector(UIDevice.setValue(_:forKey:)), #selector(UIDevice.lo_setValue(_:forKey:)))
        ]
    }

    @objc
    func lo_setValue(_ value: Any?, forKey key: String) {
        if key == "orientation" && Utils.isiOSAppOnMacSystem {
            /// 在 Mac 上运行 app 忽略通过 kvc 设置 设备方向
        } else {
            super.setValue(value, forKey: key)
        }
    }
}
