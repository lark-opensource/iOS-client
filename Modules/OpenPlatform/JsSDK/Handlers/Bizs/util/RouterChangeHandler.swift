//
//  RouterChangeHandler.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/17.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import WebBrowser

class RouterChangeHandler: JsAPIHandler {
    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        api.checkAndUpdateLeftItems()
    }
}
