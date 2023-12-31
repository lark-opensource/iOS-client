//
//  AppNotSupportHandler.swift
//  LarkOpenPlatform
//
//  Created by lilun.ios on 2020/7/9.
//

import EENavigator
import RxSwift
import SwiftyJSON
import LKCommonsLogging
import LKCommonsTracker
import RoundedHUD
import LarkFeatureGating
import LarkMessengerInterface
import LarkAppLinkSDK
import Swinject
import LarkSDKInterface
import OPFoundation

/// 提示当前平台不支持的tips，widget中的app点击的时候调用
class AppNotSupportHandler: NSObject {
    private static let logger = Logger.log(AppNotSupportHandler.self,
                                           category: "AppNotSupportHandler")
    func handle(appLink: AppLink, resolver: Resolver) {
        let tips = BundleI18n.LarkOpenPlatform.Lark_Legacy_MsgCardUnsupportedActionMobile
        if let fromVC = applinkFrom(appLink: appLink) {
            RoundedHUD.showFailure(with: tips, on: fromVC.view)
        } else {
            AppNotSupportHandler.logger.error("AppNotSupportHandler show toast \(tips) failed")
        }
    }
}
