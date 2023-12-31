//
//  ExpressionEnv.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/9/29.
//

import Foundation
import LarkExpressionEngine

public final class ExpressionEnv: NSObject {
    private let contextParams: [String: Any]
    private var timeCost: CFTimeInterval = 0

    public init(contextParams: [String: Any]) {
        self.contextParams = contextParams
    }
}

// Native
extension ExpressionEnv: LKREExprEnvProtocol {
    public func envValue(ofKey key: String) -> Any? {
        contextParams[key]
    }

    public func resetCost() {
        timeCost = 0
    }

    public func cost() -> CFTimeInterval {
        timeCost
    }
}

// Rust
extension ExpressionEnv {
    func generateParam() -> [String: Any] {
        return contextParams
    }
}
