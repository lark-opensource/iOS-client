//
//  TrackMetricHandler.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/12.
//

import WebBrowser
import LKCommonsLogging
import LKMetric

class TrackMetricHandler: JsAPIHandler {

    private static let logger = Logger.log(TrackMetricHandler.self, category: "TrackMetricHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        TrackMetricHandler.logger.debug("handle args = \(args))")

        guard let params = args["params"] as? [String: String],
            let domainRaw = args["domain"] as? [Int32],
            let typeRaw = args["type"] as? Int32,
            let emitTypeRaw = args["emitType"] as? Int32,
            let id = args["id"] as? Int32 else {
                if let onFailed = args["onFailed"] as? String {
                    let arguments = [NewJsSDKErrorAPI.missingRequiredArgs.description()] as [[String: Any]]
                    callbackWith(api: api, funcName: onFailed, arguments: arguments)
                }
                TrackMetricHandler.logger.error("TrackMetricHandler failed, args = \(args)")
                return
        }

        let domain = MetricDomain.domain(rawValue: domainRaw)
        if let type = MetricType(rawValue: typeRaw),
            let emitType = EmitType(rawValue: emitTypeRaw) {
            var arguments = [] as [Any]
            if let emitValueRaw = args["emitValue"] as? Int64,
                let emitValue = EmitValue(exactly: emitValueRaw) {
                LKMetric.log(domain: domain, type: type, id: id, emitType: emitType, emitValue: emitValue, params: params)
                arguments = [["domainkey": domain.value, "emitType": emitType.rawValue, "emitValue": emitValue, "type": type.rawValue, "id": id, "params": params]]
                TrackMetricHandler.logger.debug("TrackMetricHandler domain = \(domain.value), type = \(type), id = \(id), emitType = \(emitType.rawValue), emitValue = \(emitValue)")
            } else {
                arguments = [["domainkey": domain.value, "emitType": emitType.rawValue, "type": type.rawValue, "id": id, "params": params]]
                TrackMetricHandler.logger.debug("TrackMetricHandler domain = \(domain.value), type = \(type), id = \(id), emitType = \(emitType.rawValue)")
            }
            LKMetric.log(domain: domain, type: type, id: id, emitType: emitType, params: params)
            if let onSuccess = args["onSuccess"] as? String {
                callbackWith(api: api, funcName: onSuccess, arguments: arguments)
            }
        } else {
            TrackMetricHandler.logger.error("TrackMetricHandler args failed, domain = \(domain.value), typeRaw = \(typeRaw), emitTypeRaw = \(emitTypeRaw)")
        }

        TrackMetricHandler.logger.debug("TrackMetricHandler success, domain = \(domain.value), id = \(id), params = \(params)")
    }
}
