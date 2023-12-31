//
//  CopyTextHandler.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/20.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkUIKit
import LKCommonsLogging
import RoundedHUD
import WebBrowser
import LarkEMM
import OPFoundation

class CopyTextHandler: JsAPIHandler {
    static let logger = Logger.log(CopyTextHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let text = args["text"] as? String else {
            CopyTextHandler.logger.error("copy text failed, has no text args")
            return
        }
        let config = PasteboardConfig(token: OPSensitivityEntryToken.copyTextHandler.psdaToken)
        SCPasteboard.general(config).string = text
        RoundedHUD.showSuccess(with: BundleI18n.JsSDK.Lark_Legacy_JssdkCopySuccess, on: api.view)
    }
}
