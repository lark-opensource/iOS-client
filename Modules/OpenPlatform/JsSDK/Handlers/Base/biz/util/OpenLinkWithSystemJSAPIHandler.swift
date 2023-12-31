//
//  OpenLinkWithSystemJSAPIHandler.swift
//  JsSDK
//
//  Created by tangyunfei.tyf on 2021/4/22.
//
import Foundation
import LKCommonsLogging
import WebBrowser

class OpenLinkWithSystemJSAPIHandler: JsAPIHandler {

    private static let logger = Logger.log(OpenLinkWithSystemJSAPIHandler.self, category: "OpenLinkWithSystemJSAPIHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        Self.logger.debug("handle args = \(args))")

        guard let urlString = args["url"] as? String,
              let url = URL(string: urlString) else {
            Self.logger.error("no valid url: \(String(describing: args["url"]))")
            callback.callbackSuccess(param: ["code": 1])
            return
        }

        UIApplication.shared.open(url, completionHandler: { success in
            if !success {
                Self.logger.info("open url failed: \(url.absoluteString)")
            }
        })
    }
}
