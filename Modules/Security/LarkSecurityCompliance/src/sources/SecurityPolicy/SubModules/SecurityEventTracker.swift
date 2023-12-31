//
//  SecurityEventTracker.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/12/12.
//

import Foundation
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface
import LarkPolicyEngine
import SwiftyJSON

extension ValidateConfig {
    var description: [String: String] {
        return ["cid": cid]
    }
}

final class SecurityPolicyEventTrack {
    static func larkSCSFileStrategyResult(resultGroups: [PolicyModel: ValidateResult], function: SecurityAuthFunction, additional: [String: String]) {
        resultGroups.forEach {
            let policyModel = $0.key
            let result = $0.value
            let entityDic = policyModel.entity.asParams()
            let fileBizDomian = entityDic["fileBizDomain"] ?? FileBizDomain.unknown.rawValue

            var category: [String: Any] = [
                "result": result.result.rawValue,
                "source": result.extra.resultMethod?.rawValue ?? "",
                "operation": policyModel.entity.entityOperate.rawValue,
                "entityType": policyModel.entity.entityType.rawValue,
                "entityDomain": policyModel.entity.entityDomain.rawValue,
                "pointKey": policyModel.pointKey.rawValue,
                "fileBizDomain": fileBizDomian
            ]
            category.merge(additional) { (current, _ ) in current }
            SCMonitor.info(business: .security_policy, eventName: "result", category: category)
        }
        SPLogger.info("security policy:\(function) validate, security sdk get result: \(resultGroups)", additionalData: additional)
    }

    static func larkSCSFileStrategyUpdate(trigger: String, duration: Double, result: [ValidateResponse]) {
        let category: [String: Any] = [
            "trigger": trigger
        ]

        let metric: [String: Any] = [
            "duration": duration * 1000
        ]

        SCMonitor.info(business: .security_policy, eventName: "update", category: category, metric: metric)
    }

    static func larkSCSActionFailPopUpView(businessType: String, actionType: String) {
        let params: [String: Any] = [
            "business_type": businessType,
            "action_type": actionType
        ]
        let servicename = "scs_action_fail_popup_view"
        SPLogger.info("security policy: pop intercept dialog with \(businessType), \(actionType)")
        Events.track(servicename, params: params)
    }

    static func larkSCSUnknownAction(actionName: String) {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        SPLogger.error("security policy: unknow action name \(actionName)")
        Events.track("security_policy_unknown_action", params: [
                   "action_name": actionName,
                   "versionName": appVersion
               ])
    }

    static func larkSCSHandleAction(actionSource: SecurityPolicyActionSource,
                                    actionName: String,
                                    actionStyle: String = SecurityPolicyActionStyle.unknown.rawValue) {
        let category: [String: Any] = [
            "actionSource": actionSource.rawValue,
            "actionName": actionName,
            "actionStyle": actionStyle
        ]
        SCMonitor.info(business: .security_policy,
                       eventName: "handle_action",
                       category: category)
    }

    static func larkSCSHandleActionError(actionSource: SecurityPolicyActionSource,
                                         errorType: SecurityPolicyHandleActionErrorType) {
        let category: [String: Any] = [
            "actionSource": actionSource.rawValue,
            "errorType": errorType.rawValue
        ]
        SCMonitor.info(business: .security_policy,
                       eventName: "handle_action_error",
                       category: category)
    }

    static func scsSecurityPolicyInit(duration: Double) {
        let metric: [String: Any] = [
            "duration": duration * 1000
        ]
        SCMonitor.info(business: .security_policy,
                       eventName: "init",
                       metric: metric)
    }

    static func scsSecurityPolicyDynamicCapacity(pointKey: String, current: Int) {
        let category: [String: Any] = [
            "pointKey": pointKey
        ]
        let metric: [String: Any] = [
            "current_capacity": current
        ]
        SCMonitor.info(business: .security_policy,
                       eventName: "dynamic_capacity",
                       category: category,
                       metric: metric)
    }

    static func scsSecurityPolicyHitDelayClearCache(policyModel: PolicyModel, duration: Double) {
        let entity = policyModel.entity
        let entityDic = policyModel.entity.asParams()
        let fileBizDomian = entityDic["fileBizDomain"]
        let category: [String: Any] = [
            "operation": entity.entityOperate.rawValue,
            "entityType": entity.entityType.rawValue,
            "entityDomain": entity.entityDomain.rawValue,
            "pointKey": policyModel.pointKey.rawValue,
            "fileSourceDomain": fileBizDomian ?? FileBizDomain.unknown.rawValue
        ]
        let metric: [String: Any] = [
            "delay_duration": duration
        ]
        SPLogger.info("security policy: hit delay clear cache \(policyModel.pointKey.rawValue)")
        SCMonitor.info(business: .security_policy,
                       eventName: "hit_delay_clear_cache",
                       category: category,
                       metric: metric)
    }
    
    static func hitInvalidCache(policyModel: PolicyModel, checkerType: String, duration: Double) {
        let entity = policyModel.entity
        let entityDic = policyModel.entity.asParams()
        let fileBizDomian = entityDic["fileBizDomain"]
        let category: [String: Any] = [
            "operation": entity.entityOperate.rawValue,
            "entityType": entity.entityType.rawValue,
            "entityDomain": entity.entityDomain.rawValue,
            "pointKey": policyModel.pointKey.rawValue,
            "fileSourceDomain": fileBizDomian ?? FileBizDomain.unknown.rawValue,
            "checker": checkerType
        ]
        let metric: [String: Any] = [
            "invalid_duration": duration
        ]
        SCMonitor.info(business: .security_policy,
                       eventName: "hit_invalid_cache",
                       category: category,
                       metric: metric)
    }
    
    static func dlpEngineFetch(trigger: String, duration: Double) {
        let category: [String: Any] = [
            "trigger": trigger
        ]
        let metric: [String: Any] = [
            "duration": duration
        ]
        SCMonitor.info(business: .security_policy,
                       eventName: "dlp_engine_fetch",
                       category: category,
                       metric: metric)
    }

    static func scsSecurityPolicyInitVersion() {
        SCMonitor.info(business: .security_policy,
                       eventName: "init_version",
                       category: ["version": "V1"])
        SPLogger.info("init SP V1")
    }

}

internal enum SecurityPolicyHandleActionErrorType: String {
    case deserialization
    case requiredFieldNotFound
}

internal enum SecurityPolicyActionSource: String {
    case business
    case responseHeaderOrSDKInternal
    case responseHeader
    case sdkInternal
}

internal enum SecurityPolicyUpdateTrigger {
    case constructor
    case becomeActive
    case networkChange
    case strategyEngine

    var callTrigger: StrategyEngineCallTrigger {
        switch self {
        case .constructor:
            return .constructor
        case .becomeActive:
            return .becomeActive
        case .networkChange:
            return .networkChange
        case .strategyEngine:
            return .strategyEngine
        }
    }
}

internal enum StrategyEngineCallTrigger: String {
    case unknown
    case constructor
    case becomeActive
    case networkChange
    case strategyEngine
    case noCacheRetry
    case businessCheck
    case retry
}

internal enum SecurityAuthFunction {
    case asyncValidate
    case cacheValidate
    case batchAsyncValidate
}
