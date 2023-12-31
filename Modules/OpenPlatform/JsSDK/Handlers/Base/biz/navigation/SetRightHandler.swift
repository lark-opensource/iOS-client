//
//  SetRightHandler.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging
import WebBrowser

class SetRightHandler: JsAPIHandler {
    static let logger = Logger.log(SetRightHandler.self, category: "Module.JSSDK")

    fileprivate var rightItems: [UIBarButtonItem]?

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let show = args["show"] as? Bool else {
            SetRightHandler.logger.error("参数有误")
            return
        }

        if show {
            if api.isNavigationRightBarExtensionDisable {
                api.setRightBarButtonItems(
                    rightItems ?? api.navigationItem.rightBarButtonItems,
                    animated: false
                )
            } else {
                if let navigationExtension = api.resolve(NavigationBarRightExtensionItem.self) {
                    navigationExtension.isHideRightItems = false
                    navigationExtension.resetAndUpdateRightItems(browser: api)
                }
            }
            
        } else {
            if api.isNavigationRightBarExtensionDisable {
                rightItems = api.navigationItem.rightBarButtonItems
                api.setRightBarButtonItems(nil, animated: false)
            } else {
                if let navigationExtension = api.resolve(NavigationBarRightExtensionItem.self) {
                    navigationExtension.isHideRightItems = true
                    navigationExtension.resetAndUpdateRightItems(browser: api)
                }
            }
            
        }
    }
}
