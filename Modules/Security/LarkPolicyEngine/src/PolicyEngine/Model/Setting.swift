//
//  Setting.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/11/22.
//

import Foundation
import LarkSnCService

// setting列表
struct Setting {
    static let enablePolicyEngine = "enable_policy_engine"
    static let policyEngineDisableLocalValidate = "policy_engine_disable_local_validate"
    static let policyEngineFetchPolicyInterval = "policy_engine_fetch_policy_interval"
    static let policyEngineLocalValidateCountLimit = "policy_engine_local_validate_count_limit"
    static let policyEnginePointcutRetryDelay = "policy_engine_pointcut_retry_delay"
    static let useRustExpressionEngine = "use_rust_expression_engine"
    static let disableLocalDecisionPointcutList = "disable_local_decision_pointcut_list"
    static let policyEngineFetchPolicyNum = "policy_engine_fetch_policy_num"

    private let service: SnCService

    init(service: SnCService) {
        self.service = service
    }

    var isEnablePolicyEngine: Bool {
        return (try? service.settings?.bool(key: Setting.enablePolicyEngine, default: true)) ?? true
    }

    var disableLocalValidate: Bool {
        return (try? service.settings?.bool(key: Setting.policyEngineDisableLocalValidate, default: false)) ?? false
    }

    var localValidateLimitCount: Int {
        return (try? service.settings?.int(key: Setting.policyEngineLocalValidateCountLimit, default: 100)) ?? 100
    }

    var fetchPolicyInterval: Int {
        return (try? service.settings?.int(key: Setting.policyEngineFetchPolicyInterval, default: 60 * 5)) ?? 5 * 60
    }

    var pointcutRetryDelay: Int {
        return (try? service.settings?.int(key: Setting.policyEnginePointcutRetryDelay, default: 5)) ?? 5
    }
    
    var isUseRustExpressionEngine: Bool {
        return (try? service.settings?.bool(key: Setting.useRustExpressionEngine, default: false)) ?? false
    }

    var disableLocalDecisionPointcutList: [String] {
        return (try? service.settings?.stringList(key: Setting.disableLocalDecisionPointcutList, default: [])) ?? []
    }

    var policyEngineFetchPolicyNum: Int {
        return (try? service.settings?.int(key: Setting.policyEngineFetchPolicyNum, default: 20)) ?? 20
    }
}
