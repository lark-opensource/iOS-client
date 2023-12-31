//
//  NativeLoggerHandler.swift
//  JsSDK
//
//  Created by Miaoqi Wang on 2020/9/22.
//

import UIKit
import WebBrowser
import LKCommonsLogging

/// https://bytedance.feishu.cn/docs/doccnJBsS2lZl87oWhDmZkfqY5d#ODc8N5
class NativeLoggerHandler: CheckPermissionJsAPIHandler {

    override func validatedHandle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard var msg = args["msg"] as? String else {
            Self.logger.error("no msg for log")
            callback.callbackFailure(param: NewJsSDKErrorAPI.badArgumentType(extraMsg: "").description())
            return
        }
        let tag = (args["tag"] as? String) ?? ""
        msg = "\(tag)-\(msg)"
        if let rawLavel = args["level"] as? Int, let level = Level(rawValue: rawLavel) {
            Self.logger.log(level: level.nativeLogLevel(), msg, tag: tag)
        } else {
            Self.logger.info(msg, tag: tag)
        }

        callback.callbackSuccess(param: ["code": 0])
    }
}

extension NativeLoggerHandler {
    enum Level: Int {
        case info
        case verbose
        case debug
        case warn
        case error

        func nativeLogLevel() -> LogLevel {
            switch self {
            case .info: return .info
            case .verbose: return .trace
            case .debug: return .debug
            case .warn: return .warn
            case .error: return .error
            }
        }
    }
}
