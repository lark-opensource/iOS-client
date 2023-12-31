//
//  WebFeatureGating.swift
//  WebBrowser
//
//  Created by lilun.ios on 2022/3/16.
//

import Foundation
import LarkSetting
import LarkUIKit

public enum FeatureGatingKey: String, CaseIterable {
    case webBrowserProfileCloseBtnGap = "webbrowser.navigation.closebtn.incspace"
}

extension FeatureGatingKey {
    public func fgValue() -> Bool {
        if Display.pad {
            return false
        } else {
            // 已经全量
            //https://lark-devops.bytedance.net/page/fg/detail?key_word=webbrowser.navigation.closebtn.incspace&env=online&unit=cn&feature_key=webbrowser.navigation.closebtn.incspace&tab=rule&app=Feishu
            return true
        }
    }
}
