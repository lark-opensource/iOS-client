//
//  OpenLinkHandler.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging
import WebBrowser
import LarkContainer
import LarkAccountInterface

typealias OpenLinkBlock = (URL, _ vc: UIViewController, _ from: URL?) -> Void

class OpenLinkHandler: JsAPIHandler {
    static let logger = Logger.log(OpenLinkHandler.self, category: "Module.JSSDK")
    private var openlink: OpenLinkBlock
    @Provider private var dependency: PassportWebViewDependency

    init(openlink: @escaping OpenLinkBlock) {
        self.openlink = openlink
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        dependency.monitorSensitiveJsApi(apiName: "biz.account.openLink", sourceUrl: api.browserURL, from: "JSSDK")
        let newTab = args["newTab"] as? Bool ?? true
        guard let urlStr = args["url"] as? String,
            let url = URL(string: urlStr) else {
                OpenLinkHandler.logger.error("参数有误")
                return
        }

        if newTab {
            openlink(url, api, api.webView.url)
        } else {
            api.open(url: url)
        }
    }
}
