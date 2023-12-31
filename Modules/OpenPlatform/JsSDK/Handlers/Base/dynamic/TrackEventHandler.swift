//
//  TrackEventHandler.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/12.
//

import WebBrowser
import LKCommonsLogging
import LKCommonsTracker

class TrackEventHandler: JsAPIHandler {

    private static let logger = Logger.log(TrackEventHandler.self, category: "TrackEventHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        TrackEventHandler.logger.debug("handle args = \(args))")

        if let eventName = args["eventName"] as? String,
            let eventParams = args["eventParams"] as? [String: Any] {
            if let onSuccess = args["onSuccess"] as? String {
                let arguments = [["eventName": "\(eventName)", "eventParams": eventParams]] as [[String: Any]]
                callbackWith(api: api, funcName: onSuccess, arguments: arguments)
            }
            Tracker.post(TeaEvent(eventName, params: eventParams))
            TrackEventHandler.logger.debug("TrackEventHandler success, eventName = \(eventName), eventParams = \(eventParams)")
        } else {
            if let onFailed = args["onFailed"] as? String {
                let arguments = [NewJsSDKErrorAPI.missingRequiredArgs.description()] as [[String: Any]]
                callbackWith(api: api, funcName: onFailed, arguments: arguments)
            }
        }
    }
}
