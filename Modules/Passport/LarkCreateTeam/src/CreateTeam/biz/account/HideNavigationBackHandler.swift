//
//  HideNavigationBackHandler.swift
//  Pods
//
//  Created by Yiming Qu on 2019/5/21.
//

import LarkUIKit
import WebBrowser
import LKCommonsLogging
import LarkAccountInterface
import LarkContainer

class HideNavigationBackHandler: LarkWebJSAPIHandler {

    static let logger = Logger.log(HideNavigationBackHandler.self, category: "Module.JSSDK")

    @Provider var dependency: PassportWebViewDependency

    func handle(args: [String: Any], api: WebBrowser, sdk: LarkWebJSSDK) {
        HideNavigationBackHandler.logger.info("HideNavigationBackHandler args: \(args)")
        self.dependency.monitorSensitiveJsApi(apiName: "biz.account.hideNavigationBack", sourceUrl: api.browserURL, from: "LarkCreateTeam")
        let show = (args["show"] as? Int32) ?? 0

        api.navigationItem.leftBarButtonItems?.forEach({ (item) in
            self.visualize(item, show: show == 1)
        })
    }

    func visualize(_ item: UIBarButtonItem?, show: Bool) {
        guard let it = item else {
            return
        }
        guard let lkItem = it as? LKBarButtonItem else {
            return
        }

        lkItem.button.isHidden = !show

    }
}
