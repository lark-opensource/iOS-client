//
//  ExprExcutorWrapper.swift
//  LarkPolicyEngine
//
//  Created by ByteDance on 2023/9/6.
//

import Foundation
import LarkSnCService
import LarkRustClient
import LarkExpressionEngine

public protocol ExprExcutor {
    func evaluate(expr: String, env: ExpressionEnv) throws -> ExprEvalResult
    func type() -> ExprEngineType
}

public enum ExprEngineType: String {
    case rust
    case native
    case unknown
}

public struct ExprEvalResult {
    let paramCost: Int
    let execCost: Int
    let parseCost: Int
    /// if raw is Bool value, it will be fill in result, otherwise will be nil
    let result: Bool?
    var raw: Any
}

public final class ExprExcutorWrapper {
    
    private let inner: ExprExcutor
    private let useRust: Bool
    private let service: SnCService
    
    var exprCount = 0
    var parseCost = 0
    var execCost = 0
    var paramCost = 0
    
    public init(service: SnCService, useRust: Bool, uuid: String) {
        self.useRust = useRust
        self.service = service
        if useRust {
            inner = RustExprExcutor()
        } else {
            inner = NativeExprExcutor(uuid: uuid, service: service)
        }
    }
}

extension ExprExcutorWrapper: ExprExcutor {
    
    public func evaluate(expr: String, env: ExpressionEnv) throws -> ExprEvalResult {
        return try inner.evaluate(expr: expr, env: env)
    }
    
    public func type() -> ExprEngineType {
        return inner.type()
    }
}
