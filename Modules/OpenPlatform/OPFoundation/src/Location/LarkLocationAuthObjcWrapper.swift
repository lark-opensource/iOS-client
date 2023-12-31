//
//  LarkLocationAuthObjcWrapper.swift
//  EEMicroAppSDK
//
//  Created by zhangxudong on 4/8/22.
//

import Foundation
import LarkPrivacySetting

@objc(EMALarkLocationAuthority)
public final class LarkLocationAuthObjcWrapper: NSObject {
    @objc
    static public func checkAuthority() -> Bool {
        return LarkLocationAuthority.checkAuthority()
    }
    @objc
    static public func showDisableTip(on view: UIView) {
        LarkLocationAuthority.showDisableTip(on: view)
    }
}
