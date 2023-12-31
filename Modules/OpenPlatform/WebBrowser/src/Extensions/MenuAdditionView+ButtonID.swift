//
//  MenuAdditionView+ButtonID.swift
//  WebBrowser
//
//  Created by yinyuan on 2022/5/7.
//

import LarkSetting
import LarkUIKit

extension MenuAdditionView {
    
    private static var _webButtonIDListKey: Void?
    
    public var webButtonIDList: [String]? {
        get {
            return objc_getAssociatedObject(self, &MenuAdditionView._webButtonIDListKey) as? [String]
        }
        set {
            objc_setAssociatedObject(self, &MenuAdditionView._webButtonIDListKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
}
