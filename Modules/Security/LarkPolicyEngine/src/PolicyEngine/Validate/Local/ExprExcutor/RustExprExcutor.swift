//
//  RustExprExcutor.swift
//  LarkPolicyEngine
//
//  Created by ByteDance on 2023/9/4.
//

import Foundation
import LarkRustClient
import RustPB
import LarkContainer
import LarkExpressionEngine

final class RustExprExcutor {
    @Provider var rustClient: GlobalRustService
}

extension RustExprExcutor: ExprExcutor {
    public func evaluate(expr: String, env: ExpressionEnv) throws -> ExprEvalResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        var request = Security_V1_ExpressionEvalRequest()
        request.enableCache = true
        request.expression = expr
        request.paramters = try env.generateParam().mapValues({ value in
            try Security_V1_ExprValue(value: value)
        })
        let paramCostTime = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1_000_000)
        do {
            let response = try rustClient.sync(message: request) as Security_V1_ExpressionEvalResponse
            guard response.hasResult else {
                let error = ExprEngineError(code: ExprErrorCode.unknown.rawValue, msg: "Response has no result.")
                throw error
            }
            var boolRet: Bool?
            if case .boolValue(let v)? = response.result.value {
                boolRet = v
            }
            let exprEvalResult = ExprEvalResult(paramCost: paramCostTime,
                                                execCost: Int(response.execCost),
                                                parseCost: Int(response.parseCost),
                                                result: boolRet,
                                                raw: response)
            return exprEvalResult
        } catch {
            if case let .businessFailure(info) = error as? RCError {
                let errorCode = UInt(info.errorCode)
                let engineError = ExprEngineError(code: errorCode, msg: info.debugMessage)
                throw engineError
            } else {
                throw ExprEngineError(code: ExprErrorCode.unknown.rawValue, msg: error.localizedDescription)
            }
        }
    }
    
    public func type() -> ExprEngineType {
        .rust
    }
}

extension Security_V1_ExprValue {
    init(value: Any) throws {
        self.init()
        switch value {
        case let value as Bool: self.value = .boolValue(value)
        case let value as String: self.value = .stringValue(value)
        case let value as Array<Any>: self.value = .arrayValue(try ArrayValue(value: value))
        case let value as NSNumber:
            if value.stringValue.contains(".") {
                self.value = .doubleValue(value.doubleValue)
            } else {
                self.value = .longValue(value.int64Value)
            }
        case is NSNull: self.value = .nullValue(Security_V1_ExprValue.NullValue())
        default: throw ExprEngineError(code: ExprErrorCode.unknown.rawValue, msg: "Unknown value type: \(String(describing: value))")
        }
    }
}

extension Security_V1_ExprValue.ArrayValue {
    init(value: Array<Any>) throws {
        self.init()
        self.value = try value.map({ item in
            try Security_V1_ExprValue(value: item)
        })
    }
}
