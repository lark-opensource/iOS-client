//
//  TrackExtension.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/11/22.
//

import Foundation
import LarkSnCService

struct LocalValidateLogInfo {
    var parseCost: Int
    var execCost: Int
    var paramCost: Int
    var exprCount: Int
    var totalCost: Int
    var averageCost: Int {
        guard exprCount > 0 else {
            return 0
        }
        return totalCost / exprCount
    }
    var exprEngineType: ExprEngineType

    static var `default`: LocalValidateLogInfo {
        return LocalValidateLogInfo(parseCost: 0, execCost: 0, paramCost: 0, exprCount: 0, totalCost: 0, exprEngineType: .unknown)
    }
}

extension ValidateResponse {
    private struct AssociatedKeys {
        static var logInfo: Bool = false
    }

    var logInfo: LocalValidateLogInfo {
        get {
            if let t = objc_getAssociatedObject(self, &AssociatedKeys.logInfo) as? LocalValidateLogInfo {
                return t
            }
            let t = LocalValidateLogInfo.default
            objc_setAssociatedObject(self, &AssociatedKeys.logInfo, t, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return t
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.logInfo, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func trackTaskPerf(request: ValidateRequest, monitor: Monitor?) {
        // 业务属性
        // - uuid: 唯一标识符
        // - point_key: 切点key
        // - policy_type: 策略类型 （这个可能要拓展）
        // - entity_domain
        // - entity_type
        // - entity_operate
        // - result_type:  ("fast_pass", "block", "pass", "error") 计算的结果类型
        // 性能属性
        // - parse_cost : 表达式解析总时长
        // - exec_cost : 所有表达式总的执行耗时
        // - param_cost : 所有表达式总的参数获取耗时
        // - expr_count：表达式条数
        // - total_cost: 总耗时（从策略选取，到计算出结果的总时长）
        // - average_cost: 平均耗时(total_cost / expr_count)
        let entityDomain = request.entityJSONObject["entityDomain"]
        let entityType = request.entityJSONObject["entityType"]
        let entityOperate = request.entityJSONObject["entityOperate"]
        monitor?.info(service: "single_validate_cost", category: [
            "uuid": self.uuid,
            "point_key": request.pointKey,
            "entity_domain": entityDomain,
            "entity_type": entityType,
            "entity_operate": entityOperate,
            "result_type": type.rawValue,
            "expr_engine_type": logInfo.exprEngineType.rawValue
        ], metric: [
            "parse_cost": logInfo.parseCost,
            "exec_cost": logInfo.execCost,
            "param_cost": logInfo.paramCost,
            "expr_count": logInfo.exprCount,
            "total_cost": logInfo.totalCost,
            "average_cost": logInfo.averageCost
        ])
    }

    func trackResult(request: ValidateRequest, tracker: Tracker?) {
        tracker?.track(event: "policy_engine_result", params: [
            "pointKey": request.pointKey,
            "effect": effect.rawValue,
            "actions": actions.map({ action in
                action.name
            }).reduce("", { partialResult, string in
                return "\(partialResult), \(string)"
            }),
            "result_type": type.rawValue
        ])
    }
}

extension PolicyEngine {
    func trackCombineValidateCost(localDuration: Int, remoteDuration: Int, totalDuration: Int, count: Int) {
        service.monitor?.info(service: "combine_validate_cost", category: [
            "task_count": count
        ], metric: [
            "total_cost": totalDuration,
            "local_cost": localDuration,
            "remote_cost": remoteDuration
        ])
    }

    enum ResponseState: String {
        case fastPass = "fast_pass"
        case onlyLocal = "only_local"
        case mixRemote = "mix_remote"
        case onlyRemote = "only_remote"
        case mixDowngrade = "mix_downgrade"
        case onlyDowngrade = "only_downgrade"
    }

    func trackCombineResult(responseMap: [String: ValidateResponse]) {
        var state: ResponseState = .fastPass
        var local = false
        var remote = false
        var downgrade = false
        var fastPass = false
        responseMap.forEach { _, response in
            switch response.type {
            case .local:
                local = true
            case .remote:
                remote = true
            case .downgrade:
                downgrade = true
            case .fastPass:
                fastPass = true
            }
        }

        if downgrade {
            if remote || local || fastPass {
                state = .mixDowngrade
            } else {
                state = .onlyDowngrade
            }
        } else if remote {
            if local || fastPass {
                state = .mixRemote
            } else {
                state = .onlyRemote
            }
        } else if local {
            state = .onlyLocal
        } else {
            state = .fastPass
        }

        service.tracker?.track(event: "policy_engine_usage", params: [
            "validate_count": responseMap.count,
            "state": state.rawValue
        ])
    }
}
