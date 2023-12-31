//
//  FirstPermitApplicableAlgorithm.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/2/13.
//

import Foundation

final class FirstPermitApplicableAlgorithm<T>: CombineAlgorithmType<T> {

    var permitItems = [T]()
    var denyItems = [T]()
    var hasIndeterminate = false

    override
    func push(node: T, effect: Effect) {
        switch effect {
        case .permit:
            permitItems.append(node)
        case .deny:
            denyItems.append(node)
        case .indeterminate:
            hasIndeterminate = true
        case .notApplicable:
            break
        }
    }

    override
    func interrupt() -> Bool {
        return !permitItems.isEmpty
    }

    override
    func genResult() -> (Effect, [T]) {
        guard permitItems.isEmpty else {
            return (.permit, permitItems)
        }
        guard !hasIndeterminate else {
            return (.indeterminate, [])
        }
        guard denyItems.isEmpty else {
            return (.deny, denyItems)
        }
        return (.notApplicable, [])
    }
}
