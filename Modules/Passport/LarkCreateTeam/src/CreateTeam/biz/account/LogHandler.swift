//
//  LogHandler.swift
//  Pods
//
//  Created by quyiming@bytedance.com on 2019/6/26.
//

import Foundation
import WebBrowser
import LKCommonsLogging
import LarkAccountInterface
import LarkContainer

class LogHandler: LarkWebJSAPIHandler {

    static let logger = Logger.log(LogHandler.self, category: "Module.JSSDK")

    @Provider var dependency: PassportWebViewDependency

    func handle(args: [String: Any], api: WebBrowser, sdk: LarkWebJSSDK) {

        self.dependency.monitorSensitiveJsApi(apiName: "biz.account.log", sourceUrl: api.browserURL, from: "LarkCreateTeam")

        let additionalData: [String: String] = ["h5Log": "1"]
        if let msg = args["msg"] as? String, let l = args["level"] as? String, let level = Level(rawValue: l) {
            switch level {
            case .error:
                AppInfoHandler.logger.error(msg, additionalData: additionalData, error: nil)
            case .warn:
                AppInfoHandler.logger.warn(msg, additionalData: additionalData, error: nil)
            case .info:
                AppInfoHandler.logger.info(msg, additionalData: additionalData, error: nil)
            case .debug:
                AppInfoHandler.logger.debug(msg, additionalData: additionalData, error: nil)
            }
        } else if args["msg"] as? String != nil {
            AppInfoHandler.logger.warn("h5 log miss level value, args: \(args)", additionalData: additionalData, error: nil)
        } else {
            AppInfoHandler.logger.warn("h5 log miss msg & level value, args: \(args)", additionalData: additionalData, error: nil)
        }
    }

}
