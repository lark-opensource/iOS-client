//
//  MailAPMMonitorService.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/10/4.
//

import Foundation
import AppReciableSDK

class MailAPMMonitorService {
    static let shared = MailAPMMonitorService()

    let queue = DispatchQueue(label: "MailAPMMonitorService.logQueue", qos: .background)
}

extension MailAPMMonitorable {
    fileprivate func toEventData() -> EventData {
        var costTime: TimeInterval = 0
        if let baseEvent = self as? MailAPMEventPropery {
            // we will add cost time for end event
            costTime = baseEvent.totalCostTime
        } else {
            assert(false, "call @liutefeng!")
            costTime = 0
        }
        return EventData(startKey: startKey,
                         commonParams: commonParams,
                         startParams: startParams,
                         requireStartParamsKey: requireStartParamsKey,
                         endKey: endKey,
                         endParams: endParams,
                         requireEndParamsKey: requireEndParamsKey,
                         totalCostTime: costTime,
                         reciableConfig: reciableConfig)
    }
}

private struct EventData {
    var startKey: MailAPMEventConstant.StartKey
    /// this will be added to start & end
    var commonParams: [MailAPMEventParamAble]

    var startParams: [MailAPMEventParamAble]

    /// the params that start event should upload
    var requireStartParamsKey: Set<String>

    var endKey: MailAPMEventConstant.EndKey

    var endParams: [MailAPMEventParamAble]

    /// the params that end event should upload
    var requireEndParamsKey: Set<String>

    var totalCostTime: TimeInterval

    var reciableConfig: MailAPMReciableConfig?
}

extension MailAPMMonitorService {
    static func postStart(event: MailAPMMonitorable) {
        let data = event.toEventData()
        MailAPMMonitorService.shared.queue.async {
            MailAPMMonitorService.innerPostStart(event: data)
        }
    }

    private static func innerPostStart(event: EventData) {
        guard event.startKey != .unknown else {
            return
        }
        var event = event
        let key = event.startKey
        var paramArray = event.startParams
        // add common params
        appendCommonParams(event: &event)
        if !event.commonParams.isEmpty {
            paramArray.append(contentsOf: event.commonParams)
        }
        let (param, _) = paramArray.apmEventParams()
        // check whether key is all covered
        var requireKeys = event.requireStartParamsKey
        for temp in param.keys {
            requireKeys.remove(temp)
        }
        if !requireKeys.isEmpty {
            assert(false, "missing start param")
            MailLogger.debug("event: \(event.startKey). missing start params:\(requireKeys)")
            offTrack(event: event.endKey, type: .type_fill_without_start, message: nil)
        }
        print("----------------- event start: \(key), params: \(param)")
        MailTracker.log(event: key.rawValue, params: param)
        // reciable event has no Start Event
    }

    static func postEnd(event: MailAPMMonitorable) {
        let data = event.toEventData()
        MailAPMMonitorService.shared.queue.async {
            MailAPMMonitorService.innerPostEnd(event: data)
        }
    }

    static func postEndImmediately(event: MailAPMMonitorable) {
        let data = event.toEventData()
        MailAPMMonitorService.innerPostEnd(event: data)
    }

    private static func innerPostEnd(event: EventData) {
        guard event.endKey != .unknown else {
            return
        }
        var event = event
        let key = event.endKey
        var paramArray = event.endParams
        // add common params
        appendCommonParams(event: &event)
        if !event.commonParams.isEmpty {
            paramArray.append(contentsOf: event.commonParams)
        }
        var (param, recibaleParams) = paramArray.apmEventParams()
            // we will add cost time for end event
        param["time_cost_ms"] = event.totalCostTime * 1000
        recibaleParams["time_cost_ms"] = event.totalCostTime * 1000
        // check whether key is all covered
        var requireKeys = event.requireEndParamsKey
        for temp in param.keys {
            requireKeys.remove(temp)
        }
        if !requireKeys.isEmpty {
            MailLogger.debug("event: \(event.endKey). missing end params:\(requireKeys) param: \(param)")
//            assert(false, "missing end param")
            offTrack(event: event.endKey, type: .type_launch_without_fill, message: nil)
        }
        if key != .rustCall {
            print("----------------- event end: \(key), params: \(param)")
        }
        MailTracker.log(event: key.rawValue, params: param)
        if let config = event.reciableConfig {
            reciablePostEnd(config: config, params: recibaleParams)
        }
    }

    private static func appendCommonParams(event: inout EventData) {
        // if exist. we should remove old one
        if let index = event.commonParams.firstIndex(where: { (param) -> Bool in
            return param.key == MailAPMEventConstant.CommonParam.net_status(0).key
        }) {
            event.commonParams.remove(at: index)
        }
        if let index = event.commonParams.firstIndex(where: { (param) -> Bool in
            return param.key == MailAPMEventConstant.CommonParam.app_env("").key
        }) {
            event.commonParams.remove(at: index)
        }
        let current = LarkPushDataManager.shared.dynamicNetStatus.value
        event.commonParams.append(MailAPMEventConstant.CommonParam.net_status(current.netWorkStatusValue()))
        event.commonParams.append(MailAPMEventConstant.CommonParam.app_env(MailEnvConfig.appEnv))
        event.commonParams.appendOrUpdate(MailAPMEventConstant.CommonParam.mail_account_type(Store.settingData.getMailAccountType()))
        // 增加账号相关信息公参，不要触发请求，有就用没有就算了
        if let account = Store.settingData.getCachedCurrentAccount(fetchNet: false) {
            event.commonParams.append(MailAPMEventConstant.CommonParam.customKeyValue(key: "is_main_account", value: account.isShared ? 0 : 1 ))
            event.commonParams.append(MailAPMEventConstant.CommonParam.customKeyValue(key: "mail_account_id", value: account.mailAccountID))
        }
    }
}

extension MailAPMMonitorService {
    static func offTrack(event key: MailAPMEventConstant.EndKey,
                                 type: MailAPMEventSingle.OffTrack.EndParam,
                                 message: String?) {
        let event = MailAPMEventSingle.OffTrack()
        event.endParams.append(MailAPMEventSingle.OffTrack.EndParam.event_name(key))
        event.endParams.append(type)
        if let info = message {
            event.endParams.append(MailAPMEventSingle.OffTrack.EndParam.message(info))
        }
        event.markPostStart()
        event.postEnd()
    }
}

// MARK: App Reciable Event
extension MailAPMMonitorService {
    static func reciablePostEnd(config: MailAPMReciableConfig, params: [String: Any]) {
        // 排除user_leave的情况
        if let status = params[MailAPMEventConstant.CommonParam.status_user_leave.reciableKey] as? String,
           let leaveValue = MailAPMEventConstant.CommonParam.status_user_leave.value as? String,
           status == leaveValue {
            return
        }

        var latencyDetail: [String: Any]?
        var category: [String: Any] = params
        var metric: [String: Any]? = nil
        if let temp = config.latencyDetailKeys {
            latencyDetail = [:]
            for key in temp.map({ return $0.reciableKey }) {
                if let value = params[key] {
                    latencyDetail?[key] = value
                    category[key] = nil // remove from param
                } else {
                    assert(false, "no target key found in params")
                }
            }
        }
        if let temp = config.metricKeys {
            metric = [:]
            for key in temp.map({ return $0.reciableKey }) {
                if let value = params[key] {
                    metric?[key] = value
                    category[key] = nil // remove from param
                } else {
                    assert(false, "no target key found in params")
                }
            }
        }
        let extra = Extra(isNeedNet: true,
                          latencyDetail: latencyDetail,
                          metric: metric,
                          category: category,
                          extra: nil)

        if let status = params[MailAPMEventConstant.CommonParam.status_success.reciableKey] as? String,
           let successValue = MailAPMEventConstant.CommonParam.status_success.value as? String,
           status == successValue {
            if let cost = costMapper(param: params) {
                // only SUCCESS can post timecost event
                let timeCost = TimeCostParams(biz: .Mail,
                                              scene: config.scene,
                                              eventable: config.event,
                                              cost: cost,
                                              page: config.page?.rawValue,
                                              extra: extra)
                MailLogger.info("[MailAPMEvent][success] eventKey:(\(config.event)) timeCost:(\(cost))")
                AppReciableSDK.shared.timeCost(params: timeCost)
            } else {
                mailAssertionFailure("cannot success without time cost")
            }
        } else if let status = params[MailAPMEventConstant.CommonParam.status_success.reciableKey] as? String,
                   let timeout = MailAPMEventConstant.CommonParam.status_timeout.value as? String,
                  let rustfail = MailAPMEventConstant.CommonParam.status_rust_fail.value as? String,
                  let exception = MailAPMEventConstant.CommonParam.status_exception.value as? String,
                  let httpFail = MailAPMEventConstant.CommonParam.status_http_fail.value as? String,
                  [timeout, rustfail, exception, httpFail].contains(status) {
            var code: Int = 0
            if let value = params[MailAPMEventConstant.CommonParam.error_code(0).key],
                let errorCode = Int(String(describing: value)) {
                code = errorCode
            }

            let error = ErrorParams.init(biz: .Mail,
                                         scene: config.scene,
                                         eventable: config.event,
                                         errorType: errorTypeMapper(params: params),
                                         errorLevel: .Fatal,
                                         errorCode: code,
                                         userAction: nil,
                                         page: config.page?.rawValue,
                                         errorMessage: status,
                                         extra: extra)
            MailLogger.info("[MailAPMEvent][] eventKey:(\(config.event)) debugMessage:(\(extra.category?[MailAPMEventConstant.CommonParam.debug_message("").reciableKey]))")
            AppReciableSDK.shared.error(params: error)
        } else {
            mailAssertionFailure("missing reciable event \(config)")
        }
    }

    private static func costMapper(param: [String: Any]) -> Int? {
        if let intValue = param["time_cost_ms"] as? Int {
            return intValue
        } else if let doubleValue = param["time_cost_ms"] as? Double {
            return doubleValue < Double.init(Int.max) ? Int.init(doubleValue) + 1 : Int.max
        } else if let intValue = param["cost_time"] as? Int {
            return intValue
        } else if let doubleValue = param["cost_time"] as? Double {
            return doubleValue < Double.init(Int.max) ? Int.init(doubleValue) + 1 : Int.max
        }
        return nil
    }

    private static func errorTypeMapper(params: [String: Any]) -> ErrorType {
        var type: ErrorType = .Unknown
        guard let rustFail = MailAPMEventConstant.CommonParam.status_rust_fail.value as? String,
              let exception = MailAPMEventConstant.CommonParam.status_exception as? String,
              let httpFail = MailAPMEventConstant.CommonParam.status_http_fail.value as? String else {
            return type
        }

        if let status = params[MailAPMEventConstant.CommonParam.status_rust_fail.reciableKey] as? String {
           if status == rustFail {
              if let errorCode = params[MailAPMEventConstant.CommonParam.error_code(0).key] as? Int32 {
                if errorCode == MailErrorCode.offlineError || errorCode == MailErrorCode.networkError {
                    type = .Network
                } else {
                    type = .SDK
                }
              }
           } else if status == httpFail {
               type = .Network
           } else if status == exception {
               type = .Other
           }
        }
        return type
    }
}

// MARK: helper

extension DynamicNetStatus {
    func netWorkStatusValue() -> Int {
        var value = 1
        switch self {
        case .excellent:
            value = 1
        case .evaluating:
            value = 2
        case .weak:
            value = 3
        case .netUnavailable:
            value = 4
        case .serviceUnavailable:
            value = 5
        case .offline:
            value = 6
        @unknown default:
            assert(false, "please fix it")
        }
        return value
    }
}
