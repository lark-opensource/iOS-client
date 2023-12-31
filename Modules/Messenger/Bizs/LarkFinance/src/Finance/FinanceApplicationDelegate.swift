//
//  FinanceApplicationDelegate.swift
//  LarkFinance
//
//  Created by ByteDance on 2023/10/7.
//

import Foundation
import UIKit
import AppContainer
import LKCommonsLogging

#if canImport(DouyinOpenPlatformSDK)
import DouyinOpenPlatformSDK

final class FinanceApplicationDelegate: ApplicationDelegate {
    //实现抖开SDK 代码配置
    static let config = Config(name: "DouyinHandleOpenURL", daemon: true)
    static let logger = Logger.log(FinanceApplicationDelegate.self, category: "finance.pay.appDelegate")

    required init(context: AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message: OpenURL) in
            self?.openURL(message)
        }
        if #available(iOS 13.0, *) {
            context.dispatcher.add(observer: self) { [weak self] (_, message: SceneOpenURLContexts) in
                self?.openSceneURL(message)
            }
        }
    }

    private func openURL(_ message: OpenURL) {
        Self.logger.info("finance open url")
        DouyinOpenSDKApplicationDelegate.sharedInstance().application(UIApplication.shared,
                                                                      open: message.url,
                                                                      sourceApplication: message.options[.sourceApplication] as? String,
                                                                      annotation: message.options[.annotation])
    }

    @available(iOS 13.0, *)
    private func openSceneURL(_ message: SceneOpenURLContexts) {
        if let urlContext = message.urlContexts.first {
            Self.logger.info("finance open scene url")
            DouyinOpenSDKApplicationDelegate.sharedInstance().application(UIApplication.shared,
                                                                          open: urlContext.url,
                                                                          sourceApplication: urlContext.options.sourceApplication,
                                                                          annotation: urlContext.options.annotation)
        }
    }
}
#endif
