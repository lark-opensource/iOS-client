//
//  OnlyOneApplicableAlgorithm.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/2/13.
//

import Foundation

final class OnlyOneApplicableAlgorithm<T>: CombineAlgorithmType<T> {

    var items = [T]()
    var hasIndeterminate = false
    var effect: Effect = .notApplicable

    override
    func push(node: T, effect: Effect) {
        switch effect {
        case .permit, .deny:
            items.append(node)
            self.effect = effect
        case .indeterminate:
            hasIndeterminate = true
        case .notApplicable:
            break
        }
    }

    override
    func interrupt() -> Bool {
        return false
    }

    override
    func genResult() -> (Effect, [T]) {
        if items.count == 1 {
            return (effect, items)
        }
        if items.count >= 2 || hasIndeterminate {
            return (.indeterminate, [])
        }
        return (effect, items)
    }
}
