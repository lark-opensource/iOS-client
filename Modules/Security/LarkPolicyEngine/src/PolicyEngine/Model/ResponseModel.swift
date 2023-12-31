//
//  ResponseModel.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/1/13.
//

import Foundation

struct ResponseModel<T: Codable>: Codable {
    let code: Int?
    let data: T?
    let msg: String?
}

extension Optional where Wrapped == Int {
    var isZeroOrNil: Bool {
        guard let real = self else { return true }
        return real == 0
    }
}
