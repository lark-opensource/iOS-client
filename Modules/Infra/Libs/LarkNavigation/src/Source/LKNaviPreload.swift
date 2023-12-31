//
//  LKNaviPreload.swift
//  LarkNavigation
//
//  Created by Lark iOS on 2021/6/8.
//

import Foundation
import LarkUIKit
import Reachability
import LarkAppConfig
import LarkSetting

@objc
public final class LKNaviPreload: NSObject {
    @objc
    public static func preload() {
        preloadDefaultSetting()
        _ = Resources.LarkNavigation.MainTab.tabbar_feed_shadow
        _ = BundleI18n.LarkNavigation.Lark_Chat_JoinOrCreateTeam
        _ = LkNavigationController.imageForDefaultStyle
        try? Reachability()?.startNotifier()
    }
}
