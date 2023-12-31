//
//  ExprExcutor.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/8/18.
//

import Foundation
import LarkExpressionEngine
import LarkSnCService

final class NativeExprExcutor {
    let uuid: String

    init(uuid: String, service: SnCService) {
        self.uuid = uuid
        
        // setup logger
        LKRuleEngineInjectServiceImpl.shared.updateLogger(logger: service.logger)
        LKRuleEngineLogger.register(LKRuleEngineInjectServiceImpl.shared)
        // setup monitor
        LKRuleEngineInjectServiceImpl.shared.updateMonitor(monitor: service.monitor)
        LKRuleEngineReporter.register(LKRuleEngineInjectServiceImpl.shared)
    }
}

extension NativeExprExcutor: ExprExcutor {
    public func evaluate(expr: String, env: ExpressionEnv) throws -> ExprEvalResult {
        let response: LKREExprResponse = LKREExprRunner.shared().execute(expr, with: env, uuid: uuid)
        if response.code != 0 {
            throw ExprEngineError(code: response.code, msg: response.message)
        }
        return ExprEvalResult(paramCost: Int(response.envCost), execCost: Int(response.execCost), parseCost: Int(response.parseCost), result: response.result as? Bool, raw: response.result)
    }
    
    public func type() -> ExprEngineType {
        .native
    }
}
