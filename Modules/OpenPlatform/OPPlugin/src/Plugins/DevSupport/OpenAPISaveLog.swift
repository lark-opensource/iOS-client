//
//  OpenAPISaveLog.swift
//  OPPlugin
//
//  Created by 王飞 on 2021/10/28.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LKCommonsLogging
import LarkContainer

private let logger = Logger.oplog(OpenAPISaveLog.self, category: "open_platform_api_save_log")

@objc(OpenAPISaveLog)
final class OpenAPISaveLog: OpenBasePlugin {
    struct Log: CustomStringConvertible {
        struct LogTag {
            let appIdentify: String
            let traceId: String
            func toDictionary() -> [String: Any] {
                [
                    "appIdentify": appIdentify,
                    "traceid": traceId
                ]
            }
        }
        let message: [AnyHashable]
        let level: String
        let time: TimeInterval
        let tag: LogTag
        init(log: OpenAPILogModel, tag: LogTag) {
            message = log.message
            level = log.level
            time = log.time
            self.tag = tag
        }
        func toDictionary() -> [String: Any] {
            [
                "message": message,
                "level": level,
                "time": time,
                "tags": [
                    "common-tag": tag.toDictionary()
                ]
            ]
        }
        var description: String {
            do {
                let data = try JSONSerialization.data(withJSONObject: toDictionary(), options: .fragmentsAllowed)
                return String(data: data, encoding: .utf8) ?? "OpenAPISaveLog data to String encode failed"
            } catch let err {
                return err.localizedDescription
            }
        }
    }

    // implemention of api handlers
    private class func saveLog(params: OpenAPILogModel, context: OpenAPIContext) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        let appIdentify = context.gadgetContext?.uniqueID.identifier ?? "nil"
        let traceId = context.apiTrace.traceId
        let log = Log(log: params, tag: Log.LogTag(appIdentify: appIdentify, traceId: traceId))
        logger.info("\(log)", tag: "open_platform_api_save_log")
        return .success(data: nil)
    }
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        // register your api handlers here
        registerSyncHandler(for: "saveLog", paramsType: OpenAPILogModel.self, handler: Self.saveLog)
    }

}
