//
//  SetTitleHandler.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging
import WebBrowser

class SetTitleHandler: JsAPIHandler {
    static let logger = Logger.log(SetTitleHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let title = args["title"] as? String else {
            SetTitleHandler.logger.error("参数有误")
            return
        }
        api.update(title: title)
    }
}
