//
//  AppLinkRouteHelper.swift
//  LarkOpenPlatform
//
//  Created by lilun.ios on 2021/4/2.
//

import Foundation
import OPFoundation
import LarkAppLinkSDK
import LarkSceneManager
import LarkFeatureGating
import EENavigator

public func applinkFrom(appLink: AppLink) -> UIViewController? {
    if let from = appLink.navigationFrom() {
        return from
    }
    return Navigator.shared.mainSceneWindow?.fromViewController
}
