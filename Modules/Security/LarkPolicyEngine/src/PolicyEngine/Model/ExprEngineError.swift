//
//  ExprEngineError.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/9/25.
//

import Foundation

public enum ExprErrorCode: UInt {
    case unknown = 100
}

struct ExprEngineError: Error {
    let code: ExprErrorCode
    let msg: String
    
    init(code: UInt, msg: String) {
        self.code = ExprErrorCode(rawValue: code) ?? .unknown
        self.msg = msg
    }
}
