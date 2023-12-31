//
//  CombineAlgorithmType.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/2/13.
//

import Foundation

class CombineAlgorithmType<T> {
    func push(node: T, effect: Effect) {
        assertionFailure()
    }

    func interrupt() -> Bool {
        assertionFailure()
        return true
    }

    func genResult() -> (Effect, [T]) {
        assertionFailure()
        return (.permit, [])
    }
}
