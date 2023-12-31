//
//  PolicyRunner.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/9/27.
//

import Foundation
import LarkExpressionEngine
import LarkSnCService

public struct PolicyCheckResult {
    public let policy: Policy
    public var isExecuted: Bool = false
    public var effect: Effect = .notApplicable
    public var actions = [ActionName]()
}

public struct RunnerResult {
    public var hits = [PolicyCheckResult]()
    public var combinedEffect = Effect.notApplicable

    public var combinedActions = [ActionName]()
    public var cost: RunnerCost = RunnerCost()
}

public final class PolicyRunner {
    
    private let context: RunnerContext
    private let exprExcutor: ExprExcutor
    private let exprEnv: ExpressionEnv
    private var cost: RunnerCost
    
    public init(context: RunnerContext) {
        self.context = context
        let setting = Setting(service: context.service)
        exprExcutor = ExprExcutorWrapper(service: context.service, useRust: setting.isUseRustExpressionEngine, uuid: context.uuid)
        exprEnv = ExpressionEnv(contextParams: context.contextParams)
        cost = RunnerCost(excutorType: exprExcutor.type())
    }
    
    public func runPolicy() throws -> RunnerResult {
        var result = RunnerResult()
        
        // 策略组合算法
        let policyCombiner = CombineAlgorithmChecker<[ActionName]>(algorithm: context.combineAlgorithm)
        logMsg(level: .info, "Begin run policy with combine algorithm:\(context.combineAlgorithm)")
        
        for policy in context.policies.values {
            logMsg(level: .info, "Begin excute policy [ID:\(policy.id)], [Name: \(policy.name)]")
            
            if policyCombiner.interrupt() {
                logMsg(level: .info, "Interrupt to execute policy with combine algorithm: \(context.combineAlgorithm)")
                break
            }
            
            logMsg(level: .info, "Begin run policy with id:\(policy.id), name:\(policy.name), rule combine algorithm:\(policy.combineAlgorithm)")
            let ruleCombiner = CombineAlgorithmChecker<[ConditionalAction]>(algorithm: policy.combineAlgorithm)
            
            for rule in policy.rules {
                guard !ruleCombiner.interrupt() else {
                    logMsg(level: .info, "Interrupt to execute rule with combine algorithm: \(policy.combineAlgorithm)")
                    break
                }
                logMsg(level: .info, "Start check rule condition. [\(rule.condition.rawExpression)]")
                guard let ruleCheckRet = executeExpression(expression: rule.condition.rawExpression) else {
                    logMsg(level: .info, "Fail to excute rule condition: [\(rule.condition.rawExpression)]")
                    ruleCombiner.push(node: [], effect: .indeterminate)
                    continue
                }
                if ruleCheckRet {
                    ruleCombiner.push(node: rule.decision.actions, effect: rule.decision.effect)
                }
            }
            let (effect, actions) = ruleCombiner.genResult()
            let filterActions = actions.flatMap { $0 }.filter { action in
                return executeExpression(expression: action.condition.rawExpression) ?? false
            }.flatMap { $0.actions }
            policyCombiner.push(node: filterActions, effect: effect)
            result.hits.append(PolicyCheckResult(policy: policy, isExecuted: true, effect: effect, actions: filterActions))
        }
        
        let (effect, actions) = policyCombiner.genResult()
        let compactActions = actions.flatMap { $0 }
        result.combinedEffect = effect
        result.combinedActions = compactActions
        result.cost = self.cost
        return result
    }
}

extension PolicyRunner {
    
    private func reportFailure(expr: String, code: UInt, reason: String) {
        self.context.service.monitor?.info(service: "expression_engine_exec_failure", category: [
            "code": code,
            "reason": reason,
            "expression": expr,
            "type": exprExcutor.type().rawValue
        ])
    }
    
    private func executeExpression(expression: String) -> Bool? {
        cost.exprCount += 1
        do {
            let response = try exprExcutor.evaluate(expr: expression, env: exprEnv)
            cost.paramCost += response.paramCost
            cost.execCost += response.execCost
            cost.parseCost += response.parseCost
            guard let result = response.result else {
                throw ExprEngineError(code: ExprErrorCode.unknown.rawValue, msg: "Result is not a bool value, real type: \(response.raw)")
            }
            return result
        } catch let err as ExprEngineError {
            reportFailure(expr: expression, code: err.code.rawValue, reason: err.msg)
            logMsg(level: .error, err.msg)
        } catch {
            reportFailure(expr: expression, code: ExprErrorCode.unknown.rawValue, reason: error.localizedDescription)
            logMsg(level: .error, error.localizedDescription)
        }
        return nil
    }

    func logMsg(level: LogLevel,
                _ message: String,
                file: String = #fileID,
                line: Int = #line,
                function: String = #function) {
        context.service.logger?.log(level: level, "[PDP: Policy Runner: \(context.uuid)]: \(message)", file: file, line: line, function: function)
    }
}

@objc
final class LKRuleEngineInjectServiceImpl: NSObject, LKRuleEngineLoggerProtocol, LKRuleEngineReporterProtocol {

    static let shared = LKRuleEngineInjectServiceImpl()

    var logger: Logger?
    var monitor: Monitor?

    func updateLogger(logger: Logger?) {
        self.logger = logger
    }

    func updateMonitor(monitor: Monitor?) {
        self.monitor = monitor
    }

    func log(with level: LKRuleEngineLogLevel, message: String, file: String, line: Int, function: String) {
        switch level {
        case .info:
            logger?.log(level: .info, message, file: file, line: line, function: function)
        case .debug:
            logger?.log(level: .debug, message, file: file, line: line, function: function)
        case .warn:
            logger?.log(level: .warn, message, file: file, line: line, function: function)
        case .error:
            logger?.log(level: .error, message, file: file, line: line, function: function)
        default:
            return
        }
    }

    func log(_ event: String, metric: [String: Any], category: [String: Any]) {
        monitor?.info(service: event, category: category, metric: metric)
    }
}
